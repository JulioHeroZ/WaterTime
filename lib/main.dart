import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'water_reminder_app.dart';
import 'notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Força a orientação retrato
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final notificationManager = NotificationManager();
  await notificationManager.initializeNotifications();

  runApp(WaterReminderApp(
    notificationManager: notificationManager,
  ));
}
