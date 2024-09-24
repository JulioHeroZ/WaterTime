import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../History Page/history_page.dart';
import '../Settings Page/settings_page.dart';
import '../tray_manager.dart';
import '../data_manager.dart';
import '../notification_manager.dart';
import '../custom_amount.dart';
import '../dialogs.dart';
import '../Login Page/login_page.dart';
import '../widgets/cup_widget.dart';

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
  int _dailyGoal = 2000;
  DateTime _lastResetDay = DateTime.now();
  Timer? _notificationTimer;

  double _notificationInterval = 2.0;
  List<bool> _selectedDays = List.filled(7, true);
  TimeOfDay _startTime = TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 22, minute: 0);
  List<CustomAmount> _customAmounts = [];
  int? _lastAddedAmount;

  Timer? _midnightResetTimer;

  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadData();
    _scheduleNotifications();
    _loadCustomAmounts();
    _scheduleMidnightReset();
    _loadHistory();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _notificationTimer?.cancel();
    _midnightResetTimer?.cancel();
    super.dispose();
  }

  void _scheduleMidnightReset() {
    _midnightResetTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight =
        DateTime(now.year, now.month, now.day).add(Duration(days: 1));
    final timeUntilMidnight = nextMidnight.difference(now);

    _midnightResetTimer = Timer(timeUntilMidnight, () {
      _resetDaily();
      _scheduleMidnightReset();
    });
  }

  void _resetDaily() {
    setState(() {
      _waterConsumed = 0;
      _lastResetDay = DateTime.now();
    });
    _saveData();
  }

  Future<void> _loadData() async {
    final data = await DataManager.loadData();
    setState(() {
      _waterConsumed = data['waterConsumed'] ?? 0;
      _dailyGoal = data['dailyGoal'] ?? 2000;
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
    _checkAndResetIfNeeded();
  }

  void _checkAndResetIfNeeded() {
    final now = DateTime.now();
    final lastMidnight = DateTime(now.year, now.month, now.day);
    if (_lastResetDay.isBefore(lastMidnight)) {
      _resetDaily();
    }
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
    final currentDay = now.weekday - 1;
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
      return now >= startMinutes || now <= endMinutes;
    }
  }

  Future<void> _saveData() async {
    final data = {
      'waterConsumed': _waterConsumed,
      'dailyGoal': _dailyGoal,
      'lastResetDay': _lastResetDay.toIso8601String(),
    };
    await DataManager.saveData(data);
  }

  Future<void> _addWater(int amount) async {
    setState(() {
      int previousWaterConsumed = _waterConsumed;
      _waterConsumed += amount;
      _lastAddedAmount = amount;
      if (previousWaterConsumed < _dailyGoal && _waterConsumed >= _dailyGoal) {
        widget.notificationManager.showNotification(
          'Meta Atingida!',
          'Parabéns! Você atingiu sua meta diária de $_dailyGoal ml de água.',
        );
      }
    });
    await DataManager.addWater(amount);
    await _loadHistory(); // Recarrega o histórico após adicionar água

    // Verificar marcos e enviar notificações
  }

  Future<void> _removeLastWater() async {
    final int? lastAmount = await DataManager.removeLastAddition();
    if (lastAmount != null) {
      setState(() {
        _waterConsumed -= lastAmount;
        if (_waterConsumed < 0) _waterConsumed = 0;
      });
      await _saveData();
      await _loadHistory(); // Recarregar o histórico após remover água
    } else {
      // Informar ao usuário que não há adições para remover
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhuma quantidade para remover')),
      );
    }
  }

  Future<void> _loadHistory() async {
    final history = await DataManager.getHistory();
    setState(() {
      _history = history;
    });
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
            iconTheme: IconThemeData(
              color: Colors.white, // Define a cor dos ícones para branco
            ),
            backgroundColor: const Color.fromARGB(255, 18, 90, 148),
            elevation: 10,
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
            constraints: BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CupWidget(
                    currentIntake: _waterConsumed.toDouble(),
                    dailyGoal: _dailyGoal.toDouble(),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Meta diária: $_dailyGoal ml',
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Água consumida: $_waterConsumed ml',
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
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
                    onPressed:
                        (_lastAddedAmount != null) ? _removeLastWater : null,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      textStyle: TextStyle(fontSize: 14),
                    ),
                    child: Text('Remover quantidade'),
                  ),
                  SizedBox(height: 32),
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
                      _loadData();
                    })),
          );
        },
        child: Icon(Icons.settings),
        tooltip: 'Configurações',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            ListTile(
              title: Text('Histórico'),
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoricoPage()),
                );
                await _loadData(); // Recarregar dados locais
                setState(() {});
              },
            ),
            ListTile(
              title: Text('Login (Em Breve)'),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
                if (result == true) {
                  // Usuário fez login com sucesso, recarregar dados
                  await _loadData();
                  setState(() {});
                }
              },
            ),
            /*ListTile(
              title: Text('Logout'),
              onTap: () async {
                await _loadData(); // Recarregar dados locais
                setState(() {});
              },
            ),*/
          ],
        ),
      ),
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
    if (eventName == 'close') {
      widget.trayManager.minimizeToTray();
    }
  }
}
