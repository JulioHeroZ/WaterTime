import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'platform/platform_manager.dart';

class NotificationManager {
  final FlutterLocalNotificationsPlugin _flutterLocalNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    if (PlatformManager.isMobile) {
      await _initializeMobileNotifications();
    }
  }

  Future<void> _initializeMobileNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _flutterLocalNotifications.initialize(initSettings);
  }

  Future<void> showNotification(String title, String body) async {
    if (PlatformManager.isMobile) {
      await _showMobileNotification(title, body);
    } else if (PlatformManager.isWindows) {
      await _showWindowsNotification(title, body);
    }
  }

  Future<void> _showMobileNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'water_reminder_channel',
      'Water Reminder',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    await _flutterLocalNotifications.show(0, title, body, notificationDetails);
  }

  Future<void> _showWindowsNotification(String title, String body) async {
    // Mantém a lógica existente para Windows
  }
}
