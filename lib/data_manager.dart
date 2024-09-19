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
        return {};
      }
      final contents = await file.readAsString();
      return json.decode(contents);
    } catch (e) {
      print('Erro ao carregar dados: $e');
      return {};
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
