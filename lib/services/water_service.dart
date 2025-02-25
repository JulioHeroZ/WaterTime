import 'package:supabase_flutter/supabase_flutter.dart';

class WaterService {
  static final supabase = Supabase.instance.client;

  // Adicionar registro de água
  static Future<void> addWaterRecord(int amount) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      await supabase.from('water_records').insert({
        'user_id': user.id,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      }).select(); // Deixe o Supabase gerar o UUID automaticamente
    }
  }

  // Buscar histórico de água
  static Future<List<Map<String, dynamic>>> getWaterHistory() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('water_records')
          .select()
          .eq('user_id', user.id)
          .order('timestamp', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }
}
