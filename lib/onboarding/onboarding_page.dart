import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../data_manager.dart';
import '../Home Page/water_reminder_home_page.dart';
import '../notification_manager.dart';
import '../tray_manager.dart';

class OnboardingPage extends StatefulWidget {
  final TrayManager? trayManager;

  const OnboardingPage({Key? key, this.trayManager}) : super(key: key);

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  String _sex = 'Masculino';
  int _weight = 70;
  bool _isAutomaticGoal = true;
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _weightFocusNode = FocusNode();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);

  void _next() {
    _controller.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  void initState() {
    super.initState();
    _weightController.text = _weight.toString();
    _weightFocusNode.addListener(() {
      if (!_weightFocusNode.hasFocus) {
        _onWeightEditingComplete();
      }
    });
  }

  void _prev() {
    _controller.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _onWeightEditingComplete() {
    final text = _weightController.text.trim();
    final parsed = int.tryParse(text);
    if (parsed != null && parsed > 0) {
      setState(() {
        _weight = parsed;
      });
    }
  }

  Future<void> _finish() async {
    final dailyGoal = _sex == 'Feminino' ? (_weight * 30) : (_weight * 35);
    // Decide final daily goal depending on automatic/manual preference
    int finalDailyGoal;
    if (_isAutomaticGoal) {
      finalDailyGoal = dailyGoal;
    } else {
      final prefs = await SharedPreferences.getInstance();
      finalDailyGoal = prefs.getInt('defaultDailyGoal') ?? 2000;
    }

    await DataManager.saveData({
      'sex': _sex,
      'weight': _weight,
      'startTimeHour': _startTime.hour,
      'startTimeMinute': _startTime.minute,
      'endTimeHour': _endTime.hour,
      'endTimeMinute': _endTime.minute,
      'dailyGoal': finalDailyGoal,
      'isAutomaticGoal': _isAutomaticGoal,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);

    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => WaterReminderHomePage(
              trayManager: widget.trayManager,
              notificationManager: NotificationManager(),
            )));
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    return showTimePicker(context: context, initialTime: initial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildIntro(),
                _buildSex(),
                _buildWeight(),
                _buildTimes(),
                _buildSummary(),
              ],
            ),
            // Exit button on top-right
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: _exitApp,
                tooltip: 'Sair do aplicativo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exitApp() {
    // Fecha o app de forma apropriada para desktop e mobile
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        exit(0);
      } else {
        SystemNavigator.pop();
      }
    } catch (e) {
      // fallback
      SystemNavigator.pop();
    }
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const Text('Olá,\nsou seu companheiro de\nhidratação pessoal',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          const Text(
            'Para fornecer consultoria personalizada sobre hidratação, preciso de alguns dados básicos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: _next,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text('VAMOS'),
            ),
            style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
          )
        ],
      ),
    );
  }

  Widget _buildSex() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Seu sexo', style: TextStyle(fontSize: 22)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _sexOption('Masculino', Icons.male),
            _sexOption('Feminino', Icons.female),
          ],
        ),
        const SizedBox(height: 36),
        _navigationButtons(),
      ],
    );
  }

  Widget _sexOption(String label, IconData icon) {
    final selected = _sex == label;
    return GestureDetector(
      onTap: () => setState(() => _sex = label),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: selected ? Colors.blueAccent : Colors.grey[200],
            child: Icon(icon, size: 36, color: selected ? Colors.white : Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: selected ? Colors.blue : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWeight() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Seu peso', style: TextStyle(fontSize: 22)),
        const SizedBox(height: 24),
        Text('$_weight kg', style: const TextStyle(fontSize: 32, color: Colors.blue)),
        const SizedBox(height: 8),
        SizedBox(
          width: 350, // largura fixa para o campo de peso
          child: TextField(
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
        ),
        const SizedBox(height: 12),
        if (_isAutomaticGoal)
          Text('Meta calculada: ${(_sex == 'Feminino' ? (_weight * 30) : (_weight * 35))} ml'),
        const SizedBox(height: 12),
        // Option to choose automatic or manual goal
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Meta automática'),
            Switch(
              value: _isAutomaticGoal,
              onChanged: (v) => setState(() => _isAutomaticGoal = v),
            ),

          ],
        ),
        const SizedBox(height: 24),
        _navigationButtons(),
      ],
    );
  }

  Widget _buildTimes() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Hora de acordar', style: TextStyle(fontSize: 22)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            final t = await _pickTime(_startTime);
            if (t != null) setState(() => _startTime = t);
          },
          child: Text(_startTime.format(context), style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(height: 24),
        const Text('Hora de dormir', style: TextStyle(fontSize: 22)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            final t = await _pickTime(_endTime);
            if (t != null) setState(() => _endTime = t);
          },
          child: Text(_endTime.format(context), style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(height: 24),
        _navigationButtons(),
      ],
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Pronto!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Sexo: $_sex'),
          Text('Peso: $_weight kg'),
          Text('Acordar: ${_startTime.format(context)}'),
          Text('Dormir: ${_endTime.format(context)}'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _finish,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text('Concluir'),
            ),
          )
        ],
      ),
    );
  }

  Widget _navigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: _prev, icon: const Icon(Icons.arrow_back)),
        IconButton(onPressed: _next, icon: const Icon(Icons.arrow_forward)),
      ],
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }
}

// Nota: usamos uma nova instância de NotificationManager ao navegar para a Home.
