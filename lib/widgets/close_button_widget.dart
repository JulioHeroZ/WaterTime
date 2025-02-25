import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../tray_manager.dart';

class CustomCloseButton extends StatelessWidget {
  final TrayManager? trayManager;

  const CustomCloseButton({
    Key? key,
    this.trayManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 10,
      top: 10,
      child: IconButton(
        icon: const Icon(Ionicons.close_outline, color: Colors.white),
        onPressed: () {
          trayManager?.minimizeToTray();
        },
      ),
    );
  }
}
