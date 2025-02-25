import 'package:flutter/material.dart';
import '../Settings Page/settings_page.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../tray_manager.dart';
import '../widgets/close_button_widget.dart';
import '../data_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final TrayManager? trayManager;
  final Function()? onSettingsChanged;

  const ProfilePage({
    super.key,
    this.trayManager,
    this.onSettingsChanged,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _photoUrl = '';
  String _name = '';
  String _email = '';
  bool _isLoading = true;
  String _selectedSex = 'Masculino';
  int _selectedWeight = 70;
  bool _isAutomaticGoal = false;
  int _dailyGoal = 2000;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    // Carrega dados síncronos primeiro
    final prefs = SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;

      setState(() {
        _photoUrl = prefs.getString('defaultPhotoUrl') ?? '';
        _name = prefs.getString('defaultName') ?? '';
        _email = prefs.getString('defaultEmail') ?? '';
        _selectedSex = prefs.getString('defaultSex') ?? 'Masculino';
        _selectedWeight = prefs.getInt('defaultWeight') ?? 70;
        _isAutomaticGoal = prefs.getBool('defaultIsAutomaticGoal') ?? false;
        _dailyGoal = prefs.getInt('defaultDailyGoal') ??
            _calculateWaterGoal(_selectedWeight);
      });

      // Depois carrega dados do servidor
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await UserService.getUserData();
      final localData = await DataManager.loadData();

      if (userData != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('defaultName', userData['name'] ?? '');
        await prefs.setString('defaultEmail', userData['email'] ?? '');
        await prefs.setString('defaultPhotoUrl', userData['avatar_url'] ?? '');
        await prefs.setBool(
            'defaultIsAutomaticGoal', localData['isAutomaticGoal'] ?? false);
        await prefs.setInt('defaultDailyGoal',
            localData['dailyGoal'] ?? _calculateWaterGoal(_selectedWeight));

        setState(() {
          _name = userData['name'] ?? '';
          _email = userData['email'] ?? '';
          _photoUrl = userData['avatar_url'] ?? '';
          _selectedSex = localData['sex'] ?? userData['sex'] ?? 'Masculino';
          _selectedWeight = localData['weight'] ?? userData['weight'] ?? 70;
          _isAutomaticGoal = localData['isAutomaticGoal'] ?? false;
          _dailyGoal =
              localData['dailyGoal'] ?? _calculateWaterGoal(_selectedWeight);
        });
      }
    } catch (e) {
      print('Erro ao carregar dados do usuário: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _calculateWaterGoal(int weight) {
    // Mulheres: 30ml por kg
    // Homens: 35ml por kg
    final multiplier = _selectedSex == 'Feminino' ? 30 : 35;
    return weight * multiplier; // ml por dia
  }

  Future<void> _updateUserPreferences(String sex, int weight) async {
    try {
      final int calculatedGoal = _calculateWaterGoal(weight);
      final int finalGoal = _isAutomaticGoal ? calculatedGoal : _dailyGoal;

      // Salva todas as configurações necessárias
      final settingsData = {
        'sex': sex,
        'weight': weight,
        'isAutomaticGoal': _isAutomaticGoal,
        'dailyGoal': finalGoal,
        'lastResetDay': DateTime.now().toIso8601String(),
      };

      // Salva localmente
      await DataManager.saveData(settingsData);

      // Salva no Supabase se estiver logado
      if (await AuthService.isUserLoggedIn()) {
        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser!.id;

        await supabase.from('user_settings').upsert({
          'id': userId,
          'sex': sex,
          'weight': weight,
          'is_automatic_goal': _isAutomaticGoal,
          'daily_goal': finalGoal,
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Sincroniza os dados
        await SyncService.syncUserData();
      }

      // Atualiza a HomePage
      widget.onSettingsChanged?.call();
    } catch (e) {
      print('Erro ao atualizar preferências: $e');
      if (e is PostgrestException) {
        print('Detalhes do erro: ${e.details}');
        print('Código: ${e.code}');
        print('Mensagem: ${e.message}');
      }
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
                  Container(
                    color: const Color.fromARGB(255, 95, 189, 212),
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              'Você',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _photoUrl.isNotEmpty
                              ? NetworkImage(_photoUrl)
                              : null,
                          child: _photoUrl.isEmpty
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24),
                        ),
                        Text(
                          _email,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: const Text('Sexo'),
                          trailing: DropdownButton<String>(
                            value: _selectedSex,
                            onChanged: (String? newValue) async {
                              if (newValue != null) {
                                setState(() => _selectedSex = newValue);
                                await _updateUserPreferences(
                                    _selectedSex, _selectedWeight);
                              }
                            },
                            items: <String>['Masculino', 'Feminino']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.monitor_weight_outlined),
                          title: const Text('Peso'),
                          trailing: SizedBox(
                            width: 100,
                            child: DropdownButton<int>(
                              value: _selectedWeight,
                              onChanged: (int? newValue) async {
                                if (newValue != null) {
                                  setState(() => _selectedWeight = newValue);
                                  await _updateUserPreferences(
                                      _selectedSex, _selectedWeight);
                                }
                              },
                              items: List<int>.generate(200, (i) => i + 1)
                                  .map<DropdownMenuItem<int>>((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('$value kg'),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Meta automática baseada no peso'),
                          subtitle: Text(_isAutomaticGoal
                              ? 'Meta atual: ${_calculateWaterGoal(_selectedWeight)} ml'
                              : 'Meta atual: $_dailyGoal ml'),
                          value: _isAutomaticGoal,
                          onChanged: (bool value) async {
                            setState(() => _isAutomaticGoal = value);
                            await _updateUserPreferences(
                                _selectedSex, _selectedWeight);
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.people_outline),
                          title: const Text('Contatos'),
                          onTap: () {
                            // Implementar navegação para tela de contatos
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('Configurações'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsPage(
                                  onSettingsChanged:
                                      widget.onSettingsChanged ?? () {},
                                  trayManager: widget.trayManager,
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.exit_to_app, color: Colors.red),
                          title:
                              Text('Sair', style: TextStyle(color: Colors.red)),
                          onTap: () async {
                            await AuthService.logout();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
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
}
