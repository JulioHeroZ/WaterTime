import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'water_reminder_app.dart';
import 'tray_manager.dart';
import 'notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(800, 400),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(400, 700), // Definindo o tamanho mínimo da janela
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
