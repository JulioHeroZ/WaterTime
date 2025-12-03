import 'package:flutter/material.dart';
import '../data_manager.dart';
import 'package:provider/provider.dart';
import '../theme_manager.dart';
import '../tray_manager.dart';
import '../widgets/close_button_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notification_manager.dart';
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
  String _sex = 'Masculino';
  int _weight = 70;
  bool _isAutomaticGoal = false;
  final TextEditingController _dailyGoalController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _weightFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _weightFocusNode.addListener(() {
      if (!_weightFocusNode.hasFocus) {
        _onWeightEditingComplete();
      }
    });
  }

  void _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _notificationInterval = prefs.getDouble('defaultNotificationInterval') ?? 2.0;
      _sex = prefs.getString('defaultSex') ?? 'Masculino';
      _weight = prefs.getInt('defaultWeight') ?? 70;
      _isAutomaticGoal = prefs.getBool('defaultIsAutomaticGoal') ?? false;
      _selectedDays = List<bool>.from(
          (prefs.getStringList('defaultSelectedDays') ?? List.filled(7, 'true'))
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
      _weightController.text = _weight.toString();
    });

    // Load persisted data file and merge
    final data = await DataManager.loadData();
    if (!mounted) return;
    setState(() {
      _notificationInterval = (data['notificationInterval'] ?? _notificationInterval).toDouble();
      _sex = data['sex'] ?? _sex;
      _weight = data['weight'] ?? _weight;
      _isAutomaticGoal = data['isAutomaticGoal'] ?? _isAutomaticGoal;
      _selectedDays = List<bool>.from(data['selectedDays'] ?? _selectedDays);
      _startTime = TimeOfDay(
        hour: data['startTimeHour'] ?? _startTime.hour,
        minute: data['startTimeMinute'] ?? _startTime.minute,
      );
      _endTime = TimeOfDay(
        hour: data['endTimeHour'] ?? _endTime.hour,
        minute: data['endTimeMinute'] ?? _endTime.minute,
      );
      _dailyGoal = data['dailyGoal'] ?? _dailyGoal;
      _dailyGoalController.text = _dailyGoal.toString();
      _weightController.text = _weight.toString();
    });

    // Save defaults back to prefs
    await prefs.setDouble('defaultNotificationInterval', _notificationInterval);
    await prefs.setString('defaultSex', _sex);
    await prefs.setInt('defaultWeight', _weight);
    await prefs.setBool('defaultIsAutomaticGoal', _isAutomaticGoal);
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
    _weightController.dispose();
    _weightFocusNode.dispose();
    _dailyGoalController.dispose();
    super.dispose();
  }

  Future<void> _saveSettingsAutomatically() async {
    // Calculate daily goal when automatic is enabled
    final multiplier = _sex == 'Feminino' ? 30 : 35;
    final int calculatedGoal = _weight * multiplier;
    final int finalGoal = _isAutomaticGoal ? calculatedGoal : _dailyGoal;

    final data = {
      'notificationInterval': _notificationInterval,
      'selectedDays': _selectedDays,
      'startTimeHour': _startTime.hour,
      'startTimeMinute': _startTime.minute,
      'endTimeHour': _endTime.hour,
      'endTimeMinute': _endTime.minute,
      'dailyGoal': finalGoal,
      'sex': _sex,
      'weight': _weight,
      'isAutomaticGoal': _isAutomaticGoal,
    };

  // Note: do not overwrite the controller here to avoid interrupting user typing.
  // The controller is updated only when switching to automatic mode or when loading settings.

    await DataManager.saveData(data);
    widget.onSettingsChanged();

    // Reagenda as notificações com as novas configurações
    final notificationManager = NotificationManager();
    await notificationManager.scheduleNotifications(
      _notificationInterval,
      _startTime,
      _endTime,
      _selectedDays,
    );

    // Sincronização remota removida (Supabase)
  }

  void _onWeightEditingComplete() async {
    final text = _weightController.text.trim();
    final parsed = int.tryParse(text);
    if (parsed != null && parsed > 0) {
      setState(() {
        _weight = parsed;
      });
      if (_isAutomaticGoal) {
        final multiplier = _sex == 'Feminino' ? 30 : 35;
        final int calculatedGoal = _weight * multiplier;
        setState(() {
          _dailyGoal = calculatedGoal;
          _dailyGoalController.text = _dailyGoal.toString();
        });
      }
      await _saveSettingsAutomatically();
    }
  }

  String _formatIntervalLabel(double value) {
    // value is in hours, possibly fractional (e.g. 1.5)
    final totalMinutes = (value * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
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
                    actions: [
                      CustomCloseButton(trayManager: widget.trayManager),
                    ],
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
                            const SizedBox(height: 12),
                            
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
                              label: _formatIntervalLabel(_notificationInterval),
                              onChanged: (double value) {
                                setState(() {
                                  _notificationInterval = value;
                                });
                                _saveSettingsAutomatically();
                              },
                            ),
                            Text(
                              'Notificar a cada ${_formatIntervalLabel(_notificationInterval)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),

                            // Sex selection
                            const Text('Sexo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Masculino'),
                                    selected: _sex == 'Masculino',
                                    onSelected: (s) {
                                      if (!s) return; // Ignora deselecionar virtual
                                      setState(() {
                                        _sex = 'Masculino';
                                        if (_isAutomaticGoal) {
                                          final multiplier = _sex == 'Feminino' ? 30 : 35;
                                          final int calculatedGoal = _weight * multiplier;
                                          _dailyGoal = calculatedGoal;
                                          _dailyGoalController.text = _dailyGoal.toString();
                                        }
                                      });
                                      _saveSettingsAutomatically();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Feminino'),
                                    selected: _sex == 'Feminino',
                                    onSelected: (s) {
                                      if (!s) return;
                                      setState(() {
                                        _sex = 'Feminino';
                                        if (_isAutomaticGoal) {
                                          final multiplier = _sex == 'Feminino' ? 30 : 35;
                                          final int calculatedGoal = _weight * multiplier;
                                          _dailyGoal = calculatedGoal;
                                          _dailyGoalController.text = _dailyGoal.toString();
                                        }
                                      });
                                      _saveSettingsAutomatically();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Weight selector (editable text)
                            const Text('Peso (kg)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _weightController,
                              focusNode: _weightFocusNode,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                suffixText: 'kg',
                                labelText: 'Peso',
                              ),
                              onSubmitted: (v) => _onWeightEditingComplete(),
                            ),
                            const SizedBox(height: 8),
                            // Automatic / Manual goal
                            SwitchListTile(
                              title: const Text('Meta automática baseada no peso'),
                              subtitle: Text(_isAutomaticGoal
                                  ? 'Meta calculada automaticamente'
                                  : 'Defina manualmente sua meta'),
                              value: _isAutomaticGoal,
                              onChanged: (bool value) async {
                                setState(() => _isAutomaticGoal = value);
                                // If switched to automatic, calculate and update the controller
                                if (_isAutomaticGoal) {
                                  final multiplier = _sex == 'Feminino' ? 30 : 35;
                                  final int calculatedGoal = _weight * multiplier;
                                  setState(() {
                                    _dailyGoal = calculatedGoal;
                                    _dailyGoalController.text = _dailyGoal.toString();
                                  });
                                }
                                await _saveSettingsAutomatically();
                              },
                            ),
                            const Divider(),
                            const Text(
                              'Meta diária de água (ml)',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _dailyGoalController,
                              keyboardType: TextInputType.number,
                              enabled: !_isAutomaticGoal,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Meta diária (ml)',
                                helperText: _isAutomaticGoal
                                    ? 'Desative meta automática para editar'
                                    : null,
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
