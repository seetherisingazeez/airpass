/// Airpass Protocol — Media Type Enum
///
/// Classifies the type of media attached to a store-and-forward message.
/// Text-only messages use [MediaType.text] (the default).
library;

/// The type of media content attached to a message.
enum MediaType {
  /// Regular text message — no media attachment.
  text(0),

  /// Image attachment (JPEG, PNG, WebP, GIF, etc.).
  image(1),

  /// Video attachment (MP4, WebM, etc.).
  video(2),

  /// Audio attachment (voice note, MP3, OGG, etc.).
  audio(3),

  /// Generic file attachment (PDF, ZIP, document, etc.).
  file(4);

  const MediaType(this.value);

  /// Integer value stored in the Drift database.
  final int value;

  /// Deserialize from the integer stored in the database.
  static MediaType fromValue(int value) {
    return MediaType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => MediaType.text, // Safe default
    );
  }

  /// Whether this type represents a media attachment (anything except text).
  bool get isMedia => this != MediaType.text;

  /// Whether this type supports thumbnail generation.
  bool get supportsThumbnail => this == MediaType.image || this == MediaType.video;
}
