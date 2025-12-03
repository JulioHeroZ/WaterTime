import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'water_reminder_app.dart';
import 'tray_manager.dart';
import 'notification_manager.dart';
import 'achievements/achievement_manager.dart';
import 'services/auth_service.dart';
import 'package:provider/provider.dart';
import 'theme_manager.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Evita múltiplas instâncias do app: tenta obter lock exclusivo em arquivo no diretório temporário
  final lockFile = File('${Directory.systemTemp.path}/watertime_single_instance.lock');
  RandomAccessFile? raf;
  try {
    if (!lockFile.existsSync()) {
      lockFile.createSync(recursive: true);
    }
    raf = lockFile.openSync(mode: FileMode.append);
    // Tenta lock exclusivo; se não conseguir, encerra este processo
    raf.lockSync(FileLock.exclusive);
  } catch (e) {
    // Outra instância já está rodando
    // Opcional: tentar focar janela existente via mecanismo IPC; por ora, apenas encerrar
    exit(0);
  }

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

  // Ao terminar, libera o lock (não bloqueante; quando o processo fecha o SO libera de qualquer modo)
  ProcessSignal.sigint.watch().listen((_) {
    try {
      raf?.unlockSync();
      raf?.closeSync();
    } catch (_) {}
    exit(0);
  });
}
