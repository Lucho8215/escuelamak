// ============================================================
// APP ROUTER — Sistema de navegación de EscuelaMAK
// ============================================================
// Usa GoRouter para manejar todas las rutas de la app.
// Detecta automáticamente si hay sesión activa y redirige
// al login o al dashboard según corresponda.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/features/auth/presentation/login_screen.dart';
import 'package:escuelamak/features/home/presentation/splash_screen.dart';
import 'package:escuelamak/features/home/presentation/home_screen.dart';

// Provider del router — lo usa MaterialApp.router en main.dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Splash: verifica sesión y redirige
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),

      // Login
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // Home (dashboard) — recibe rol y nombre del usuario
      GoRoute(
        path: '/home',
        builder: (context, state) {
          // Leer los datos del usuario desde los extra del router
          final extra = state.extra as Map<String, String>? ?? {};
          return HomeScreen(
            rol: extra['rol'] ?? 'student',
            nombre: extra['nombre'] ?? 'Usuario',
          );
        },
      ),
    ],

    // Manejo de errores de navegación
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Página no encontrada: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});
