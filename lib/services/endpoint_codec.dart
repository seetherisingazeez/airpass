/// Airpass Protocol — Endpoint Name Codec
///
/// Encodes and decodes node metadata into the Nearby Connections
/// endpoint name string. This string is broadcast during advertising
/// and received during discovery — BEFORE any connection is established.
///
/// This enables "connectionless filtering": a discovering node can
/// inspect the encoded metadata and decide whether to initiate a
/// handshake without wasting a connection attempt.
///
/// ## Wire Format (v2 — Multi-Group + Micro-Message)
///
/// ```
/// AP|<version>|<role_code>|<groups_csv>|<node_id_prefix>[|<micro_msg>]
/// ```
///
/// - `AP` — magic prefix identifying Airpass protocol endpoints
/// - `version` — protocol version integer
/// - `role_code` — single char: 'G' (Global) or 'R' (Group)
/// - `groups_csv` — comma-separated group IDs, or '*' if ungrouped
///   e.g., `GroupA,GroupB,GroupC`
/// - `node_id_prefix` — first 8 chars of the node UUID
/// - `micro_msg` — (OPTIONAL) a tiny base64 payload for connectionless
///   broadcasting. Only present when a pending message fits within
///   the remaining byte budget.
///
/// Total length MUST NOT exceed [kEndpointNameMaxBytes] (131 bytes).
library;

import 'dart:convert';

import '../config/airpass_config.dart';
import '../models/node_role.dart';

/// Separator for multiple group IDs within the groups field.
const String kGroupSeparator = ',';

/// Decoded metadata extracted from an endpoint name string.
class EndpointMetadata {
  /// Protocol version of the remote peer.
  final int protocolVersion;

  /// The remote node's mesh role.
  final NodeRole role;

  /// All groups the remote node is subscribed to.
  /// Contains ['*'] if the node is ungrouped or global.
  final List<String> groupIds;

  /// Prefix of the remote node's UUID (first 8 characters).
  final String nodeIdPrefix;

  /// Optional micro-message broadcast connectionlessly via the endpoint name.
  /// Null if no micro-message is being broadcast.
  final String? microMessage;

  const EndpointMetadata({
    required this.protocolVersion,
    required this.role,
    required this.groupIds,
    required this.nodeIdPrefix,
    this.microMessage,
  });

  /// Convenience: returns the first group ID (for backward compatibility).
  /// Returns '*' if ungrouped.
  String get primaryGroupId => groupIds.isNotEmpty ? groupIds.first : '*';

  @override
  String toString() =>
      'EndpointMetadata(v$protocolVersion, ${role.name}, '
      'groups=${groupIds.join(",")}, node=$nodeIdPrefix'
      '${microMessage != null ? ", micro=${microMessage!.length}b" : ""})';
}

/// Thrown when the encoded endpoint name exceeds the 131-byte limit.
class EndpointNameTooLongException implements Exception {
  final int actualLength;
  final int maxLength;
  final String encoded;

  const EndpointNameTooLongException({
    required this.actualLength,
    required this.maxLength,
    required this.encoded,
  });

  @override
  String toString() =>
      'EndpointNameTooLongException: Encoded name is $actualLength bytes, '
      'max is $maxLength bytes. Reduce subscribed groups or shorten group IDs. '
      'Encoded: "$encoded"';
}

/// Encodes and decodes Airpass metadata for use in the Nearby Connections
/// endpoint name field.
class EndpointCodec {
  /// Encode local node metadata into an endpoint name string.
  ///
  /// [nodeId] — full UUID of this node (only the first 8 chars are encoded).
  /// [role] — this node's mesh role.
  /// [groupIds] — all groups this node is subscribed to (may be empty).
  /// [microMessage] — optional tiny payload to broadcast connectionlessly.
  ///
  /// Returns a pipe-delimited string under [kEndpointNameMaxBytes].
  ///
  /// Throws [EndpointNameTooLongException] if the combined group names
  /// and micro-message exceed the byte limit.
  String encode({
    required String nodeId,
    required NodeRole role,
    List<String>? groupIds,
    String? microMessage,
  }) {
    final prefix = nodeId.length >= 8 ? nodeId.substring(0, 8) : nodeId;

    // Build the groups field: comma-separated or '*'
    final groupsField = (groupIds != null && groupIds.isNotEmpty)
        ? groupIds.join(kGroupSeparator)
        : '*';

    final parts = [
      kEndpointMagic,
      kAirpassProtocolVersion.toString(),
      role.code,
      groupsField,
      prefix,
    ];

    // Append micro-message if provided
    if (microMessage != null && microMessage.isNotEmpty) {
      parts.add(microMessage);
    }

    final encoded = parts.join(kEndpointDelimiter);

    // Validate byte length (UTF-8, not UTF-16 code units)
    final byteLength = utf8.encode(encoded).length;
    if (byteLength > kEndpointNameMaxBytes) {
      throw EndpointNameTooLongException(
        actualLength: byteLength,
        maxLength: kEndpointNameMaxBytes,
        encoded: encoded,
      );
    }

    return encoded;
  }

  /// Calculates the encoded byte length WITHOUT actually throwing.
  /// Useful for validation before committing to a group subscription.
  int encodedLength({
    required String nodeId,
    required NodeRole role,
    List<String>? groupIds,
    String? microMessage,
  }) {
    final prefix = nodeId.length >= 8 ? nodeId.substring(0, 8) : nodeId;
    final groupsField = (groupIds != null && groupIds.isNotEmpty)
        ? groupIds.join(kGroupSeparator)
        : '*';

    final parts = [
      kEndpointMagic,
      kAirpassProtocolVersion.toString(),
      role.code,
      groupsField,
      prefix,
    ];
    if (microMessage != null && microMessage.isNotEmpty) {
      parts.add(microMessage);
    }
    return utf8.encode(parts.join(kEndpointDelimiter)).length;
  }

  /// Returns the number of bytes remaining for micro-messages after
  /// encoding the base metadata (groups, role, node prefix).
  ///
  /// If negative, the base metadata alone exceeds the limit.
  int availableMicroBytes({
    required String nodeId,
    required NodeRole role,
    List<String>? groupIds,
  }) {
    // Base length + 1 for the pipe delimiter before the micro field
    final baseLength = encodedLength(
      nodeId: nodeId,
      role: role,
      groupIds: groupIds,
    );
    // +1 for the pipe delimiter that would precede the micro-message
    return kEndpointNameMaxBytes - baseLength - 1;
  }

  /// Decode an endpoint name string back into structured metadata.
  ///
  /// Returns null if the string is not a valid Airpass endpoint name
  /// (wrong magic prefix, too few fields, etc.).
  EndpointMetadata? decode(String endpointName) {
    final parts = endpointName.split(kEndpointDelimiter);

    // Need at least 5 fields: magic, version, role, groups, nodeIdPrefix
    // Optionally 6 fields if a micro-message is present
    if (parts.length < 5 || parts.length > 6) return null;

    // Verify magic prefix
    if (parts[0] != kEndpointMagic) return null;

    final version = int.tryParse(parts[1]);
    if (version == null) return null;

    // Parse groups field: split by comma
    final groupsRaw = parts[3];
    final groupIds = groupsRaw == '*' ? <String>['*'] : groupsRaw.split(kGroupSeparator);

    // Parse optional micro-message
    final microMessage = parts.length == 6 ? parts[5] : null;

    return EndpointMetadata(
      protocolVersion: version,
      role: NodeRole.fromCode(parts[2]),
      groupIds: groupIds,
      nodeIdPrefix: parts[4],
      microMessage: microMessage,
    );
  }

  /// Decides whether this node should connect to a discovered peer
  /// based on their respective metadata.
  ///
  /// Connection rules:
  /// 1. Always connect if either node is [NodeRole.global] — globals
  ///    bridge all groups.
  /// 2. Connect if the nodes share ANY common group ID.
  /// 3. Reject if no groups overlap and neither is global.
  bool shouldConnect({
    required NodeRole localRole,
    required List<String>? localGroupIds,
    required EndpointMetadata remote,
  }) {
    // Rule 1: Globals connect to everyone.
    if (localRole == NodeRole.global || remote.role == NodeRole.global) {
      return true;
    }

    // Rule 2: Any overlapping group.
    final local = localGroupIds ?? ['*'];
    for (final localGroup in local) {
      if (localGroup != '*' && remote.groupIds.contains(localGroup)) {
        return true;
      }
    }

    // Rule 3: No overlap, neither is global — skip.
    return false;
  }

  /// Encodes a micro-message payload into a base64 string suitable
  /// for embedding in the endpoint name.
  ///
  /// Returns null if the payload is too large to fit in the available
  /// byte budget after encoding the base metadata.
  String? encodeMicroMessage(
    List<int> payload, {
    required String nodeId,
    required NodeRole role,
    List<String>? groupIds,
  }) {
    final encoded = base64Encode(payload);
    final available = availableMicroBytes(
      nodeId: nodeId,
      role: role,
      groupIds: groupIds,
    );

    if (encoded.length > available || available <= 0) return null;
    return encoded;
  }
}
