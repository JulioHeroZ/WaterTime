import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  static final supabase = Supabase.instance.client;

  // Atualizar dados do usuário
  static Future<void> updateUserData({
    required String name,
    double? weight,
    double? height,
    String? avatarUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      await supabase.from('profiles').update({
        'name': name,
        if (weight != null) 'weight': weight,
        if (height != null) 'height': height,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    }
  }

  // Buscar dados do usuário
  static Future<Map<String, dynamic>?> getUserData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response =
          await supabase.from('profiles').select().eq('id', user.id).single();
      return response;
    }
    return null;
  }
}
