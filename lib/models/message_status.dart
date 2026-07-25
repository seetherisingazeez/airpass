/// Airpass Protocol — Message Status Enum
///
/// Tracks the lifecycle state of a store-and-forward message
/// as it propagates through the mesh network.
library;

/// The delivery state of a message in the local database.
enum MessageStatus {
  /// Message was created locally and has not yet been synced to any peer.
  pending(0),

  /// Message has been sent to at least one peer during a sync exchange.
  /// It may still need to reach additional hops to arrive at the target.
  sent(1),

  /// Message has been confirmed as delivered to the target node.
  ///
  /// **Not yet implemented.** A future reverse-gossip acknowledgment
  /// mechanism will transition messages to this state when the target
  /// node confirms receipt. Currently, messages only reach [sent].
  delivered(2),

  /// Message TTL has expired (hop count reached 0 or time-based TTL exceeded).
  /// It will be pruned from the database during the next cleanup cycle.
  expired(3);

  const MessageStatus(this.value);

  /// Integer value stored in the Drift database.
  final int value;

  /// Deserialize from the integer stored in the database.
  static MessageStatus fromValue(int value) {
    return MessageStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => MessageStatus.pending, // Safe default
    );
  }
}
