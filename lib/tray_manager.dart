import 'package:system_tray/system_tray.dart';
import 'dart:io';

class TrayManager {
  final SystemTray _systemTray = SystemTray();
  final AppWindow _appWindow = AppWindow();

  Future<void> initSystemTray() async {
    String path = Platform.isWindows ? 'assets/water.ico' : 'assets/water.ico';

    await _systemTray.initSystemTray(
      title: "Water Reminder",
      iconPath: path,
    );

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: 'Abrir', onClicked: (menuItem) => _appWindow.show()),
      MenuItemLabel(label: 'Sair', onClicked: (menuItem) => exit(0)),
    ]);

    await _systemTray.setContextMenu(menu);

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        _appWindow.show();
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });
  }

  void minimizeToTray() {
    _appWindow.hide();
  }
}
