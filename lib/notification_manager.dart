import 'package:local_notifier/local_notifier.dart';

class NotificationManager {
  Future<void> initializeNotifications() async {
    await localNotifier.setup(
      appName: 'Water Time',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  void showNotification(String title, String body) {
    LocalNotification notification = LocalNotification(
      title: title,
      body: body,
    );
    notification.show();
  }
}
