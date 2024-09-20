import 'package:flutter/material.dart';
import '../data_manager.dart';

class SettingsPage extends StatefulWidget {
  final Function() onSettingsChanged;

  SettingsPage({required this.onSettingsChanged});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _notificationInterval = 2.0; // Intervalo padrão de 2 horas
  List<bool> _selectedDays = List.filled(7, true);
  TimeOfDay _startTime = TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 22, minute: 0);
  int _dailyGoal = 2000; // Meta diária padrão
  TextEditingController _dailyGoalController =
      TextEditingController(text: '2000');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _dailyGoalController.dispose();
    super.dispose();
  }

  _loadSettings() async {
    final data = await DataManager.loadData();
    setState(() {
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
      _dailyGoal = data['dailyGoal'] ?? 2000;
      _dailyGoalController.text = _dailyGoal.toString();
    });
  }

  _saveSettings() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dias de notificação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildDaySelector(),
            SizedBox(height: 20),
            Text(
              'Intervalo de horário',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildTimeRangeSelector(),
            SizedBox(height: 20),
            Text(
              'Intervalo de notificação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
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
              },
            ),
            Text(
              'Notificar a cada ${_notificationInterval.toStringAsFixed(1)} horas',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Meta diária de água (ml)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _dailyGoalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Meta diária (ml)',
              ),
              onChanged: (value) {
                setState(() {
                  _dailyGoal = int.tryParse(value) ?? 2000;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _saveSettings();
                Navigator.pop(context);
              },
              child: Text('Salvar'),
            ),
          ],
        ),
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
            style: TextStyle(fontSize: 13),
          ),
          selected: _selectedDays[index],
          onSelected: (bool selected) {
            setState(() {
              _selectedDays[index] = selected;
            });
          },
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    }
  }
}
