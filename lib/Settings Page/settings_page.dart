import 'package:flutter/material.dart';
import '../data_manager.dart';
import '../services/sync_service.dart';
import 'package:provider/provider.dart';
import '../theme_manager.dart';
import '../tray_manager.dart';
import '../widgets/close_button_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme_manager.dart';

class SettingsPage extends StatefulWidget {
  final Function() onSettingsChanged;
  final TrayManager? trayManager;

  const SettingsPage(
      {super.key, required this.onSettingsChanged, this.trayManager});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _notificationInterval = 2.0;
  List<bool> _selectedDays = List.filled(7, true);
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  int _dailyGoal = 2000;
  final TextEditingController _dailyGoalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;

      setState(() {
        _notificationInterval =
            prefs.getDouble('defaultNotificationInterval') ?? 2.0;
        _selectedDays = List<bool>.from(
            (prefs.getStringList('defaultSelectedDays') ??
                    List.filled(7, 'true'))
                .map((e) => e == 'true'));
        _startTime = TimeOfDay(
          hour: prefs.getInt('defaultStartTimeHour') ?? 8,
          minute: prefs.getInt('defaultStartTimeMinute') ?? 0,
        );
        _endTime = TimeOfDay(
          hour: prefs.getInt('defaultEndTimeHour') ?? 22,
          minute: prefs.getInt('defaultEndTimeMinute') ?? 0,
        );
        _dailyGoal = prefs.getInt('defaultDailyGoal') ?? 2000;
        _dailyGoalController.text = _dailyGoal.toString();
      });

      _loadSettings();
    });
  }

  _loadSettings() async {
    final data = await DataManager.loadData();
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _notificationInterval = (data['notificationInterval'] ?? 2.0).toDouble();
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
      _dailyGoal = data['dailyGoal'] ?? 2000;
      _dailyGoalController.text = _dailyGoal.toString();
    });

    // Salva os novos valores padrão
    await prefs.setDouble('defaultNotificationInterval', _notificationInterval);
    await prefs.setStringList(
        'defaultSelectedDays', _selectedDays.map((e) => e.toString()).toList());
    await prefs.setInt('defaultStartTimeHour', _startTime.hour);
    await prefs.setInt('defaultStartTimeMinute', _startTime.minute);
    await prefs.setInt('defaultEndTimeHour', _endTime.hour);
    await prefs.setInt('defaultEndTimeMinute', _endTime.minute);
    await prefs.setInt('defaultDailyGoal', _dailyGoal);
  }

  @override
  void dispose() {
    _dailyGoalController.dispose();
    super.dispose();
  }

  Future<void> _saveSettingsAutomatically() async {
    final data = {
      'notificationInterval': _notificationInterval,
      'selectedDays': _selectedDays,
      'startTimeHour': _startTime.hour,
      'startTimeMinute': _startTime.minute,
      'endTimeHour': _endTime.hour,
      'endTimeMinute': _endTime.minute,
      'dailyGoal': _dailyGoal,
    };

    await DataManager.saveData(data);
    widget.onSettingsChanged();

    // Sincroniza com Supabase
    if (await AuthService.isUserLoggedIn()) {
      await SyncService.syncUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              Column(
                children: [
                  AppBar(
                    title: const Text(
                      'Configurações',
                      style: TextStyle(color: Colors.white),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    iconTheme: const IconThemeData(color: Colors.white),
                    backgroundColor: const Color.fromARGB(255, 95, 189, 212),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Switch de tema
                            Consumer<ThemeManager>(
                              builder: (context, themeManager, child) {
                                return SwitchListTile(
                                  title: const Text('Tema escuro'),
                                  value: themeManager.isDarkMode,
                                  onChanged: (bool value) {
                                    themeManager.toggleTheme();
                                  },
                                );
                              },
                            ),
                            const Divider(),
                            const Text(
                              'Dias de notificação',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            _buildDaySelector(),
                            const SizedBox(height: 20),
                            const Text(
                              'Intervalo de horário',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            _buildTimeRangeSelector(),
                            const SizedBox(height: 20),
                            const Text(
                              'Intervalo de notificação',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Slider(
                              value: _notificationInterval,
                              min: 0.5,
                              max: 6,
                              divisions: 11,
                              label: _notificationInterval.toString(),
                              onChanged: (double value) {
                                setState(() {
                                  _notificationInterval = value;
                                });
                                _saveSettingsAutomatically();
                              },
                            ),
                            Text(
                              'Notificar a cada ${_notificationInterval.toStringAsFixed(1)} horas',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Meta diária de água (ml)',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _dailyGoalController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Meta diária (ml)',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _dailyGoal = int.tryParse(value) ?? 2000;
                                });
                                _saveSettingsAutomatically();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              CustomCloseButton(trayManager: widget.trayManager),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(7, (index) {
        return FilterChip(
          label: Text(
            days[index],
            style: const TextStyle(fontSize: 13),
          ),
          selected: _selectedDays[index],
          onSelected: (bool selected) {
            setState(() {
              _selectedDays[index] = selected;
            });
            _saveSettingsAutomatically();
          },
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => _selectTime(context, true),
            child: Text('Início: ${_startTime.format(context)}'),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () => _selectTime(context, false),
            child: Text('Fim: ${_endTime.format(context)}'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
      _saveSettingsAutomatically();
    }
  }
}
