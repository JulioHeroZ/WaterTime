import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Inicialização stub
  static Future<void> initialize() async {
    // Backend removido: nada a fazer
  }

  // Registro (stub): retorna false pois backend foi removido
  static Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return false;
  }

  // Login (stub)
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    return false;
  }

  // Login com Google (stub)
  static Future<bool> signInWithGoogle() async {
    return false;
  }

  // Verificar se está logado (stub)
  static Future<bool> isUserLoggedIn() async {
    return false;
  }

  // Logout (limpa tokens locais se existirem)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}
