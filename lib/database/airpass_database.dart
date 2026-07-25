/// Airpass Protocol — Drift Database Definition
///
/// Defines the three core tables ([Nodes], [Messages], and [Groups])
/// and their type-safe DAO methods. Uses Drift's code generation for reactive
/// queries and compile-time SQL validation.
///
/// After modifying this file, regenerate with:
/// ```bash
/// dart run build_runner build --delete-conflicting-outputs
/// ```
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/media_availability.dart';
import '../models/media_type.dart';
import '../models/message_status.dart';
import '../models/node_role.dart';

part 'airpass_database.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TABLE DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Routing table — stores every node this device has ever learned about
/// through direct encounter or gossip relay.
class Nodes extends Table {
  /// Unique node identifier (UUID v4, generated on first launch).
  TextColumn get nodeId => text()();

  /// The node's mesh role, stored as an integer mapping to [NodeRole].
  IntColumn get role => integer().withDefault(const Constant(1))();

  /// Optional group affiliation. Null means the node is ungrouped.
  /// Used by [NodeRole.group] nodes for filtered routing.
  TextColumn get groupId => text().nullable()();

  /// Epoch milliseconds of the last time this node was encountered
  /// (directly or via gossip).
  IntColumn get lastSeen => integer()();

  /// How many relay hops away this node was last known to be.
  /// 0 = direct encounter, 1 = one hop away, etc.
  IntColumn get hopCount => integer().withDefault(const Constant(0))();

  /// Human-readable display name chosen by the user.
  TextColumn get displayName => text().nullable()();

  /// Battery level of the node (0-100).
  IntColumn get batteryLevel => integer().nullable()();

  /// Whether the node has internet access.
  BoolColumn get hasInternetAccess => boolean().withDefault(const Constant(false))();

  /// Extensible JSON blob for future metadata (e.g., capabilities, version).
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {nodeId};
}

/// Store-and-forward message table — holds messages created locally
/// or received via gossip that haven't yet reached their target.
class Messages extends Table {
  /// Globally unique message identifier (UUID v4).
  TextColumn get messageId => text()();

  /// The originating node's ID.
  TextColumn get senderId => text()();

  /// The destination node's ID. Use '*' for broadcast messages.
  TextColumn get targetId => text()();

  /// The encoded message content (arbitrary bytes).
  BlobColumn get payload => blob()();

  /// Delivery status, stored as an integer mapping to [MessageStatus].
  IntColumn get status =>
      integer().withDefault(Constant(MessageStatus.pending.value))();

  /// Epoch milliseconds when the message was originally created.
  IntColumn get createdAt => integer()();

  /// Remaining hop budget. Decremented on each relay.
  /// When this reaches 0, the message is marked [MessageStatus.expired].
  IntColumn get ttl => integer()();

  /// Optional HMAC-SHA256 signature for message integrity verification.
  /// Computed by [MessageSigner] when the message is created locally.
  /// Relaying nodes can verify the signature to detect tampering.
  TextColumn get signature => text().nullable()();

  // ─── Media Metadata ───
  // These fields support the metadata-first, file-on-demand architecture.
  // Only the metadata + thumbnail travel through epidemic routing.
  // The actual binary is transferred via Nearby's FILE payload API.

  /// The type of media attached (0 = text, 1 = image, 2 = video, etc.).
  /// See [MediaType]. Defaults to 0 (text — no media).
  IntColumn get mediaType => integer().withDefault(const Constant(0))();

  /// Original filename of the attached media (e.g., 'photo_001.jpg').
  /// Null for text-only messages.
  TextColumn get mediaFileName => text().nullable()();

  /// MIME type of the media (e.g., 'image/jpeg', 'video/mp4').
  /// Null for text-only messages.
  TextColumn get mediaMimeType => text().nullable()();

  /// Size of the full media file in bytes.
  /// Used by the UI to display file size and decide auto-download.
  IntColumn get mediaFileSize => integer().nullable()();

  /// SHA-256 hash of the full media file for integrity verification.
  /// Computed on send, verified on receive after FILE transfer.
  TextColumn get mediaHash => text().nullable()();

  /// Local filesystem path to the downloaded media binary.
  /// Null until the binary is successfully transferred.
  TextColumn get mediaLocalPath => text().nullable()();

  /// Availability state of the media binary on this device.
  /// See [MediaAvailability]. Defaults to 0 (notApplicable — text message).
  IntColumn get mediaAvailability =>
      integer().withDefault(const Constant(0))();

  /// Compressed thumbnail bytes (JPEG, ≤5 KB) for instant preview.
  /// Embedded directly in the epidemic sync payload so users see
  /// a preview even before the full file is transferred.
  BlobColumn get mediaThumbnail => blob().nullable()();

  @override
  Set<Column> get primaryKey => {messageId};
}

/// Group directory — stores groups discovered through the mesh network.
/// Groups are learned passively (from endpoint names during discovery)
/// and actively (from routing tables exchanged during sync).
class Groups extends Table {
  /// Unique group identifier string (e.g., 'protest-2026', 'aid-sector-5').
  TextColumn get groupId => text()();

  /// Human-readable display name for the group.
  /// May be the same as [groupId] when first discovered; can be updated later.
  TextColumn get displayName => text()();

  /// Epoch milliseconds when this group was first discovered.
  IntColumn get discoveredAt => integer()();

  /// Epoch milliseconds of the last time a node advertising this group
  /// was encountered (directly or via gossip).
  IntColumn get lastSeenAt => integer()();

  /// Number of distinct nodes currently known to belong to this group.
  /// Updated during sync merges for UI display (e.g., "12 members").
  IntColumn get memberCount => integer().withDefault(const Constant(1))();

  /// Whether the local node is subscribed (actively participating) in
  /// this group. Only one group can be active at a time for
  /// [NodeRole.group] nodes.
  BoolColumn get isSubscribed => boolean().withDefault(const Constant(false))();

  /// Extensible JSON blob for future metadata (e.g., description, icon).
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {groupId};
}

/// Per-peer message delivery tracking — prevents retransmitting
/// messages to peers that have already received them.
///
/// When we successfully sync a message to a peer, we record the
/// delivery here. On the next sync with the same peer, we exclude
/// messages that already have a delivery record for that peer.
///
/// This is the bandwidth optimization for epidemic routing — without
/// this table, every sync would re-send the full message store.
class MessageDeliveries extends Table {
  /// The message that was delivered.
  TextColumn get messageId => text()();

  /// The peer node that received this message.
  TextColumn get peerNodeId => text()();

  /// Epoch milliseconds when the delivery occurred.
  IntColumn get deliveredAt => integer()();

  @override
  Set<Column> get primaryKey => {messageId, peerNodeId};
}

// ─────────────────────────────────────────────────────────────────────────────
// DATABASE CLASS
// ─────────────────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Nodes, Messages, Groups, MessageDeliveries])
class AirpassDatabase extends _$AirpassDatabase {
  /// Creates the database using [driftDatabase] which handles
  /// platform-specific SQLite opening logic automatically, or a custom [executor] for testing.
  AirpassDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'airpass_mesh'));

  /// Bump this when you change the schema. See [migration] below.
  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 → v2: Add the Groups table for dynamic group discovery.
            await m.createTable(groups);
          }
          if (from < 3) {
            // v2 → v3: Add the MessageDeliveries table for per-peer dedup.
            await m.createTable(messageDeliveries);
          }
          if (from < 4) {
            // v3 → v4: Add displayName to Nodes table.
            await m.addColumn(nodes, nodes.displayName);
          }
          if (from < 5) {
            // v4 → v5: Add batteryLevel and hasInternetAccess to Nodes table.
            await m.addColumn(nodes, nodes.batteryLevel);
            await m.addColumn(nodes, nodes.hasInternetAccess);
          }
          if (from < 6) {
            // v5 → v6: Add multimedia metadata columns to Messages table.
            await m.addColumn(messages, messages.mediaType);
            await m.addColumn(messages, messages.mediaFileName);
            await m.addColumn(messages, messages.mediaMimeType);
            await m.addColumn(messages, messages.mediaFileSize);
            await m.addColumn(messages, messages.mediaHash);
            await m.addColumn(messages, messages.mediaLocalPath);
            await m.addColumn(messages, messages.mediaAvailability);
            await m.addColumn(messages, messages.mediaThumbnail);
          }
        },
      );

  // ───────────────────────────────────────────────────────────────────────────
  // NODE OPERATIONS (Routing Table)
  // ───────────────────────────────────────────────────────────────────────────

  /// Watches all known nodes, ordered by most recently seen.
  /// Use this to build a live routing table view in the UI.
  Stream<List<Node>> watchKnownNodes() {
    return (select(nodes)..orderBy([(t) => OrderingTerm.desc(t.lastSeen)]))
        .watch();
  }

  /// Returns all known nodes as a one-shot query.
  Future<List<Node>> getAllNodes() => select(nodes).get();

  /// Insert or update a node. On conflict (same [nodeId]), the existing
  /// row is **unconditionally** overwritten with the incoming data.
  ///
  /// **Important:** This method does NOT enforce freshness — callers are
  /// responsible for checking whether the incoming data is newer before
  /// calling this method. The [AirpassSyncEngine._mergeNodes] method
  /// performs this check by comparing [lastSeen] timestamps.
  Future<void> upsertNode(NodesCompanion entry) async {
    await into(nodes).insertOnConflictUpdate(entry);
  }

  /// Resolves an 8-character node ID prefix to the full UUID stored in
  /// the routing table.
  ///
  /// This is used by [NearbyConnectionManager._performSync] to fix the
  /// per-peer dedup mismatch: endpoint names only carry an 8-char prefix,
  /// but [MessageDeliveries] records full UUIDs. On re-encounters, we
  /// need the full UUID to correctly query delivery history.
  ///
  /// Returns null if no node with this prefix has been seen before
  /// (i.e., this is a first encounter — full sync is appropriate).
  Future<String?> resolveFullNodeId(String prefix) async {
    final node = await (select(nodes)
          ..where((t) => t.nodeId.like('$prefix%'))
          ..limit(1))
        .getSingleOrNull();
    return node?.nodeId;
  }

  /// Removes nodes that haven't been seen within [threshold].
  /// Call this periodically from the background service.
  Future<int> pruneStaleNodes(Duration threshold) {
    final cutoff =
        DateTime.now().subtract(threshold).millisecondsSinceEpoch;
    return (delete(nodes)..where((t) => t.lastSeen.isSmallerThanValue(cutoff)))
        .go();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MESSAGE OPERATIONS (Store-and-Forward)
  // ───────────────────────────────────────────────────────────────────────────

  /// Watches all messages matching [targetId] — reactively.
  ///
  /// This is the primary UI-facing query. It:
  /// 1. Immediately emits all historical messages from the database.
  /// 2. Emits updates whenever new messages arrive via sync.
  ///
  /// [targetId] can be:
  /// - A specific group/role name to watch group messages
  /// - '*' to watch broadcast messages
  ///
  /// Messages are ordered by creation time (newest last).
  Stream<List<Message>> watchMessagesForTarget(String targetId) {
    return (select(messages)
          ..where((t) => t.targetId.equals(targetId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Watches direct messages between the local node and a specific peer.
  /// Includes messages sent BY local TO peer, and BY peer TO local.
  Stream<List<Message>> watchDirectMessages(String peerId, String localId) {
    return (select(messages)
          ..where((t) =>
              (t.senderId.equals(localId) & t.targetId.equals(peerId)) |
              (t.senderId.equals(peerId) & t.targetId.equals(localId)))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Watches all messages addressed to the local node or broadcast.
  ///
  /// This is useful for a unified inbox view.
  Stream<List<Message>> watchIncomingMessages(String localNodeId) {
    return (select(messages)
          ..where((t) =>
              t.targetId.equals(localNodeId) | t.targetId.equals('*'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }


  /// Watches all pending messages (not yet synced to any peer).
  Stream<List<Message>> watchPendingMessages() {
    return (select(messages)
          ..where(
              (t) => t.status.equals(MessageStatus.pending.value)))
        .watch();
  }

  /// Returns messages that should be sent to a specific peer during sync.
  ///
  /// This includes:
  /// - Messages targeting the peer's node ID directly
  /// - Broadcast messages (targetId == '*')
  /// - Messages still pending/sent that have TTL > 0
  /// - **Excludes** messages already delivered to this peer (per-peer dedup)
  Future<List<Message>> getMessagesForSync(String peerNodeId) async {
    // Get IDs of messages already delivered to this peer
    final deliveredIds = await (selectOnly(messageDeliveries)
          ..addColumns([messageDeliveries.messageId])
          ..where(messageDeliveries.peerNodeId.equals(peerNodeId)))
        .map((row) => row.read(messageDeliveries.messageId)!)
        .get();

    // Query eligible messages, excluding already-delivered ones
    var query = select(messages)
      ..where((t) =>
          t.ttl.isBiggerThanValue(0) &
          (t.status.equals(MessageStatus.pending.value) |
              t.status.equals(MessageStatus.sent.value)));

    if (deliveredIds.isNotEmpty) {
      query = query..where((t) => t.messageId.isNotIn(deliveredIds));
    }

    return query.get();
  }

  /// Returns all messages that are pending or sent (for full-mesh sync).
  Future<List<Message>> getAllSyncableMessages() {
    return (select(messages)
          ..where((t) =>
              t.ttl.isBiggerThanValue(0) &
              (t.status.equals(MessageStatus.pending.value) |
                  t.status.equals(MessageStatus.sent.value))))
        .get();
  }

  /// Insert a message, ignoring duplicates (same [messageId]).
  /// Returns true if the message was inserted (new), false if it was
  /// a duplicate.
  Future<bool> upsertMessage(MessagesCompanion entry) async {
    final existing = await (select(messages)
          ..where((t) => t.messageId.equals(entry.messageId.value)))
        .getSingleOrNull();

    if (existing != null) {
      // Message already exists — do not overwrite.
      // This is the core deduplication logic for epidemic routing.
      return false;
    }

    await into(messages).insert(entry);
    return true;
  }

  /// Update the status of a specific message.
  Future<void> markMessageStatus(String messageId, MessageStatus newStatus) {
    return (update(messages)..where((t) => t.messageId.equals(messageId)))
        .write(MessagesCompanion(status: Value(newStatus.value)));
  }

  /// Mark all pending messages that were included in a sync as [sent].
  Future<void> markMessagesAsSent(List<String> messageIds) {
    return (update(messages)
          ..where((t) => t.messageId.isIn(messageIds)))
        .write(MessagesCompanion(status: Value(MessageStatus.sent.value)));
  }

  /// Prune messages whose TTL has reached 0 or whose creation time
  /// exceeds the time-based TTL.
  Future<int> pruneExpiredMessages({required int ttlHours}) {
    final cutoff = DateTime.now()
        .subtract(Duration(hours: ttlHours))
        .millisecondsSinceEpoch;

    return (delete(messages)
          ..where(
              (t) => t.ttl.isSmallerOrEqualValue(0) | t.createdAt.isSmallerThanValue(cutoff)))
        .go();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DELIVERY TRACKING (Per-Peer Dedup)
  // ───────────────────────────────────────────────────────────────────────────

  /// Records that a list of messages were successfully delivered to a peer.
  ///
  /// Call this after a successful sync cycle. On the next sync with the
  /// same peer, these messages will be excluded from [getMessagesForSync].
  Future<void> recordDeliveries({
    required List<String> messageIds,
    required String peerNodeId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final msgId in messageIds) {
      await into(messageDeliveries).insertOnConflictUpdate(
        MessageDeliveriesCompanion.insert(
          messageId: msgId,
          peerNodeId: peerNodeId,
          deliveredAt: now,
        ),
      );
    }
  }

  /// Removes delivery records for messages that no longer exist.
  /// Call this after [pruneExpiredMessages] to keep the table clean.
  Future<int> pruneOrphanedDeliveries() async {
    // Get all message IDs that still exist
    final existingIds = await (selectOnly(messages)
          ..addColumns([messages.messageId]))
        .map((row) => row.read(messages.messageId)!)
        .get();

    if (existingIds.isEmpty) {
      // All messages are gone — clear the entire deliveries table
      return (delete(messageDeliveries)).go();
    }

    return (delete(messageDeliveries)
          ..where((t) => t.messageId.isNotIn(existingIds)))
        .go();
  }

  /// Convenience: insert a new outgoing message created by the local user.
  ///
  /// Usage:
  /// ```dart
  /// await db.createMessage(
  ///   messageId: uuid.v4(),
  ///   senderId: localNodeId,
  ///   targetId: recipientNodeId,  // or '*' for broadcast
  ///   payload: utf8.encode('Hello mesh!'),
  ///   ttl: kAirpassDefaultMaxHops,
  /// );
  /// ```
  Future<void> createMessage({
    required String messageId,
    required String senderId,
    required String targetId,
    required List<int> payload,
    required int ttl,
    String? signature,
    // Media fields (all optional — text messages omit these)
    MediaType mediaType = MediaType.text,
    String? mediaFileName,
    String? mediaMimeType,
    int? mediaFileSize,
    String? mediaHash,
    String? mediaLocalPath,
    MediaAvailability mediaAvailability = MediaAvailability.notApplicable,
    Uint8List? mediaThumbnail,
  }) {
    return into(messages).insert(MessagesCompanion.insert(
      messageId: messageId,
      senderId: senderId,
      targetId: targetId,
      payload: Uint8List.fromList(payload),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      ttl: ttl,
      signature: Value(signature),
      mediaType: Value(mediaType.value),
      mediaFileName: Value(mediaFileName),
      mediaMimeType: Value(mediaMimeType),
      mediaFileSize: Value(mediaFileSize),
      mediaHash: Value(mediaHash),
      mediaLocalPath: Value(mediaLocalPath),
      mediaAvailability: Value(mediaAvailability.value),
      mediaThumbnail: Value(mediaThumbnail),
    ));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MEDIA OPERATIONS
  // ───────────────────────────────────────────────────────────────────────────

  /// Returns messages with media that are pending download.
  ///
  /// Used by the sync engine to decide which media files to request
  /// from peers during Phase 3.
  Future<List<Message>> getMessagesWithPendingMedia() {
    return (select(messages)
          ..where((t) => t.mediaAvailability.equals(
              MediaAvailability.pendingDownload.value)))
        .get();
  }

  /// Returns pending media messages that qualify for auto-download
  /// (file size under [maxAutoDownloadBytes]).
  Future<List<Message>> getAutoDownloadableMedia(int maxAutoDownloadBytes) {
    return (select(messages)
          ..where((t) =>
              t.mediaAvailability.equals(
                  MediaAvailability.pendingDownload.value) &
              t.mediaFileSize.isSmallerOrEqualValue(maxAutoDownloadBytes)))
        .get();
  }

  /// Updates the media availability and local path for a message.
  ///
  /// Called after a FILE payload transfer completes (or fails).
  Future<void> updateMediaAvailability(
    String messageId,
    MediaAvailability availability, {
    String? localPath,
  }) {
    return (update(messages)..where((t) => t.messageId.equals(messageId)))
        .write(MessagesCompanion(
      mediaAvailability: Value(availability.value),
      mediaLocalPath: Value(localPath),
    ));
  }

  /// Watches a specific message by ID — used for media download progress.
  Stream<Message?> watchMessage(String messageId) {
    return (select(messages)
          ..where((t) => t.messageId.equals(messageId)))
        .watchSingleOrNull();
  }

  /// Returns all messages that have media files stored locally.
  /// Used by [MediaStorageService.pruneOrphanedMedia] to find
  /// which files are still referenced.
  Future<List<Message>> getMessagesWithLocalMedia() {
    return (select(messages)
          ..where((t) => t.mediaAvailability.equals(
              MediaAvailability.available.value)))
        .get();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GROUP OPERATIONS (Group Directory)
  // ───────────────────────────────────────────────────────────────────────────

  /// Watches all discovered groups, ordered by most recently seen.
  /// Use this to populate a "Browse Groups" UI.
  Stream<List<Group>> watchDiscoveredGroups() {
    return (select(groups)..orderBy([(t) => OrderingTerm.desc(t.lastSeenAt)]))
        .watch();
  }

  /// Watches only the groups the local node is subscribed to.
  Stream<List<Group>> watchSubscribedGroups() {
    return (select(groups)
          ..where((t) => t.isSubscribed.equals(true)))
        .watch();
  }

  /// Returns all known groups as a one-shot query.
  Future<List<Group>> getAllGroups() => select(groups).get();

  /// Looks up a single group by ID. Returns null if not discovered yet.
  Future<Group?> getGroupById(String groupId) {
    return (select(groups)..where((t) => t.groupId.equals(groupId)))
        .getSingleOrNull();
  }

  /// Insert or update a discovered group.
  ///
  /// If the group already exists, only [lastSeenAt] and [memberCount]
  /// are updated — preserving the user's [isSubscribed] preference and
  /// any custom [displayName] they may have set.
  Future<void> upsertDiscoveredGroup({
    required String groupId,
    String? displayName,
    int? memberCount,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await getGroupById(groupId);

    if (existing != null) {
      // Group already known — update freshness + member count only
      await (update(groups)..where((t) => t.groupId.equals(groupId))).write(
        GroupsCompanion(
          lastSeenAt: Value(now),
          memberCount: memberCount != null
              ? Value(memberCount)
              : const Value.absent(),
        ),
      );
    } else {
      // New group discovered — insert it
      await into(groups).insert(GroupsCompanion.insert(
        groupId: groupId,
        displayName: displayName ?? groupId,
        discoveredAt: now,
        lastSeenAt: now,
        memberCount: Value(memberCount ?? 1),
      ));
    }
  }

  /// Subscribe the local node to a group.
  ///
  /// This sets [isSubscribed] = true for the target group and
  /// optionally unsubscribes from all other groups (since [NodeRole.group]
  /// nodes can only be in one group at a time).
  Future<void> subscribeToGroup(String groupId,
      {bool exclusive = false}) async {
    if (exclusive) {
      // Unsubscribe from all groups first
      await (update(groups)).write(
        const GroupsCompanion(isSubscribed: Value(false)),
      );
    }
    await (update(groups)..where((t) => t.groupId.equals(groupId))).write(
      const GroupsCompanion(isSubscribed: Value(true)),
    );
  }

  /// Unsubscribe from a specific group.
  Future<void> unsubscribeFromGroup(String groupId) {
    return (update(groups)..where((t) => t.groupId.equals(groupId))).write(
      const GroupsCompanion(isSubscribed: Value(false)),
    );
  }

  /// Counts distinct group IDs across the nodes routing table.
  /// Returns a map of groupId → member count for updating the group directory.
  Future<Map<String, int>> countGroupMemberships() async {
    final allNodes = await getAllNodes();
    final counts = <String, int>{};
    for (final node in allNodes) {
      final gid = node.groupId;
      if (gid != null && gid != '*') {
        counts[gid] = (counts[gid] ?? 0) + 1;
      }
    }
    return counts;
  }
}
