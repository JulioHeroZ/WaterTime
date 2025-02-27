import 'package:flutter/material.dart';
import '../tray_manager.dart';

class CustomCloseButton extends StatelessWidget {
  final TrayManager? trayManager;

  const CustomCloseButton({Key? key, this.trayManager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: () {
        if (trayManager != null) {
          trayManager!.minimizeToTray();
        } else {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
