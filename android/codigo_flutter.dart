// ============================================================
// ESCUELAMAK — Código Base Flutter
// Archivos principales para comenzar el proyecto
// ============================================================
// Crea cada archivo en la ruta indicada en el comentario
// ============================================================


// ── ARCHIVO: lib/main.dart ──────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase — reemplaza con TUS credenciales
  await Supabase.initialize(
    url: 'https://TU_PROYECTO.supabase.co',
    anonKey: 'TU_ANON_KEY_AQUI',
  );

  runApp(
    // ProviderScope es el contenedor raíz de Riverpod
    const ProviderScope(child: EscuelaMakApp()),
  );
}

// Acceso global al cliente Supabase (usa en cualquier parte)
final supabase = Supabase.instance.client;


// ── ARCHIVO: lib/app.dart ───────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class EscuelaMakApp extends ConsumerWidget {
  const EscuelaMakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'EscuelaMAK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}


// ── ARCHIVO: lib/core/theme/app_theme.dart ──────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores principales de EscuelaMAK
  static const Color primaryColor   = Color(0xFF6750A4);  // Púrpura Material 3
  static const Color secondaryColor = Color(0xFF625B71);
  static const Color errorColor     = Color(0xFFB3261E);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
  );
}


// ── ARCHIVO: lib/core/router/app_router.dart ────────────────
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/courses/presentation/courses_screen.dart';
// ... importar más pantallas conforme las crees

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isOnLogin  = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn  &&  isOnLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login',   builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home',    builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/courses', builder: (_, __) => const CoursesScreen()),
      GoRoute(
        path: '/courses/:id',
        builder: (ctx, state) => CourseDetailScreen(
          courseId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(path: '/tasks',    builder: (_, __) => const TasksScreen()),
      GoRoute(path: '/quizzes',  builder: (_, __) => const QuizzesScreen()),
      GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
      GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
      GoRoute(path: '/admin',    builder: (_, __) => const AdminScreen()),
      GoRoute(path: '/profile',  builder: (_, __) => const ProfileScreen()),
    ],
  );
});


// ── ARCHIVO: lib/features/auth/presentation/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../main.dart';
import '../data/auth_repository.dart';

// Observa el estado de autenticación en tiempo real
final authStateProvider = StreamProvider<User?>((ref) {
  return supabase.auth.onAuthStateChange.map((event) => event.session?.user);
});

// Datos del perfil del usuario actual
final currentProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  final response = await supabase
    .from('profiles')
    .select()
    .eq('id', user.id)
    .single();

  return response;
});

// Permisos del usuario actual
final userPermissionsProvider = FutureProvider<List<String>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final response = await supabase
    .rpc('get_user_permissions', params: {'p_user_id': user.id});

  return (response as List)
    .where((p) => p['is_granted'] == true)
    .map<String>((p) => p['permission_key'].toString())
    .toList();
});

// Notifier para acciones de auth (login/logout/register)
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String nombres,
    required String apellidos,
    String rol = 'estudiante',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombres': nombres,
          'apellidos': apellidos,
          'rol': rol,
        },
      );
    });
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }
}


// ── ARCHIVO: lib/features/auth/presentation/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword        = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackbar('Por favor completa todos los campos');
      return;
    }

    await ref.read(authNotifierProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      _showSnackbar('Error: ${state.error}');
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final theme     = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Logo / Título
              Icon(Icons.school_rounded,
                size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('EscuelaMAK',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )),
              const SizedBox(height: 8),
              Text('Bienvenido de regreso',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),

              const SizedBox(height: 48),

              // Campo Email
              TextField(
                key: const Key('email_field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Contraseña
              TextField(
                key: const Key('password_field'),
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword
                      ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {}, // TODO: pantalla recuperar contraseña
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),

              const SizedBox(height: 24),

              // Botón Login
              ElevatedButton(
                onPressed: isLoading ? null : _login,
                child: isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Iniciar Sesión',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 24),

              // Link a registro
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('¿No tienes cuenta?',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                TextButton(
                  onPressed: () {}, // TODO: navegar a RegisterScreen
                  child: const Text('Regístrate'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}


// ── ARCHIVO: lib/features/courses/data/courses_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../domain/course_model.dart';

final coursesRepositoryProvider = Provider<CoursesRepository>(
  (ref) => CoursesRepository(),
);

class CoursesRepository {

  // Obtener todos los cursos publicados con paginación
  Future<List<CourseModel>> getCourses({int page = 0, int limit = 10}) async {
    try {
      final response = await supabase
        .from('courses')
        .select('''
          *,
          profiles:instructor_id (nombres, apellidos, foto_url),
          categories:categoria_id (nombre)
        ''')
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .range(page * limit, (page + 1) * limit - 1);

      return (response as List)
        .map((json) => CourseModel.fromJson(json))
        .toList();
    } catch (e) {
      throw Exception('Error al cargar cursos: $e');
    }
  }

  // Obtener cursos matriculados del estudiante actual
  Future<List<CourseModel>> getEnrolledCourses(String userId) async {
    final response = await supabase
      .from('courses')
      .select('''
        *,
        profiles:instructor_id (nombres, apellidos),
        course_enrollments!inner (user_id, status)
      ''')
      .eq('course_enrollments.user_id', userId)
      .eq('course_enrollments.status', 'activo');

    return (response as List)
      .map((json) => CourseModel.fromJson(json))
      .toList();
  }

  // Obtener detalle de un curso con sus lecciones
  Future<Map<String, dynamic>> getCourseDetail(String courseId) async {
    final response = await supabase
      .from('courses')
      .select('''
        *,
        profiles:instructor_id (nombres, apellidos, foto_url),
        categories:categoria_id (nombre),
        lessons (id, titulo, orden, video_url)
      ''')
      .eq('id', courseId)
      .single();

    return response;
  }

  // Matricular estudiante en un curso
  Future<void> enrollStudent(String courseId, String userId) async {
    await supabase.from('course_enrollments').insert({
      'course_id': courseId,
      'user_id':   userId,
      'status':    'activo',
    });
  }
}


// ── ARCHIVO: lib/features/courses/domain/course_model.dart ──
class CourseModel {
  final String   id;
  final String   titulo;
  final String?  descripcion;
  final String?  imagenUrl;
  final int      duracion;
  final bool     isPublished;
  final String?  instructorNombre;
  final String?  categoriaNombre;
  final DateTime createdAt;

  const CourseModel({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.imagenUrl,
    required this.duracion,
    required this.isPublished,
    this.instructorNombre,
    this.categoriaNombre,
    required this.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final instructor = json['profiles'] as Map<String, dynamic>?;
    final categoria  = json['categories'] as Map<String, dynamic>?;

    return CourseModel(
      id:               json['id'] as String,
      titulo:           json['titulo'] as String,
      descripcion:      json['descripcion'] as String?,
      imagenUrl:        json['imagen_url'] as String?,
      duracion:         json['duracion'] as int? ?? 0,
      isPublished:      json['is_published'] as bool? ?? false,
      instructorNombre: instructor != null
        ? '${instructor['nombres']} ${instructor['apellidos']}'
        : null,
      categoriaNombre:  categoria?['nombre'] as String?,
      createdAt:        DateTime.parse(json['created_at'] as String),
    );
  }
}


// ── ARCHIVO: lib/features/messages/data/messages_repository.dart
import '../../../main.dart';

class MessagesRepository {

  // Stream de mensajes en tiempo real para una conversación
  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('created_at')
      .map((data) => List<Map<String, dynamic>>.from(data));
  }

  // Enviar mensaje
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String contenido,
    String tipo = 'texto',
  }) async {
    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id':       senderId,
      'receiver_id':     receiverId,
      'contenido':       contenido,
      'tipo':            tipo,
    });
  }

  // Obtener o crear conversación entre dos usuarios
  Future<String> getOrCreateConversation(
    String userId1, String userId2,
  ) async {
    // Buscar conversación existente
    final existing = await supabase
      .from('conversations')
      .select('id')
      .contains('participant_ids', [userId1, userId2])
      .maybeSingle();

    if (existing != null) return existing['id'] as String;

    // Crear nueva conversación
    final newConv = await supabase
      .from('conversations')
      .insert({'participant_ids': [userId1, userId2]})
      .select('id')
      .single();

    return newConv['id'] as String;
  }
}


// ── ARCHIVO: lib/features/quizzes/presentation/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;
  final int tiempoLimite; // minutos

  const QuizScreen({
    super.key,
    required this.quizId,
    this.tiempoLimite = 30,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late Timer _timer;
  late int   _segundosRestantes;
  int        _preguntaActual = 0;
  Map<int, dynamic> _respuestas = {};

  @override
  void initState() {
    super.initState();
    _segundosRestantes = widget.tiempoLimite * 60;
    _iniciarTemporizador();
  }

  void _iniciarTemporizador() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes <= 0) {
        timer.cancel();
        _enviarQuiz();
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  String get _tiempoFormateado {
    final min = _segundosRestantes ~/ 60;
    final seg = _segundosRestantes  %  60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  bool get _tiempoEsCritico => _segundosRestantes <= 60;

  void _enviarQuiz() {
    _timer.cancel();
    // TODO: guardar respuestas en quiz_results
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Completado'),
        content: const Text('Tus respuestas han sido enviadas.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ver Resultados'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          // Temporizador
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _tiempoEsCritico
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Icon(Icons.timer,
                size: 16,
                color: _tiempoEsCritico
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                _tiempoFormateado,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _tiempoEsCritico
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                ),
              ),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        // Barra de progreso
        LinearProgressIndicator(
          value: (_preguntaActual + 1) / 5, // TODO: total preguntas real
          backgroundColor: theme.colorScheme.surfaceVariant,
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Pregunta ${_preguntaActual + 1} de 5',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
                const SizedBox(height: 16),

                // Texto de la pregunta
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '¿Pregunta de ejemplo para quiz ${widget.quizId}?',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Opciones de respuesta
                ...['Opción A', 'Opción B', 'Opción C', 'Opción D']
                  .asMap()
                  .entries
                  .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: BorderSide(
                          color: _respuestas[_preguntaActual] == entry.key
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                          width: _respuestas[_preguntaActual] == entry.key
                            ? 2 : 1,
                        ),
                        backgroundColor:
                          _respuestas[_preguntaActual] == entry.key
                            ? theme.colorScheme.primaryContainer
                            : null,
                      ),
                      onPressed: () => setState(() {
                        _respuestas[_preguntaActual] = entry.key;
                      }),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(entry.value),
                      ),
                    ),
                  )),

                const Spacer(),

                // Botones de navegación
                Row(children: [
                  if (_preguntaActual > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                          setState(() => _preguntaActual--),
                        child: const Text('Anterior'),
                      ),
                    ),
                  if (_preguntaActual > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _respuestas[_preguntaActual] == null
                        ? null
                        : () {
                          if (_preguntaActual < 4) {
                            setState(() => _preguntaActual++);
                          } else {
                            _enviarQuiz();
                          }
                        },
                      child: Text(
                        _preguntaActual < 4 ? 'Siguiente' : 'Enviar Quiz',
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}


// ── ARCHIVO: lib/features/permissions/presentation/admin_permissions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';

// Provider para cargar todos los permisos de la plataforma
final platformPermissionsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    return await supabase
      .from('platform_permissions')
      .select()
      .eq('is_active', true)
      .order('name');
  },
);

class AdminPermissionsScreen extends ConsumerWidget {
  final String userId; // Usuario al que se le gestionan permisos

  const AdminPermissionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(platformPermissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Permisos')),
      body: permissionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (permissions) => FutureBuilder(
          future: supabase
            .from('user_permissions')
            .select()
            .eq('user_id', userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userPerms = (snapshot.data as List)
              .map((p) => p['permission_key'].toString())
              .toSet();

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: permissions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final perm    = permissions[i];
                final key     = perm['key'] as String;
                final granted = userPerms.contains(key);

                return SwitchListTile(
                  title: Text(perm['name'] as String),
                  subtitle: Text(perm['description'] as String? ?? ''),
                  secondary: Icon(_getIcon(perm['icon'] as String? ?? '')),
                  value: granted,
                  onChanged: (val) async {
                    final adminId = supabase.auth.currentUser!.id;

                    if (val) {
                      // Otorgar permiso
                      await supabase.from('user_permissions').upsert({
                        'user_id':        userId,
                        'permission_key': key,
                        'is_granted':     true,
                        'granted_by':     adminId,
                      });
                    } else {
                      // Revocar permiso
                      await supabase.from('user_permissions')
                        .update({'is_granted': false})
                        .eq('user_id', userId)
                        .eq('permission_key', key);
                    }
                    ref.invalidate(platformPermissionsProvider);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    const icons = {
      'book':         Icons.book_outlined,
      'assignment':   Icons.assignment_outlined,
      'quiz':         Icons.quiz_outlined,
      'chat':         Icons.chat_outlined,
      'calendar':     Icons.calendar_today_outlined,
      'bar_chart':    Icons.bar_chart_outlined,
      'admin_panel':  Icons.admin_panel_settings_outlined,
      'person':       Icons.person_outlined,
    };
    return icons[iconName] ?? Icons.circle_outlined;
  }
}


// ── ARCHIVO: lib/shared/widgets/custom_button.dart ──────────
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String   label;
  final VoidCallback? onPressed;
  final bool     isLoading;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
        ? const SizedBox(
            height: 20, width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold,
              )),
            ],
          ),
    );
  }
}
