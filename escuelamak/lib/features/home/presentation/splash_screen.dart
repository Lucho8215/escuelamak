// ============================================================
// SPLASH SCREEN — Pantalla de carga inicial
// ============================================================
// Esta pantalla aparece al abrir la app. Hace 2 cosas:
//   1. Muestra el logo animado de EscuelaMAK
//   2. Verifica si hay sesión activa en Supabase
//      - Si HAY sesión → va directo al dashboard
//      - Si NO hay sesión → va al login
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // AnimationController controla el tiempo de todas las animaciones
  late final AnimationController _ctrl;

  // Animación de escala del logo (crece de pequeño a normal)
  late final Animation<double> _scale;

  // Animación de opacidad del texto (aparece gradualmente)
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // La animación dura 1.2 segundos en total
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // El logo va de tamaño 0.5 a 1.0 con efecto elástico
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // El texto aparece entre el 40% y 80% de la animación
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    // Iniciar animación y luego verificar sesión
    _ctrl.forward().then((_) => _checkSession());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── VERIFICAR SESIÓN ACTIVA ──────────────────────────────────
  Future<void> _checkSession() async {
    // Pequeña pausa para que el logo se vea bien
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      // No hay sesión → ir al login
      context.go('/login');
      return;
    }

    try {
      // Hay sesión → obtener datos del usuario de app_users
      final userData = await supabase
          .from('app_users')
          .select('role, name')
          .eq('auth_user_id', session.user.id)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (userData == null) {
        // Usuario en auth pero no en app_users → ir al login
        await supabase.auth.signOut();
        context.go('/login');
        return;
      }

      // Ir al dashboard con los datos del usuario
      context.go('/home', extra: {
        'rol': userData['role'] as String? ?? 'student',
        'nombre': userData['name'] as String? ?? 'Usuario',
      });
    } catch (_) {
      // Error al consultar → ir al login
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.seedColor;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── LOGO ANIMADO ──
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 58,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── NOMBRE DE LA APP ──
            FadeTransition(
              opacity: _textOpacity,
              child: Column(
                children: [
                  Text(
                    'EscuelaMAK',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plataforma Educativa',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // ── INDICADOR DE CARGA ──
            FadeTransition(
              opacity: _textOpacity,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
