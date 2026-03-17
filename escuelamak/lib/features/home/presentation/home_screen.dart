// ============================================================
// HOME SCREEN — Dashboard principal por rol
// ============================================================
// Muestra un dashboard diferente según el rol del usuario:
//   - admin   → Panel de administración (rojo)
//   - teacher → Panel de profesor (azul)
//   - student/tutor → Panel de estudiante (verde)
//
// Cada dashboard tiene:
//   - Tab Inicio: tarjeta de bienvenida + módulos
//   - Tab Clases: lista de clases desde Supabase
//   - Tab Mensajes: chat en tiempo real (próximamente)
//   - Tab Perfil: info del usuario + cerrar sesión
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/core/theme/app_theme.dart';
import 'package:escuelamak/features/classes/presentation/classes_screen.dart';

class HomeScreen extends StatefulWidget {
  final String rol;
  final String nombre;

  const HomeScreen({
    super.key,
    required this.rol,
    required this.nombre,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tab activo del bottom nav (0=Inicio, 1=Clases, 2=Mensajes, 3=Perfil)
  int _tab = 0;

  // Color del dashboard según el rol
  Color get _color => AppTheme.colorForRole(widget.rol);

  // Título del AppBar según el rol
  String get _titulo {
    switch (widget.rol) {
      case 'admin':
        return 'Panel Admin';
      case 'teacher':
        return 'Mi Aula';
      default:
        return 'Mi Aprendizaje';
    }
  }

  // Primera letra del nombre para el avatar
  String get _inicial => widget.nombre.isNotEmpty
      ? widget.nombre.split(' ').first[0].toUpperCase()
      : 'U';

  // Primer nombre del usuario
  String get _primerNombre =>
      widget.nombre.isNotEmpty ? widget.nombre.split(' ').first : 'Usuario';

  // Módulos según el rol
  List<_Modulo> get _modulos {
    switch (widget.rol) {
      case 'admin':
        return [
          _Modulo('Usuarios', Icons.people_rounded, Colors.blue),
          _Modulo('Cursos', Icons.book_rounded, Colors.green),
          _Modulo('Permisos', Icons.admin_panel_settings, Colors.red),
          _Modulo('Reportes', Icons.bar_chart_rounded, Colors.orange),
          _Modulo('Mensajes', Icons.chat_rounded, Colors.purple),
          _Modulo('Config', Icons.settings_rounded, Colors.grey),
        ];
      case 'teacher':
        return [
          _Modulo('Clases', Icons.class_rounded, Colors.blue),
          _Modulo('Tareas', Icons.assignment_rounded, Colors.orange),
          _Modulo('Quizzes', Icons.quiz_rounded, Colors.purple),
          _Modulo('Calificar', Icons.grade_rounded, Colors.green),
          _Modulo('Mensajes', Icons.chat_rounded, Colors.teal),
          _Modulo('Horario', Icons.calendar_today_rounded, Colors.red),
        ];
      default:
        return [
          _Modulo('Clases', Icons.book_rounded, Colors.green),
          _Modulo('Tareas', Icons.assignment_rounded, Colors.orange),
          _Modulo('Quizzes', Icons.quiz_rounded, Colors.purple),
          _Modulo('Mensajes', Icons.chat_rounded, Colors.blue),
          _Modulo('Horario', Icons.calendar_today_rounded, Colors.red),
          _Modulo('Perfil', Icons.person_rounded, Colors.teal),
        ];
    }
  }

  // ── CERRAR SESIÓN ────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/login');
    }
  }

  // ── CONTENIDO SEGÚN EL TAB ACTIVO ───────────────────────────
  Widget get _contenido {
    switch (_tab) {
      case 1:
        return const ClassesScreen();
      case 2:
        return _buildProximamente(
            'Mensajes', Icons.chat_rounded, Colors.purple);
      case 3:
        return _buildPerfil();
      default:
        return _buildInicio();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── APP BAR ────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _color,
        foregroundColor: Colors.white,
        title: Text(
          _titulo,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),

      // ── BODY — muestra el tab activo ────────────────────────
      // IndexedStack mantiene el estado de cada tab al cambiar
      body: IndexedStack(
        index: _tab,
        children: [
          _buildInicio(),
          const ClassesScreen(),
          _buildProximamente('Mensajes', Icons.chat_rounded, Colors.purple),
          _buildPerfil(),
        ],
      ),

      // ── BOTTOM NAVIGATION BAR ────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        selectedItemColor: _color,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: 'Clases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_rounded),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // ── TAB: INICIO ──────────────────────────────────────────────
  Widget _buildInicio() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de bienvenida
          FadeSlideIn(
            child: _WelcomeCard(
              nombre: _primerNombre,
              inicial: _inicial,
              rol: widget.rol,
              color: _color,
            ),
          ),
          const SizedBox(height: 24),

          // Título de módulos
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Text(
              'Módulos disponibles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 12),

          // Grid de módulos
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: _modulos.asMap().entries.map((e) {
              return FadeSlideIn(
                delay: Duration(milliseconds: 100 + e.key * 50),
                child: _ModuloCard(modulo: e.value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── TAB: PRÓXIMAMENTE ────────────────────────────────────────
  Widget _buildProximamente(String titulo, IconData icono, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 72, color: color.withOpacity(0.25)),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Módulo en desarrollo',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── TAB: PERFIL ──────────────────────────────────────────────
  Widget _buildPerfil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Avatar grande
          FadeSlideIn(
            child: CircleAvatar(
              radius: 52,
              backgroundColor: _color,
              child: Text(
                _inicial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nombre completo
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Text(
              widget.nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Badge de rol
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.rol.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Botón cerrar sesión
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _logout,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGET: Tarjeta de bienvenida
// ─────────────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String nombre;
  final String inicial;
  final String rol;
  final Color color;

  const _WelcomeCard({
    required this.nombre,
    required this.inicial,
    required this.rol,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 28,
          backgroundColor: color,
          child: Text(
            inicial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Nombre y rol
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $nombre!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  rol.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODELO y WIDGET: Tarjeta de módulo en el grid
// ─────────────────────────────────────────────────────────────
class _Modulo {
  final String label;
  final IconData icon;
  final Color color;
  const _Modulo(this.label, this.icon, this.color);
}

class _ModuloCard extends StatelessWidget {
  final _Modulo modulo;
  const _ModuloCard({required this.modulo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${modulo.label} - Próximamente'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: modulo.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: modulo.color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(modulo.icon, color: modulo.color, size: 30),
            const SizedBox(height: 8),
            Text(
              modulo.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: modulo.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
