import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Represents the hardware state required by Airpass.
enum AirpassHardwareState {
  /// Both Bluetooth and Wi-Fi (Location) are enabled.
  ready,

  /// Bluetooth is turned off.
  bluetoothDisabled,

  /// Location (Wi-Fi/Network) is turned off.
  locationDisabled,

  /// Both are disabled.
  bothDisabled,
}

/// Provides a unified API to handle runtime permissions and hardware state
/// for the Airpass mesh network.
class AirpassPermissions {
  /// Requests all necessary runtime permissions for the mesh network to operate.
  /// 
  /// Returns `true` if all mandatory permissions were granted.
  static Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) {
      // iOS permissions for Nearby Connections usually rely on Info.plist and
      // prompt automatically when the API is invoked. 
      // But we can still request Location/Bluetooth via permission_handler if needed.
      return true;
    }

    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = deviceInfo.version.sdkInt;

    final permissionsToRequest = <Permission>[
      Permission.location,
      // Notification permission is needed for the background service
      Permission.notification,
    ];

    if (sdkInt >= 31) { // Android 12+
      permissionsToRequest.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ]);
    }
    
    if (sdkInt >= 33) { // Android 13+
      permissionsToRequest.add(Permission.nearbyWifiDevices);
    }

    // Request all missing permissions
    final statuses = await permissionsToRequest.request();

    // Check if any mandatory permission was denied
    bool allGranted = true;
    for (final entry in statuses.entries) {
      if (entry.value != PermissionStatus.granted) {
        allGranted = false;
        break;
      }
    }

    return allGranted;
  }

  /// Returns a dictionary of all the required permissions and their current statuses.
  static Future<Map<Permission, PermissionStatus>> getPermissionStatuses() async {
    final statuses = <Permission, PermissionStatus>{};
    
    if (!Platform.isAndroid) {
      return statuses;
    }

    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = deviceInfo.version.sdkInt;

    final permissionsToCheck = <Permission>[
      Permission.location,
      Permission.notification,
    ];

    if (sdkInt >= 31) { // Android 12+
      permissionsToCheck.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ]);
    }
    
    if (sdkInt >= 33) { // Android 13+
      permissionsToCheck.add(Permission.nearbyWifiDevices);
    }

    for (final perm in permissionsToCheck) {
      statuses[perm] = await perm.status;
    }

    return statuses;
  }

  /// Requests a specific permission if it has not been granted yet.
  /// Returns `true` if the permission is granted.
  static Future<bool> requestPermission(Permission permission) async {
    final currentStatus = await permission.status;
    if (currentStatus.isGranted) return true;
    
    final newStatus = await permission.request();
    return newStatus.isGranted;
  }

  /// Actively checks and returns the current hardware state without subscribing to a stream.
  static Future<AirpassHardwareState> getHardwareState() async {
    final btStatus = await Permission.bluetooth.serviceStatus;
    final locStatus = await Permission.location.serviceStatus;

    final bool btOff = btStatus == ServiceStatus.disabled;
    final bool locOff = locStatus == ServiceStatus.disabled;

    if (btOff && locOff) {
      return AirpassHardwareState.bothDisabled;
    } else if (btOff) {
      return AirpassHardwareState.bluetoothDisabled;
    } else if (locOff) {
      return AirpassHardwareState.locationDisabled;
    } else {
      return AirpassHardwareState.ready;
    }
  }

  /// Returns a stream that periodically polls the hardware status of
  /// Bluetooth and Location (Wi-Fi) and emits an [AirpassHardwareState].
  ///
  /// This can be used by the UI to show a banner if the user turns off
  /// their radios, which would break the mesh network.
  ///
  /// The internal timer is automatically cancelled when the stream
  /// subscription is cancelled, preventing resource leaks.
  static Stream<AirpassHardwareState> watchHardwareState({
    Duration pollInterval = const Duration(seconds: 3),
  }) {
    late StreamController<AirpassHardwareState> controller;
    Timer? timer;

    Future<void> poll() async {
      final btStatus = await Permission.bluetooth.serviceStatus;
      final locStatus = await Permission.location.serviceStatus;

      final bool btOff = btStatus == ServiceStatus.disabled;
      final bool locOff = locStatus == ServiceStatus.disabled;

      if (controller.isClosed) return;

      if (btOff && locOff) {
        controller.add(AirpassHardwareState.bothDisabled);
      } else if (btOff) {
        controller.add(AirpassHardwareState.bluetoothDisabled);
      } else if (locOff) {
        controller.add(AirpassHardwareState.locationDisabled);
      } else {
        controller.add(AirpassHardwareState.ready);
      }
    }

    controller = StreamController<AirpassHardwareState>(
      onListen: () {
        // Emit immediately, then on interval
        poll();
        timer = Timer.periodic(pollInterval, (_) => poll());
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
      },
    );

    return controller.stream;
  }
}
