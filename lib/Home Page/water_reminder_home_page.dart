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
import 'package:ionicons/ionicons.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';

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
    with WindowListener, TickerProviderStateMixin {
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

  // Controllers para animação da onda
  late AnimationController firstController;
  late Animation<double> firstAnimation;

  late AnimationController secondController;
  late Animation<double> secondAnimation;

  late AnimationController thirdController;
  late Animation<double> thirdAnimation;

  late AnimationController fourthController;
  late Animation<double> fourthAnimation;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadData();
    _scheduleNotifications();
    _loadCustomAmounts();
    _scheduleMidnightReset();
    _loadHistory();

    // Inicialização das animações
    firstController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1500));
    firstAnimation = Tween<double>(begin: 1.9, end: 2.1).animate(
        CurvedAnimation(parent: firstController, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          firstController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          firstController.forward();
        }
      });

    secondController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1500));
    secondAnimation = Tween<double>(begin: 1.8, end: 2.4).animate(
        CurvedAnimation(parent: secondController, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          secondController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          secondController.forward();
        }
      });

    thirdController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1500));
    thirdAnimation = Tween<double>(begin: 1.8, end: 2.4).animate(
        CurvedAnimation(parent: thirdController, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          thirdController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          thirdController.forward();
        }
      });

    fourthController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1500));
    fourthAnimation = Tween<double>(begin: 1.9, end: 2.1).animate(
        CurvedAnimation(parent: fourthController, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          fourthController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          fourthController.forward();
        }
      });

    Timer(Duration(seconds: 2), () {
      firstController.forward();
    });

    Timer(Duration(milliseconds: 1600), () {
      secondController.forward();
    });

    Timer(Duration(milliseconds: 800), () {
      thirdController.forward();
    });

    fourthController.forward();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _notificationTimer?.cancel();
    _midnightResetTimer?.cancel();

    // Dispose dos controladores de animação
    firstController.dispose();
    secondController.dispose();
    thirdController.dispose();
    fourthController.dispose();

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

  final SideMenuController _sideMenuController = SideMenuController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SideMenu do easy_sidemenu
          SideMenu(
            controller: _sideMenuController,
            style: SideMenuStyle(
              itemInnerSpacing: 6,
              itemHeight: 50.0,
              showTooltip: true,
              iconSize: 25,
              compactSideMenuWidth: 60,
              openSideMenuWidth: 200,
              itemBorderRadius: const BorderRadius.all(
                Radius.circular(0.0),
              ),
              displayMode: SideMenuDisplayMode.auto,
              hoverColor: const Color.fromARGB(255, 255, 255, 255),
              selectedColor: const Color.fromARGB(255, 255, 255, 255),
              selectedTitleTextStyle:
                  TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
              unselectedTitleTextStyle: TextStyle(color: Colors.black),
              backgroundColor: Color.fromARGB(255, 255, 255, 255),
              // Adicione mais estilos conforme necessário
            ),
            items: [
              SideMenuItem(
                title: 'Login (Em Breve)',
                onTap: (index, _) async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignIn()),
                  );
                  if (result == true) {
                    // Usuário fez login com sucesso, recarregar dados
                    await _loadData();
                    setState(() {});
                  }
                },
                icon: Icon(Ionicons.person_circle_outline),
              ),
              SideMenuItem(
                title: 'Histórico',
                onTap: (index, _) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HistoricoPage()),
                  );
                  _loadData(); // Recarregar dados locais
                  setState(() {});
                },
                icon: Icon(Ionicons.calendar_outline),
              ),

              // Você pode adicionar mais itens aqui
            ],
          ),

          Expanded(
            child: Scaffold(
              backgroundColor: Color.fromARGB(255, 250, 250, 250),
              body: Column(
                children: [
                  // Animação de onda substituindo o AppBar
                  SizedBox(
                    height: 150, // Altura desejada para a animação
                    width: double.infinity,
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: MyPainter(
                            firstAnimation.value,
                            secondAnimation.value,
                            thirdAnimation.value,
                            fourthAnimation.value,
                          ),
                          child: SizedBox(
                            height: 150,
                            width: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: -30,
                          left: 0,
                          right: 0,
                          child: GestureDetector(
                            onPanStart: (details) {
                              windowManager.startDragging();
                            },
                            child: Image.asset(
                              'assets/Logo.png',
                              height: 120, // Ajuste conforme necessário
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: IconButton(
                            icon: Icon(Ionicons.close_outline,
                                color: Colors.white),
                            onPressed: () {
                              widget.trayManager.minimizeToTray();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
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
                                  style: TextStyle(
                                      fontSize: 24,
                                      color:
                                          const Color.fromARGB(255, 0, 0, 0)),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Água consumida: $_waterConsumed ml',
                                  style: TextStyle(
                                      fontSize: 24,
                                      color:
                                          const Color.fromARGB(255, 0, 0, 0)),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 32),
                                ElevatedButton(
                                  onPressed: () {
                                    _showWaterSelectionDialog();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(255, 246, 255, 252),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 16),
                                    textStyle: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  child: Text('Adicionar água'),
                                ),
                                SizedBox(height: 16),
                                if (_lastAddedAmount != null)
                                  ElevatedButton(
                                    onPressed: () async {
                                      await _addWater(_lastAddedAmount!);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromARGB(255, 246, 255, 252),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                      textStyle: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    child: Text('+ $_lastAddedAmount ml'),
                                  ),
                                SizedBox(height: 16),
                                TextButton(
                                  onPressed: (_lastAddedAmount != null)
                                      ? _removeLastWater
                                      : null,
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
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SettingsPage(onSettingsChanged: () {
                              _loadData();
                            })),
                  );
                },
                child: const Icon(Ionicons.settings_outline),
                tooltip: 'Configurações',
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
            ),
          ),
        ],
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

class MyPainter extends CustomPainter {
  final double firstValue;
  final double secondValue;
  final double thirdValue;
  final double fourthValue;

  MyPainter(
    this.firstValue,
    this.secondValue,
    this.thirdValue,
    this.fourthValue,
  );

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Color.fromARGB(255, 59, 161, 186).withOpacity(.8)
      ..style = PaintingStyle.fill;

    var path = Path()
      ..moveTo(0, size.height / firstValue)
      ..cubicTo(size.width * .4, size.height / secondValue, size.width * .7,
          size.height / thirdValue, size.width, size.height / fourthValue)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
