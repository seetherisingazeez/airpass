import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'airpass_logger.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      // Note: iOS initialization can be added here if needed
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
      );

      // Create Android channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'airpass_messages_channel',
        'New Messages',
        description: 'Notifications for new mesh network messages',
        importance: Importance.max,
        enableVibration: true,
      );

      final platformPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (platformPlugin != null) {
        await platformPlugin.createNotificationChannel(channel);
      }
      AirpassLogger.log('NotificationHelper', 'Initialized successfully');
    } catch (e) {
      AirpassLogger.log('NotificationHelper', 'Initialization failed: $e');
    }
  }

  static Future<void> showNewMessageNotification({
    required String title,
    required String body,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'airpass_messages_channel',
            'New Messages',
            channelDescription: 'Notifications for new mesh network messages',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notificationsPlugin.show(
        id: DateTime.now().millisecond, // random enough ID
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
      );
    } catch (e) {
      AirpassLogger.log('NotificationHelper', 'Failed to show notification: $e');
    }
  }
}
