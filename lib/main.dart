import 'package:flutter/material.dart';
import 'water_reminder_app.dart';
import 'notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationManager = NotificationManager();
  await notificationManager.initializeNotifications();

  runApp(WaterReminderApp(
    notificationManager: notificationManager,
  ));
}
