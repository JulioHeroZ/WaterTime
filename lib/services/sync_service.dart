// import 'package:supabase_flutter/supabase_flutter.dart';
import '../data_manager.dart';
import '../achievements/achievement_manager.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
// import '../services/ranking_service.dart'; // Ranking desativado

class SyncService {
  // static final supabase = Supabase.instance.client;
  static Timer? _syncTimer;

  // Removido: sincronização com Supabase
  static Future<void> syncUserData() async {
    // Função mantida para compatibilidade, mas não faz nada
    return;
  }

  // Removido: sincronização de configurações com Supabase
  static Future<void> _syncSettings(String userId) async {
    return;
  }

  // Removido: sincronização de histórico com Supabase
  static Future<void> _syncWaterHistory(String userId) async {
    return;
  }

  // Removido: sincronização de conquistas com Supabase
  static Future<void> _syncAchievements(String userId) async {
    return;
  }

  // Removido: carregamento de dados do Supabase
  static Future<void> loadFromServer() async {
    return;
  }

  // Método para sincronização completa
  // Removido: sincronização completa com Supabase
  static Future<void> syncAllData() async {
    return;
  }

  // Método de ranking removido/comentado. Mantido aqui como referência para
  // reimplementação futura.
  /*
  static Future<void> _updateDailyRanking(String userId, int amount) async {
    try {
    // final userDataResult = await supabase
    //     .from('profiles')
    //     .select('name')
    //     .eq('id', userId)
    //     .limit(1);

      if (userDataResult.isEmpty) {
        print('Usuário não encontrado');
        return;
      }

      final userData = userDataResult.first;
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Executa uma transação para garantir atomicidade
      // await supabase.rpc('update_ranking', params: {
      //   'p_user_id': userId,
      //   'p_display_name': userData['name'],
      //   'p_daily_score': amount,
      //   'p_created_at': today,
      //   'p_last_update': DateTime.now().toIso8601String(),
      // });
    } catch (e) {
      print('Erro ao atualizar ranking diário: $e');
    }
  }
  */

  // Iniciar sincronização periódica (chamado ao iniciar o app)
  // Removido: sincronização periódica
  static void startPeriodicSync({Duration interval = const Duration(minutes: 30)}) {
    // Não faz nada
  }

  // Parar sincronização periódica (chamado ao fazer logout)
  // Removido: parada de sincronização periódica
  static void stopPeriodicSync() {
    // Não faz nada
  }
}
