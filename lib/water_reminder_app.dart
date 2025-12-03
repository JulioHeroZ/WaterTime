import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'Home Page/water_reminder_home_page.dart';
import 'onboarding/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tray_manager.dart';
import 'notification_manager.dart';
import 'achievements/achievement_manager.dart';
import 'platform/platform_manager.dart';
import 'package:provider/provider.dart';
import 'theme_manager.dart';

class WaterReminderApp extends StatelessWidget {
  final TrayManager? trayManager;
  final NotificationManager notificationManager;

  const WaterReminderApp({
    super.key,
    this.trayManager,
    required this.notificationManager,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AchievementManager.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Water Reminder',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 64, 187, 224),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 64, 187, 224),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[850],
        canvasColor: Colors.grey[850],
      ),
      themeMode: context.watch<ThemeManager>().themeMode,
      builder: (context, child) {
        if (PlatformManager.isWindows) {
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
        }
        return child!;
      },
      home: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final prefs = snapshot.data!;
          final completed = prefs.getBool('hasCompletedOnboarding') ?? false;
          if (!completed) {
            return OnboardingPage(trayManager: trayManager);
          }
          return WaterReminderHomePage(
            trayManager: trayManager,
            notificationManager: notificationManager,
          );
        },
      ),
    );
  }
}
