import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:auto_updater/auto_updater.dart';
import 'water_reminder_app.dart';
import 'tray_manager.dart';
import 'notification_manager.dart';
import 'achievements/achievement_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa as conquistas
  await AchievementManager.initializeAchievements();

  // Configuração do auto updater
  String feedURL =
      'https://raw.githubusercontent.com/JulioHeroZ/WaterTime/release/dist/appcast.xml'; // URL do seu servidor de updates
  await autoUpdater.setFeedURL(feedURL);
  await autoUpdater.checkForUpdates(); // Verifica updates ao iniciar
  await autoUpdater.setScheduledCheckInterval(3600); // Verifica a cada 1 hora

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 700),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(400, 700),
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final trayManager = TrayManager();
  await trayManager.initSystemTray();

  // Inicialize o NotificationManager aqui
  final notificationManager = NotificationManager();
  await notificationManager.initializeNotifications();

  runApp(WaterReminderApp(
    trayManager: trayManager,
    notificationManager: notificationManager,
  ));
}
