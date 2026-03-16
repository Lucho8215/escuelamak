import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/core/theme/app_theme.dart';
import 'package:escuelamak/features/home/presentation/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;
  bool _mostrarPassword = false;

  // Animaciones
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Cliente Supabase
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Iniciar animación
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Función de login
  Future<void> _login() async {
    // Validar campos vacíos
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _mostrarError('Por favor completa todos los campos');
      return;
    }

    setState(() => _cargando = true);

    try {
      // Intentar login con Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Login exitoso — obtener el rol del usuario desde app_users
        final perfiles = await _supabase
            .from('app_users')
            .select('role, name')
            .eq('auth_user_id', response.user!.id)
            .limit(1);

        if (perfiles.isEmpty) {
          _mostrarError('Usuario no encontrado en la plataforma');
          await _supabase.auth.signOut();
          return;
        }

        final rol = perfiles[0]['role'] as String;
        final nombres = perfiles[0]['name'] as String;

        if (mounted) {
          // Animación de salida antes de navegar
          await _animationController.reverse();

          if (!mounted) return;

          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  HomeScreen(rol: rol, nombre: nombres),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      _mostrarError(_traducirError(e.message));
    } catch (e) {
      _mostrarError('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Traducir errores de Supabase al español
  String _traducirError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos';
    }
    if (error.contains('Email not confirmed')) {
      return 'Debes confirmar tu correo electrónico';
    }
    if (error.contains('Too many requests')) {
      return 'Demasiados intentos. Espera un momento';
    }
    return 'Error: $error';
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.seedColor;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo con animación
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  Text(
                    'EscuelaMAK',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Campo email
                  _AnimatedTextField(
                    controller: _emailController,
                    enabled: !_cargando,
                    prefixIcon: Icons.email_outlined,
                    label: 'Correo electrónico',
                    hint: 'ejemplo@correo.com',
                    keyboardType: TextInputType.emailAddress,
                    delay: 100,
                  ),
                  const SizedBox(height: 16),

                  // Campo contraseña
                  _AnimatedTextField(
                    controller: _passwordController,
                    enabled: !_cargando,
                    prefixIcon: Icons.lock_outlined,
                    label: 'Contraseña',
                    hint: '••••••••',
                    obscureText: !_mostrarPassword,
                    suffixIcon: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _mostrarPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          key: ValueKey(_mostrarPassword),
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _mostrarPassword = !_mostrarPassword),
                    ),
                    delay: 200,
                  ),
                  const SizedBox(height: 12),

                  // Olvidé contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _cargando
                          ? null
                          : () {
                              _mostrarError('Función próximamente disponible');
                            },
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón login
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: color.withOpacity(0.4),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _cargando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.login_rounded),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Footer
                  Text(
                    '© 2024 EscuelaMAK',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET DE TEXFIELD ANIMADO
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final IconData prefixIcon;
  final String label;
  final String hint;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int delay;

  const _AnimatedTextField({
    required this.controller,
    required this.enabled,
    required this.prefixIcon,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.delay = 0,
  });

  @override
  State<_AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<_AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Iniciar animación con delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          enabled: widget.enabled,
          obscureText: widget.obscureText,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.seedColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}
