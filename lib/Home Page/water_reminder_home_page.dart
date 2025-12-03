import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../History Page/history_page.dart';
import '../Settings Page/settings_page.dart';
import '../tray_manager.dart';
import '../data_manager.dart';
import '../notification_manager.dart';
import '../custom_amount.dart';
import 'package:ionicons/ionicons.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';
import '../Statistics Page/statistics_page.dart';
import '../widgets/animated_water_glass.dart';
import '../achievements/achievements_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  // Última quantidade selecionada pelo usuário para rápido reuso
  int? _lastSelectedAmount;
  // Quantidade personalizada padrão salva em SharedPreferences
  int _customQuickAmount = 0;

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

  bool _isAddingWater = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadData();
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
      final prefs = await SharedPreferences.getInstance();
      final savedLastSelected = prefs.getInt('last_selected_amount');
      final savedCustomQuick = prefs.getInt('customWaterAmount');

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
        // Mantém última quantidade selecionada independente de remoções
        _lastSelectedAmount = savedLastSelected;
        _customQuickAmount = savedCustomQuick ?? _customQuickAmount;
      });

      _checkAndResetIfNeeded();
      // (Re)agenda notificações usando o gerenciador centralizado (singleton)
      await widget.notificationManager.scheduleNotifications(
        _notificationInterval,
        _startTime,
        _endTime,
        _selectedDays,
      );
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

  // Removido: _saveCustomAmounts não utilizado

  

  // Removido: _isTimeInRange não utilizado nesta classe (controle movido para NotificationManager)

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

      // Atualiza última quantidade selecionada (persistente)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_selected_amount', amount);
        setState(() {
          _lastSelectedAmount = amount;
        });
      } catch (e) {
        print('Falha ao salvar última quantidade selecionada: $e');
      }

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
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: SideMenu(
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
                title: 'Configurações',
                onTap: (index, _) {
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
                icon: const Icon(Icons.settings),
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
            ],
          ),
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
                                      // Usa a última quantidade selecionada persistida;
                                      // se inexistente, usa a quantidade personalizada salva;
                                      // fallback para 0.
                                      final amountToAdd = _lastSelectedAmount ?? _customQuickAmount;
                                      if (amountToAdd > 0) {
                                        _addWater(amountToAdd);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Defina uma quantidade primeiro.')),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 246, 255, 252),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                    ),
                                    child: Text(
                                      '+ ${_lastSelectedAmount ?? _customQuickAmount} ml',
                                      style: TextStyle(
                                        color: const Color.fromARGB(
                                          255, 95, 189, 212),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),
                                  // Botão de remover
                                  TextButton(
                                    onPressed: _removeLastWater,
                                    child:  Text(
                                      'Remover quantidade',
                                      style: TextStyle(
                                        color: isDarkMode ? const Color.fromARGB(255, 255, 255, 255) : Color.fromARGB(
                                              255, 100, 100, 100)  ,),
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
      // FloatingActionButton de configurações removido porque o atalho para
      // Configurações foi adicionado no menu lateral.
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();

            final customAmount = snapshot.data!.getInt('customWaterAmount');
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador de arraste
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Adicionar Água',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Grid de opções
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ...[250, 500, 600, 1000]
                          .map((amount) => _buildAmountButton(
                                amount: amount,
                                onTap: () {
                                  Navigator.pop(context);
                                  _addWater(amount);
                                },
                              )),
                      if (customAmount != null)
                        _buildAmountButton(
                          amount: customAmount,
                          onTap: () {
                            Navigator.pop(context);
                            _addWater(customAmount);
                          },
                        ),
                      // Botão de quantidade personalizada
                      _buildCustomAmountButton(),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAmountButton(
      {required int amount, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 95, 189, 212).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color.fromARGB(255, 95, 189, 212),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$amount',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 95, 189, 212),
              ),
            ),
            const Text(
              'ml',
              style: TextStyle(
                color: Color.fromARGB(255, 95, 189, 212),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAmountButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showCustomAmountDialog();
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.add,
              size: 24,
              color: Colors.grey,
            ),
            Text(
              'Personalizado',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
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
                // Atualiza estado local
                setState(() {
                  _customQuickAmount = amount;
                  _lastSelectedAmount ??= amount; // se ainda não houver última seleção
                });

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
