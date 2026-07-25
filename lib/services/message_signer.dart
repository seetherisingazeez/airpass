/// Airpass Protocol — Message Signing Service
///
/// Provides HMAC-SHA256 signing and verification for message integrity.
///
/// ## How It Works
///
/// 1. When a message is created locally, `signMessage()` produces a
///    hex-encoded HMAC-SHA256 digest of the payload + metadata.
/// 2. The signature is stored in the `Messages.signature` column.
/// 3. When a message arrives via sync, `verifySignature()` re-computes
///    the HMAC and compares it to the stored signature.
///
/// ## Key Management
///
/// The signing key is derived from the local node's UUID. This means:
/// - Any node can verify messages it created.
/// - Relaying nodes can verify the sender's signature only if they
///   share a group key (future: group-level key exchange).
/// - For now, the node UUID serves as a simple shared secret that
///   proves the message wasn't tampered with by the originating node.
///
/// In a production deployment, replace this with proper PKI or
/// pre-shared group keys distributed via a trusted bootstrap.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Signs and verifies Airpass messages using HMAC-SHA256.
class MessageSigner {
  /// The secret key used for HMAC computation.
  /// Derived from the local node's UUID.
  final List<int> _keyBytes;

  /// Creates a signer using the node's UUID as the signing key.
  ///
  /// [nodeId] — the local node's UUID (used as the HMAC key).
  MessageSigner({required String nodeId})
      : _keyBytes = utf8.encode(nodeId);

  /// Signs a message and returns the hex-encoded HMAC-SHA256 signature.
  ///
  /// The signature covers:
  /// - `messageId` — prevents replay attacks with different IDs
  /// - `senderId` — binds the signature to the sender
  /// - `targetId` — prevents retargeting
  /// - `payload` — covers the actual content
  /// - `createdAt` — prevents timestamp manipulation
  ///
  /// Returns a 64-character lowercase hex string.
  String signMessage({
    required String messageId,
    required String senderId,
    required String targetId,
    required Uint8List payload,
    required int createdAt,
  }) {
    final hmac = Hmac(sha256, _keyBytes);
    final data = _buildSigningData(
      messageId: messageId,
      senderId: senderId,
      targetId: targetId,
      payload: payload,
      createdAt: createdAt,
    );
    final digest = hmac.convert(data);
    return digest.toString(); // hex string
  }

  /// Verifies that a message's signature is valid.
  ///
  /// Returns `true` if the signature matches, `false` if tampered.
  ///
  /// Note: This can only verify messages signed with the SAME key.
  /// For messages from other nodes, the signature serves as a
  /// tamper-detection mechanism — if a relaying node modifies the
  /// payload, the signature won't match when the original sender
  /// (or any node with the same key) verifies it.
  bool verifySignature({
    required String messageId,
    required String senderId,
    required String targetId,
    required Uint8List payload,
    required int createdAt,
    required String signature,
  }) {
    final expected = signMessage(
      messageId: messageId,
      senderId: senderId,
      targetId: targetId,
      payload: payload,
      createdAt: createdAt,
    );
    // Constant-time comparison to prevent timing attacks
    return _constantTimeEquals(expected, signature);
  }

  /// Builds the canonical byte sequence for signing.
  ///
  /// Format: `messageId|senderId|targetId|createdAt|<payload_bytes>`
  List<int> _buildSigningData({
    required String messageId,
    required String senderId,
    required String targetId,
    required Uint8List payload,
    required int createdAt,
  }) {
    final prefix = utf8.encode('$messageId|$senderId|$targetId|$createdAt|');
    return [...prefix, ...payload];
  }

  /// Constant-time string comparison to prevent timing attacks.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
