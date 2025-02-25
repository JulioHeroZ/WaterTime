import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../Utils/colors.dart';
import '../Home Page/water_reminder_home_page.dart';
import '../services/sync_service.dart';

class LoginPage extends StatefulWidget {
  final dynamic trayManager;
  final dynamic notificationManager;

  const LoginPage({
    super.key,
    required this.trayManager,
    required this.notificationManager,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [backgroundColor2, backgroundColor2, backgroundColor4],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Conteúdo principal
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 60, // Adicionar espaço para o botão voltar
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // Logo ou Ícone
                      Icon(
                        Icons.water_drop,
                        size: 80,
                        color: textColor2,
                      ),
                      const SizedBox(height: 30),
                      // Título
                      Text(
                        _isLoginMode ? "Bem-vindo de volta!" : "Criar conta",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor2,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Campos de entrada
                      if (!_isLoginMode) _buildNameField(),
                      const SizedBox(height: 16),
                      _buildEmailField(),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      const SizedBox(height: 24),
                      // Botão principal
                      _buildMainButton(),
                      const SizedBox(height: 16),
                      // Alternar entre login e registro
                      _buildToggleModeButton(),
                      const SizedBox(height: 32),
                      // Divisor
                      _buildDivider(),
                      const SizedBox(height: 32),
                      // Botões de mídia social
                      _buildSocialButtons(),
                    ],
                  ),
                ),
              ),
              // Botão Voltar
              Positioned(
                top: 10,
                left: 10,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: textColor2),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => WaterReminderHomePage(
                            trayManager: widget.trayManager,
                            notificationManager: widget.notificationManager,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: 'Nome completo',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.person_outline),
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Por favor, insira seu nome' : null,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'Email',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.email_outlined),
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Por favor, insira seu email' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(
        hintText: 'Senha',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.lock_outline),
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Por favor, insira sua senha' : null,
    );
  }

  Widget _buildMainButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              _isLoginMode ? 'Entrar' : 'Cadastrar',
              style: const TextStyle(fontSize: 18),
            ),
    );
  }

  Widget _buildToggleModeButton() {
    return TextButton(
      onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
      child: Text(
        _isLoginMode
            ? 'Não tem uma conta? Cadastre-se'
            : 'Já tem uma conta? Entre',
        style: TextStyle(color: textColor2),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: textColor2.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou continue com',
            style: TextStyle(color: textColor2),
          ),
        ),
        Expanded(child: Divider(color: textColor2.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialButton(
          'assets/images/google.png',
          'Google',
          _handleGoogleSignIn,
        ),
        _buildSocialButton(
          'assets/images/facebook.png',
          'Facebook',
          _handleFacebookSignIn,
        ),
      ],
    );
  }

  Widget _buildSocialButton(String icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Image.asset(icon, height: 24),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final response = _isLoginMode
            ? await AuthService.login(
                email: _emailController.text,
                password: _passwordController.text,
              )
            : await AuthService.register(
                email: _emailController.text,
                password: _passwordController.text,
                name: _nameController.text,
              );

        if (response != null && mounted) {
          await SyncService.loadFromServer();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => WaterReminderHomePage(
                trayManager: widget.trayManager,
                notificationManager: widget.notificationManager,
              ),
            ),
          );
        } else {
          _showError(
              _isLoginMode ? 'Erro ao fazer login' : 'Erro ao criar conta');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final response = await AuthService.signInWithGoogle();
      if (response?.session != null && mounted) {
        await SyncService.loadFromServer();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WaterReminderHomePage(
              trayManager: widget.trayManager,
              notificationManager: widget.notificationManager,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFacebookSignIn() async {
    // Implementar login com Facebook
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
