/// Airpass Protocol — Background Service (Main Isolate Mesh)
///
/// Configures [flutter_background_service] to show a persistent notification,
/// which keeps the Android process alive.
///
/// The actual mesh network logic now runs in the main UI isolate instead of a
/// background isolate. This allows `nearby_connections` to access the `Activity`
/// it requires. If the user explicitly swipes the app away from recent apps,
/// the main isolate dies and the mesh stops.
///
/// ## Scanning Strategy: Exponential Backoff
///
/// To preserve battery while maintaining mesh participation, the
/// service cycles between active scanning windows and sleep intervals:
///
/// ```
/// [SCAN 10s] → sleep 5s → [SCAN 10s] → sleep 7.5s → [SCAN 10s] → sleep 11.25s → ...
///                                                                         ↑
///                                                           caps at 5 minutes
/// ```
///
/// When a successful sync occurs, the backoff resets to the initial
/// interval (aggressive scanning after productive encounters).
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';

import '../config/airpass_config.dart';
import '../di/service_locator.dart';
import '../models/node_role.dart';
import 'nearby_connection_manager.dart';
import '../utils/airpass_logger.dart';
import '../utils/notification_helper.dart';

/// Initializes and configures the background service.
///
/// Call this once from `main()` before `runApp()`.
Future<void> initializeAirpassBackgroundService() async {
  _log('Initializing background service...');
  await NotificationHelper.initialize();
  final service = FlutterBackgroundService();

  try {
    if (await service.isRunning()) {
      _log('Background service is already running.');
      return;
    }
  } catch (e) {
    _log('Could not query background service state: $e');
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onServiceStart,
      autoStart: true,
      isForegroundMode: true,
      initialNotificationTitle: 'United Voices',
      initialNotificationContent: 'Mesh network is active',
      foregroundServiceNotificationId: 42,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: _onServiceStart,
      onBackground: _onIosBackground,
    ),
  );
  _log('Background service configured successfully.');
}

/// Starts the background service (e.g., triggered by a user toggle).
Future<void> startAirpassService() async {
  _log('Starting Airpass service...');
  final service = FlutterBackgroundService();
  await service.startService();

  // Start the scan loop in the main isolate
  _startMainIsolateScanLoop();
}

/// Stops the background service.
Future<void> stopAirpassService() async {
  _log('Stopping Airpass service (invoking stop command)...');
  final service = FlutterBackgroundService();
  service.invoke('stop');
  _isScanLoopRunning = false;

  try {
    getIt<NearbyConnectionManager>().stopAll();
  } catch (e) {
    _log('Error stopping NearbyConnectionManager: $e');
  }
}

/// Checks if the background service is currently running.
Future<bool> isAirpassServiceRunning() async {
  try {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    _log('isAirpassServiceRunning query result: $running');
    return running;
  } catch (e) {
    _log('Error checking service status: $e');
    return false;
  }
}

/// Sends a role/group update command.
/// Updates the singletons in the main isolate and restarts advertising.
Future<void> updateAdvertising({NodeRole? role, List<String>? groupIds}) async {
  _log(
    'updateAdvertising requested: role=${role?.name}, groupIds=${groupIds?.join(",")}',
  );

  // Persist role change so it survives app restarts
  if (role != null) {
    await updateLocalNodeRole(role);
  }

  try {
    final manager = getIt<NearbyConnectionManager>();

    // Stop advertising to clear old endpoint name from the air
    await manager.stopAdvertising();

    // Update identity
    if (role != null) {
      manager.localRole = role;
      manager.syncEngine.localRole = role;
    }
    if (groupIds != null) {
      manager.localGroupIds = groupIds;
      manager.syncEngine.localGroupIds = groupIds;
    }

    // Restart advertising with the new endpoint name
    await manager.startAdvertising();

    // Reset backoff — the user wants to be found immediately
    _currentScanInterval = kInitialScanIntervalMs;

    _log('Identity updated — re-advertising');
  } catch (e) {
    _log('Failed to update advertising: $e');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN ISOLATE EXPONENTIAL BACKOFF SCANNER
// ─────────────────────────────────────────────────────────────────────────────

bool _isScanLoopRunning = false;
int _currentScanInterval = kInitialScanIntervalMs;
Completer<void>? _wakeupCompleter;
bool _isAppForeground = true;

/// Sets the foreground state of the app.
/// When in the foreground, the mesh engine aggressively scans for peers.
void setAppForegroundState(bool isForeground) {
  _log('App foreground state changed: $isForeground');
  _isAppForeground = isForeground;
  if (isForeground) {
    triggerImmediateSync();
  }
}

/// Wakes up the scan loop immediately if it is currently sleeping, and resets
/// the backoff interval. Useful when a new message is ready to send.
void triggerImmediateSync() {
  _log('triggerImmediateSync: Waking up scan loop');
  _currentScanInterval = kInitialScanIntervalMs;
  if (_wakeupCompleter != null && !_wakeupCompleter!.isCompleted) {
    _wakeupCompleter!.complete();
  }
}

/// The core scanning loop with exponential backoff, now running in the MAIN isolate.
Future<void> _startMainIsolateScanLoop() async {
  if (_isScanLoopRunning) return;
  _isScanLoopRunning = true;
  _currentScanInterval = kInitialScanIntervalMs;

  _log('Starting main isolate scan loop...');
  final manager = getIt<NearbyConnectionManager>();

  // Start advertising once, continuously
  await manager.stopAdvertising();
  await manager.startAdvertising();

  while (_isScanLoopRunning) {
    // ─── SCAN WINDOW: Activate discovery ───
    _log('Scan window open (${kScanWindowDurationMs}ms)');

    // Always restart discovery to ensure the OS hasn't
    // silently killed it. Also prevents STATUS_ALREADY_DISCOVERING (8002)
    // by explicitly stopping before restarting.
    await manager.stopDiscovery();
    await manager.startDiscovery();

    // Listen for successful syncs to reset backoff
    late StreamSubscription<AirpassEvent> sub;
    bool hadSync = false;
    sub = manager.events.listen((event) {
      if (event is SyncCompleted) {
        hadSync = true;
      }
    });

    // Keep the scan window open for the configured duration
    await Future.delayed(const Duration(milliseconds: kScanWindowDurationMs));

    // Close scan window
    await manager.stopDiscovery();
    await sub.cancel();

    // Reset backoff if a sync occurred during this window
    if (hadSync) {
      _currentScanInterval = kInitialScanIntervalMs;
      _log('Sync occurred — backoff reset to ${_currentScanInterval}ms');
    }

    if (!_isScanLoopRunning) {
      _log('Scan loop no longer running, exiting');
      break;
    }

    // ─── SLEEP: Exponential backoff or Aggressive ───
    int sleepDuration = _isAppForeground ? 1000 : _currentScanInterval;
    _log('Sleeping for ${sleepDuration}ms (backoff)');

    // Update the notification with current state
    final service = FlutterBackgroundService();
    try {
      if (await service.isRunning()) {
        service.invoke('setNotificationInfo', {
          'title': 'Airpass Mesh',
          'content': _isAppForeground
              ? 'Scanning actively (foreground)'
              : 'Next scan in ${(sleepDuration / 1000).round()}s',
        });
      }
    } catch (_) {}

    _wakeupCompleter = Completer<void>();
    await Future.any([
      Future.delayed(Duration(milliseconds: sleepDuration)),
      _wakeupCompleter!.future,
    ]);
    _wakeupCompleter = null; // Clean up

    // Grow the interval only if in background
    if (!_isAppForeground) {
      _currentScanInterval = (_currentScanInterval * kBackoffMultiplier)
          .round()
          .clamp(kInitialScanIntervalMs, kMaxScanIntervalMs);
    }
  }

  // Ensure everything is stopped when exiting the scan loop
  await manager.stopAdvertising();
  await manager.stopDiscovery();
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE ENTRY POINTS (BACKGROUND ISOLATE)
// ─────────────────────────────────────────────────────────────────────────────

/// The main entry point for the background service.
/// Now just acts as an anchor to keep the persistent notification alive.
@pragma('vm:entry-point')
void _onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  _log('Background service (anchor) started');

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  // Handle stop command from the UI isolate
  service.on('stop').listen((_) {
    _log('Stop command received in background isolate');
    service.stopSelf();
  });

  // Allow UI isolate to update notification
  service.on('setNotificationInfo').listen((event) {
    if (event != null && service is AndroidServiceInstance) {
      final title = event['title'] as String?;
      final content = event['content'] as String?;
      if (title != null && content != null) {
        service.setForegroundNotificationInfo(title: title, content: content);
      }
    }
  });
}

/// iOS background handler.
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  _log('iOS background task triggered (noop)');
  return true;
}

void _log(String message) {
  AirpassLogger.log('AirpassBgService', message);
}
