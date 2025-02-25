import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_amount.dart';
import 'achievements/achievement_manager.dart';
import 'sound_manager.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';

class DataManager {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final waterTimeDir = Directory('${directory.path}/WaterTime');
    if (!await waterTimeDir.exists()) {
      await waterTimeDir.create(recursive: true);
    }
    return waterTimeDir.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/water_data.json');
  }

  static Future<Map<String, dynamic>> loadData() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        // Carrega as últimas configurações salvas ou usa valores padrão
        final prefs = await SharedPreferences.getInstance();
        return {
          'waterConsumed': 0,
          'dailyGoal': prefs.getInt('defaultDailyGoal') ?? 2000,
          'lastResetDay': DateTime.now().toIso8601String(),
          'history': [],
          'additions': [],
          'sex': prefs.getString('defaultSex') ?? 'Masculino',
          'weight': prefs.getInt('defaultWeight') ?? 70,
          'isAutomaticGoal': prefs.getBool('defaultIsAutomaticGoal') ?? false,
        };
      }
      final contents = await file.readAsString();
      return json.decode(contents);
    } catch (e) {
      print('Erro ao carregar dados: $e');
      return {
        'waterConsumed': 0,
        'dailyGoal': 2000,
        'lastResetDay': DateTime.now().toIso8601String(),
        'history': [],
        'additions': [],
        'sex': 'Masculino',
        'weight': 70,
        'isAutomaticGoal': false,
      };
    }
  }

  static Future<void> saveData(Map<String, dynamic> data) async {
    try {
      final file = await _localFile;
      final existingData = await loadData();
      final updatedData = {...existingData, ...data};
      await file.writeAsString(json.encode(updatedData));

      // Salva os valores padrão nas SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (data.containsKey('dailyGoal')) {
        await prefs.setInt('defaultDailyGoal', data['dailyGoal']);
      }
      if (data.containsKey('sex')) {
        await prefs.setString('defaultSex', data['sex']);
      }
      if (data.containsKey('weight')) {
        await prefs.setInt('defaultWeight', data['weight']);
      }
      if (data.containsKey('isAutomaticGoal')) {
        await prefs.setBool('defaultIsAutomaticGoal', data['isAutomaticGoal']);
      }
    } catch (e) {
      print('Erro ao salvar dados: $e');
    }
  }

  // Método para adicionar água
  static Future<void> addWater(int amount) async {
    try {
      final data = await loadData();
      final currentConsumed = data['waterConsumed'] ?? 0;
      final dailyGoal = data['dailyGoal'] ?? 2000;
      final updatedConsumed = currentConsumed + amount;

      // Atualiza o consumo de água
      data['waterConsumed'] = updatedConsumed;

      // Atualiza o histórico diário
      final history = List<Map<String, dynamic>>.from(data['history'] ?? []);
      final today = DateTime.now().toIso8601String().split('T')[0];

      final todayIndex = history.indexWhere((item) => item['date'] == today);
      if (todayIndex != -1) {
        history[todayIndex]['amount'] += amount;
      } else {
        history.add({
          'date': today,
          'amount': amount,
        });
      }

      // Salva o histórico atualizado
      data['history'] = history;
      await saveData(data);

      // Toca o som e verifica conquistas
      if (amount > 0) {
        await SoundManager.playSound('add_water');
        await AchievementManager.checkAchievement('first_water');
      }

      if (currentConsumed < dailyGoal && updatedConsumed >= dailyGoal) {
        await SoundManager.playSound('goal_complete');
        await AchievementManager.checkAchievement('daily_goal');
      }

      if (await AuthService.isUserLoggedIn()) {
        await SyncService.syncUserData();
      }
    } catch (e) {
      print('Erro ao adicionar água: $e');
      throw Exception('Falha ao adicionar água: $e');
    }
  }

  // Método para remover a última adição
  static Future<int?> removeLastAddition() async {
    try {
      final data = await loadData();
      final additions =
          List<Map<String, dynamic>>.from(data['additions'] ?? []);
      final history = List<Map<String, dynamic>>.from(data['history'] ?? []);

      if (additions.isNotEmpty) {
        final lastAddition = additions.removeLast();
        final amount = lastAddition['amount'] as int;
        final today = DateTime.now().toIso8601String().split('T')[0];

        // Atualiza o histórico
        final todayIndex = history.indexWhere((item) => item['date'] == today);
        if (todayIndex != -1) {
          history[todayIndex]['amount'] =
              (history[todayIndex]['amount'] as int) - amount;

          // Remove o registro do dia se a quantidade for zero
          if (history[todayIndex]['amount'] <= 0) {
            history.removeAt(todayIndex);
          }
        }

        // Atualiza os dados
        data['additions'] = additions;
        data['history'] = history;
        await saveData(data);

        if (await AuthService.isUserLoggedIn()) {
          await SyncService.syncUserData();
        }

        return amount;
      }
      return null;
    } catch (e) {
      print('Erro ao remover última adição: $e');
      return null;
    }
  }

  // Método para obter o histórico diário
  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final data = await loadData();
      if (data['history'] == null) {
        return [];
      }

      // Converte e ordena o histórico por data (mais recente primeiro)
      final history = List<Map<String, dynamic>>.from(data['history']);
      history.sort((a, b) => b['date'].compareTo(a['date']));

      return history;
    } catch (e) {
      print('Erro ao carregar histórico: $e');
      return [];
    }
  }

  // Método para obter o histórico de adições
  static Future<List<Map<String, dynamic>>> getAdditions() async {
    final data = await loadData();
    return List<Map<String, dynamic>>.from(data['additions'] ?? []);
  }

  static Future<List<CustomAmount>> loadCustomAmounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? customAmountsJson = prefs.getString('customAmounts');
    if (customAmountsJson != null) {
      final List<dynamic> decoded = jsonDecode(customAmountsJson);
      return decoded.map((item) => CustomAmount.fromJson(item)).toList();
    }
    return [];
  }

  static Future<void> saveCustomAmounts(
      List<CustomAmount> customAmounts) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded =
        jsonEncode(customAmounts.map((e) => e.toJson()).toList());
    await prefs.setString('customAmounts', encoded);
  }

  static Future<Map<String, dynamic>?> getLastAddition() async {
    try {
      final data = await loadData();
      final additions =
          List<Map<String, dynamic>>.from(data['additions'] ?? []);

      if (additions.isNotEmpty) {
        return additions.last;
      }
      return null;
    } catch (e) {
      print('Erro ao obter última adição: $e');
      return null;
    }
  }
}

class HistoricoManager {
  static Future<List<Map<String, dynamic>>> obterHistorico() async {
    return await DataManager.getHistory();
  }
}
