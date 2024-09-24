import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_amount.dart';

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
        return {
          'waterConsumed': 0,
          'dailyGoal': 2000,
          'lastResetDay': DateTime.now().toIso8601String(),
          'history': [],
          'additions': [], // Inicializa o histórico de adições
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
        'additions': [], // Inicializa o histórico de adições
      };
    }
  }

  static Future<void> saveData(Map<String, dynamic> data) async {
    try {
      final file = await _localFile;
      final existingData = await loadData();
      final updatedData = {...existingData, ...data};
      await file.writeAsString(json.encode(updatedData));
    } catch (e) {
      print('Erro ao salvar dados: $e');
    }
  }

  // Método para adicionar água
  static Future<void> addWater(int amount) async {
    final data = await loadData();

    // Atualiza o consumo de água
    final int currentConsumed = data['waterConsumed'] ?? 0;
    final int updatedConsumed = currentConsumed + amount;
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

    // Limita o histórico aos últimos 30 dias
    if (history.length > 30) {
      history.removeAt(0);
    }

    data['history'] = history;

    // Atualiza o histórico de adições
    final additions = List<Map<String, dynamic>>.from(data['additions'] ?? []);
    additions.add({
      'timestamp': DateTime.now().toIso8601String(),
      'amount': amount,
    });
    data['additions'] = additions;

    await saveData(data);
  }

  // Método para remover a última adição
  static Future<int?> removeLastAddition() async {
    final data = await loadData();
    final additions = List<Map<String, dynamic>>.from(data['additions'] ?? []);
    if (additions.isNotEmpty) {
      final lastAddition = additions.removeLast();
      data['additions'] = additions;

      // Atualiza o consumo de água
      final int currentConsumed = data['waterConsumed'] ?? 0;
      final int updatedConsumed =
          currentConsumed - (lastAddition['amount'] as int);
      data['waterConsumed'] = updatedConsumed >= 0 ? updatedConsumed : 0;

      // Atualiza o histórico diário
      final DateTime additionDate = DateTime.parse(lastAddition['timestamp']);
      final String additionDay = additionDate.toIso8601String().split('T')[0];
      final history = List<Map<String, dynamic>>.from(data['history'] ?? []);
      final dayIndex =
          history.indexWhere((item) => item['date'] == additionDay);
      if (dayIndex != -1) {
        history[dayIndex]['amount'] -= lastAddition['amount'] as int;
        if (history[dayIndex]['amount'] <= 0) {
          history.removeAt(dayIndex);
        }
        data['history'] = history;
      }

      await saveData(data);
      return lastAddition['amount'] as int;
    }
    return null;
  }

  // Método para obter o histórico diário
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final data = await loadData();
    return List<Map<String, dynamic>>.from(data['history'] ?? []);
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
}

class HistoricoManager {
  static Future<List<Map<String, dynamic>>> obterHistorico() async {
    return await DataManager.getHistory();
  }
}
