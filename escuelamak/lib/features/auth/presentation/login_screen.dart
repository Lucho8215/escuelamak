// ============================================================
// LOGIN SCREEN — Pantalla de inicio de sesión
// ============================================================
// Conecta con Supabase Auth para autenticar al usuario.
// Después del login exitoso, busca el rol en app_users
// y navega al dashboard correcto.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores de los campos de texto
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Estado de la pantalla
  bool _loading = false;
  bool _showPassword = false;
  String? _errorMessage;

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── FUNCIÓN DE LOGIN ─────────────────────────────────────────
  Future<void> _login() async {
    // Limpiar error anterior
    setState(() {
      _errorMessage = null;
    });

    // Validar campos vacíos
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor completa todos los campos');
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. Autenticar con Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: _emailCtrl.text.trim().toLowerCase(),
        password: _passwordCtrl.text,
      );

      if (response.user == null) {
        setState(() => _errorMessage = 'No se pudo iniciar sesión');
        return;
      }

      // 2. Obtener datos del usuario desde app_users
      final userData = await _supabase
          .from('app_users')
          .select('role, name')
          .eq('auth_user_id', response.user!.id)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (userData == null) {
        // Usuario existe en auth pero no en app_users
        await _supabase.auth.signOut();
        setState(
            () => _errorMessage = 'Usuario no registrado en la plataforma');
        return;
      }

      // 3. Navegar al dashboard con los datos del usuario
      context.go('/home', extra: {
        'rol': userData['role'] as String? ?? 'student',
        'nombre': userData['name'] as String? ?? 'Usuario',
      });
    } on AuthException catch (e) {
      // Errores específicos de autenticación
      setState(() => _errorMessage = _traducirError(e.message));
    } catch (_) {
      setState(() => _errorMessage = 'Error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Traduce los errores de Supabase (en inglés) al español
  String _traducirError(String msg) {
    if (msg.contains('Invalid login credentials'))
      return 'Correo o contraseña incorrectos';
    if (msg.contains('Email not confirmed'))
      return 'Debes confirmar tu correo electrónico';
    if (msg.contains('Too many requests'))
      return 'Demasiados intentos. Espera un momento';
    return 'Error al iniciar sesión';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.seedColor;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // ── LOGO ──────────────────────────────────────────
              FadeSlideIn(
                child: Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(Icons.school_rounded, size: 52, color: color),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── TÍTULO ────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Column(children: [
                  Text(
                    'EscuelaMAK',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Inicia sesión para continuar',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 40),

              // ── CAMPO EMAIL ───────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: TextField(
                  controller: _emailCtrl,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'tucorreo@ejemplo.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── CAMPO CONTRASEÑA ──────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: TextField(
                  controller: _passwordCtrl,
                  enabled: !_loading,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── OLVIDÉ CONTRASEÑA ─────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Recuperación de contraseña - Próximamente'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: color, fontSize: 13),
                    ),
                  ),
                ),
              ),

              // ── MENSAJE DE ERROR ──────────────────────────────
              if (_errorMessage != null)
                FadeSlideIn(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),

              // ── BOTÓN LOGIN ───────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: color.withOpacity(0.6),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Iniciar Sesión'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
