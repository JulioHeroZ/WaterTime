import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'Home Page/water_reminder_home_page.dart';
import 'tray_manager.dart';
import 'notification_manager.dart';
import 'achievements/achievement_manager.dart';

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
      navigatorKey: AchievementManager.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Water Reminder',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 64, 187, 224)),
      ),
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => GestureDetector(
                onPanStart: (details) {
                  windowManager.startDragging();
                },
                child: child!,
              ),
            ),
          ],
        );
      },
      home: WaterReminderHomePage(
        trayManager: trayManager,
        notificationManager: notificationManager,
      ),
    );
  }
}
