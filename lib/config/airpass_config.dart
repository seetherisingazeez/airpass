/// Airpass Protocol — Configuration Constants
///
/// All tunable protocol parameters are centralized here.
/// Modify these values to adjust scanning behavior, mesh topology,
/// message lifetimes, and endpoint encoding budgets.
library;

import 'package:nearby_connections/nearby_connections.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// NETWORK IDENTITY
/// ──────────────────────────────────────────────────────────────────────────────

/// The Nearby Connections service identifier.
/// Must match across all devices participating in the mesh.
/// Change this to your own reverse-domain string.
const String kAirpassServiceId = 'com.unitedvoices.airpass';

/// The Nearby Connections strategy.
/// P2P_CLUSTER allows many-to-many discovery — required for mesh topology.
const Strategy kAirpassStrategy = Strategy.P2P_CLUSTER;

/// Current protocol version.
/// Encoded into the endpoint name so peers can reject incompatible versions.
const int kAirpassProtocolVersion = 1;

/// ──────────────────────────────────────────────────────────────────────────────
/// MESSAGE LIFECYCLE
/// ──────────────────────────────────────────────────────────────────────────────

/// Maximum number of hops a message can traverse before it is dropped.
/// Each relay decrements the TTL by 1. When TTL reaches 0, the message
/// is marked as [MessageStatus.expired] and will not be forwarded further.
const int kAirpassDefaultMaxHops = 10;

/// Time-based TTL in hours. Messages older than this are pruned from the
/// local database regardless of hop count.
const int kAirpassMessageTtlHours = 72; // 3 days

/// ──────────────────────────────────────────────────────────────────────────────
/// SCANNING / BACKOFF
/// ──────────────────────────────────────────────────────────────────────────────

/// Initial scan interval when the app enters the background (milliseconds).
/// The scanner will advertise + discover for one cycle, then sleep this long.
const int kInitialScanIntervalMs = 5000; // 5 seconds

/// Maximum scan interval after repeated backoff (milliseconds).
/// Caps the exponential growth to preserve battery.
const int kMaxScanIntervalMs = 300000; // 5 minutes

/// Multiplier applied to the scan interval after each idle cycle.
/// interval = min(interval * multiplier, kMaxScanIntervalMs)
const double kBackoffMultiplier = 1.5;

/// Duration of each active scan window (milliseconds).
/// During this window, both advertising and discovery are active.
const int kScanWindowDurationMs = 10000; // 10 seconds

/// ──────────────────────────────────────────────────────────────────────────────
/// ENDPOINT NAME ENCODING
/// ──────────────────────────────────────────────────────────────────────────────

/// Maximum byte length for the Nearby Connections endpoint name.
/// The Android API silently truncates names exceeding this limit.
const int kEndpointNameMaxBytes = 131;

/// Delimiter used to separate fields in the encoded endpoint name.
const String kEndpointDelimiter = '|';

/// Magic prefix to identify Airpass protocol endpoints.
/// Peers without this prefix are ignored during discovery.
const String kEndpointMagic = 'AP';

/// Maximum raw payload size (bytes) that can be broadcast connectionlessly
/// via the BLE endpoint name. Payloads under this threshold will be
/// base64-encoded and appended to the endpoint name string.
/// Payloads above this are sent via the Wi-Fi Direct sync cycle.
const int kMicroMessageMaxBytes = 100;

/// ──────────────────────────────────────────────────────────────────────────────
/// SYNC ENGINE
/// ──────────────────────────────────────────────────────────────────────────────

/// Payload size threshold (bytes) above which JSON parsing is offloaded
/// to a background isolate via [Isolate.run].
const int kIsolateParsingThresholdBytes = 10240; // 10 KB

/// ──────────────────────────────────────────────────────────────────────────────
/// NODE PRUNING
/// ──────────────────────────────────────────────────────────────────────────────

/// Nodes not seen within this duration are pruned from the routing table.
const Duration kStaleNodeThreshold = Duration(hours: 48);

/// ──────────────────────────────────────────────────────────────────────────────
/// BLOOM FILTER (Pre-Sync Dedup)
/// ──────────────────────────────────────────────────────────────────────────────

/// Target false positive rate for the pre-sync Bloom filter.
///
/// 1% means ~1 in 100 messages the peer doesn't have will be incorrectly
/// filtered out. Those messages will arrive via another path or on the
/// next encounter — acceptable in epidemic routing.
const double kBloomFilterFalsePositiveRate = 0.01;

/// Maximum time (milliseconds) to wait for the peer's Bloom filter
/// before falling back to an unfiltered sync.
///
/// This prevents deadlocks if the peer is slow to build their filter
/// or if payload delivery is delayed.
const int kBloomFilterTimeoutMs = 3000; // 3 seconds

/// ──────────────────────────────────────────────────────────────────────────────
/// MULTIMEDIA
/// ──────────────────────────────────────────────────────────────────────────────

/// Maximum file size allowed for multimedia messages (bytes).
/// Files larger than this are rejected at the client level.
const int kMaxMediaFileSizeBytes = 25 * 1024 * 1024; // 25 MB

/// Maximum thumbnail size embedded in the message payload (bytes).
/// Thumbnails exceeding this are re-compressed to fit.
const int kMaxThumbnailSizeBytes = 5 * 1024; // 5 KB

/// Thumbnail dimensions (pixels) for image/video previews.
/// Both width and height are capped at this value (aspect ratio preserved).
const int kThumbnailMaxDimension = 120;

/// Maximum number of media file transfers per sync connection.
/// Prevents a single sync from being monopolized by large files.
/// Text messages always sync first (Phase 2); media is Phase 3.
const int kMaxMediaSyncsPerConnection = 3;

/// Directory name for storing media files within the app's data directory.
/// Structure: `{appDir}/airpass_media/{messageId}/{fileName}`
const String kMediaStorageDir = 'airpass_media';

/// TTL (hop count) for media messages. Lower than text to limit
/// epidemic amplification of large payloads across the mesh.
const int kMediaDefaultMaxHops = 5;

/// Time-based TTL for media messages (hours). Shorter than text
/// (72 hours) to conserve on-device storage.
const int kMediaMessageTtlHours = 24; // 1 day

/// File size threshold (bytes) for auto-downloading media.
/// Images/files under this size are fetched automatically during
/// Phase 3 sync. Larger files require the user to tap "download".
const int kAutoDownloadMaxBytes = 1 * 1024 * 1024; // 1 MB

/// Magic bytes prefix for media request payloads.
/// Used to distinguish media requests from Bloom filters and sync payloads
/// in [NearbyConnectionManager._onPayloadReceived].
const List<int> kMediaRequestMagic = [0x4D, 0x52]; // 'MR'

/// Magic bytes prefix for media response payloads.
/// Sent before a FILE payload to tell the receiver which message ID
/// the incoming file corresponds to.
const List<int> kMediaResponseMagic = [0x4D, 0x53]; // 'MS'
