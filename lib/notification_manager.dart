import 'package:local_notifier/local_notifier.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'sound_manager.dart';
import 'data_manager.dart';

class NotificationManager {
  Timer? _notificationTimer;
  int _lastKnownConsumed = 0;
  int _dailyGoal = 0;
  bool _goalAchievedNotified = false;

  Future<void> initializeNotifications() async {
    await localNotifier.setup(appName: "WaterTime");
  }

  Future<void> showNotification(String title, String body) async {
    final notification = LocalNotification(
      title: title,
      body: body,
      actions: [LocalNotificationAction(text: "OK")],
    );

    await notification.show();
    await SoundManager.playSound('notification');
  }

  Future<void> scheduleNotifications(double interval, TimeOfDay startTime,
      TimeOfDay endTime, List<bool> selectedDays) async {
    cancelNotifications();
    _goalAchievedNotified = false;

    _notificationTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) async {
        final now = DateTime.now();
        final currentTimeOfDay = TimeOfDay.fromDateTime(now);
        final currentDayIndex = now.weekday - 1;

        // Atualiza os valores de consumo e meta
        final data = await DataManager.loadData();
        _lastKnownConsumed = data['waterConsumed'] ?? 0;
        _dailyGoal = data['dailyGoal'] ?? 2000;

        // Verifica se atingiu a meta e ainda não notificou
        if (_lastKnownConsumed >= _dailyGoal && !_goalAchievedNotified) {
          await showNotification(
            'Parabéns! 🎉',
            'Você atingiu sua meta diária de água! Continue assim!',
          );
          _goalAchievedNotified = true;
          return;
        }

        if (selectedDays[currentDayIndex] &&
            _isTimeInRange(currentTimeOfDay, startTime, endTime)) {
          final currentMinutes =
              currentTimeOfDay.hour * 60 + currentTimeOfDay.minute;
          final startMinutes = startTime.hour * 60 + startTime.minute;
          final intervalMinutes = (interval * 60).round();

          // Mensagem comum para todas as notificações
          final progressMessage =
              'Você bebeu $_lastKnownConsumed ml de $_dailyGoal ml hoje.';

          if (currentMinutes == startMinutes) {
            await showNotification(
              'Hora de começar a se hidratar!',
              'Vamos começar bem o dia! $progressMessage',
            );
            return;
          }

          if (currentMinutes == (endTime.hour * 60 + endTime.minute)) {
            await showNotification(
              'Último lembrete do dia!',
              'Não se esqueça de beber água antes de dormir. $progressMessage',
            );
            return;
          }

          final minutesFromStart = currentMinutes - startMinutes;
          if (minutesFromStart > 0 && minutesFromStart % intervalMinutes == 0) {
            final remaining = _dailyGoal - _lastKnownConsumed;
            await showNotification(
              'Hora de beber água!',
              'Faltam $remaining ml para atingir sua meta! $progressMessage',
            );
          }
        }
      },
    );
  }

  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final now = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return now >= startMinutes && now <= endMinutes;
  }

  void cancelNotifications() {
    _notificationTimer?.cancel();
    _goalAchievedNotified = false;
  }
}
