/// Airpass Protocol — Media Availability Enum
///
/// Tracks whether the actual binary file for a media message
/// is available on the local filesystem.
///
/// Media messages travel through the epidemic mesh as lightweight
/// metadata envelopes (type, filename, hash, size, thumbnail).
/// The actual binary is transferred separately via Nearby's
/// FILE payload API. This enum tracks the binary's local state.
library;

/// The local availability state of a media message's binary file.
enum MediaAvailability {
  /// No media attached — this is a text-only message.
  /// Default for all existing messages.
  notApplicable(0),

  /// Media metadata exists but the binary hasn't been fetched yet.
  /// The UI should show the thumbnail + a download indicator.
  pendingDownload(1),

  /// Currently being transferred from a peer via `sendFilePayload`.
  /// The UI should show a progress bar.
  downloading(2),

  /// Binary file is available on the local filesystem.
  /// The UI can display the full image/video/file.
  available(3),

  /// Transfer failed or source peer is unreachable.
  /// The UI should offer a retry button.
  failed(4);

  const MediaAvailability(this.value);

  /// Integer value stored in the Drift database.
  final int value;

  /// Deserialize from the integer stored in the database.
  static MediaAvailability fromValue(int value) {
    return MediaAvailability.values.firstWhere(
      (a) => a.value == value,
      orElse: () => MediaAvailability.notApplicable,
    );
  }
}
