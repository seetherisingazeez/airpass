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
import 'dart:io';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import 'config/airpass_config.dart';
import 'database/airpass_database.dart';
import 'di/service_locator.dart';
import 'models/media_availability.dart';
import 'models/media_type.dart';
import 'models/node_role.dart';
import 'services/airpass_background_service.dart';
import 'services/airpass_sync_engine.dart';
import 'services/endpoint_codec.dart';
import 'services/media_storage_service.dart';
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
  final MediaStorageService _mediaStorage;
  final String _localNodeId;
  final NodeRole _localRole;

  /// UUID generator for new messages.
  static const _uuid = Uuid();

  AirpassClient({
    required AirpassDatabase db,
    required EndpointCodec codec,
    required MediaStorageService mediaStorage,
    required String localNodeId,
    required NodeRole localRole,
  })  : _db = db,
        _codec = codec,
        _mediaStorage = mediaStorage,
        _localNodeId = localNodeId,
        _localRole = localRole;

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

  // ───────────────────────────────────────────────────────────────────────────
  // 7. SEND MEDIA MESSAGE
  // ───────────────────────────────────────────────────────────────────────────

  /// Sends a media message (image, video, audio, or file).
  ///
  /// The file is:
  /// 1. Validated (size check against [kMaxMediaFileSizeBytes]).
  /// 2. Copied to internal Airpass storage.
  /// 3. SHA-256 hashed for integrity verification.
  /// 4. Thumbnailed for instant preview (images only in v1).
  /// 5. Saved as a message with metadata + embedded thumbnail.
  ///
  /// The actual binary propagates via FILE payloads on-demand (Phase 3).
  /// The metadata + thumbnail propagate through epidemic routing immediately.
  ///
  /// [filePath] — absolute path to the source file on the device.
  /// [mediaType] — the type of media (image, video, audio, file).
  /// [targetId] — the target (group ID, node UUID, or '*' for broadcast).
  /// [caption] — optional text caption alongside the media.
  ///
  /// Throws [MediaFileTooLargeException] if the file exceeds the size limit.
  /// Throws [FileSystemException] if the file doesn't exist.
  ///
  /// Returns the generated message ID.
  Future<String> sendMediaMessage({
    required String filePath,
    required MediaType mediaType,
    required String targetId,
    String? caption,
  }) async {
    final file = File(filePath);

    // 1. Validate file exists
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    // 2. Validate file size
    final fileSize = await file.length();
    if (fileSize > kMaxMediaFileSizeBytes) {
      throw MediaFileTooLargeException(
        fileSize: fileSize,
        maxSize: kMaxMediaFileSizeBytes,
        fileName: file.uri.pathSegments.last,
      );
    }

    final messageId = _uuid.v4();
    final fileName = file.uri.pathSegments.last;

    // 3. Copy to internal storage
    final localPath = await _mediaStorage.saveMediaFromPath(
      messageId: messageId,
      sourcePath: filePath,
      fileName: fileName,
    );

    // 4. Compute SHA-256 hash
    final hash = await _mediaStorage.computeHash(localPath);

    // 5. Generate thumbnail (images only in v1)
    Uint8List? thumbnail;
    if (mediaType == MediaType.image) {
      final imageBytes = await file.readAsBytes();
      thumbnail = await _mediaStorage.generateThumbnail(imageBytes);
    }

    // 6. Determine MIME type from extension
    final mimeType = _inferMimeType(fileName, mediaType);

    // 7. Encode caption (or empty string) as the message payload
    final payloadBytes = utf8.encode(caption ?? '');

    // 8. Save to database
    await _db.createMessage(
      messageId: messageId,
      senderId: _localNodeId,
      targetId: targetId,
      payload: payloadBytes,
      ttl: kMediaDefaultMaxHops,
      mediaType: mediaType,
      mediaFileName: fileName,
      mediaMimeType: mimeType,
      mediaFileSize: fileSize,
      mediaHash: hash,
      mediaLocalPath: localPath,
      mediaAvailability: MediaAvailability.available, // We have it locally
      mediaThumbnail: thumbnail,
    );

    _log(
      'Saved outgoing media message $messageId '
      '(${mediaType.name}, $fileSize bytes) for target "$targetId"',
    );

    // Wake up the background service to broadcast metadata immediately
    triggerImmediateSync();

    return messageId;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 8. GET MEDIA PATH
  // ───────────────────────────────────────────────────────────────────────────

  /// Returns the local file path for a media message, or null
  /// if the binary hasn't been downloaded yet.
  ///
  /// Use this to display images/videos in the UI:
  /// ```dart
  /// final path = await client.getMediaPath(msg.messageId);
  /// if (path != null) {
  ///   // Display the image/video
  ///   Image.file(File(path));
  /// } else {
  ///   // Show thumbnail + download button
  /// }
  /// ```
  Future<String?> getMediaPath(String messageId) async {
    return _mediaStorage.getMediaPath(messageId);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 9. REQUEST MEDIA DOWNLOAD
  // ───────────────────────────────────────────────────────────────────────────

  /// Manually requests download of a media file.
  ///
  /// Queue a manual media download and immediately try to fetch it.
  Future<void> requestMediaDownload(String messageId) async {
    await _db.updateMediaAvailability(
      messageId,
      MediaAvailability.manualDownloadRequested,
    );
    _log('Queued manual media download for message $messageId');

    // Trigger a sync to try to fetch the file immediately
    triggerImmediateSync();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MEDIA HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  /// Infers the MIME type from a filename and media type.
  String _inferMimeType(String fileName, MediaType type) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (type) {
      MediaType.image => switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        _ => 'image/jpeg',
      },
      MediaType.video => switch (ext) {
        'mp4' => 'video/mp4',
        'webm' => 'video/webm',
        'mov' => 'video/quicktime',
        'avi' => 'video/x-msvideo',
        _ => 'video/mp4',
      },
      MediaType.audio => switch (ext) {
        'mp3' => 'audio/mpeg',
        'ogg' => 'audio/ogg',
        'wav' => 'audio/wav',
        'aac' => 'audio/aac',
        'm4a' => 'audio/mp4',
        _ => 'audio/mpeg',
      },
      MediaType.file => 'application/octet-stream',
      MediaType.text => 'text/plain',
    };
  }
}

/// Thrown when a media file exceeds the maximum allowed size.
class MediaFileTooLargeException implements Exception {
  final int fileSize;
  final int maxSize;
  final String fileName;

  const MediaFileTooLargeException({
    required this.fileSize,
    required this.maxSize,
    required this.fileName,
  });

  @override
  String toString() =>
      'MediaFileTooLargeException: "$fileName" is ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB, '
      'but the maximum allowed size is ${(maxSize / 1024 / 1024).toStringAsFixed(0)} MB.';
}
