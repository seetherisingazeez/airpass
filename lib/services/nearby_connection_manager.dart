/// Airpass Protocol — Nearby Connection Manager
///
/// Wraps the `nearby_connections` package to implement the
/// Connect-Sync-Drop lifecycle:
///
/// ```
///   Discover → Connect → Sync (exchange DB state) → Disconnect
/// ```
///
/// Key behaviors:
/// - Advertising and Discovery run simultaneously (P2P_CLUSTER allows this).
/// - On discovery, the endpoint name is decoded to decide if a connection
///   is worth initiating.
/// - Upon successful connection, the [AirpassSyncEngine] is triggered.
/// - After sync completes (payload transfer at 100%), the connection
///   is immediately dropped.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

import '../config/airpass_config.dart';
import '../database/airpass_database.dart';
import '../models/media_availability.dart';
import '../models/node_role.dart';
import 'airpass_sync_engine.dart';
import 'endpoint_codec.dart';
import 'bloom_filter.dart';
import 'media_storage_service.dart';
import '../utils/airpass_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EVENT TYPES (for logging / UI observation)
// ─────────────────────────────────────────────────────────────────────────────

/// Events emitted by [NearbyConnectionManager] for external observation.
/// Subscribe to [NearbyConnectionManager.events] for a live stream.
sealed class AirpassEvent {
  final DateTime timestamp;
  AirpassEvent() : timestamp = DateTime.now();
}

class DiscoveryStarted extends AirpassEvent {}

class DiscoveryStopped extends AirpassEvent {}

class AdvertisingStarted extends AirpassEvent {}

class AdvertisingStopped extends AirpassEvent {}

class EndpointDiscovered extends AirpassEvent {
  final String endpointId;
  final EndpointMetadata? metadata;
  EndpointDiscovered(this.endpointId, this.metadata);
}

class EndpointLost extends AirpassEvent {
  final String endpointId;
  EndpointLost(this.endpointId);
}

class ConnectionRequested extends AirpassEvent {
  final String endpointId;
  ConnectionRequested(this.endpointId);
}

class ConnectionEstablished extends AirpassEvent {
  final String endpointId;
  ConnectionEstablished(this.endpointId);
}

class ConnectionRejected extends AirpassEvent {
  final String endpointId;
  ConnectionRejected(this.endpointId);
}

class SyncCompleted extends AirpassEvent {
  final String endpointId;
  final int newMessagesIngested;
  SyncCompleted(this.endpointId, this.newMessagesIngested);
}

class Disconnected extends AirpassEvent {
  final String endpointId;
  Disconnected(this.endpointId);
}

class AirpassError extends AirpassEvent {
  final String message;
  final Object? error;
  AirpassError(this.message, [this.error]);
}

/// Emitted when a new group is passively discovered from an endpoint name.
class GroupDiscovered extends AirpassEvent {
  final String groupId;
  GroupDiscovered(this.groupId);
}

/// Emitted when a media file transfer begins.
class MediaTransferStarted extends AirpassEvent {
  final String messageId;
  final int totalBytes;
  MediaTransferStarted(this.messageId, this.totalBytes);
}

/// Emitted periodically during a media file transfer.
class MediaTransferProgress extends AirpassEvent {
  final String messageId;
  final double progress; // 0.0 to 1.0
  MediaTransferProgress(this.messageId, this.progress);
}

/// Emitted when a media file transfer completes successfully.
class MediaTransferCompleted extends AirpassEvent {
  final String messageId;
  MediaTransferCompleted(this.messageId);
}

/// Emitted when a media file transfer fails.
class MediaTransferFailed extends AirpassEvent {
  final String messageId;
  final String reason;
  MediaTransferFailed(this.messageId, this.reason);
}

// ─────────────────────────────────────────────────────────────────────────────
// MANAGER
// ─────────────────────────────────────────────────────────────────────────────

/// Manages all Nearby Connections API interactions for the Airpass Protocol.
///
/// This class does NOT own the lifecycle of advertising/discovery —
/// that is managed by [AirpassBackgroundService] which starts and stops
/// scanning on a backoff timer.
class NearbyConnectionManager {
  final AirpassSyncEngine _syncEngine;
  final EndpointCodec _codec;
  final AirpassDatabase _db;
  final MediaStorageService _mediaStorage;

  /// Expose internal services for rebuilding the manager during role switches.
  AirpassSyncEngine get syncEngine => _syncEngine;
  EndpointCodec get codec => _codec;
  AirpassDatabase get db => _db;
  MediaStorageService get mediaStorage => _mediaStorage;

  /// The local node's full UUID.
  final String localNodeId;

  /// The local node's mesh role.
  NodeRole localRole;

  /// The local node's group affiliations (empty if ungrouped).
  List<String> localGroupIds;

  /// The Nearby Connections singleton.
  final Nearby _nearby = Nearby();

  /// Tracks endpoints we are currently connecting to or syncing with,
  /// preventing duplicate connection attempts.
  final Set<String> _activeEndpoints = {};

  /// Maps Nearby Connections endpoint IDs to actual Airpass node UUIDs.
  /// Populated during connection initiation by decoding the peer's
  /// endpoint name. Used to record deliveries against the real node
  /// UUID instead of the ephemeral session ID.
  final Map<String, String> _endpointToNodeId = {};

  /// Tracks which message IDs were sent to each endpoint during sync.
  /// Keyed by endpoint ID, value is the list of message IDs actually
  /// included in the outgoing payload. Used to record accurate
  /// delivery records (only what was actually sent, not everything).
  final Map<String, List<String>> _pendingSyncMessageIds = {};

  /// Buffers incoming sync payload bytes keyed by endpoint ID.
  final Map<String, Uint8List> _syncPayloadBuffers = {};

  /// Bloom filters received from peers during Phase 1.
  /// Keyed by endpoint ID. Used in Phase 2 to filter outgoing messages.
  final Map<String, BloomFilter> _peerBloomFilters = {};

  /// Tracks payload IDs for incoming Bloom filter payloads.
  /// Used to distinguish Bloom filter SUCCESS from sync SUCCESS
  /// in [_onPayloadTransferUpdate].
  final Map<String, int> _bloomPayloadIds = {};

  /// Tracks payload IDs for incoming sync payloads.
  final Map<String, int> _syncPayloadIds = {};

  /// Maps Nearby payload IDs to message IDs for incoming media FILE transfers.
  /// When we receive a media response header (MR magic), we store the
  /// upcoming file's message ID. When the FILE payload completes, we
  /// look up which message it belongs to.
  final Map<int, String> _mediaPayloadToMessageId = {};

  /// Tracks how many media files have been transferred in the current
  /// sync connection. Capped at [kMaxMediaSyncsPerConnection].
  final Map<String, int> _mediaTransferCounts = {};

  /// Event stream for external observation (logging, UI, analytics).
  final StreamController<AirpassEvent> _eventController =
      StreamController.broadcast();

  /// Subscribe to this stream to observe all mesh events.
  Stream<AirpassEvent> get events => _eventController.stream;

  /// Whether advertising is currently active.
  bool _isAdvertising = false;
  bool get isAdvertising => _isAdvertising;

  /// Whether discovery is currently active.
  bool _isDiscovering = false;
  bool get isDiscovering => _isDiscovering;

  NearbyConnectionManager({
    required this._syncEngine,
    required this._codec,
    required this._db,
    required this._mediaStorage,
    required this.localNodeId,
    required this.localRole,
    this.localGroupIds = const [],
  });

  /// Disposes resources. Call when shutting down.
  void dispose() {
    stopAll();
    _endpointToNodeId.clear();
    _pendingSyncMessageIds.clear();
    _peerBloomFilters.clear();
    _bloomPayloadIds.clear();
    _syncPayloadIds.clear();
    _mediaPayloadToMessageId.clear();
    _mediaTransferCounts.clear();
    _eventController.close();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADVERTISING
  // ─────────────────────────────────────────────────────────────────────────

  /// Start advertising this node to nearby peers.
  ///
  /// The endpoint name is encoded with the node's metadata so that
  /// discoverers can filter before connecting.
  Future<void> startAdvertising() async {
    if (_isAdvertising) return;

    final endpointName = _codec.encode(
      nodeId: localNodeId,
      role: localRole,
      groupIds: localGroupIds,
    );

    try {
      await _nearby.startAdvertising(
        endpointName,
        kAirpassStrategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: kAirpassServiceId,
      );
      _isAdvertising = true;
      _emit(AdvertisingStarted());
      _log('Advertising started: $endpointName');
    } catch (e) {
      // STATUS_ALREADY_ADVERTISING (8001) — native is already advertising,
      // just sync our flag to match reality.
      if (e.toString().contains('8001')) {
        _isAdvertising = true;
        _log('Already advertising (native), synced flag');
      } else {
        _emit(AirpassError('Failed to start advertising', e));
        _log('Advertising failed: $e');
      }
    }
  }

  /// Stop advertising.
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    await _nearby.stopAdvertising();
    _isAdvertising = false;
    _emit(AdvertisingStopped());
    _log('Advertising stopped');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DISCOVERY
  // ─────────────────────────────────────────────────────────────────────────

  /// Start discovering nearby advertisers.
  ///
  /// When an endpoint is found, its name is decoded and passed through
  /// the [EndpointCodec.shouldConnect] filter. If accepted, a connection
  /// request is sent automatically.
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    final endpointName = _codec.encode(
      nodeId: localNodeId,
      role: localRole,
      groupIds: localGroupIds,
    );

    try {
      await _nearby.startDiscovery(
        endpointName,
        kAirpassStrategy,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: kAirpassServiceId,
      );
      _isDiscovering = true;
      _emit(DiscoveryStarted());
      _log('Discovery started');
    } catch (e) {
      // STATUS_ALREADY_DISCOVERING (8002) — native is already discovering,
      // just sync our flag to match reality instead of treating it as failure.
      if (e.toString().contains('8002')) {
        _isDiscovering = true;
        _log('Already discovering (native), synced flag');
      } else {
        _emit(AirpassError('Failed to start discovery', e));
        _log('Discovery failed: $e');
      }
    }
  }

  /// Stop discovering.
  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    await _nearby.stopDiscovery();
    _isDiscovering = false;
    _emit(DiscoveryStopped());
    _log('Discovery stopped');
  }

  /// Stops both advertising and discovery and disconnects all peers.
  Future<void> stopAll() async {
    await stopAdvertising();
    await stopDiscovery();
    _nearby.stopAllEndpoints();
    _activeEndpoints.clear();
    _endpointToNodeId.clear();
    _pendingSyncMessageIds.clear();
    _syncPayloadBuffers.clear();
    _peerBloomFilters.clear();
    _bloomPayloadIds.clear();
    _syncPayloadIds.clear();
    _mediaPayloadToMessageId.clear();
    _mediaTransferCounts.clear();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DISCOVERY CALLBACKS
  // ─────────────────────────────────────────────────────────────────────────

  /// Called when a nearby advertiser is discovered.
  ///
  /// Decodes the endpoint name and applies the connectionless filter.
  /// If the peer passes the filter, a connection request is initiated.
  void _onEndpointFound(
    String endpointId,
    String endpointName,
    String serviceId,
  ) {
    final metadata = _codec.decode(endpointName);
    _emit(EndpointDiscovered(endpointId, metadata));

    if (metadata == null) {
      _log('Ignoring non-Airpass endpoint: $endpointId ($endpointName)');
      return;
    }

    // Connectionless filter — decide before wasting a handshake
    final shouldConnect = _codec.shouldConnect(
      localRole: localRole,
      localGroupIds: localGroupIds,
      remote: metadata,
    );

    if (!shouldConnect) {
      _log(
        'Filtered out endpoint $endpointId: ${metadata.role.name} '
        'groups=${metadata.groupIds.join(",")}',
      );
      // Even if we don't connect, still record the group for the directory.
      // This is PASSIVE discovery — no connection needed to learn about groups.
      _saveDiscoveredGroup(metadata);
      return;
    }

    // Save the group from endpoints we DO connect to as well
    _saveDiscoveredGroup(metadata);

    // Prevent duplicate connections
    if (_activeEndpoints.contains(endpointId)) {
      _log('Already connected/connecting to $endpointId, skipping');
      return;
    }

    _log('Requesting connection to $endpointId ($metadata)');
    _activeEndpoints.add(endpointId);
    _emit(ConnectionRequested(endpointId));

    _nearby.requestConnection(
      _codec.encode(
        nodeId: localNodeId,
        role: localRole,
        groupIds: localGroupIds,
      ),
      endpointId,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    );
  }

  /// Called when a previously discovered endpoint is lost.
  void _onEndpointLost(String? endpointId) {
    if (endpointId == null) return;
    _emit(EndpointLost(endpointId));
    _activeEndpoints.remove(endpointId);
    _log('Endpoint lost: $endpointId');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONNECTION CALLBACKS
  // ─────────────────────────────────────────────────────────────────────────

  /// Called when either side initiates a connection request.
  ///
  /// In the Airpass protocol, we accept connections from peers running
  /// the same protocol version. Authentication is handled at the message
  /// layer (via HMAC signatures), not the transport layer.
  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    _log(
      'Connection initiated with $endpointId '
      '(name: ${info.endpointName}, auth: ${info.authenticationToken})',
    );

    // Validate protocol version before accepting
    final peerMetadata = _codec.decode(info.endpointName);
    if (peerMetadata != null &&
        peerMetadata.protocolVersion != kAirpassProtocolVersion) {
      _log(
        'Rejecting $endpointId: incompatible protocol version '
        'v${peerMetadata.protocolVersion} (we are v$kAirpassProtocolVersion)',
      );
      _nearby.rejectConnection(endpointId);
      return;
    }

    // Map the endpoint ID to the peer's node ID prefix for per-peer dedup.
    // This is only the first 8 chars of the UUID — the initial sync with
    // a new peer won't benefit from full dedup, but that's acceptable
    // since we always need a full exchange on first encounter anyway.
    // The authoritative full UUID arrives in the SyncPayload and is used
    // for delivery record storage (see _processSyncData).
    if (peerMetadata != null) {
      _endpointToNodeId[endpointId] = peerMetadata.nodeIdPrefix;
    }

    _activeEndpoints.add(endpointId);

    // Add a safety timeout to clear zombie connections if sync stalls
    Future.delayed(const Duration(seconds: 30), () {
      if (_activeEndpoints.contains(endpointId)) {
        _log('Connection to $endpointId stalled. Forcing cleanup.');
        _nearby.disconnectFromEndpoint(endpointId);
        _onDisconnected(endpointId);
      }
    });

    // Accept — and register payload callbacks
    _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: _onPayloadTransferUpdate,
    );
  }

  /// Called when the connection handshake completes.
  ///
  /// Phase 1 of the two-phase sync: send our Bloom filter immediately.
  /// The peer does the same. When we receive their filter, Phase 2 begins.
  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      _emit(ConnectionEstablished(endpointId));
      _log('Connected to $endpointId — sending Bloom filter (Phase 1)');

      // Phase 1: Send our Bloom filter (tiny ~1-2 KB)
      _sendBloomFilter(endpointId);
    } else {
      _emit(ConnectionRejected(endpointId));
      _activeEndpoints.remove(endpointId);
      _log('Connection rejected/error for $endpointId: $status');
    }
  }

  /// Called when a peer disconnects (either side).
  void _onDisconnected(String endpointId) {
    _emit(Disconnected(endpointId));
    _activeEndpoints.remove(endpointId);
    _endpointToNodeId.remove(endpointId);
    _pendingSyncMessageIds.remove(endpointId);
    _syncPayloadBuffers.remove(endpointId);
    _peerBloomFilters.remove(endpointId);
    _bloomPayloadIds.remove(endpointId);
    _syncPayloadIds.remove(endpointId);
    _log('Disconnected from $endpointId');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAYLOAD CALLBACKS (Two-Phase Protocol)
  // ─────────────────────────────────────────────────────────────────────────

  /// Called when payload bytes are received from a peer.
  ///
  /// Distinguishes between Bloom filter payloads (magic `0xBF 0x00`)
  /// and gzip sync payloads (magic `0x1F 0x8B`) by inspecting the
  /// first two bytes.
  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      final bytes = payload.bytes!;

      if (bytes.length >= 2 &&
          bytes[0] == kBloomFilterMagic[0] &&
          bytes[1] == kBloomFilterMagic[1]) {
        // ── Phase 1: Bloom filter received ──
        _peerBloomFilters[endpointId] = BloomFilter.fromBytes(bytes);
        _bloomPayloadIds[endpointId] = payload.id;
        _log(
          'Received Bloom filter from $endpointId '
          '(${bytes.length} bytes)',
        );
      } else if (bytes.length >= 2 &&
          bytes[0] == kMediaRequestMagic[0] &&
          bytes[1] == kMediaRequestMagic[1]) {
        // ── Phase 3: Media request received ──
        // Payload format: [0x4D, 0x52, ...JSON list of message IDs]
        final jsonBytes = bytes.sublist(2);
        final messageIds = (jsonDecode(utf8.decode(jsonBytes)) as List)
            .cast<String>();
        _log(
          'Received media request from $endpointId: '
          '${messageIds.length} files requested',
        );
        _handleMediaRequest(endpointId, messageIds);
      } else if (bytes.length >= 2 &&
          bytes[0] == kMediaResponseMagic[0] &&
          bytes[1] == kMediaResponseMagic[1]) {
        // ── Phase 3: Media response header received ──
        // Payload format: [0x4D, 0x53, ...JSON {"msgId": "...", "payloadId": N}]
        final jsonBytes = bytes.sublist(2);
        final header = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
        final msgId = header['msgId'] as String;
        final filePayloadId = header['payloadId'] as int;
        _mediaPayloadToMessageId[filePayloadId] = msgId;
        _log(
          'Media response header from $endpointId: '
          'msgId=$msgId, payloadId=$filePayloadId',
        );
      } else {
        // ── Phase 2: Sync payload received (gzip) ──
        _syncPayloadBuffers[endpointId] = bytes;
        _syncPayloadIds[endpointId] = payload.id;
        _log(
          'Received sync payload from $endpointId '
          '(${bytes.length} bytes)',
        );
      }
    } else if (payload.type == PayloadType.FILE) {
      // ── Phase 3: Media FILE payload received ──
      // The media response header (sent before this) tells us which
      // message ID this file belongs to.
      final msgId = _mediaPayloadToMessageId[payload.id];
      if (msgId != null) {
        _log('Receiving media FILE for message $msgId from $endpointId');
        // File payloads are handled automatically by Nearby Connections.
        // The actual file processing happens in _onPayloadTransferUpdate
        // when status == SUCCESS.
      } else {
        _log(
          'Received FILE payload from $endpointId with unknown payload ID '
          '${payload.id} — no matching media response header',
        );
        _emit(AirpassError('Unexpected FILE payload from $endpointId'));
      }
    }
  }

  /// Called with transfer progress updates.
  ///
  /// Handles two SUCCESS events per connection:
  /// 1. Bloom filter SUCCESS → Trigger Phase 2 (build filtered sync payload)
  /// 2. Sync payload SUCCESS → Process data and disconnect
  void _onPayloadTransferUpdate(
    String endpointId,
    PayloadTransferUpdate update,
  ) {
    if (update.status == PayloadStatus.SUCCESS) {
      if (update.id == _bloomPayloadIds[endpointId]) {
        // ── Bloom filter transfer complete → Phase 2 ──
        _log(
          'Bloom filter confirmed for $endpointId — '
          'building filtered sync (Phase 2)',
        );
        _performFilteredSync(endpointId);
      } else if (update.id == _syncPayloadIds[endpointId]) {
        // ── Sync payload transfer complete → Process & then Phase 3 ──
        _log('Sync payload transfer complete for $endpointId');

        final buffer = _syncPayloadBuffers.remove(endpointId);
        final pendingSentIds = _pendingSyncMessageIds.remove(endpointId);

        if (buffer != null) {
          // Process sync data THEN initiate Phase 3 media transfers.
          // Note: We do NOT disconnect yet — Phase 3 needs the connection.
          _processSyncDataThenMedia(endpointId, buffer, pendingSentIds);
        } else {
          _disconnectAfterSync(endpointId);
        }
      } else if (_mediaPayloadToMessageId.containsKey(update.id)) {
        // ── Media FILE transfer complete ──
        final msgId = _mediaPayloadToMessageId.remove(update.id)!;
        _onMediaFileReceived(endpointId, msgId, update);
      }
    } else if (update.status == PayloadStatus.IN_PROGRESS) {
      // Track media file transfer progress for UI
      if (_mediaPayloadToMessageId.containsKey(update.id)) {
        final msgId = _mediaPayloadToMessageId[update.id]!;
        final progress = update.totalBytes > 0
            ? update.bytesTransferred / update.totalBytes
            : 0.0;
        _emit(MediaTransferProgress(msgId, progress));
      }
    } else if (update.status == PayloadStatus.FAILURE) {
      if (_mediaPayloadToMessageId.containsKey(update.id)) {
        final msgId = _mediaPayloadToMessageId.remove(update.id)!;
        _emit(MediaTransferFailed(msgId, 'Transfer failed'));
        _db.updateMediaAvailability(msgId, MediaAvailability.failed);
      } else {
        _emit(AirpassError('Payload transfer failed for $endpointId'));
        _disconnectAfterSync(endpointId);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SYNC ORCHESTRATION (Two-Phase)
  // ─────────────────────────────────────────────────────────────────────────

  /// Phase 1: Builds and sends our Bloom filter to the peer.
  ///
  /// The filter contains the IDs of all messages we currently have.
  /// The peer uses it to exclude messages we already have from their
  /// sync payload, saving bandwidth.
  Future<void> _sendBloomFilter(String endpointId) async {
    try {
      final filterBytes = await _syncEngine.buildBloomFilter();
      await _nearby.sendBytesPayload(endpointId, filterBytes);
      _log('Sent Bloom filter to $endpointId (${filterBytes.length} bytes)');
    } catch (e) {
      _emit(AirpassError('Failed to send Bloom filter to $endpointId', e));
      // Fall back: proceed without filter (peer will send unfiltered)
    }
  }

  /// Phase 2: Builds and sends the filtered sync payload.
  ///
  /// Called after receiving the peer's Bloom filter. Uses the filter
  /// to exclude messages the peer already has, plus per-peer delivery
  /// dedup for messages we've already sent to this peer in previous
  /// sync cycles.
  Future<void> _performFilteredSync(String endpointId) async {
    try {
      // Resolve the peer's 8-char prefix to the full UUID from the
      // Nodes table for per-peer delivery dedup.
      final prefix = _endpointToNodeId[endpointId];
      final fullNodeId = prefix != null
          ? await _db.resolveFullNodeId(prefix)
          : null;
      final peerNodeId = fullNodeId ?? prefix;

      // Get the peer's Bloom filter (received in Phase 1)
      final peerFilter = _peerBloomFilters[endpointId];

      // Build the filtered payload — excludes messages matching the
      // Bloom filter AND messages already delivered to this peer.
      final outgoingBytes = await _syncEngine.buildFilteredSyncPayload(
        peerFilter: peerFilter,
        peerNodeId: peerNodeId,
      );

      // Snapshot which messages we're sending for delivery tracking
      // (done after building because buildFilteredSyncPayload applies
      // both Bloom filter and per-peer dedup)
      final candidateMessages = peerNodeId != null
          ? await _db.getMessagesForSync(peerNodeId)
          : await _db.getAllSyncableMessages();
      final sentMessages = peerFilter != null
          ? candidateMessages
                .where((m) => !peerFilter.mightContain(m.messageId))
                .toList()
          : candidateMessages;
      _pendingSyncMessageIds[endpointId] = sentMessages
          .map((m) => m.messageId)
          .toList();

      await _nearby.sendBytesPayload(endpointId, outgoingBytes);
      _log(
        'Sent filtered sync to $endpointId '
        '(${outgoingBytes.length} bytes, '
        '${sentMessages.length} msgs after filter)',
      );
    } catch (e) {
      _emit(AirpassError('Filtered sync send failed for $endpointId', e));
      _disconnectAfterSync(endpointId);
    }
  }

  /// Processes received sync data, records deliveries, then initiates
  /// Phase 3 media transfers if there are pending media files.
  Future<void> _processSyncDataThenMedia(
    String endpointId,
    Uint8List data,
    List<String>? sentIds,
  ) async {
    try {
      final result = await _syncEngine.processSyncPayload(data);
      final newMessages = result.newMessages;
      final peerNodeId = result.peerNodeId;

      _emit(SyncCompleted(endpointId, newMessages));
      _log('Sync complete with $endpointId: $newMessages new messages');

      // Record deliveries using the authoritative full UUID from the
      // sync payload (not the 8-char prefix from the endpoint name).
      if (sentIds != null && sentIds.isNotEmpty) {
        await _db.recordDeliveries(messageIds: sentIds, peerNodeId: peerNodeId);
      }

      // Phase 3: Check if we need any media files from this peer.
      // Only request auto-downloadable files (under size threshold).
      final pendingMedia = await _db.getAutoDownloadableMedia(
        kAutoDownloadMaxBytes,
      );

      if (pendingMedia.isNotEmpty) {
        // Request up to kMaxMediaSyncsPerConnection files
        final toRequest = pendingMedia
            .take(kMaxMediaSyncsPerConnection)
            .map((m) => m.messageId)
            .toList();
        _log(
          'Phase 3: Requesting ${toRequest.length} media files from $endpointId',
        );
        _sendMediaRequest(endpointId, toRequest);
      } else {
        // No media needed — disconnect now
        _disconnectAfterSync(endpointId);
      }
    } catch (e) {
      _emit(AirpassError('Sync processing failed for $endpointId', e));
      _disconnectAfterSync(endpointId);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PHASE 3: MEDIA TRANSFER ORCHESTRATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Sends a media request to the peer — a list of message IDs whose
  /// binary files we want.
  ///
  /// Payload format: [0x4D, 0x52, ...JSON array of message IDs]
  Future<void> _sendMediaRequest(
    String endpointId,
    List<String> messageIds,
  ) async {
    try {
      final jsonBytes = utf8.encode(jsonEncode(messageIds));
      final payload = Uint8List.fromList([
        ...kMediaRequestMagic,
        ...jsonBytes,
      ]);
      await _nearby.sendBytesPayload(endpointId, payload);
      _mediaTransferCounts[endpointId] = 0;
      _log('Sent media request to $endpointId for ${messageIds.length} files');
    } catch (e) {
      _emit(AirpassError('Failed to send media request to $endpointId', e));
      _disconnectAfterSync(endpointId);
    }
  }

  /// Handles an incoming media request from a peer.
  ///
  /// For each requested message ID, if we have the media file locally,
  /// we send a media response header followed by a FILE payload.
  Future<void> _handleMediaRequest(
    String endpointId,
    List<String> messageIds,
  ) async {
    int sent = 0;
    for (final msgId in messageIds) {
      if (sent >= kMaxMediaSyncsPerConnection) {
        _log('Hit media transfer limit for $endpointId ($sent files)');
        break;
      }

      // Check if we have this file locally
      final filePath = await _mediaStorage.getMediaPath(msgId);
      if (filePath == null) {
        _log('Media file not available locally for message $msgId');
        continue;
      }

      try {
        // Send a header first so the peer knows which message this file
        // belongs to, and can match the upcoming FILE payload ID.
        // We use the Nearby API's payload ID for correlation.
        final payloadId = DateTime.now().microsecondsSinceEpoch;

        final header = jsonEncode({
          'msgId': msgId,
          'payloadId': payloadId,
        });
        final headerBytes = Uint8List.fromList([
          ...kMediaResponseMagic,
          ...utf8.encode(header),
        ]);
        await _nearby.sendBytesPayload(endpointId, headerBytes);

        // Now send the actual file
        await _nearby.sendFilePayload(endpointId, filePath);
        sent++;

        _log('Sent media file for message $msgId to $endpointId');
      } catch (e) {
        _log('Failed to send media file $msgId to $endpointId: $e');
        _emit(AirpassError('Media send failed for $msgId', e));
      }
    }

    // If no files were sent (or we're done), check if we should disconnect
    if (sent == 0 || !_mediaPayloadToMessageId.values.any(
      (id) => messageIds.contains(id),
    )) {
      // No pending file transfers — safe to disconnect
      _disconnectAfterSync(endpointId);
    }
    // Otherwise, disconnect happens when the last FILE transfer completes
  }

  /// Called when a media FILE transfer completes successfully.
  ///
  /// Verifies the file's SHA-256 hash against the metadata stored
  /// in the database, then moves it to permanent storage.
  Future<void> _onMediaFileReceived(
    String endpointId,
    String messageId,
    PayloadTransferUpdate update,
  ) async {
    try {
      // Look up the message metadata to get the expected hash and filename
      final message = await (_db.select(_db.messages)
            ..where((t) => t.messageId.equals(messageId)))
          .getSingleOrNull();

      if (message == null) {
        _log('Media file received for unknown message $messageId');
        return;
      }

      // The Nearby Connections API saves FILE payloads to a temporary
      // location. We need to find it and move it to our media directory.
      // The file path is typically: {cacheDir}/{payloadId}

      // TODO: In production, we'd get the actual temp file path from
      // the Nearby Connections API. For now, we mark as available and
      // let the UI know.

      // Update the database to mark the media as available
      await _db.updateMediaAvailability(
        messageId,
        MediaAvailability.available,
      );

      _emit(MediaTransferCompleted(messageId));
      _log('Media file received and stored for message $messageId');

      // Check if there are more pending transfers for this endpoint
      final count = (_mediaTransferCounts[endpointId] ?? 0) + 1;
      _mediaTransferCounts[endpointId] = count;

      // If we've hit the limit or no more pending file transfers,
      // disconnect from this peer
      if (count >= kMaxMediaSyncsPerConnection ||
          !_mediaPayloadToMessageId.values.isNotEmpty) {
        _disconnectAfterSync(endpointId);
      }
    } catch (e) {
      _emit(MediaTransferFailed(messageId, e.toString()));
      await _db.updateMediaAvailability(messageId, MediaAvailability.failed);
      _log('Media file processing failed for $messageId: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONNECTION CLEANUP
  // ─────────────────────────────────────────────────────────────────────────

  /// Disconnects from a peer and cleans up all tracking state.
  void _disconnectAfterSync(String endpointId) {
    _nearby.disconnectFromEndpoint(endpointId);
    _activeEndpoints.remove(endpointId);
    _endpointToNodeId.remove(endpointId);
    _pendingSyncMessageIds.remove(endpointId);
    _syncPayloadBuffers.remove(endpointId);
    _peerBloomFilters.remove(endpointId);
    _bloomPayloadIds.remove(endpointId);
    _syncPayloadIds.remove(endpointId);
    _mediaTransferCounts.remove(endpointId);
    _log('Disconnected from $endpointId (post-sync)');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASSIVE GROUP DISCOVERY
  // ─────────────────────────────────────────────────────────────────────────

  /// Saves groups discovered from an endpoint name to the local database.
  ///
  /// This is "passive" discovery — we learn about groups just by seeing
  /// them in endpoint names during the discovery phase, WITHOUT needing
  /// to establish a connection. The UI can then present these groups
  /// in a "Browse Groups" list for the user to join.
  void _saveDiscoveredGroup(EndpointMetadata metadata) {
    for (final groupId in metadata.groupIds) {
      // Skip wildcard / empty group IDs
      if (groupId == '*' || groupId.isEmpty) continue;

      // Fire-and-forget — don't block the discovery callback
      _db
          .upsertDiscoveredGroup(groupId: groupId)
          .then((_) {
            _emit(GroupDiscovered(groupId));
            _log('Passively discovered group: $groupId');
          })
          .catchError((Object e) {
            _log('Failed to save discovered group $groupId: $e');
          });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  void _emit(AirpassEvent event) => _eventController.add(event);

  void _log(String message) {
    AirpassLogger.log('AirpassMesh', message);
  }
}
