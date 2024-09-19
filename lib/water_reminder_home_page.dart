import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'settings_page.dart';
import 'tray_manager.dart';
import 'data_manager.dart';
import 'notification_manager.dart';
import 'custom_amount.dart';
import 'dialogs.dart';

class WaterReminderHomePage extends StatefulWidget {
  final TrayManager trayManager;
  final NotificationManager notificationManager;

  const WaterReminderHomePage({
    Key? key,
    required this.trayManager,
    required this.notificationManager,
  }) : super(key: key);

  @override
  _WaterReminderHomePageState createState() => _WaterReminderHomePageState();
}

class _WaterReminderHomePageState extends State<WaterReminderHomePage>
    with WindowListener {
  int _waterConsumed = 0;
  int _dailyGoal = 2000; // Meta diária em mililitros
  List<int> _waterHistory = [];
  DateTime _lastResetDay = DateTime.now();
  Timer? _notificationTimer;

  double _notificationInterval = 2.0;
  List<bool> _selectedDays = List.filled(7, true);
  TimeOfDay _startTime = TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 22, minute: 0);
  List<CustomAmount> _customAmounts = [];
  int? _lastAddedAmount; // Armazena a última quantidade adicionada

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadData();
    _scheduleNotifications();
    _loadCustomAmounts();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await DataManager.loadData();
    setState(() {
      _waterConsumed = data['waterConsumed'] ?? 0;
      _dailyGoal = data['dailyGoal'] ?? 2000;
      _waterHistory = List<int>.from(data['waterHistory'] ?? []);
      _lastResetDay = DateTime.parse(
          data['lastResetDay'] ?? DateTime.now().toIso8601String());

      _notificationInterval = data['notificationInterval'] ?? 2.0;
      _selectedDays =
          List<bool>.from(data['selectedDays'] ?? List.filled(7, true));
      _startTime = TimeOfDay(
        hour: data['startTimeHour'] ?? 8,
        minute: data['startTimeMinute'] ?? 0,
      );
      _endTime = TimeOfDay(
        hour: data['endTimeHour'] ?? 22,
        minute: data['endTimeMinute'] ?? 0,
      );
    });
  }

  Future<void> _loadCustomAmounts() async {
    final loadedAmounts = await DataManager.loadCustomAmounts();
    setState(() {
      _customAmounts = loadedAmounts;
    });
  }

  Future<void> _saveCustomAmounts() async {
    await DataManager.saveCustomAmounts(_customAmounts);
  }

  void _scheduleNotifications() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkAndSendNotification();
    });
  }

  void _checkAndSendNotification() {
    final now = DateTime.now();
    final currentDay = now.weekday - 1; // 0 = Segunda, 6 = Domingo
    final currentTime = TimeOfDay.fromDateTime(now);

    if (_selectedDays[currentDay] &&
        _isTimeInRange(currentTime, _startTime, _endTime) &&
        _waterConsumed < _dailyGoal) {
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      final elapsedMinutes = currentMinutes - startMinutes;

      if (elapsedMinutes % (_notificationInterval * 60).round() == 0) {
        widget.notificationManager.showNotification(
          'Lembrete de Água',
          'Hora de beber água! Você já bebeu $_waterConsumed ml de $_dailyGoal ml.',
        );
        print('Notificação enviada às ${currentTime.format(context)}');
      }
    }
  }

  bool _isTimeInRange(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final now = time.hour * 60 + time.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes > startMinutes) {
      return now >= startMinutes && now <= endMinutes;
    } else {
      // Caso o horário final seja no dia seguinte
      return now >= startMinutes || now <= endMinutes;
    }
  }

  Future<void> _saveData() async {
    final data = {
      'waterConsumed': _waterConsumed,
      'dailyGoal': _dailyGoal,
      'waterHistory': _waterHistory,
      'lastResetDay': _lastResetDay.toIso8601String(),
    };
    await DataManager.saveData(data);
  }

  void _checkAndResetDaily() {
    final now = DateTime.now();
    if (now.day != _lastResetDay.day ||
        now.month != _lastResetDay.month ||
        now.year != _lastResetDay.year) {
      setState(() {
        _waterConsumed = 0;
        _waterHistory.clear();
        _lastResetDay = now;
      });
      _saveData();
    }
  }

  Future<void> _addWater(int amount) async {
    setState(() {
      _waterConsumed += amount;
      _waterHistory.add(amount);
      _lastAddedAmount = amount; // Atualiza a última quantidade adicionada
    });
    await _saveData();

    // Verifique se a meta foi atingida após adicionar água
    if (_waterConsumed >= _dailyGoal) {
      widget.notificationManager.showNotification(
        'Meta Atingida!',
        'Parabéns! Você atingiu sua meta diária de $_dailyGoal ml de água.',
      );
    }
  }

  Future<void> _removeLastWater() async {
    if (_waterHistory.isNotEmpty) {
      setState(() {
        int lastAmount = _waterHistory.removeLast();
        _waterConsumed -= lastAmount;
      });
      await _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: GestureDetector(
          onPanStart: (details) {
            windowManager.startDragging();
          },
          child: AppBar(
            backgroundColor: const Color.fromARGB(255, 18, 90, 148),
            elevation: 0,
            centerTitle: true,
            title: Image.asset(
              'assets/Logo.png',
              height: 150,
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  widget.trayManager.minimizeToTray();
                },
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onPanStart: (details) {
          windowManager.startDragging();
        },
        child: Center(
          child: Container(
            constraints:
                BoxConstraints(maxWidth: 400), // Limita a largura máxima
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment
                    .center, // Centraliza os itens horizontalmente
                children: <Widget>[
                  Text(
                    'Meta diária: $_dailyGoal ml',
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center, // Centraliza o texto
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Água consumida: $_waterConsumed ml',
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center, // Centraliza o texto
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      _showWaterSelectionDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 246, 255, 252),
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    child: Text('Adicionar água'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _lastAddedAmount != null
                        ? () async {
                            await _addWater(_lastAddedAmount!);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 246, 255, 252),
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    child: Text('Predefinido'),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: _waterHistory.isEmpty ? null : _removeLastWater,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      textStyle: TextStyle(fontSize: 14),
                    ),
                    child: Text('Remover quantidade'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SettingsPage(onSettingsChanged: () {
                      _loadData(); // Recarrega os dados e reagenda as notificações
                    })), // Atualiza a meta de ml
          );
        },
        child: Icon(Icons.settings),
        tooltip: 'Configurações',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showWaterSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return WaterSelectionDialog(
              customAmounts: _customAmounts,
              addWater: _addWater,
              updateCustomAmounts: (amounts) {
                setState(() {
                  _customAmounts = amounts;
                });
              },
            );
          },
        );
      },
    );
  }

  @override
  void onWindowEvent(String eventName) {
    print('Window event: $eventName');
    if (eventName == 'close') {
      widget.trayManager.minimizeToTray();
    }
  }

  void _testNotificationSchedule() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < 1440; i++) {
      // Simula 24 horas (1440 minutos)
      final testTime = startOfDay.add(Duration(minutes: i));
      final testTimeOfDay = TimeOfDay.fromDateTime(testTime);

      if (_selectedDays[testTime.weekday - 1] &&
          _isTimeInRange(testTimeOfDay, _startTime, _endTime)) {
        final startMinutes = _startTime.hour * 60 + _startTime.minute;
        final currentMinutes = testTimeOfDay.hour * 60 + testTimeOfDay.minute;
        final elapsedMinutes = currentMinutes - startMinutes;

        if (elapsedMinutes % (_notificationInterval * 60).round() == 0) {
          print(
              'Notificação seria enviada às ${testTimeOfDay.format(context)}');
        }
      }
    }
  }
}
