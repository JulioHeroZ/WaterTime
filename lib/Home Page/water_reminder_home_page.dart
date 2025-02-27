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
import 'package:ionicons/ionicons.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';
import '../Statistics Page/statistics_page.dart';
import '../widgets/animated_water_glass.dart';
import '../achievements/achievements_page.dart';
import 'package:auto_updater/auto_updater.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Profile Page/profile_page.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../Ranking Page/ranking_page.dart';

class WaterReminderHomePage extends StatefulWidget {
  final TrayManager? trayManager;
  final NotificationManager notificationManager;

  const WaterReminderHomePage({
    super.key,
    this.trayManager,
    required this.notificationManager,
  });

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
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
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

  final bool _testAchievementUnlocked = false;

  bool _isAddingWater = false;

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
        vsync: this, duration: const Duration(milliseconds: 1500));
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
        vsync: this, duration: const Duration(milliseconds: 1500));
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
        vsync: this, duration: const Duration(milliseconds: 1500));
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
        vsync: this, duration: const Duration(milliseconds: 1500));
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

    Timer(const Duration(seconds: 2), () {
      firstController.forward();
    });

    Timer(const Duration(milliseconds: 1600), () {
      secondController.forward();
    });

    Timer(const Duration(milliseconds: 800), () {
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
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
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
    try {
      final data = await DataManager.loadData();
      final lastAddition = await DataManager
          .getLastAddition(); // Novo método para pegar última adição

      setState(() {
        _waterConsumed = (data['waterConsumed'] ?? 0).toInt();
        _dailyGoal = (data['dailyGoal'] ?? 2000).toInt();
        _notificationInterval =
            (data['notificationInterval'] ?? 2.0).toDouble();
        _selectedDays =
            List<bool>.from(data['selectedDays'] ?? List.filled(7, true));
        _startTime = _parseTimeOfDay(data['startTime'] ?? '08:00');
        _endTime = _parseTimeOfDay(data['endTime'] ?? '22:00');
        _customAmounts = List<CustomAmount>.from(data['customAmounts'] ?? []);
        _history = List<Map<String, dynamic>>.from(data['history'] ?? []);

        // Atualiza o último valor adicionado
        _lastAddedAmount =
            lastAddition != null ? lastAddition['amount'] as int : null;
      });

      _checkAndResetIfNeeded();
    } catch (e) {
      print('Erro ao carregar dados: $e');
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
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

  void _scheduleNotifications() async {
    _notificationTimer?.cancel();
    _notificationTimer =
        Timer.periodic(const Duration(minutes: 1), (timer) async {
      final now = DateTime.now();
      const lastNotificationKey = 'last_notification_time';
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationTime = prefs.getString(lastNotificationKey);

      if (lastNotificationTime != null) {
        final lastTime = DateTime.parse(lastNotificationTime);
        final difference = now.difference(lastTime).inMinutes;

        // Só notifica se passou o intervalo definido
        if (difference < (_notificationInterval * 60).round()) {
          return;
        }
      }

      _checkAndSendNotification();
      prefs.setString(lastNotificationKey, now.toIso8601String());
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
      'lastAddedAmount': _lastAddedAmount,
    };
    await DataManager.saveData(data);
  }

  Future<void> _addWater(int amount) async {
    if (_isAddingWater) return;

    try {
      _isAddingWater = true;

      setState(() {
        int previousWaterConsumed = _waterConsumed;
        _waterConsumed += amount;
        _lastAddedAmount = amount;
        if (previousWaterConsumed < _dailyGoal &&
            _waterConsumed >= _dailyGoal) {
          widget.notificationManager.showNotification(
            'Meta Atingida!',
            'Parabéns! Você atingiu sua meta diária de $_dailyGoal ml de água.',
          );
        }
      });

      await Future.wait([
        DataManager.addWater(amount),
        _loadHistory(),
      ]);
    } catch (e) {
      print('Erro ao adicionar água: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar água: $e')),
      );
    } finally {
      _isAddingWater = false;
    }
  }

  Future<void> _removeLastWater() async {
    if (_isAddingWater) return;

    try {
      _isAddingWater = true;

      final int? lastAmount = await DataManager.removeLastAddition();
      if (lastAmount != null) {
        setState(() {
          _waterConsumed -= lastAmount;
          if (_waterConsumed < 0) _waterConsumed = 0;
        });

        await Future.wait([
          _loadData(),
          _loadHistory(),
        ]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma quantidade para remover')),
        );
      }
    } catch (e) {
      print('Erro ao remover água: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover água: $e')),
      );
    } finally {
      _isAddingWater = false;
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await DataManager.getHistory();
      setState(() {
        _history = history;
      });

      // Sincroniza com o Supabase se estiver logado
      if (await AuthService.isUserLoggedIn()) {
        await SyncService.syncUserData();
      }
    } catch (e) {
      print('Erro ao carregar histórico: $e');
    }
  }

  final SideMenuController _sideMenuController = SideMenuController();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: Row(
        children: [
          SideMenu(
            controller: _sideMenuController,
            style: SideMenuStyle(
              displayMode: SideMenuDisplayMode.auto,
              backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
              selectedColor: const Color.fromARGB(255, 95, 189, 212),
              unselectedIconColor: isDarkMode ? Colors.white70 : Colors.black54,
              unselectedTitleTextStyle: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              selectedTitleTextStyle: const TextStyle(
                color: Colors.white,
              ),
              selectedIconColor: Colors.white,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
              ),
            ),
            items: [
              SideMenuItem(
                title: 'Perfil',
                onTap: (index, _) async {
                  final isLoggedIn = await AuthService.isUserLoggedIn();
                  if (isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          trayManager: widget.trayManager,
                          onSettingsChanged: () {
                            _loadData();
                          },
                        ),
                      ),
                    );
                  } else {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(
                          trayManager: widget.trayManager,
                          notificationManager: widget.notificationManager,
                        ),
                      ),
                    );
                    if (result == true) {
                      await _loadData();
                      setState(() {});
                    }
                  }
                },
                icon: const Icon(Ionicons.person_circle_outline),
              ),
              SideMenuItem(
                title: 'Histórico',
                onTap: (index, _) async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoricoPage(
                        trayManager: widget.trayManager,
                      ),
                    ),
                  );
                  await _loadHistory(); // Recarrega o histórico após retornar
                  setState(() {});
                },
                icon: const Icon(Ionicons.calendar_outline),
              ),
              SideMenuItem(
                title: 'Estatísticas',
                onTap: (index, _) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StatisticsPage()),
                  );
                },
                icon: const Icon(Ionicons.stats_chart_outline),
              ),
              SideMenuItem(
                title: 'Conquistas',
                onTap: (index, _) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AchievementsPage()),
                  );
                },
                icon: const Icon(Icons.emoji_events_outlined),
              ),
              SideMenuItem(
                title: 'Ranking',
                onTap: (index, _) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RankingPage(trayManager: widget.trayManager),
                    ),
                  );
                },
                icon: const Icon(Icons.leaderboard_outlined),
              ),
              SideMenuItem(
                title: 'Verificar Atualizações',
                onTap: (index, _) async {
                  try {
                    await autoUpdater.checkForUpdates();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verificando atualizações...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao verificar atualizações: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.system_update_outlined),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80), // Espaço para o FAB
              child: Stack(
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
                          child: const SizedBox(
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
                            icon: const Icon(Ionicons.close_outline,
                                color: Colors.white),
                            onPressed: () {
                              widget.trayManager?.minimizeToTray();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                        top: 100), // Ajuste conforme necessário
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              _buildWaterDisplay(),
                              const SizedBox(height: 8),
                              Text(
                                'Meta diária: $_dailyGoal ml',
                                style: TextStyle(
                                  fontSize: 24,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Botão principal de adicionar água
                                  ElevatedButton(
                                    onPressed: _showWaterSelectionModal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 95, 189, 212),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                    ),
                                    child: const Text(
                                      'Adicionar água',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Botão de quantidade personalizada - SEMPRE visível
                                  ElevatedButton(
                                    onPressed: () async {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final customAmount =
                                          prefs.getInt('customWaterAmount') ??
                                              0;
                                      final amountToAdd = _lastAddedAmount == 0
                                          ? customAmount
                                          : _lastAddedAmount ?? 0;
                                      _addWater(amountToAdd);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 246, 255, 252),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                    ),
                                    child: FutureBuilder<SharedPreferences>(
                                      future: SharedPreferences.getInstance(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData)
                                          return const Text('+ 0 ml');
                                        final customAmount = snapshot.data!
                                                .getInt('customWaterAmount') ??
                                            0;
                                        final displayAmount =
                                            _lastAddedAmount == 0
                                                ? customAmount
                                                : _lastAddedAmount ?? 0;
                                        return Text('+ $displayAmount ml');
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 8),
                                  // Botão de remover
                                  TextButton(
                                    onPressed: _removeLastWater,
                                    child: const Text(
                                      'Remover quantidade',
                                      style: TextStyle(
                                          color: Color.fromARGB(
                                              255, 100, 100, 100)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
              builder: (context) => SettingsPage(
                onSettingsChanged: () {
                  _loadData();
                },
                trayManager: widget.trayManager,
              ),
            ),
          );
        },
        heroTag: 'settings',
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildWaterDisplay() {
    return Column(
      children: [
        AnimatedWaterGlass(
          progress: _waterConsumed / _dailyGoal,
          height: 150,
          width: 120,
        ),
        const SizedBox(height: 20),
        Text(
          '$_waterConsumed / $_dailyGoal ml',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showWaterSelectionModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();

            final customAmount = snapshot.data!.getInt('customWaterAmount');

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Selecione a quantidade\nde água',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botões de quantidade fixa
                  ...[250, 500, 600, 1000].map((amount) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _addWater(amount);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('$amount ml'),
                          ),
                        ),
                      )),
                  // Botão de quantidade personalizada salva
                  if (customAmount != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _addWater(customAmount);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('$customAmount ml'),
                        ),
                      ),
                    ),
                  // Botão para adicionar nova quantidade personalizada
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCustomAmountDialog();
                      },
                      child: const Text(
                        'Adicionar quantidade\npersonalizada',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCustomAmountDialog() async {
    final TextEditingController controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quantidade personalizada'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantidade em ml',
            suffixText: 'ml',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                // Salva a quantidade personalizada
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('customWaterAmount', amount);

                Navigator.pop(context);
                _addWater(amount);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'close') {
      widget.trayManager?.minimizeToTray();
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
      ..color = const Color.fromARGB(255, 59, 161, 186).withOpacity(.8)
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
