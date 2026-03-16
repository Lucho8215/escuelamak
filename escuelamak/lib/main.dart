import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/core/constants/supabase_keys.dart';
import 'package:escuelamak/core/theme/app_theme.dart';
import 'package:escuelamak/features/auth/presentation/login_screen.dart';
import 'package:escuelamak/features/home/presentation/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientacion preferida
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurar color de status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routes: {
        '/login': (_) => const LoginScreen(),
      },
      home: const AnimatedSplashScreen(),
    );
  }
}
/// Splash Screen profesional con animaciones estilo Google Classroom
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _loadingWidth;

  @override
  void initState() {
    super.initState();
    
    // Controlador para animacion del logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Controlador para animacion del texto
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Controlador para la barra de carga
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Animacion de escala del logo (0.5 -> 1.0)
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Animacion de opacidad del logo
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // Animacion de opacidad del texto
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    
    // Animacion de deslizamiento del texto
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    
    // Animacion de la barra de carga
    _loadingWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    
    // Iniciar secuencia de animaciones
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // 1. Animar logo
    _logoController.forward();
    
    // 2. Despues de 300ms, iniciar animacion de texto
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();
    
    // 3. Iniciar barra de carga
    await Future.delayed(const Duration(milliseconds: 200));
    _loadingController.repeat(reverse: true);
    
    // 4. Verificar sesion
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      _checkSession();
    }
  }

  Future<void> _checkSession() async {
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
        
        // Animacion de salida
        await _navigateWithFade(
          HomeScreen(rol: rol, nombre: nombre),
        );
        return;
      }
    }
    
    if (mounted) {
      _navigateWithFade(const LoginScreen());
    }
  }

  Future<void> _navigateWithFade(Widget destination) async {
    await _logoController.reverse();
    await _textController.reverse();
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.seedColor;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo con animacion
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
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
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Texto con animacion
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _textSlide,
                    child: Opacity(
                      opacity: _textOpacity.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Text(
                      'EscuelaMAK',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aprende sin límites',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Barra de carga
              AnimatedBuilder(
                animation: _loadingController,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _loadingWidth.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
