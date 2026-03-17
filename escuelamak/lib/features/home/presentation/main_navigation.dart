import 'package:flutter/material.dart';
import 'package:escuelamak/features/home/presentation/home_screen.dart';
import 'package:escuelamak/features/courses/presentation/classes_screen.dart';

// Este widget maneja la navegación principal con bottom nav
// Separa la lógica de navegación del dashboard
class MainNavigation extends StatefulWidget {
  final String rol;
  final String nombre;

  const MainNavigation({
    super.key,
    required this.rol,
    required this.nombre,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _tab = 0;

  // Color según el rol
  Color get _color {
    switch (widget.rol) {
      case 'admin':   return Colors.red;
      case 'teacher': return Colors.blue;
      default:        return Colors.green;
    }
  }

  // Pantallas del bottom nav
  Widget get _pantalla {
    switch (_tab) {
      case 0: return HomeScreen(rol: widget.rol, nombre: widget.nombre);
      case 1: return ClassesScreen();
      case 2: return const _Proximamente('Mensajes', Icons.chat, Colors.blue);
      case 3: return _Perfil(nombre: widget.nombre, rol: widget.rol, color: _color);
      default: return HomeScreen(rol: widget.rol, nombre: widget.nombre);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantalla,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _color,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home),   label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.book),   label: 'Clases'),
          BottomNavigationBarItem(icon: Icon(Icons.chat),   label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// Pantalla de próximamente
class _Proximamente extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;

  const _Proximamente(this.titulo, this.icono, this.color);

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icono, size: 80, color: color.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(titulo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Modulo en desarrollo', style: TextStyle(color: Colors.grey)),
      ],
    ));
  }
}

// Pantalla de perfil
class _Perfil extends StatelessWidget {
  final String nombre;
  final String rol;
  final Color color;

  const _Perfil({required this.nombre, required this.rol, required this.color});

  String get _inicial => nombre.isNotEmpty ? nombre.split(' ').first[0].toUpperCase() : 'U';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 60),
        CircleAvatar(radius: 50, backgroundColor: color,
          child: Text(_inicial, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))),
        const SizedBox(height: 16),
        Text(nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
          child: Text(rol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 52,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Cerrar sesion', style: TextStyle(color: Colors.red, fontSize: 16)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar sesion'),
                  content: const Text('Seguro que quieres salir?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Salir', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                import_supabase: await supabaseSignOut(context);
              }
            },
          ),
        ),
      ]),
    );
  }
}

Future<void> supabaseSignOut(BuildContext context) async {
  final supabase = await _getSupabase();
  await supabase.auth.signOut();
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }
}

dynamic _getSupabase() {
  import 'package:supabase_flutter/supabase_flutter.dart';
  return Supabase.instance.client;
}
