/// Airpass Protocol — Bloom Filter
///
/// A compact, serializable probabilistic set membership test used for
/// pre-sync message deduplication.
///
/// ## How It's Used
///
/// Before exchanging the full sync payload, each peer sends a Bloom
/// filter containing the IDs of all messages it already has. The other
/// peer uses this filter to exclude messages the receiver already has,
/// dramatically reducing bandwidth in dense meshes.
///
/// ## False Positive Tradeoff
///
/// A Bloom filter can produce false positives ("probably in set") but
/// never false negatives ("definitely not in set"):
/// - **False positive** (1% default): We skip sending a message the peer
///   doesn't actually have. That message will arrive via another path
///   or on the next encounter. Acceptable in epidemic routing.
/// - **False negative** (impossible): We would never send a message the
///   peer already has. This is guaranteed by the data structure.
///
/// ## Wire Format
///
/// ```
/// [0xBF, 0x00] [bitCount: 4 bytes LE] [hashCount: 1 byte] [bit array...]
/// ```
///
/// The magic prefix `0xBF 0x00` distinguishes Bloom filter payloads from
/// gzip sync payloads (which start with `0x1F 0x8B`).
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Magic bytes prefixed to serialized Bloom filters.
/// Distinguishes them from gzip sync payloads (`0x1F 0x8B`).
const List<int> kBloomFilterMagic = [0xBF, 0x00];

/// A space-efficient probabilistic set membership test.
///
/// Usage:
/// ```dart
/// // Build a filter from local message IDs
/// final filter = BloomFilter.optimal(expectedItems: messages.length);
/// for (final msg in messages) {
///   filter.add(msg.messageId);
/// }
///
/// // Send filter.toBytes() to peer...
///
/// // Peer uses it to filter outgoing messages:
/// if (!peerFilter.mightContain(msg.messageId)) {
///   // Peer definitely doesn't have this message — send it
/// }
/// ```
class BloomFilter {
  /// The underlying bit array, stored as bytes.
  final Uint8List _bits;

  /// Total number of bits in the filter.
  final int _bitCount;

  /// Number of independent hash functions used.
  final int _hashCount;

  BloomFilter._({
    required Uint8List bits,
    required int bitCount,
    required int hashCount,
  })  : _bits = bits,
        _bitCount = bitCount,
        _hashCount = hashCount;

  /// Creates an optimally-sized Bloom filter for [expectedItems] with
  /// the given [falsePositiveRate].
  ///
  /// Formulas (from Bloom filter theory):
  /// - m = -n * ln(p) / (ln(2)^2)   (optimal bit count)
  /// - k = (m / n) * ln(2)           (optimal hash count)
  ///
  /// where n = expected items, p = false positive rate.
  factory BloomFilter.optimal({
    required int expectedItems,
    double falsePositiveRate = 0.01,
  }) {
    // Ensure sane minimums
    final n = math.max(expectedItems, 1);
    final p = falsePositiveRate.clamp(0.0001, 0.5);

    // Optimal bit count
    final m = (-(n * math.log(p)) / (math.ln2 * math.ln2)).ceil();
    // Clamp to at least 8 bits (1 byte) and at most 1MB
    final bitCount = m.clamp(8, 8 * 1024 * 1024);

    // Optimal hash count
    final k = ((bitCount / n) * math.ln2).ceil();
    // Clamp to 1..16 (SHA-256 gives us up to 8 hashes per digest,
    // we can double-hash for up to 16)
    final hashCount = k.clamp(1, 16);

    final byteCount = (bitCount + 7) ~/ 8; // Round up to full bytes
    return BloomFilter._(
      bits: Uint8List(byteCount),
      bitCount: bitCount,
      hashCount: hashCount,
    );
  }

  /// Creates an empty Bloom filter that accepts everything.
  ///
  /// Used as a fallback when no filter is available (e.g., first encounter
  /// or timeout). `mightContain()` always returns false.
  factory BloomFilter.empty() {
    return BloomFilter._(
      bits: Uint8List(0),
      bitCount: 0,
      hashCount: 0,
    );
  }

  /// Whether this is an empty/passthrough filter.
  bool get isEmpty => _bitCount == 0;

  /// The size of this filter in bytes (just the bit array, not the header).
  int get sizeInBytes => _bits.length;

  // ─────────────────────────────────────────────────────────────────────────
  // CORE OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Adds an item to the filter.
  ///
  /// After this call, `mightContain(item)` is guaranteed to return true.
  void add(String item) {
    if (isEmpty) return;
    final hashes = _computeHashes(item);
    for (final h in hashes) {
      final bitIndex = h % _bitCount;
      _bits[bitIndex ~/ 8] |= (1 << (bitIndex % 8));
    }
  }

  /// Tests whether an item might be in the filter.
  ///
  /// - Returns `false` → the item is **definitely not** in the set.
  /// - Returns `true`  → the item is **probably** in the set
  ///   (with ~[falsePositiveRate] chance of being wrong).
  bool mightContain(String item) {
    if (isEmpty) return false;
    final hashes = _computeHashes(item);
    for (final h in hashes) {
      final bitIndex = h % _bitCount;
      if ((_bits[bitIndex ~/ 8] & (1 << (bitIndex % 8))) == 0) {
        return false; // Definitely not in set
      }
    }
    return true; // Probably in set
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SERIALIZATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Serializes the Bloom filter to bytes for transmission.
  ///
  /// Wire format:
  /// ```
  /// [0xBF, 0x00] [bitCount: 4 bytes LE] [hashCount: 1 byte] [bit array...]
  /// ```
  ///
  /// Total overhead: 7 bytes. The bit array is the dominant size.
  Uint8List toBytes() {
    final header = ByteData(7);
    // Magic
    header.setUint8(0, kBloomFilterMagic[0]);
    header.setUint8(1, kBloomFilterMagic[1]);
    // Bit count (little-endian 32-bit)
    header.setUint32(2, _bitCount, Endian.little);
    // Hash count
    header.setUint8(6, _hashCount);

    final result = Uint8List(7 + _bits.length);
    result.setAll(0, header.buffer.asUint8List());
    result.setAll(7, _bits);
    return result;
  }

  /// Deserializes a Bloom filter from bytes.
  ///
  /// The input should include the magic prefix (`0xBF 0x00`).
  /// Returns [BloomFilter.empty] if the data is malformed.
  factory BloomFilter.fromBytes(Uint8List data) {
    if (data.length < 7) return BloomFilter.empty();

    // Verify magic
    if (data[0] != kBloomFilterMagic[0] || data[1] != kBloomFilterMagic[1]) {
      return BloomFilter.empty();
    }

    final header = ByteData.view(data.buffer, data.offsetInBytes, 7);
    final bitCount = header.getUint32(2, Endian.little);
    final hashCount = header.getUint8(6);

    final expectedBytes = (bitCount + 7) ~/ 8;
    if (data.length < 7 + expectedBytes) return BloomFilter.empty();

    final bits = Uint8List.fromList(data.sublist(7, 7 + expectedBytes));
    return BloomFilter._(
      bits: bits,
      bitCount: bitCount,
      hashCount: hashCount,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HASH FUNCTIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Computes [_hashCount] independent hash values for [item].
  ///
  /// Strategy: Compute SHA-256 of the item, then extract up to 8
  /// independent 4-byte hashes by slicing the 32-byte digest.
  /// For k > 8, compute a second SHA-256 with a salt suffix.
  ///
  /// This approach is proven to be as effective as k truly independent
  /// hash functions for Bloom filters (Kirsch & Mitzenmacher, 2006).
  List<int> _computeHashes(String item) {
    final itemBytes = utf8.encode(item);
    final digest1 = sha256.convert(itemBytes).bytes;

    // Second digest (for k > 8)
    List<int>? digest2;
    if (_hashCount > 8) {
      digest2 = sha256.convert([...itemBytes, 0x01]).bytes;
    }

    final hashes = <int>[];
    for (int i = 0; i < _hashCount; i++) {
      final digest = i < 8 ? digest1 : digest2!;
      final offset = (i % 8) * 4;
      // Read 4 bytes as an unsigned 32-bit integer (little-endian)
      final h = (digest[offset]) |
          (digest[offset + 1] << 8) |
          (digest[offset + 2] << 16) |
          (digest[offset + 3] << 24);
      // Ensure non-negative by masking to 31 bits
      hashes.add(h & 0x7FFFFFFF);
    }

    return hashes;
  }

  @override
  String toString() =>
      'BloomFilter(bits=$_bitCount, hashes=$_hashCount, '
      'bytes=${_bits.length})';
}
