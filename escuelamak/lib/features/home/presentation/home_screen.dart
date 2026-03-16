import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/features/auth/presentation/login_screen.dart';

// Decide qué dashboard mostrar según el rol del usuario
class HomeScreen extends StatelessWidget {
  final String rol;
  final String nombre;
  const HomeScreen({super.key, required this.rol, required this.nombre});

  @override
  Widget build(BuildContext context) {
    switch (rol) {
      case 'admin':
        return AdminDashboard(nombre: nombre);
      case 'teacher':
        return TeacherDashboard(nombre: nombre);
      default:
        return StudentDashboard(nombre: nombre);
    }
  }
}

// Dashboard del Administrador
class AdminDashboard extends StatelessWidget {
  final String nombre;
  const AdminDashboard({super.key, required this.nombre});
  @override
  Widget build(BuildContext context) => DashboardBase(
        nombre: nombre,
        rol: 'Administrador',
        color: Colors.red.shade700,
        titulo: 'Panel Admin',
        modulos: [
          Modulo('Usuarios', Icons.people, Colors.blue),
          Modulo('Cursos', Icons.book, Colors.green),
          Modulo('Permisos', Icons.admin_panel_settings, Colors.red),
          Modulo('Reportes', Icons.bar_chart, Colors.orange),
          Modulo('Mensajes', Icons.chat, Colors.purple),
          Modulo('Config', Icons.settings, Colors.grey),
        ],
      );
}

// Dashboard del Profesor
class TeacherDashboard extends StatelessWidget {
  final String nombre;
  const TeacherDashboard({super.key, required this.nombre});
  @override
  Widget build(BuildContext context) => DashboardBase(
        nombre: nombre,
        rol: 'Profesor',
        color: Colors.blue.shade700,
        titulo: 'Mi Aula',
        modulos: [
          Modulo('Clases', Icons.class_, Colors.blue),
          Modulo('Tareas', Icons.assignment, Colors.orange),
          Modulo('Quizzes', Icons.quiz, Colors.purple),
          Modulo('Calificar', Icons.grade, Colors.green),
          Modulo('Mensajes', Icons.chat, Colors.teal),
          Modulo('Calendario', Icons.calendar_today, Colors.red),
        ],
      );
}

// Dashboard del Estudiante
class StudentDashboard extends StatelessWidget {
  final String nombre;
  const StudentDashboard({super.key, required this.nombre});
  @override
  Widget build(BuildContext context) => DashboardBase(
        nombre: nombre,
        rol: 'Estudiante',
        color: Colors.green.shade700,
        titulo: 'Mi Aprendizaje',
        modulos: [
          Modulo('Clases', Icons.book, Colors.green),
          Modulo('Tareas', Icons.assignment, Colors.orange),
          Modulo('Quizzes', Icons.quiz, Colors.purple),
          Modulo('Mensajes', Icons.chat, Colors.blue),
          Modulo('Calendario', Icons.calendar_today, Colors.red),
          Modulo('Perfil', Icons.person, Colors.teal),
        ],
      );
}

// Modelo de datos para cada módulo del grid
class Modulo {
  final String label;
  final IconData icon;
  final Color color;
  Modulo(this.label, this.icon, this.color);
}

// Widget base reutilizable para los 3 dashboards
class DashboardBase extends StatefulWidget {
  final String nombre;
  final String rol;
  final Color color;
  final String titulo;
  final List<Modulo> modulos;

  const DashboardBase({
    super.key,
    required this.nombre,
    required this.rol,
    required this.color,
    required this.titulo,
    required this.modulos,
  });

  @override
  State<DashboardBase> createState() => _DashboardBaseState();
}

class _DashboardBaseState extends State<DashboardBase> {
  // Tab activo del bottom nav
  int _tab = 0;

  // Primer nombre del usuario
  String get _primerNombre =>
      widget.nombre.isNotEmpty ? widget.nombre.split(' ').first : 'Usuario';

  // Primera letra del nombre (para el avatar)
  String get _inicial => _primerNombre[0].toUpperCase();

  // Cerrar sesión con confirmación
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesion'),
        content: const Text('Seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // Contenido según el tab activo
  Widget get _contenido {
    switch (_tab) {
      case 0:
        return _inicio();
      case 1:
        return _proximamente('Clases', Icons.book, Colors.green);
      case 2:
        return _proximamente('Mensajes', Icons.chat, Colors.blue);
      case 3:
        return _perfil();
      default:
        return _inicio();
    }
  }

  // Tab Inicio: tarjeta de bienvenida + grid de módulos
  Widget _inicio() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de bienvenida
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withOpacity(0.3)),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: widget.color,
                child: Text(_inicial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola, $_primerNombre!',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.color)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(widget.rol.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 24),

          Text('Modulos disponibles',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Grid 3 columnas
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: widget.modulos.map<Widget>((Modulo m) {
              return GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${m.label} - Proximamente'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: m.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: m.color.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m.icon, color: m.color, size: 32),
                      const SizedBox(height: 8),
                      Text(m.label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: m.color),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Tab Proximamente
  Widget _proximamente(String titulo, IconData icono, Color color) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icono, size: 80, color: color.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(titulo,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Modulo en desarrollo',
            style: TextStyle(color: Colors.grey)),
      ],
    ));
  }

  // Tab Perfil
  Widget _perfil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 50,
          backgroundColor: widget.color,
          child: Text(_inicial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Text(widget.nombre,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(widget.rol,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Cerrar sesion',
                style: TextStyle(color: Colors.red, fontSize: 16)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _logout,
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _contenido,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: widget.color,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Clases'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
