/// Airpass Protocol — Media Storage Service
///
/// Handles all filesystem operations for media binaries:
/// - Saving media files to app-local storage
/// - Computing SHA-256 hashes for integrity verification
/// - Generating thumbnails for instant preview
/// - Pruning orphaned media files
///
/// Media files are stored outside of SQLite to avoid bloating the
/// database. The database only stores metadata + a tiny thumbnail.
/// The actual binary lives at:
/// ```
/// {appDataDir}/airpass_media/{messageId}/{fileName}
/// ```
library;


import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../config/airpass_config.dart';
import '../database/airpass_database.dart';

import '../utils/airpass_logger.dart';

/// Manages media file storage, hashing, thumbnailing, and pruning.
///
/// Obtain via GetIt:
/// ```dart
/// final mediaStorage = getIt<MediaStorageService>();
/// ```
class MediaStorageService {
  final AirpassDatabase _db;

  /// Lazily resolved base directory for media files.
  String? _baseDirPath;

  MediaStorageService({required AirpassDatabase database}) : _db = database;

  // ─────────────────────────────────────────────────────────────────────────
  // DIRECTORY MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns (and creates if needed) the base media storage directory.
  Future<String> _getBaseDir() async {
    if (_baseDirPath != null) return _baseDirPath!;

    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(appDir.path, kMediaStorageDir));

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    _baseDirPath = mediaDir.path;
    return _baseDirPath!;
  }

  /// Returns the directory path for a specific message's media.
  Future<String> _getMessageMediaDir(String messageId) async {
    final baseDir = await _getBaseDir();
    final msgDir = Directory(p.join(baseDir, messageId));

    if (!await msgDir.exists()) {
      await msgDir.create(recursive: true);
    }

    return msgDir.path;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SAVE / RETRIEVE
  // ─────────────────────────────────────────────────────────────────────────

  /// Saves a media file to local storage.
  ///
  /// [messageId] — the message this media belongs to.
  /// [bytes] — the raw file bytes.
  /// [fileName] — the original filename (e.g., 'photo.jpg').
  ///
  /// Returns the absolute path where the file was saved.
  Future<String> saveMedia({
    required String messageId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dir = await _getMessageMediaDir(messageId);
    final filePath = p.join(dir, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    _log('Saved media: $filePath (${bytes.length} bytes)');
    return filePath;
  }

  /// Saves a media file from a source path (move/copy).
  ///
  /// Used when the user picks a file from their device — copies it
  /// into the Airpass media directory so it persists independently
  /// of the user's original file.
  ///
  /// Returns the absolute path where the file was saved.
  Future<String> saveMediaFromPath({
    required String messageId,
    required String sourcePath,
    required String fileName,
  }) async {
    final dir = await _getMessageMediaDir(messageId);
    final destPath = p.join(dir, fileName);
    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);

    _log('Copied media: $sourcePath → $destPath');
    return destPath;
  }

  /// Returns the local file path for a message's media, or null
  /// if the file doesn't exist on disk.
  Future<String?> getMediaPath(String messageId) async {
    final dir = await _getMessageMediaDir(messageId);
    final msgDir = Directory(dir);

    if (!await msgDir.exists()) return null;

    final files = await msgDir.list().toList();
    if (files.isEmpty) return null;

    // Return the first (and typically only) file in the directory
    return files.first.path;
  }

  /// Reads the raw bytes of a stored media file.
  Future<Uint8List?> readMedia(String messageId) async {
    final path = await getMediaPath(messageId);
    if (path == null) return null;

    final file = File(path);
    if (!await file.exists()) return null;

    return file.readAsBytes();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HASHING
  // ─────────────────────────────────────────────────────────────────────────

  /// Computes the SHA-256 hash of a file at [filePath].
  ///
  /// Used for integrity verification: the sender computes the hash
  /// when creating the message, and the receiver verifies after
  /// the FILE transfer completes.
  Future<String> computeHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return _computeHashFromBytes(bytes);
  }

  /// Computes SHA-256 hash from raw bytes.
  String computeHashFromBytes(Uint8List bytes) {
    return _computeHashFromBytes(bytes);
  }

  String _computeHashFromBytes(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies a file's integrity against an expected SHA-256 hash.
  ///
  /// Returns true if the file matches, false otherwise.
  Future<bool> verifyHash(String filePath, String expectedHash) async {
    final actualHash = await computeHash(filePath);
    return actualHash == expectedHash;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // THUMBNAILING
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates a compressed JPEG thumbnail from image bytes.
  ///
  /// The thumbnail is capped at [kThumbnailMaxDimension] pixels on
  /// the longest side and [kMaxThumbnailSizeBytes] in file size.
  ///
  /// Returns the thumbnail bytes, or null if generation fails.
  ///
  /// Note: For v1, this uses Flutter's `instantiateImageCodec` to
  /// decode and re-encode the image. Video thumbnails require a
  /// native plugin and are deferred to v2.
  Future<Uint8List?> generateThumbnail(Uint8List imageBytes) async {
    try {
      // Decode the image
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: kThumbnailMaxDimension,
        targetHeight: kThumbnailMaxDimension,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Encode as PNG (Flutter doesn't expose JPEG encoding natively)
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      codec.dispose();

      if (byteData == null) return null;

      final thumbnailBytes = byteData.buffer.asUint8List();

      // If thumbnail exceeds our size limit, return a further-compressed version
      if (thumbnailBytes.length > kMaxThumbnailSizeBytes) {
        // Re-encode at a smaller resolution
        final smallerCodec = await ui.instantiateImageCodec(
          imageBytes,
          targetWidth: kThumbnailMaxDimension ~/ 2,
          targetHeight: kThumbnailMaxDimension ~/ 2,
        );
        final smallerFrame = await smallerCodec.getNextFrame();
        final smallerImage = smallerFrame.image;
        final smallerData = await smallerImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        smallerImage.dispose();
        smallerCodec.dispose();

        if (smallerData == null) return thumbnailBytes;
        return smallerData.buffer.asUint8List();
      }

      return thumbnailBytes;
    } catch (e) {
      _log('Thumbnail generation failed: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLEANUP
  // ─────────────────────────────────────────────────────────────────────────

  /// Deletes all media files associated with a message.
  Future<void> deleteMedia(String messageId) async {
    final baseDir = await _getBaseDir();
    final msgDir = Directory(p.join(baseDir, messageId));

    if (await msgDir.exists()) {
      await msgDir.delete(recursive: true);
      _log('Deleted media for message: $messageId');
    }
  }

  /// Prunes media files whose messages no longer exist in the database.
  ///
  /// Call this after [AirpassDatabase.pruneExpiredMessages] to keep
  /// the filesystem in sync with the database.
  Future<int> pruneOrphanedMedia() async {
    final baseDir = await _getBaseDir();
    final mediaDirRoot = Directory(baseDir);

    if (!await mediaDirRoot.exists()) return 0;

    // Get all message IDs that still have local media in the DB
    final messagesWithMedia = await _db.getMessagesWithLocalMedia();
    final validIds = messagesWithMedia.map((m) => m.messageId).toSet();

    int pruned = 0;
    await for (final entity in mediaDirRoot.list()) {
      if (entity is Directory) {
        final dirName = p.basename(entity.path);
        if (!validIds.contains(dirName)) {
          await entity.delete(recursive: true);
          pruned++;
          _log('Pruned orphaned media directory: $dirName');
        }
      }
    }

    return pruned;
  }

  /// Returns the total size of all stored media files (bytes).
  /// Useful for displaying storage usage in settings.
  Future<int> getTotalMediaSize() async {
    final baseDir = await _getBaseDir();
    final mediaDirRoot = Directory(baseDir);

    if (!await mediaDirRoot.exists()) return 0;

    int totalSize = 0;
    await for (final entity in mediaDirRoot.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  void _log(String message) {
    AirpassLogger.log('MediaStorage', message);
  }
}
