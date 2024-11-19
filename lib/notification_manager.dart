import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';

class NotificationManager {
  Future<void> initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'water_reminder_channel',
          channelName: 'Lembretes de Água',
          channelDescription: 'Canal para lembretes de beber água',
          defaultColor: Color.fromARGB(255, 64, 187, 224),
          ledColor: Color.fromARGB(255, 64, 187, 224),
          importance: NotificationImportance.High,
        )
      ],
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> showNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'water_reminder_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> checkBatteryOptimization(BuildContext context) async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    
    if (deviceInfo.version.sdkInt >= 23) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Otimização de Bateria'),
          content: Text(
            'Para garantir que você receba as notificações corretamente, '
            'é importante desativar a otimização de bateria para este app.\n\n'
            'Deseja abrir as configurações agora?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Depois'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openBatterySettings(context);
              },
              child: Text('Configurar'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> openBatterySettings(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:${packageInfo.packageName}',
      );
      await intent.launch();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Configurações de Bateria'),
          content: Text(
            'Para garantir o funcionamento correto das notificações:\n\n'
            '1. Vá em Configurações do dispositivo\n'
            '2. Abra Aplicativos ou Gerenciador de Apps\n'
            '3. Encontre o WaterTime\n'
            '4. Selecione Bateria\n'
            '5. Escolha "Não otimizar" ou "Sem restrições"'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Entendi'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> scheduleNotification(DateTime scheduledTime) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'water_reminder_channel',
        title: 'Hora de beber água!',
        body: 'Mantenha-se hidratado para uma vida mais saudável.',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: scheduledTime.hour,
        minute: scheduledTime.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        preciseAlarm: true,
      ),
    );
  }
}
