import 'package:supabase_flutter/supabase_flutter.dart';
import '../data_manager.dart';
import '../achievements/achievement_manager.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ranking_service.dart';

class SyncService {
  static final supabase = Supabase.instance.client;
  static Timer? _syncTimer;

  static Future<void> syncUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Sincronizar configurações
    await _syncSettings(user.id);

    // Sincronizar histórico de água
    await _syncWaterHistory(user.id);

    // Sincronizar conquistas
    await _syncAchievements(user.id);
  }

  static Future<void> _syncSettings(String userId) async {
    final localData = await DataManager.loadData();

    final settingsData = {
      'id': userId,
      'sex': localData['sex'] ?? 'Masculino',
      'weight': localData['weight'] ?? 70,
      'notification_interval':
          (localData['notificationInterval'] ?? 2.0).toDouble(),
      'selected_days':
          List<bool>.from(localData['selectedDays'] ?? List.filled(7, true)),
      'start_time': localData['startTime'] ?? '08:00',
      'end_time': localData['endTime'] ?? '22:00',
      'daily_goal': (localData['dailyGoal'] ?? 2000).toInt(),
      'custom_amounts': List<dynamic>.from(localData['customAmounts'] ?? []),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('user_settings').upsert(settingsData);
    } catch (e) {
      print('Erro ao sincronizar configurações: $e');
      throw Exception('Falha ao sincronizar configurações: $e');
    }
  }

  static Future<void> _syncWaterHistory(String userId) async {
    final history = await DataManager.getHistory();

    try {
      // Primeiro, limpa o histórico existente
      await supabase.from('daily_consumption').delete().eq('user_id', userId);

      // Depois, insere apenas os registros válidos (com quantidade > 0)
      for (var entry in history) {
        if (entry['amount'] > 0) {
          final String uniqueId = const Uuid().v4();
          await supabase.from('daily_consumption').insert({
            'id': uniqueId,
            'user_id': userId,
            'date': entry['date'],
            'amount': entry['amount'].toInt(),
          });
        }
      }
    } catch (e) {
      print('Erro ao sincronizar histórico: $e');
      throw Exception('Falha ao sincronizar histórico: $e');
    }
  }

  static Future<void> _syncAchievements(String userId) async {
    try {
      final unlockedAchievements =
          await AchievementManager.getUnlockedAchievements();

      // Primeiro, limpa as conquistas existentes
      await supabase.from('user_achievements').delete().eq('user_id', userId);

      // Depois, insere todas as conquistas desbloqueadas
      for (var achievement in unlockedAchievements) {
        await supabase.from('user_achievements').insert({
          'id': const Uuid().v4(),
          'user_id': userId,
          'achievement_id': achievement.id,
          'unlocked_at': achievement.unlockedAt!.toIso8601String(),
        });
      }

      print('Sincronizadas ${unlockedAchievements.length} conquistas');
    } catch (e) {
      print('Erro ao sincronizar conquistas: $e');
      throw Exception('Falha ao sincronizar conquistas: $e');
    }
  }

  static Future<void> loadFromServer() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Carregar configurações
      final settings = await supabase
          .from('user_settings')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (settings != null) {
        await DataManager.saveData({
          'notificationInterval': settings['notification_interval'],
          'selectedDays': settings['selected_days'],
          'startTime': settings['start_time'],
          'endTime': settings['end_time'],
          'dailyGoal': settings['daily_goal'],
          'customAmounts': settings['custom_amounts'],
        });
      }

      // Carregar histórico
      final history = await supabase
          .from('daily_consumption')
          .select()
          .eq('user_id', user.id);

      if (history != null) {
        await DataManager.saveData({'history': history});
      }
    } catch (e) {
      print('Erro ao carregar dados do servidor: $e');
    }
  }

  // Método para sincronização completa
  static Future<void> syncAllData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final localData = await DataManager.loadData();
      final history =
          List<Map<String, dynamic>>.from(localData['history'] ?? []);
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Pega o valor atual do dia
      final todayAmount = history.firstWhere(
        (item) => item['date'] == today,
        orElse: () => {'amount': localData['waterConsumed'] ?? 0},
      )['amount'] as int;

      // Busca o registro do dia
      final existingRecord = await supabase
          .from('daily_consumption')
          .select()
          .eq('user_id', user.id)
          .eq('date', today)
          .maybeSingle();

      if (existingRecord != null) {
        // Atualiza o registro existente
        await supabase
            .from('daily_consumption')
            .update({'amount': todayAmount}).eq('id', existingRecord['id']);
      } else {
        // Cria um novo registro com UUID válido
        await supabase.from('daily_consumption').insert({
          'id': const Uuid().v4(),
          'user_id': user.id,
          'date': today,
          'amount': todayAmount,
        });
      }

      // Atualiza o ranking diário
      await _updateDailyRanking(user.id, todayAmount);
    } catch (e) {
      print('Erro na sincronização completa: $e');
    }
  }

  // Método atualizado para usar a tabela correta do ranking
  static Future<void> _updateDailyRanking(String userId, int amount) async {
    try {
      final userDataResult = await supabase
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .limit(1);

      if (userDataResult.isEmpty) {
        print('Usuário não encontrado');
        return;
      }

      final userData = userDataResult.first;
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Executa uma transação para garantir atomicidade
      await supabase.rpc('update_ranking', params: {
        'p_user_id': userId,
        'p_display_name': userData['name'],
        'p_daily_score': amount,
        'p_created_at': today,
        'p_last_update': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erro ao atualizar ranking diário: $e');
    }
  }

  // Iniciar sincronização periódica (chamado ao iniciar o app)
  static void startPeriodicSync(
      {Duration interval = const Duration(minutes: 30)}) {
    _syncTimer?.cancel(); // Cancela timer existente se houver

    _syncTimer = Timer.periodic(interval, (timer) async {
      final user = supabase.auth.currentUser;
      if (user != null) {
        try {
          await syncAllData();
        } catch (e) {
          print('Erro na sincronização periódica: $e');
        }
      }
    });
  }

  // Parar sincronização periódica (chamado ao fazer logout)
  static void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
