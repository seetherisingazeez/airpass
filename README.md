# Airpass Protocol

**Airpass** is a decentralized, offline, store-and-forward mesh networking protocol built specifically for Flutter. It leverages the **Google Nearby Connections API** (Bluetooth LE, Bluetooth Classic, and Wi-Fi Direct) to allow devices to communicate without internet access or cellular infrastructure.

Unlike standard real-time chat protocols, Airpass is designed for **epidemic routing** and **ephemeral connections**. It prioritizes battery life, bandwidth, and high-latency disconnected environments (e.g., natural disasters, protests, remote areas).

---

## 🏗 Architecture & Protocol Layer

The Airpass protocol operates on a strict **Connect-Sync-Drop** architecture. It intentionally breaks the standard real-time socket paradigm:

### 1. Ephemeral Connections (Connect-Sync-Drop)
The system **never** maintains persistent connections. Maintaining constant Wi-Fi Direct connections between multiple devices drains batteries and creates unstable mesh topologies. 
Instead, nodes use low-energy BLE to advertise their presence. When two nodes discover each other, they execute a two-phase protocol:
1. **Connect:** Establish a high-bandwidth Wi-Fi Direct connection.
2. **Filter Exchange (Phase 1):** Each node sends a tiny Bloom filter (~1.2 KB) representing the messages it already has.
3. **Filtered Sync (Phase 2):** Each node uses the received filter to exclude messages the peer already has, then sends only the *novel* messages + routing table in a compressed payload. This eliminates redundant data transfers and saves massive amounts of battery.
4. **Drop:** The exact millisecond the payload transfer reaches 100%, the connection is immediately terminated.
5. Heavy JSON parsing and database merging happens *offline*, after the radio connection is closed.

### 2. Epidemic Routing (Store-and-Forward)
Airpass uses a Gossip / Epidemic routing model. 
When you send a message, it is stored in your local SQLite database (powered by Drift) as `PENDING`. As you walk around, your phone briefly connects with other nodes, syncing messages. Even if your recipient is miles away, your message hops from phone to phone (Node A -> Node B -> Node C) until it reaches the destination. Every message has a `TTL` (Time To Live / Hop count) to prevent infinite loops.

### 3. Smart Endpoint Advertising
The protocol utilizes the 131-byte Endpoint Name in the Nearby Connections BLE beacon to broadcast metadata. Before devices even connect, they know each other's Node ID Prefix, Role, and Subscribed Groups. This prevents unnecessary connections (e.g., if neither node has new messages for the other's groups).

---

## 🚀 How to Use It

The Airpass architecture strictly separates the **Background Network Engine** from the **UI Client**. The Flutter UI *never* triggers network requests directly; it only reads/writes to the local database.

### 1. Initialization (Main.dart)
Airpass uses `get_it` for dependency injection. Initialize it before `runApp`.

```dart
import 'package:airpass/airpass.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Register all services and generate local Node ID
  await setupAirpassServiceLocator();

  // 2. Request Android 12+ / iOS runtime permissions
  final permissionsGranted = await AirpassPermissions.requestPermissions();
  
  if (permissionsGranted) {
    // 3. Start the background mesh service.
    //    Android: Runs as a persistent foreground service (always active).
    //    iOS: Limited to ~30s via BGTaskScheduler when backgrounded.
    //    The mesh is effectively paused when the iOS app is closed.
    final isRunning = await isAirpassServiceRunning();
    if (!isRunning) {
      await initializeAirpassBackgroundService();
    }
  }

  runApp(const MyApp());
}
```

**Starting & Stopping the Service Manually:**
```dart
// You can manually start or stop the background service later
await startAirpassService();
await stopAirpassService();
```

### 2. Handling Hardware State
You should warn users if they turn off Bluetooth or Wi-Fi, as this breaks the mesh network.

```dart
AirpassPermissions.watchHardwareState().listen((state) {
  if (state == AirpassHardwareState.bluetoothDisabled) {
    print("Please turn on Bluetooth to connect to the mesh.");
  }
});
```

**Active Hardware Check (One-off):**
If you need to perform a synchronous, one-off check without subscribing to a stream (e.g., during `initState` or right before a manual action):

```dart
final currentState = await AirpassPermissions.getHardwareState();
if (currentState != AirpassHardwareState.ready) {
  print("Please enable your radios to proceed.");
}
```

**Fine-grained Permission Checks:**
If you need to know exactly which permissions are granted or denied (for example, to show a customized settings UI), you can use the fine-grained API:

```dart
// Get a map of all required permissions and their current status
final statuses = await AirpassPermissions.getPermissionStatuses();
if (statuses[Permission.nearbyWifiDevices] != PermissionStatus.granted) {
  // Request just this specific permission
  await AirpassPermissions.requestPermission(Permission.nearbyWifiDevices);
}
```

### 3. UI Interactions (AirpassClient)
All UI interactions are done via the `AirpassClient` and `AirpassDatabase`.

**Listen for Discovered Groups (Reactive):**
```dart
final client = getIt<AirpassClient>();

client.watchDiscoveredGroups().listen((groups) {
  for (final group in groups) {
    print('Found group: ${group.groupId}');
  }
});
```

**Subscribe to a Group:**
```dart
// Validates byte limits and re-configures the BLE beacon
await client.subscribeToGroup('protest-2026');
```

**Send a Message:**
```dart
// Saves to local DB. The background service handles actual delivery.
await client.sendMessage(
  payload: 'Need medical supplies at Main St.',
  targetId: 'protest-2026', 
);
```

**Listen for Incoming Messages:**
```dart
client.listenForMessages('protest-2026').listen((messages) {
  for (final msg in messages) {
    print("New Message: ${utf8.decode(msg.payload)}");
  }
});
```

**View Routing Table (All known nodes):**
```dart
final db = getIt<AirpassDatabase>();

db.watchKnownNodes().listen((nodes) {
  print("Known nodes in mesh: ${nodes.length}");
});
```
