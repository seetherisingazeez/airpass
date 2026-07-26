/// Airpass Protocol — Service Locator (Dependency Injection)
///
/// Uses [GetIt] to register and resolve all Airpass services.
///
/// This is used by both the main UI isolate and can be called
/// from the background service isolate (with its own GetIt instance).
///
/// ## Usage
///
/// ```dart
/// // In main.dart:
/// await setupAirpassServiceLocator();
///
/// // Anywhere in the app:
/// final client = getIt<AirpassClient>();
/// client.sendMessage(payload: 'hello', targetId: 'protest-2026');
/// ```
library;

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../airpass_client.dart';
import '../database/airpass_database.dart';
import '../models/node_role.dart';
import '../services/airpass_sync_engine.dart';
import '../services/endpoint_codec.dart';
import '../services/media_storage_service.dart';
import '../services/nearby_connection_manager.dart';

/// Global GetIt instance for the Airpass protocol.
final GetIt getIt = GetIt.instance;

/// SharedPreferences key for the persisted local node UUID.
const String _kNodeIdKey = 'airpass_local_node_id';

/// SharedPreferences key for the persisted local node role.
const String _kNodeRoleKey = 'airpass_local_node_role';

/// SharedPreferences key for the user's chosen display name.
const String _kDisplayNameKey = 'airpass_local_display_name';

/// SharedPreferences key for the user's selected skills.
const String _kSkillsKey = 'airpass_local_skills';

/// SharedPreferences key for the user's phone number.
const String _kPhoneKey = 'airpass_local_phone';

/// SharedPreferences key for the persisted local group ID.
/// (Legacy — kept for migration. Multi-group is now persisted in the DB.)
const String _kGroupIdKey = 'airpass_local_group_id';

/// Registers all Airpass services in the GetIt container.
///
/// Call this once during app startup (before `runApp()`).
///
/// Node identity is generated on first launch and persisted
/// in SharedPreferences.
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await setupAirpassServiceLocator();
///   runApp(const MyApp());
/// }
/// ```
Future<void> setupAirpassServiceLocator() async {
  // ─── Load or generate persistent node identity ───
  final prefs = await SharedPreferences.getInstance();
  final nodeId = await _loadOrCreateNodeId(prefs);
  final role = _loadNodeRole(prefs);
  final displayName = prefs.getString(_kDisplayNameKey);
  final skills = prefs.getStringList(_kSkillsKey) ?? [];
  final phone = prefs.getString(_kPhoneKey);

  // ─── Register database ───
  getIt.registerLazySingleton<AirpassDatabase>(() => AirpassDatabase());

  // ─── Register codec ───
  getIt.registerLazySingleton<EndpointCodec>(() => EndpointCodec());

  // ─── Load subscribed groups from the database ───
  // On startup, we query the DB for groups marked isSubscribed.
  // This is an async call so we do it eagerly during setup.
  final db = getIt<AirpassDatabase>();
  final subscribedGroups = await db.getAllGroups();
  final groupIds = subscribedGroups
      .where((g) => g.isSubscribed)
      .map((g) => g.groupId)
      .toList();

  // ─── Register sync engine ───
  getIt.registerLazySingleton<AirpassSyncEngine>(
    () => AirpassSyncEngine(
      database: db,
      localNodeId: nodeId,
      localRole: role,
      localGroupIds: groupIds,
      localDisplayName: displayName,
      localSkills: skills,
      localPhone: phone,
    ),
  );

  // ─── Register media storage service ───
  getIt.registerLazySingleton<MediaStorageService>(
    () => MediaStorageService(database: db),
  );

  // ─── Register connection manager ───
  getIt.registerLazySingleton<NearbyConnectionManager>(
    () => NearbyConnectionManager(
      syncEngine: getIt<AirpassSyncEngine>(),
      codec: getIt<EndpointCodec>(),
      db: db,
      mediaStorage: getIt<MediaStorageService>(),
      localNodeId: nodeId,
      localRole: role,
      localGroupIds: groupIds,
    ),
  );

  // ─── Register the UI facade ───
  getIt.registerLazySingleton<AirpassClient>(
    () => AirpassClient(
      db: db,
      codec: getIt<EndpointCodec>(),
      mediaStorage: getIt<MediaStorageService>(),
      localNodeId: nodeId,
      localRole: role,
    ),
  );

  // ─── Register the node identity values for easy access ───
  getIt.registerSingleton<String>(nodeId, instanceName: 'localNodeId');
  getIt.registerSingleton<NodeRole>(role, instanceName: 'localNodeRole');
  if (displayName != null) {
    getIt.registerSingleton<String>(displayName, instanceName: 'localDisplayName');
  }
  getIt.registerSingleton<List<String>>(skills, instanceName: 'localSkills');
  if (phone != null) {
    getIt.registerSingleton<String>(phone, instanceName: 'localPhone');
  }
}

/// Loads the local node UUID from SharedPreferences, or generates
/// a new one on first launch.
///
/// The write is awaited to prevent a race condition where the background
/// isolate reads `null` before the new ID is flushed to disk.
Future<String> _loadOrCreateNodeId(SharedPreferences prefs) async {
  final existing = prefs.getString(_kNodeIdKey);
  if (existing != null && existing.isNotEmpty) return existing;

  // First launch — generate a new UUID v4
  final newId = const Uuid().v4();
  await prefs.setString(_kNodeIdKey, newId);
  return newId;
}

/// Loads the node role from SharedPreferences.
/// Defaults to [NodeRole.group] if not set.
///
/// Role changes are persisted via [updateLocalNodeRole], which is
/// called by [updateAdvertising] when the user switches roles.
NodeRole _loadNodeRole(SharedPreferences prefs) {
  final roleValue = prefs.getInt(_kNodeRoleKey);
  if (roleValue != null) return NodeRole.fromValue(roleValue);
  return NodeRole.group; // Default role
}

/// Updates the local node's role and persists it.
///
/// Call this from UI when the user changes their role:
/// ```dart
/// await updateLocalNodeRole(NodeRole.global);
/// ```
Future<void> updateLocalNodeRole(NodeRole newRole) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kNodeRoleKey, newRole.value);
}

/// Updates the local node's group ID and persists it (legacy).
///
/// NOTE: Multi-group subscriptions are now managed through the
/// database's Groups table via [AirpassClient]. This method is
/// kept for backward compatibility.
Future<void> updateLocalGroupId(String? newGroupId) async {
  final prefs = await SharedPreferences.getInstance();
  if (newGroupId != null) {
    await prefs.setString(_kGroupIdKey, newGroupId);
  } else {
    await prefs.remove(_kGroupIdKey);
  }
}

/// Saves the user's chosen profile data (name and skills) and registers it in GetIt.
Future<void> setLocalUserProfile(String name, List<String> skills, {String? phone}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kDisplayNameKey, name);
  await prefs.setStringList(_kSkillsKey, skills);
  
  if (phone != null && phone.isNotEmpty) {
    await prefs.setString(_kPhoneKey, phone);
  } else {
    await prefs.remove(_kPhoneKey);
  }
  
  if (getIt.isRegistered<String>(instanceName: 'localDisplayName')) {
    getIt.unregister<String>(instanceName: 'localDisplayName');
  }
  getIt.registerSingleton<String>(name, instanceName: 'localDisplayName');
  
  if (getIt.isRegistered<List<String>>(instanceName: 'localSkills')) {
    getIt.unregister<List<String>>(instanceName: 'localSkills');
  }
  getIt.registerSingleton<List<String>>(skills, instanceName: 'localSkills');

  if (getIt.isRegistered<String>(instanceName: 'localPhone')) {
    getIt.unregister<String>(instanceName: 'localPhone');
  }
  if (phone != null && phone.isNotEmpty) {
    getIt.registerSingleton<String>(phone, instanceName: 'localPhone');
  }
  
  // Also update the sync engine so future syncs broadcast the new name and skills
  if (getIt.isRegistered<AirpassSyncEngine>()) {
    getIt<AirpassSyncEngine>().localDisplayName = name;
    getIt<AirpassSyncEngine>().localSkills = skills;
    getIt<AirpassSyncEngine>().localPhone = phone;
  }
}
