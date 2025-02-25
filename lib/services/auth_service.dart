import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final supabase = Supabase.instance.client;

  // Inicialização do Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://sgoevmfbophescfrimuw.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnb2V2bWZib3BoZXNjZnJpbXV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAxNDUzMzksImV4cCI6MjA1NTcyMTMzOX0.AeFA2kYlIvjQAU1SfoRCMAufBhdNEPTcOGCtR_Yzmbs',
    );
  }

  // Registro
  static Future<AuthResponse?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      print('Usuário criado: ${response.user?.id}');

      if (response.user != null) {
        await Future.delayed(const Duration(seconds: 1));

        final userData = {
          'id': response.user!.id,
          'name': name,
          'email': email,
        };
        print('Tentando criar perfil com dados: $userData');

        try {
          final result =
              await supabase.from('profiles').insert(userData).select();
          print('Perfil criado com sucesso: $result');
        } catch (profileError) {
          print('Erro detalhado ao criar perfil: $profileError');
        }
      }

      return response;
    } catch (e) {
      print('Erro no registro: $e');
      return null;
    }
  }

  // Login
  static Future<AuthResponse?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        await _saveSession(response.session!);
      }

      return response;
    } catch (e) {
      print('Erro no login: $e');
      return null;
    }
  }

  // Login com Google
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      final response = await supabase.auth.signInWithOAuth(
        Provider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );

      final session = supabase.auth.currentSession;
      if (session != null) {
        await _saveSession(session);
        return AuthResponse(session: session, user: session.user);
      }
      return null;
    } catch (e) {
      print('Erro no login com Google: $e');
      return null;
    }
  }

  // Salvar sessão
  static Future<void> _saveSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', session.accessToken);
    await prefs.setString('refresh_token', session.refreshToken ?? '');
  }

  // Verificar se está logado
  static Future<bool> isUserLoggedIn() async {
    final currentUser = supabase.auth.currentUser;
    return currentUser != null;
  }

  // Logout
  static Future<void> logout() async {
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}
