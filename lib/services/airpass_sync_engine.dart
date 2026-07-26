/// Airpass Protocol — Sync Engine
///
/// The core business logic for epidemic (gossip) routing.
///
/// ## Two-Phase Sync Protocol
///
/// When two devices connect, the sync engine performs a two-phase exchange:
///
/// **Phase 1 — Filter Exchange:**
/// Each side builds a Bloom filter of its known message IDs and sends it.
/// This is a tiny payload (~1.2 KB for 1000 messages).
///
/// **Phase 2 — Filtered Sync:**
/// Each side uses the received Bloom filter to exclude messages the peer
/// already has, then sends only the novel messages + full routing table.
///
/// This dramatically reduces bandwidth in dense meshes where most nodes
/// share a large percentage of their message stores.
library;

import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:isolate';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

import '../config/airpass_config.dart';
import '../database/airpass_database.dart';
import '../models/media_availability.dart';
import '../models/media_type.dart';
import '../models/node_role.dart';
import 'bloom_filter.dart';
import 'message_signer.dart';
import '../utils/airpass_logger.dart';
import '../utils/notification_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SYNC PAYLOAD MODEL
// ─────────────────────────────────────────────────────────────────────────────

/// The serializable envelope exchanged between peers during a sync.
///
/// ```json
/// {
///   "v": 1,
///   "sender": "node-uuid",
///   "ts": 1234567890,
///   "nodes": [ { "id": "...", "role": 0, ... }, ... ],
///   "msgs": [ { "id": "...", "from": "...", ... }, ... ]
/// }
/// ```
class SyncPayload {
  final int protocolVersion;
  final String senderNodeId;
  final int syncTimestamp;
  final List<SyncNodeEntry> nodes;
  final List<SyncMessageEntry> messages;

  const SyncPayload({
    required this.protocolVersion,
    required this.senderNodeId,
    required this.syncTimestamp,
    required this.nodes,
    required this.messages,
  });

  /// Serialize to a JSON map. Uses short keys to minimize payload size.
  Map<String, dynamic> toJson() => {
    'v': protocolVersion,
    'sender': senderNodeId,
    'ts': syncTimestamp,
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'msgs': messages.map((m) => m.toJson()).toList(),
  };

  /// Deserialize from a JSON map.
  factory SyncPayload.fromJson(Map<String, dynamic> json) {
    return SyncPayload(
      protocolVersion: json['v'] as int,
      senderNodeId: json['sender'] as String,
      syncTimestamp: json['ts'] as int,
      nodes: (json['nodes'] as List)
          .map((e) => SyncNodeEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      messages: (json['msgs'] as List)
          .map((e) => SyncMessageEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A node entry within a [SyncPayload].
class SyncNodeEntry {
  final String nodeId;
  final int role;
  final String? groupId;
  final int lastSeen;
  final int hopCount;
  final String? displayName;
  final int? batteryLevel;
  final bool hasInternetAccess;
  final String? metadata;

  const SyncNodeEntry({
    required this.nodeId,
    required this.role,
    this.groupId,
    required this.lastSeen,
    required this.hopCount,
    this.displayName,
    this.batteryLevel,
    this.hasInternetAccess = false,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': nodeId,
    'r': role,
    if (groupId != null) 'g': groupId,
    'ts': lastSeen,
    'h': hopCount,
    if (displayName != null) 'n': displayName,
    if (batteryLevel != null) 'bl': batteryLevel,
    if (hasInternetAccess) 'net': hasInternetAccess,
    if (metadata != null) 'm': metadata,
  };

  factory SyncNodeEntry.fromJson(Map<String, dynamic> json) {
    return SyncNodeEntry(
      nodeId: json['id'] as String,
      role: json['r'] as int,
      groupId: json['g'] as String?,
      lastSeen: json['ts'] as int,
      hopCount: json['h'] as int,
      displayName: json['n'] as String?,
      batteryLevel: json['bl'] as int?,
      hasInternetAccess: json['net'] as bool? ?? false,
      metadata: json['m'] as String?,
    );
  }
}

/// A message entry within a [SyncPayload].
///
/// For media messages, only the metadata and thumbnail are included.
/// The actual binary file is transferred separately via Nearby's
/// FILE payload API (Phase 3).
class SyncMessageEntry {
  final String messageId;
  final String senderId;
  final String targetId;
  final String payloadBase64; // Base64-encoded bytes for JSON safety
  final int status;
  final int createdAt;
  final int ttl;
  final String? signature;

  // ─── Media Metadata ───
  // These travel through the mesh. The actual binary does NOT.

  /// Media type (0 = text, 1 = image, 2 = video, etc.).
  final int mediaType;

  /// Original filename (e.g., 'photo_001.jpg'). Null for text.
  final String? mediaFileName;

  /// MIME type (e.g., 'image/jpeg'). Null for text.
  final String? mediaMimeType;

  /// Size of the full media file in bytes. Null for text.
  final int? mediaFileSize;

  /// SHA-256 hash of the full media file. Null for text.
  final String? mediaHash;

  /// Base64-encoded thumbnail bytes (≤5 KB). Null for text or
  /// media types that don't support thumbnails.
  final String? thumbnailBase64;

  const SyncMessageEntry({
    required this.messageId,
    required this.senderId,
    required this.targetId,
    required this.payloadBase64,
    required this.status,
    required this.createdAt,
    required this.ttl,
    this.signature,
    this.mediaType = 0,
    this.mediaFileName,
    this.mediaMimeType,
    this.mediaFileSize,
    this.mediaHash,
    this.thumbnailBase64,
  });

  /// Whether this message carries a media attachment.
  bool get isMedia => mediaType != MediaType.text.value;

  Map<String, dynamic> toJson() => {
    'id': messageId,
    'from': senderId,
    'to': targetId,
    'p': payloadBase64,
    's': status,
    'ts': createdAt,
    'ttl': ttl,
    if (signature != null) 'sig': signature,
    // Media metadata — only included for media messages
    if (mediaType != 0) 'mt': mediaType,
    if (mediaFileName != null) 'mfn': mediaFileName,
    if (mediaMimeType != null) 'mmt': mediaMimeType,
    if (mediaFileSize != null) 'mfs': mediaFileSize,
    if (mediaHash != null) 'mh': mediaHash,
    if (thumbnailBase64 != null) 'thumb': thumbnailBase64,
  };

  factory SyncMessageEntry.fromJson(Map<String, dynamic> json) {
    return SyncMessageEntry(
      messageId: json['id'] as String,
      senderId: json['from'] as String,
      targetId: json['to'] as String,
      payloadBase64: json['p'] as String,
      status: json['s'] as int,
      createdAt: json['ts'] as int,
      ttl: json['ttl'] as int,
      signature: json['sig'] as String?,
      mediaType: json['mt'] as int? ?? 0,
      mediaFileName: json['mfn'] as String?,
      mediaMimeType: json['mmt'] as String?,
      mediaFileSize: json['mfs'] as int?,
      mediaHash: json['mh'] as String?,
      thumbnailBase64: json['thumb'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SYNC ENGINE
// ─────────────────────────────────────────────────────────────────────────────

/// Orchestrates the epidemic data exchange between two connected peers.
///
/// Usage (called by [NearbyConnectionManager]):
/// ```dart
/// // When connection is established:
/// final outgoing = await syncEngine.buildSyncPayload();
/// Nearby().sendBytesPayload(endpointId, outgoing);
///
/// // When peer's payload is received:
/// await syncEngine.processSyncPayload(incomingBytes);
/// ```
class AirpassSyncEngine {
  final AirpassDatabase _db;
  final MessageSigner _signer;

  /// The local node's UUID. Set during initialization.
  final String localNodeId;

  /// The local node's role. Used to populate the self-entry in sync payloads.
  NodeRole localRole;

  /// All groups the local node is subscribed to.
  /// Used to populate self-entries in the routing table so that multi-hop
  /// peers learn about ALL of our group memberships, not just the first.
  List<String> localGroupIds;

  /// The local user's display name, if set.
  String? localDisplayName;

  /// The local node's battery level (0-100), if available.
  int? localBatteryLevel;

  /// Whether the local node currently has internet access.
  bool localHasInternetAccess;

  /// The local user's selected skills.
  List<String> localSkills;

  AirpassSyncEngine({
    required AirpassDatabase database,
    required this.localNodeId,
    required this.localRole,
    this.localGroupIds = const [],
    this.localDisplayName,
    this.localBatteryLevel,
    this.localHasInternetAccess = false,
    this.localSkills = const [],
  }) : _db = database,
       _signer = MessageSigner(nodeId: localNodeId);

  // ─────────────────────────────────────────────────────────────────────────
  // OUTGOING: Build the sync payload to send to a peer
  // ─────────────────────────────────────────────────────────────────────────

  /// Packages the local routing table and syncable messages into a
  /// compressed bytes payload ready to send via [Nearby.sendBytesPayload].
  ///
  /// If [peerNodeId] is provided, uses per-peer dedup to exclude messages
  /// already delivered to that peer. Otherwise sends all syncable messages.
  ///
  /// Returns the gzip-compressed JSON bytes.
  Future<Uint8List> buildSyncPayload({String? peerNodeId}) async {
    // 1. Gather local state
    final allNodes = await _db.getAllNodes();
    final allMessages = peerNodeId != null
        ? await _db.getMessagesForSync(peerNodeId)
        : await _db.getAllSyncableMessages();

    // 2. Build self-entries — one per subscribed group so multi-hop peers
    //    learn about ALL of our group memberships.
    final now = DateTime.now().millisecondsSinceEpoch;
    final selfEntries = localGroupIds.isNotEmpty
        ? localGroupIds
              .map(
                (gid) => SyncNodeEntry(
                  nodeId: localNodeId,
                  role: localRole.value,
                  groupId: gid,
                  lastSeen: now,
                  hopCount: 0,
                  displayName: localDisplayName,
                  batteryLevel: localBatteryLevel,
                  hasInternetAccess: localHasInternetAccess,
                  metadata: localSkills.isNotEmpty ? jsonEncode({'skills': localSkills}) : null,
                ),
              )
              .toList()
        : [
            SyncNodeEntry(
              nodeId: localNodeId,
              role: localRole.value,
              groupId: null,
              lastSeen: now,
              hopCount: 0,
              displayName: localDisplayName,
              batteryLevel: localBatteryLevel,
              hasInternetAccess: localHasInternetAccess,
              metadata: localSkills.isNotEmpty ? jsonEncode({'skills': localSkills}) : null,
            ),
          ];

    // 3. Build the sync envelope
    final payload = SyncPayload(
      protocolVersion: kAirpassProtocolVersion,
      senderNodeId: localNodeId,
      syncTimestamp: now,
      nodes: [
        // Include self-entries for all subscribed groups
        ...selfEntries,
        // Include all known nodes with incremented hop count
        ...allNodes.map(
          (n) => SyncNodeEntry(
            nodeId: n.nodeId,
            role: n.role,
            groupId: n.groupId,
            lastSeen: n.lastSeen,
            hopCount: n.hopCount + 1, // One more hop from us
            displayName: n.displayName,
            batteryLevel: n.batteryLevel,
            hasInternetAccess: n.hasInternetAccess,
            metadata: n.metadata,
          ),
        ),
      ],
      messages: allMessages
          .map((m) {
            // Sign outgoing messages that don't have a signature yet
            final sig =
                m.signature ??
                _signer.signMessage(
                  messageId: m.messageId,
                  senderId: m.senderId,
                  targetId: m.targetId,
                  payload: m.payload,
                  createdAt: m.createdAt,
                );
            return SyncMessageEntry(
              messageId: m.messageId,
              senderId: m.senderId,
              targetId: m.targetId,
              payloadBase64: base64Encode(m.payload),
              status: m.status,
              createdAt: m.createdAt,
              ttl: m.ttl - 1, // Decrement TTL on relay
              signature: sig,
              // Media metadata — propagates through the mesh
              mediaType: m.mediaType,
              mediaFileName: m.mediaFileName,
              mediaMimeType: m.mediaMimeType,
              mediaFileSize: m.mediaFileSize,
              mediaHash: m.mediaHash,
              thumbnailBase64: m.mediaThumbnail != null
                  ? base64Encode(m.mediaThumbnail!)
                  : null,
            );
          })
          .where((m) => m.ttl > 0) // Don't send expired messages
          .toList(),
    );

    // 4. Mark included messages as SENT (transition from PENDING → SENT)
    final sentIds = payload.messages.map((m) => m.messageId).toList();
    if (sentIds.isNotEmpty) {
      await _db.markMessagesAsSent(sentIds);
    }

    // 5. Serialize → compress
    final jsonString = jsonEncode(payload.toJson());
    final jsonBytes = utf8.encode(jsonString);
    final compressed = gzip.encode(jsonBytes);

    return Uint8List.fromList(compressed);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OUTGOING: Build Bloom filter for pre-sync exchange
  // ─────────────────────────────────────────────────────────────────────────

  /// Builds a Bloom filter containing the IDs of all syncable messages
  /// in the local database.
  ///
  /// This filter is sent to the peer BEFORE the full sync payload.
  /// The peer uses it to exclude messages we already have, saving bandwidth.
  ///
  /// Returns the serialized Bloom filter bytes (prefixed with magic `0xBF 0x00`).
  Future<Uint8List> buildBloomFilter() async {
    final allMessages = await _db.getAllSyncableMessages();

    // Size the filter for the actual message count (minimum 10 to avoid
    // degenerate tiny filters)
    final filter = BloomFilter.optimal(
      expectedItems: math.max(allMessages.length, 10),
      falsePositiveRate: kBloomFilterFalsePositiveRate,
    );

    for (final m in allMessages) {
      filter.add(m.messageId);
    }

    final bytes = filter.toBytes();
    _log(
      'Built Bloom filter (${allMessages.length} message IDs, ${bytes.length} bytes)',
    );
    return bytes;
  }

  /// Packages the local routing table and syncable messages into a
  /// compressed bytes payload, using the peer's Bloom filter to exclude
  /// messages the peer already has.
  ///
  /// This is the Phase 2 method — called after receiving the peer's
  /// Bloom filter in Phase 1.
  ///
  /// [peerFilter] — the peer's Bloom filter. Messages that match
  ///   ("peer probably has this") are excluded from the payload.
  ///   If null, all syncable messages are included (no filtering).
  /// [peerNodeId] — for per-peer delivery dedup (excludes messages
  ///   we've already sent to this specific peer in previous syncs).
  ///
  /// Returns the gzip-compressed JSON bytes.
  Future<Uint8List> buildFilteredSyncPayload({
    BloomFilter? peerFilter,
    String? peerNodeId,
  }) async {
    // 1. Gather local state
    final allNodes = await _db.getAllNodes();
    final candidateMessages = peerNodeId != null
        ? await _db.getMessagesForSync(peerNodeId)
        : await _db.getAllSyncableMessages();

    // 2. Apply Bloom filter to exclude messages the peer already has
    final filteredMessages = peerFilter != null
        ? candidateMessages
              .where((m) => !peerFilter.mightContain(m.messageId))
              .toList()
        : candidateMessages;

    // 3. Build self-entries
    final now = DateTime.now().millisecondsSinceEpoch;
    final selfEntries = localGroupIds.isNotEmpty
        ? localGroupIds
              .map(
                (gid) => SyncNodeEntry(
                  nodeId: localNodeId,
                  role: localRole.value,
                  groupId: gid,
                  lastSeen: now,
                  hopCount: 0,
                  displayName: localDisplayName,
                  batteryLevel: localBatteryLevel,
                  hasInternetAccess: localHasInternetAccess,
                  metadata: localSkills.isNotEmpty ? jsonEncode({'skills': localSkills}) : null,
                ),
              )
              .toList()
        : [
            SyncNodeEntry(
              nodeId: localNodeId,
              role: localRole.value,
              groupId: null,
              lastSeen: now,
              hopCount: 0,
              displayName: localDisplayName,
              batteryLevel: localBatteryLevel,
              hasInternetAccess: localHasInternetAccess,
              metadata: localSkills.isNotEmpty ? jsonEncode({'skills': localSkills}) : null,
            ),
          ];

    // 4. Build the sync envelope
    final payload = SyncPayload(
      protocolVersion: kAirpassProtocolVersion,
      senderNodeId: localNodeId,
      syncTimestamp: now,
      nodes: [
        ...selfEntries,
        ...allNodes.map(
          (n) => SyncNodeEntry(
            nodeId: n.nodeId,
            role: n.role,
            groupId: n.groupId,
            lastSeen: n.lastSeen,
            hopCount: n.hopCount + 1,
            displayName: n.displayName,
            batteryLevel: n.batteryLevel,
            hasInternetAccess: n.hasInternetAccess,
            metadata: n.metadata,
          ),
        ),
      ],
      messages: filteredMessages
          .map((m) {
            final sig =
                m.signature ??
                _signer.signMessage(
                  messageId: m.messageId,
                  senderId: m.senderId,
                  targetId: m.targetId,
                  payload: m.payload,
                  createdAt: m.createdAt,
                );
            return SyncMessageEntry(
              messageId: m.messageId,
              senderId: m.senderId,
              targetId: m.targetId,
              payloadBase64: base64Encode(m.payload),
              status: m.status,
              createdAt: m.createdAt,
              ttl: m.ttl - 1,
              signature: sig,
              // Media metadata — propagates through the mesh
              mediaType: m.mediaType,
              mediaFileName: m.mediaFileName,
              mediaMimeType: m.mediaMimeType,
              mediaFileSize: m.mediaFileSize,
              mediaHash: m.mediaHash,
              thumbnailBase64: m.mediaThumbnail != null
                  ? base64Encode(m.mediaThumbnail!)
                  : null,
            );
          })
          .where((m) => m.ttl > 0)
          .toList(),
    );

    // 5. Mark included messages as SENT
    final sentIds = payload.messages.map((m) => m.messageId).toList();
    if (sentIds.isNotEmpty) {
      await _db.markMessagesAsSent(sentIds);
    }

    // 6. Serialize → compress
    final jsonString = jsonEncode(payload.toJson());
    final jsonBytes = utf8.encode(jsonString);
    final compressed = gzip.encode(jsonBytes);

    _log(
      'Built sync payload: ${payload.nodes.length} node entries, '
      '${payload.messages.length} filtered messages '
      '(raw: ${jsonBytes.length} bytes, gzip: ${compressed.length} bytes)',
    );

    return Uint8List.fromList(compressed);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INCOMING: Process a received sync payload from a peer
  // ─────────────────────────────────────────────────────────────────────────

  /// Decompresses, parses, and merges an incoming sync payload into the
  /// local database.
  ///
  /// Heavy JSON parsing is offloaded to a background isolate if the
  /// decompressed payload exceeds [kIsolateParsingThresholdBytes].
  ///
  /// Returns a record with the number of new messages ingested and the peer's full node ID.
  Future<({int newMessages, String peerNodeId})> processSyncPayload(
    Uint8List compressedBytes,
  ) async {
    // 1. Decompress
    final decompressed = gzip.decode(compressedBytes);
    final jsonString = utf8.decode(decompressed);

    // 2. Parse — use isolate for large payloads
    SyncPayload syncPayload;
    if (decompressed.length > kIsolateParsingThresholdBytes) {
      syncPayload = await Isolate.run(() {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return SyncPayload.fromJson(json);
      });
    } else {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      syncPayload = SyncPayload.fromJson(json);
    }

    // 3. Merge nodes into routing table
    await _mergeNodes(syncPayload.nodes, syncPayload.senderNodeId);

    // 4. Active Group Discovery — extract new groups from the routing table
    await _discoverGroupsFromNodes(syncPayload.nodes);

    // 5. Merge messages into store-and-forward table
    final newMessageCount = await _mergeMessages(syncPayload.messages);

    // 6. Update group member counts from the full routing table
    await _updateGroupMemberCounts();

    // 7. Cleanup
    await _db.pruneExpiredMessages(ttlHours: kAirpassMessageTtlHours);
    await _db.pruneStaleNodes(kStaleNodeThreshold);
    await _db.pruneOrphanedDeliveries();

    return (newMessages: newMessageCount, peerNodeId: syncPayload.senderNodeId);
  }

  /// Merges incoming node entries into the local routing table.
  ///
  /// For each node:
  /// - If unknown, insert it.
  /// - If known, update only if the incoming [lastSeen] is more recent.
  Future<void> _mergeNodes(
    List<SyncNodeEntry> incomingNodes,
    String peerNodeId,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Find the peer's self-entry in the incoming nodes list to get their
    // full metadata (displayName, batteryLevel, hasInternetAccess, etc.).
    // The self-entry has hopCount == 0 since it's about themselves.
    final peerSelfEntry = incomingNodes
        .where((n) => n.nodeId == peerNodeId && n.hopCount == 0)
        .firstOrNull;

    // Always update the direct peer as hop 0 (we just talked to them),
    // preserving their metadata from the sync payload.
    await _db.upsertNode(
      NodesCompanion(
        nodeId: Value(peerNodeId),
        lastSeen: Value(now),
        hopCount: const Value(0),
        role: Value(peerSelfEntry?.role ?? NodeRole.group.value),
        groupId: Value(peerSelfEntry?.groupId),
        displayName: Value(peerSelfEntry?.displayName),
        batteryLevel: Value(peerSelfEntry?.batteryLevel),
        hasInternetAccess: Value(peerSelfEntry?.hasInternetAccess ?? false),
        metadata: Value(peerSelfEntry?.metadata),
      ),
    );

    for (final incoming in incomingNodes) {
      // Skip self
      if (incoming.nodeId == localNodeId) continue;

      // Skip the direct peer — already handled above with fresh data
      if (incoming.nodeId == peerNodeId && incoming.hopCount == 0) continue;

      // Check if we already know this node with fresher data
      final existing = await (_db.select(
        _db.nodes,
      )..where((t) => t.nodeId.equals(incoming.nodeId))).getSingleOrNull();

      if (existing == null || incoming.lastSeen > existing.lastSeen) {
        await _db.upsertNode(
          NodesCompanion(
            nodeId: Value(incoming.nodeId),
            role: Value(incoming.role),
            groupId: Value(incoming.groupId),
            lastSeen: Value(incoming.lastSeen),
            hopCount: Value(incoming.hopCount),
            displayName: Value(incoming.displayName),
            batteryLevel: Value(incoming.batteryLevel),
            hasInternetAccess: Value(incoming.hasInternetAccess),
            // We overwrite metadata with incoming since it's fresher data
            metadata: Value(incoming.metadata),
          ),
        );
      }
    }
  }

  /// Merges incoming messages into the local store-and-forward table.
  ///
  /// Deduplication is handled by [AirpassDatabase.upsertMessage] —
  /// messages with the same [messageId] are silently skipped.
  ///
  /// Signature verification: If a message carries an HMAC-SHA256 signature,
  /// it is verified using the sender's node ID as the key. Messages with
  /// invalid signatures are dropped to prevent tampered payloads from
  /// propagating through the mesh.
  ///
  /// Returns the count of genuinely new messages ingested.
  Future<int> _mergeMessages(List<SyncMessageEntry> incomingMessages) async {
    int newCount = 0;

    for (final incoming in incomingMessages) {
      // Skip messages we sent ourselves (we already have them)
      if (incoming.senderId == localNodeId) continue;

      // Skip expired messages
      if (incoming.ttl <= 0) continue;

      // Verify signature integrity if present.
      // The HMAC key is the sender's node UUID — any node that knows the
      // sender ID can re-derive the key and verify the message wasn't
      // tampered with by intermediate relay nodes.
      if (incoming.signature != null && incoming.signature!.isNotEmpty) {
        final senderSigner = MessageSigner(nodeId: incoming.senderId);
        final payloadBytes = Uint8List.fromList(
          base64Decode(incoming.payloadBase64),
        );
        final isValid = senderSigner.verifySignature(
          messageId: incoming.messageId,
          senderId: incoming.senderId,
          targetId: incoming.targetId,
          payload: payloadBytes,
          createdAt: incoming.createdAt,
          signature: incoming.signature!,
        );
        if (!isValid) {
          // Signature mismatch — message was tampered with during relay.
          // Drop it silently to prevent poisoned data from propagating.
          continue;
        }
      }

      final wasNew = await _db.upsertMessage(
        MessagesCompanion(
          messageId: Value(incoming.messageId),
          senderId: Value(incoming.senderId),
          targetId: Value(incoming.targetId),
          payload: Value(
            Uint8List.fromList(base64Decode(incoming.payloadBase64)),
          ),
          status: Value(incoming.status),
          createdAt: Value(incoming.createdAt),
          ttl: Value(incoming.ttl),
          signature: Value(incoming.signature),
          // Media metadata — store what arrived through the mesh
          mediaType: Value(incoming.mediaType),
          mediaFileName: Value(incoming.mediaFileName),
          mediaMimeType: Value(incoming.mediaMimeType),
          mediaFileSize: Value(incoming.mediaFileSize),
          mediaHash: Value(incoming.mediaHash),
          mediaThumbnail: Value(
            incoming.thumbnailBase64 != null
                ? Uint8List.fromList(base64Decode(incoming.thumbnailBase64!))
                : null,
          ),
          // Binary is NOT available yet — it travels separately via Phase 3.
          // Text messages (mediaType == 0) stay at notApplicable.
          mediaAvailability: Value(
            incoming.isMedia
                ? MediaAvailability.pendingDownload.value
                : MediaAvailability.notApplicable.value,
          ),
          mediaLocalPath: const Value(null),
        ),
      );

      if (wasNew) {
        newCount++;

        // NOTE: Message delivery to the local node is handled reactively.
        // The UI calls `AirpassClient.listenForMessages(localNodeId)` which
        // uses Drift's `.watch()` — so the UI stream automatically emits
        // when this insert lands in the database. No explicit callback needed.

        // Show a local notification if the message is intended for us
        final isForUs = incoming.targetId == localNodeId ||
            incoming.targetId == '*' ||
            localGroupIds.contains(incoming.targetId);

        if (isForUs) {
          try {
            // Get sender's display name
            final senderNode = await (_db.select(_db.nodes)
                  ..where((t) => t.nodeId.equals(incoming.senderId)))
                .getSingleOrNull();
            final senderName = senderNode?.displayName ?? 'Unknown Node';

            String title = senderName;
            if (incoming.targetId == '*') {
              title = '$senderName (Global Broadcast)';
            } else if (localGroupIds.contains(incoming.targetId)) {
              final groupNode = await (_db.select(_db.groups)
                    ..where((t) => t.groupId.equals(incoming.targetId)))
                  .getSingleOrNull();
              final groupName = groupNode?.displayName ?? incoming.targetId;
              title = '$senderName in $groupName';
            }

            // Build notification body — media messages show a descriptive label
            // instead of trying to UTF-8 decode binary data.
            final String messageText;
            if (incoming.isMedia) {
              final mediaLabel = switch (MediaType.fromValue(incoming.mediaType)) {
                MediaType.image => '📷 Photo',
                MediaType.video => '🎥 Video',
                MediaType.audio => '🎵 Voice message',
                MediaType.file => '📎 ${incoming.mediaFileName ?? 'File'}',
                MediaType.text => '', // Won't reach here due to isMedia check
              };
              // If there's a text caption alongside the media, show both
              final captionBytes = base64Decode(incoming.payloadBase64);
              final caption = captionBytes.isNotEmpty
                  ? utf8.decode(captionBytes, allowMalformed: true)
                  : '';
              messageText = caption.isNotEmpty
                  ? '$mediaLabel: $caption'
                  : mediaLabel;
            } else {
              messageText = utf8.decode(
                base64Decode(incoming.payloadBase64),
              );
            }

            NotificationHelper.showNewMessageNotification(
              title: title,
              body: messageText,
            );
          } catch (e) {
            _log('Failed to show notification: $e');
          }
        }
      }
    } // closing brace for the `for` loop

    return newCount;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ACTIVE GROUP DISCOVERY
  // ───────────────────────────────────────────────────────────────────────────

  /// Extracts distinct group IDs from an incoming routing table and
  /// saves them to the local group directory.
  ///
  /// This is "active" group discovery — we learn about groups that may
  /// be several hops away, not just groups of directly-encountered nodes.
  /// Combined with passive discovery (from endpoint names), this gives
  /// the mesh a comprehensive view of the group landscape.
  Future<void> _discoverGroupsFromNodes(
    List<SyncNodeEntry> incomingNodes,
  ) async {
    // Collect unique, non-null, non-wildcard group IDs
    final discoveredGroupIds = <String>{};
    for (final node in incomingNodes) {
      final gid = node.groupId;
      if (gid != null && gid != '*' && gid.isNotEmpty) {
        discoveredGroupIds.add(gid);
      }
    }

    // Save each discovered group to the database
    for (final groupId in discoveredGroupIds) {
      await _db.upsertDiscoveredGroup(groupId: groupId);
    }
  }

  /// Updates the member count for all known groups by scanning the
  /// full routing table.
  ///
  /// Called after every sync merge so the UI can display accurate
  /// group sizes (e.g., "protest-2026 — 47 members").
  Future<void> _updateGroupMemberCounts() async {
    final counts = await _db.countGroupMemberships();
    for (final entry in counts.entries) {
      await _db.upsertDiscoveredGroup(
        groupId: entry.key,
        memberCount: entry.value,
      );
    }
  }

  void _log(String message) {
    AirpassLogger.log('AirpassSync', message);
  }
}
