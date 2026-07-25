/// Airpass Protocol — Barrel Export
///
/// Import this single file to access the entire Airpass protocol API:
///
/// ```dart
/// import 'package:airpass/airpass.dart';
/// ```
library;

// ─── Permissions & Hardware State ───
export 'airpass_permissions.dart';
export 'package:permission_handler/permission_handler.dart';

// ─── Config ───
export 'config/airpass_config.dart';

// ─── Models ───
export 'models/message_status.dart';
export 'models/node_role.dart';

// ─── Database ───
export 'database/airpass_database.dart';

// ─── Services ───
export 'services/airpass_background_service.dart';
export 'services/airpass_sync_engine.dart';
export 'services/bloom_filter.dart';
export 'services/endpoint_codec.dart';
export 'services/message_signer.dart';
export 'services/nearby_connection_manager.dart';

// ─── UI Client ───
export 'airpass_client.dart';

// ─── Dependency Injection ───
export 'di/service_locator.dart';

// ─── Utils ───
export 'utils/airpass_logger.dart';
