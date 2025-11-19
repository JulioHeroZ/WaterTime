import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'water_reminder_app.dart';
import 'tray_manager.dart';
import 'notification_manager.dart';
import 'achievements/achievement_manager.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'package:provider/provider.dart';
import 'theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthService.initialize();
  // SyncService.startPeriodicSync(); // Removido: sincronização Supabase
  await AchievementManager.initializeAchievements();

  final notificationManager = NotificationManager();
  await notificationManager.initializeNotifications();

  TrayManager? trayManager;

  await windowManager.ensureInitialized();

  // Sistema de atualização removido — chamadas ao plugin `auto_updater` foram
  // eliminadas. Se quiser restaurar, descomente e configure o feedURL.

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(400, 600),
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  trayManager = TrayManager();
  await trayManager.initSystemTray();

  final themeManager = ThemeManager();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>.value(value: themeManager),
      ],
      child: WaterReminderApp(
        trayManager: trayManager,
        notificationManager: notificationManager,
      ),
    ),
  );
}
