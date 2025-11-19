/*
// import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data_manager.dart';

class RankingService {
  // static final supabase = Supabase.instance.client;

  static Future<void> updateScore(int waterAmount) async {
    try {
  // final user = supabase.auth.currentUser;
      if (user == null) return;

    // final userData = await supabase
    //     .from('profiles')
    //     .select('name')
    //     .eq('id', user.id)
    //     .single();

      final today = DateTime.now();

      // Atualiza apenas o ranking diário em tempo real
      await _updateDailyRanking(user.id, userData['name'], waterAmount);

      // Verifica se é meia-noite (com margem de 5 minutos)
      if (_isMidnight()) {
        await _updatePeriodicalRankings(user.id, userData['name']);
      }
    } catch (e) {
      print('Erro ao atualizar ranking: $e');
    }
  }

  // Verifica se é meia-noite (com margem de 5 minutos)
  static bool _isMidnight() {
    final now = DateTime.now();
    return now.hour == 0 && now.minute < 5;
  }

  // Atualiza rankings mensal e anual na virada do dia
  static Future<void> _updatePeriodicalRankings(
      String userId, String displayName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString('last_ranking_update');
      final today = DateTime.now();

      // Se já atualizou hoje, não atualiza novamente
      if (lastUpdateStr != null) {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        if (lastUpdate.day == today.day &&
            lastUpdate.month == today.month &&
            lastUpdate.year == today.year) {
          return;
        }
      }

      // Busca o consumo do dia anterior
      final yesterday = today.subtract(const Duration(days: 1));
      final dailyHistory = await DataManager.getHistory();
      final yesterdayAmount = dailyHistory
          .where((item) =>
              item['date'] == yesterday.toIso8601String().split('T')[0])
          .fold(0, (sum, item) => sum + (item['amount'] as int));

      if (yesterdayAmount > 0) {
        // Atualiza ranking mensal
  // await supabase.from('monthly_rankings').upsert({
          'user_id': userId,
          'display_name': displayName,
          'monthly_score': yesterdayAmount,
          'month': yesterday.month,
          'year': yesterday.year,
          'last_update': yesterday.toIso8601String(),
        });

        // Atualiza ranking anual
  // await supabase.from('yearly_rankings').upsert({
          'user_id': userId,
          'display_name': displayName,
          'yearly_score': yesterdayAmount,
          'year': yesterday.year,
          'last_update': yesterday.toIso8601String(),
        });

        // Atualiza a data da última atualização
        await prefs.setString('last_ranking_update', today.toIso8601String());
      }
    } catch (e) {
      print('Erro ao atualizar rankings periódicos: $e');
    }
  }

  static Future<void> _updateDailyRanking(
      String userId, String displayName, int amount) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

  // await supabase.from('rankings').upsert({
      'user_id': userId,
      'display_name': displayName,
      'daily_score': amount,
      'last_update': today,
    });
  }

  // Métodos de stream para obter os rankings
  static Stream<List<Map<String, dynamic>>> getDailyRankings() {
  // return supabase.from('rankings').stream(primaryKey: ['user_id']).map(
        (data) => List<Map<String, dynamic>>.from(data)
          ..sort((a, b) =>
              (b['daily_score'] as int).compareTo(a['daily_score'] as int))
          ..take(10));
  }

  static Stream<List<Map<String, dynamic>>> getMonthlyRankings() {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

  // return supabase.from('monthly_rankings').stream(primaryKey: [
      'user_id'
    ]).map((data) => List<Map<String, dynamic>>.from(data)
        .where((item) =>
            item['month'] == currentMonth && item['year'] == currentYear)
        .toList()
      ..sort((a, b) =>
          (b['monthly_score'] as int).compareTo(a['monthly_score'] as int))
      ..take(10));
  }

  static Stream<List<Map<String, dynamic>>> getYearlyRankings() {
    final currentYear = DateTime.now().year;

  // return supabase.from('yearly_rankings').stream(primaryKey: ['user_id']).map(
        (data) => List<Map<String, dynamic>>.from(data)
            .where((item) => item['year'] == currentYear)
            .toList()
          ..sort((a, b) =>
              (b['yearly_score'] as int).compareTo(a['yearly_score'] as int))
          ..take(10));
  }

  // Método para obter histórico de rankings do usuário
  static Future<List<Map<String, dynamic>>> getUserRankingHistory() async {
  // final user = supabase.auth.currentUser;
    if (user == null) return [];

  // final response = await supabase
  //     .from('ranking_history')
  //     .select()
  //     .eq('user_id', user.id)
  //     .order('created_at', ascending: false);

  // return List<Map<String, dynamic>>.from(response);
  }
}
*/

// Stub do RankingService: deixamos uma API mínima ativa que não faz nada
// para evitar que chamadas existentes quebrem a compilação. A implementação
// completa está comentada acima e pode ser restaurada quando desejado.
class RankingService {
  // Não faz nada, apenas evita erros de import/compilação.
  static Future<void> updateScore(int waterAmount) async {
    // Ranking desativado
    return;
  }

  static Stream<List<Map<String, dynamic>>> getDailyRankings() async* {
    yield <Map<String, dynamic>>[];
  }

  static Stream<List<Map<String, dynamic>>> getMonthlyRankings() async* {
    yield <Map<String, dynamic>>[];
  }

  static Stream<List<Map<String, dynamic>>> getYearlyRankings() async* {
    yield <Map<String, dynamic>>[];
  }

  static Future<List<Map<String, dynamic>>> getUserRankingHistory() async {
    return <Map<String, dynamic>>[];
  }
}
