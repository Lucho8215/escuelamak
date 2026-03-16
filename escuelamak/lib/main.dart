import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/core/constants/supabase_keys.dart';
import 'package:escuelamak/features/auth/presentation/login_screen.dart';
import 'package:escuelamak/features/home/presentation/home_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseKeys.url,
    anonKey: SupabaseKeys.anonKey,
    debug: true,
  );
  runApp(const ProviderScope(child: EscuelaMakApp()));
}
final supabase = Supabase.instance.client;
class EscuelaMakApp extends StatelessWidget {
  const EscuelaMakApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EscuelaMAK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }
  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final session = supabase.auth.currentSession;
    if (session != null) {
      final perfiles = await supabase
        .from('app_users')
        .select('role, name')
        .eq('auth_user_id', session.user.id)
        .limit(1);
      if (!mounted) return;
      if (perfiles.isNotEmpty) {
        final rol = perfiles[0]['role'] as String;
        final nombre = perfiles[0]['name'] as String;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeScreen(rol: rol, nombre: nombre),
          ),
        );
        return;
      }
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.school_rounded, size: 54, color: color),
            ),
            const SizedBox(height: 20),
            Text('EscuelaMAK',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 40),
            CircularProgressIndicator(color: color),
          ],
        ),
      ),
    );
  }
}
