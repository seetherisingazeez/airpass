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
