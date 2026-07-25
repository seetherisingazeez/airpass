/// Airpass Protocol — Node Role Enum
///
/// Defines the role a node plays in the mesh network.
/// The role determines routing behavior and is encoded into the
/// endpoint name string for pre-connection filtering.
library;

/// The operational role of a node in the Airpass mesh.
enum NodeRole {
  /// A **Global** node relays all messages regardless of group affiliation.
  /// Think of this as a "super relay" — it bridges between groups.
  global(0, 'G'),

  /// A **Group** node only relays messages within its assigned group.
  /// It will only connect to peers that share its [groupId] or are [global].
  group(1, 'R');

  const NodeRole(this.value, this.code);

  /// Integer value stored in the Drift database.
  final int value;

  /// Single-character code used in endpoint name encoding.
  /// Kept to 1 byte for compactness.
  final String code;

  /// Deserialize from the integer stored in the database.
  static NodeRole fromValue(int value) {
    return NodeRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => NodeRole.group, // Safe default
    );
  }

  /// Deserialize from the single-character code in the endpoint name.
  static NodeRole fromCode(String code) {
    return NodeRole.values.firstWhere(
      (r) => r.code == code,
      orElse: () => NodeRole.group, // Safe default
    );
  }
}
