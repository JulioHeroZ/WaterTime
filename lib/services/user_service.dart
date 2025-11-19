// import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  // static final supabase = Supabase.instance.client;

  // Atualizar dados do usuário
  static Future<void> updateUserData({
    required String name,
    double? weight,
    double? height,
    String? avatarUrl,
  }) async {
    // Método local, não faz nada
    return;
  }

  // Buscar dados do usuário
  static Future<Map<String, dynamic>?> getUserData() async {
    // Método local, não faz nada
    return null;
  }
}
