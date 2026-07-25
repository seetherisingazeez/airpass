/// Airpass Protocol — UI Client Facade
///
/// The clean API surface for the Flutter UI to interact with the
/// background mesh networking system. All methods are safe to call
/// from the main isolate.
///
/// ## Design Principles
///
/// 1. **No direct network calls.** [sendMessage] saves to the local DB
///    as PENDING. The background [AirpassSyncEngine] handles delivery.
///
/// 2. **Reactive.** [watchDiscoveredGroups] and [listenForMessages]
///    return Drift `.watch()` streams that emit historical data
///    immediately, then live updates as the mesh syncs.
///
/// 3. **Byte-limit validated.** [subscribeToGroup] validates that the
///    combined endpoint name stays under the 131-byte Nearby API limit
///    before committing the subscription.
///
/// ## Usage
///
/// ```dart
/// final client = getIt<AirpassClient>();
///
/// // Send a message
/// await client.sendMessage(payload: 'Help needed!', targetId: 'aid-sector-5');
///
/// // Watch groups
/// client.watchDiscoveredGroups().listen((groups) => updateUI(groups));
///
/// // Listen for messages
/// client.listenForMessages('protest-2026').listen((msgs) => showMessages(msgs));
///
/// // Join a group
/// await client.subscribeToGroup('protest-2026');
/// ```
library;

import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'config/airpass_config.dart';
import 'database/airpass_database.dart';
import 'di/service_locator.dart';
import 'models/node_role.dart';
import 'services/airpass_background_service.dart';
import 'services/airpass_sync_engine.dart';
import 'services/endpoint_codec.dart';
import 'utils/airpass_logger.dart';

/// Thrown when subscribing to a group would cause the encoded endpoint
/// name to exceed the 131-byte Nearby Connections API limit.
class GroupSubscriptionLimitException implements Exception {
  final int currentLength;
  final int maxLength;
  final String attemptedGroupId;
  final List<String> currentGroupIds;

  const GroupSubscriptionLimitException({
    required this.currentLength,
    required this.maxLength,
    required this.attemptedGroupId,
    required this.currentGroupIds,
  });

  @override
  String toString() =>
      'GroupSubscriptionLimitException: Adding "$attemptedGroupId" would '
      'produce an endpoint name of $currentLength bytes, exceeding the '
      '$maxLength-byte limit. Currently subscribed to: '
      '${currentGroupIds.join(", ")}. '
      'Unsubscribe from a group or use shorter group names.';
}

/// The primary API for the Flutter UI to interact with the Airpass mesh.
///
/// Obtain via GetIt:
/// ```dart
/// final client = getIt<AirpassClient>();
/// ```
class AirpassClient {
  final AirpassDatabase _db;
  final EndpointCodec _codec;
  final String _localNodeId;
  final NodeRole _localRole;

  /// UUID generator for new messages.
  static const _uuid = Uuid();

  AirpassClient({
    required this._db,
    required this._codec,
    required this._localNodeId,
    required this._localRole,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 1. SEND MESSAGE
  // ─────────────────────────────────────────────────────────────────────────

  /// Saves a new outgoing message to the local database as PENDING.
  ///
  /// This method does NOT perform any network I/O. The message will be
  /// picked up by the background [AirpassSyncEngine] during the next
  /// connect-sync-drop cycle.
  ///
  /// **Small-message optimization:** If the payload + metadata is under
  /// [kMicroMessageMaxBytes] (100 bytes), the sync engine may broadcast
  /// it connectionlessly via the BLE endpoint name — no Wi-Fi Direct
  /// handshake required.
  ///
  /// [payload] — the message content (text or encoded data).
  /// [targetId] — the target identifier:
  ///   - A group ID (e.g., 'protest-2026') for group messages
  ///   - A node UUID for direct messages
  ///   - '*' for broadcast to all nodes
  ///
  /// Returns the generated message ID.
  Future<String> sendMessage({
    required String payload,
    required String targetId,
  }) async {
    final messageId = _uuid.v4();
    final payloadBytes = utf8.encode(payload);

    await _db.createMessage(
      messageId: messageId,
      senderId: _localNodeId,
      targetId: targetId,
      payload: payloadBytes,
      ttl: kAirpassDefaultMaxHops,
    );

    _log(
      'Saved outgoing message $messageId for target "$targetId" (${payloadBytes.length} bytes)',
    );

    // Wake up the background service's scan loop to immediately broadcast the message
    triggerImmediateSync();

    return messageId;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. WATCH DISCOVERED GROUPS
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns a reactive stream of all discovered groups.
  ///
  /// The stream immediately emits the current list of groups from the
  /// database (historical data), then emits updates whenever new groups
  /// are discovered via passive scanning or gossip sync.
  ///
  /// Groups are ordered by most recently seen.
  ///
  /// Usage:
  /// ```dart
  /// client.watchDiscoveredGroups().listen((groups) {
  ///   for (final group in groups) {
  ///     print('${group.groupId} — ${group.memberCount} members');
  ///   }
  /// });
  /// ```
  Stream<List<Group>> watchDiscoveredGroups() {
    return _db.watchDiscoveredGroups();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. LISTEN FOR MESSAGES
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns a reactive stream of messages matching [targetId].
  ///
  /// The stream immediately emits all historical messages from the
  /// database that match the target, then emits real-time updates
  /// as the background [AirpassSyncEngine] saves newly arrived payloads.
  ///
  /// [targetId] can be:
  /// - A group ID to listen for group messages
  /// - A node UUID to listen for direct messages
  /// - '*' to listen for all broadcast messages
  ///
  /// Messages are ordered by creation time (ascending).
  ///
  /// Usage:
  /// ```dart
  /// client.listenForMessages(targetId: 'protest-2026', isGroup: true).listen((msgs) {
  ///   for (final msg in msgs) {
  ///     print('${msg.senderId}: ${utf8.decode(msg.payload)}');
  ///   }
  /// });
  /// ```
  Stream<List<Message>> listenForMessages({
    required String targetId,
    bool isGroup = true,
  }) {
    if (isGroup || targetId == '*') {
      return _db.watchMessagesForTarget(targetId);
    } else {
      return _db.watchDirectMessages(targetId, _localNodeId);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. CREATE AND JOIN GROUP
  // ─────────────────────────────────────────────────────────────────────────

  /// Creates a new group and immediately subscribes to it.
  ///
  /// This is the flow when a user creates a new group from the UI:
  /// 1. Saves the group to the local database with `isSubscribed = true`.
  /// 2. Recalculates the endpoint name with the new group included.
  /// 3. Validates the byte limit.
  /// 4. Tells the background service to re-advertise.
  ///
  /// Throws [GroupSubscriptionLimitException] if adding this group
  /// would exceed the 131-byte endpoint name limit.
  Future<void> createAndJoinGroup(String groupName) async {
    _log('Creating and joining group: "$groupName"');
    // Get current subscriptions
    final currentGroupIds = await _getSubscribedGroupIds();

    // Validate byte limit BEFORE committing
    _validateEndpointLength([...currentGroupIds, groupName]);

    // Save the group as discovered + subscribed
    await _db.upsertDiscoveredGroup(groupId: groupName, displayName: groupName);
    await _db.subscribeToGroup(groupName, exclusive: false);

    // Tell the background service to re-advertise with updated groups
    final updatedGroupIds = await _getSubscribedGroupIds();
    updateAdvertising(
      groupIds: updatedGroupIds,
    ); // Fire and forget to avoid UI lag
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. SUBSCRIBE / UNSUBSCRIBE
  // ─────────────────────────────────────────────────────────────────────────

  /// Subscribes the local node to a discovered group.
  ///
  /// This method:
  /// 1. Validates that adding this group won't exceed the 131-byte limit.
  /// 2. Updates the database.
  /// 3. Tells the background service to stop advertising.
  /// 4. Recalculates the endpoint name with ALL subscribed groups.
  /// 5. Restarts advertising with the new combined string.
  ///
  /// Throws [GroupSubscriptionLimitException] if the combined endpoint
  /// name would exceed the 131-byte limit.
  ///
  /// Example combined endpoint name:
  /// ```
  /// AP|1|R|protest-2026,aid-sector-5|a1b2c3d4
  /// ```
  Future<void> subscribeToGroup(String groupName) async {
    _log('Subscribing to group: "$groupName"');
    // Get current subscriptions
    final currentGroupIds = await _getSubscribedGroupIds();

    // Already subscribed?
    if (currentGroupIds.contains(groupName)) {
      _log('Already subscribed to "$groupName"');
      return;
    }

    // Validate byte limit BEFORE committing
    _validateEndpointLength([...currentGroupIds, groupName]);

    // Commit the subscription to the DB
    await _db.subscribeToGroup(groupName, exclusive: false);

    // Recalculate and re-advertise with ALL subscribed groups
    final updatedGroupIds = await _getSubscribedGroupIds();
    updateAdvertising(
      groupIds: updatedGroupIds,
    ); // Fire and forget to avoid UI lag
  }

  /// Unsubscribes from a group and re-advertises without it.
  ///
  /// This method:
  /// 1. Updates the database.
  /// 2. Recalculates the endpoint name without this group.
  /// 3. Tells the background service to re-advertise.
  Future<void> unsubscribeFromGroup(String groupName) async {
    _log('Unsubscribing from group: "$groupName"');
    // Update the DB
    await _db.unsubscribeFromGroup(groupName);

    // Recalculate and re-advertise
    final updatedGroupIds = await _getSubscribedGroupIds();
    updateAdvertising(
      groupIds: updatedGroupIds,
    ); // Fire and forget to avoid UI lag
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. UPDATE NODE STATUS (BATTERY / INTERNET)
  // ─────────────────────────────────────────────────────────────────────────

  /// Updates the local node's battery level in the background sync engine.
  /// The new level will be included in the next sync payload.
  void updateBatteryLevel(int? batteryLevel) {
    if (getIt.isRegistered<AirpassSyncEngine>()) {
      getIt<AirpassSyncEngine>().localBatteryLevel = batteryLevel;
    }
  }

  /// Updates the local node's internet access status in the background sync engine.
  /// The new status will be included in the next sync payload.
  void updateInternetAccess(bool hasInternetAccess) {
    if (getIt.isRegistered<AirpassSyncEngine>()) {
      getIt<AirpassSyncEngine>().localHasInternetAccess = hasInternetAccess;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VALIDATION HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Validates that the given group IDs would produce an endpoint name
  /// within the 131-byte limit.
  ///
  /// Throws [GroupSubscriptionLimitException] if validation fails.
  void _validateEndpointLength(List<String> groupIds) {
    final length = _codec.encodedLength(
      nodeId: _localNodeId,
      role: _localRole,
      groupIds: groupIds,
    );

    if (length > kEndpointNameMaxBytes) {
      throw GroupSubscriptionLimitException(
        currentLength: length,
        maxLength: kEndpointNameMaxBytes,
        attemptedGroupId: groupIds.last,
        currentGroupIds: groupIds.sublist(0, groupIds.length - 1),
      );
    }
  }

  /// Queries the database for all currently subscribed group IDs.
  Future<List<String>> _getSubscribedGroupIds() async {
    final allGroups = await _db.getAllGroups();
    return allGroups
        .where((g) => g.isSubscribed)
        .map((g) => g.groupId)
        .toList();
  }

  void _log(String message) {
    AirpassLogger.log('AirpassClient', message);
  }
}
