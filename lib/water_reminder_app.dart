import 'package:flutter/material.dart';
import 'water_reminder_home_page.dart';
import 'tray_manager.dart';
import 'notification_manager.dart';

class WaterReminderApp extends StatelessWidget {
  final TrayManager trayManager;
  final NotificationManager notificationManager;

  const WaterReminderApp({
    Key? key,
    required this.trayManager,
    required this.notificationManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Reminder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF07518D)),
      ),
      home: WaterReminderHomePage(
        trayManager: trayManager,
        notificationManager: notificationManager,
      ),
    );
  }
}
