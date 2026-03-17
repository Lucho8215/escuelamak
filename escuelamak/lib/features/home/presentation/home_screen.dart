import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/core/theme/app_theme.dart';
import 'package:escuelamak/features/auth/presentation/login_screen.dart';
import 'package:escuelamak/features/courses/presentation/courses_providers.dart';
import 'package:escuelamak/features/courses/presentation/course_detail_screen.dart';
import 'package:escuelamak/shared/models/course_model.dart';
import 'package:escuelamak/features/tasks/presentation/tasks_screen.dart';
import 'package:escuelamak/features/quizzes/presentation/quizzes_screen.dart';
import 'package:escuelamak/features/profile/presentation/profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HOME SCREEN - Dashboard profesional estilo Google Classroom
// ═══════════════════════════════════════════════════════════════════════════

// Decide qué dashboard mostrar según el rol del usuario
class HomeScreen extends StatefulWidget {
  final String rol;
  final String nombre;

  const HomeScreen({super.key, required this.rol, required this.nombre});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Obtener el color según el rol
  Color get _roleColor => AppTheme.colorForRol(widget.rol);

  // Obtener titulo según el rol
  String get _roleTitle {
    switch (widget.rol) {
      case 'admin':
        return 'Panel de Administración';
      case 'teacher':
        return 'Mi Aula Virtual';
      default:
        return 'Mis Cursos';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar el color del rol en el tema
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _roleColor,
          brightness: Theme.of(context).brightness,
        ),
      ),
      child: _RoleBasedNavigator(
        rol: widget.rol,
        nombre: widget.nombre,
        roleColor: _roleColor,
        roleTitle: _roleTitle,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NAVEGADOR BASADO EN ROL - estilo Google Classroom
// ═══════════════════════════════════════════════════════════════════════════

class _RoleBasedNavigator extends StatefulWidget {
  final String rol;
  final String nombre;
  final Color roleColor;
  final String roleTitle;

  const _RoleBasedNavigator({
    required this.rol,
    required this.nombre,
    required this.roleColor,
    required this.roleTitle,
  });

  @override
  State<_RoleBasedNavigator> createState() => _RoleBasedNavigatorState();
}

class _RoleBasedNavigatorState extends State<_RoleBasedNavigator> {
  int _selectedIndex = 0;

  // Navegación diferente según el rol
  List<NavigationItem> get _navigationItems {
    switch (widget.rol) {
      case 'admin':
        return [
          NavigationItem(Icons.home_rounded, 'Inicio', 0),
          NavigationItem(Icons.school_rounded, 'Cursos', 1),
          NavigationItem(Icons.people_rounded, 'Usuarios', 2),
          NavigationItem(Icons.bar_chart_rounded, 'Reportes', 3),
          NavigationItem(Icons.person_rounded, 'Perfil', 4),
        ];
      case 'teacher':
        return [
          NavigationItem(Icons.home_rounded, 'Inicio', 0),
          NavigationItem(Icons.book_rounded, 'Mis Clases', 1),
          NavigationItem(Icons.assignment_rounded, 'Tareas', 2),
          NavigationItem(Icons.quiz_rounded, 'Quizzes', 3),
          NavigationItem(Icons.person_rounded, 'Perfil', 4),
        ];
      default: // estudiante
        return [
          NavigationItem(Icons.home_rounded, 'Inicio', 0),
          NavigationItem(Icons.book_rounded, 'Cursos', 1),
          NavigationItem(Icons.assignment_rounded, 'Tareas', 2),
          NavigationItem(Icons.quiz_rounded, 'Exámenes', 3),
          NavigationItem(Icons.person_rounded, 'Perfil', 4),
        ];
    }
  }

  // Obtener el contenido según el tab seleccionado
  Widget get _currentContent {
    switch (_selectedIndex) {
      case 0:
        return _DashboardHome(
          nombre: widget.nombre,
          rol: widget.rol,
          roleColor: widget.roleColor,
          roleTitle: widget.roleTitle,
        );
      case 1:
        return _CoursesTab(
          rol: widget.rol,
          roleColor: widget.roleColor,
        );
      case 2:
        // Tareas para teacher y student; Usuarios (coming soon) para admin
        if (widget.rol == 'admin') {
          return _ComingSoonScreen(
            title: 'Usuarios',
            icon: Icons.people_rounded,
            color: widget.roleColor,
          );
        }
        return TasksScreen(color: widget.roleColor);
      case 3:
        // Quizzes/Exámenes para teacher y student; Reportes para admin
        if (widget.rol == 'admin') {
          return _ComingSoonScreen(
            title: 'Reportes',
            icon: Icons.bar_chart_rounded,
            color: widget.roleColor,
          );
        }
        return QuizzesScreen(color: widget.roleColor);
      case 4:
        return ProfileScreen(
          nombre: widget.nombre,
          rol: widget.rol,
          color: widget.roleColor,
        );
      default:
        return _DashboardHome(
          nombre: widget.nombre,
          rol: widget.rol,
          roleColor: widget.roleColor,
          roleTitle: widget.roleTitle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentContent,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          indicatorColor: widget.roleColor.withOpacity(0.15),
          destinations: _navigationItems.map((item) {
            return NavigationDestination(
              icon: Icon(item.icon, color: Colors.grey),
              selectedIcon: Icon(item.icon, color: widget.roleColor),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DASHBOARD HOME - Pantalla principal con módulos y cursos
// ═══════════════════════════════════════════════════════════════════════════

class _DashboardHome extends ConsumerWidget {
  final String nombre;
  final String rol;
  final Color roleColor;
  final String roleTitle;

  const _DashboardHome({
    required this.nombre,
    required this.rol,
    required this.roleColor,
    required this.roleTitle,
  });

  String get _firstName =>
      nombre.isNotEmpty ? nombre.split(' ').first : 'Usuario';
  String get _initial =>
      _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'U';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(roleTitle),
        backgroundColor: roleColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 8),
                    Text('Configuración'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Recargar cursos
          ref.invalidate(coursesProvider(rol));
        },
        child: CustomScrollView(
          slivers: [
            // Bienvenida con avatar
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: _WelcomeCard(
                  firstName: _firstName,
                  initial: _initial,
                  role: rol,
                  roleColor: roleColor,
                ),
              ),
            ),

            // Sección de cursos desde Supabase
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: Row(
                    children: [
                      Icon(Icons.school, color: roleColor),
                      const SizedBox(width: 8),
                      Text(
                        'Mis Cursos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Lista de cursos desde Supabase
            _CoursesList(
              role: rol,
              roleColor: roleColor,
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir de la app?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTA DE CURSOS DESDE SUPABASE
// ═══════════════════════════════════════════════════════════════════════════

class _CoursesList extends ConsumerWidget {
  final String role;
  final Color roleColor;

  const _CoursesList({
    required this.role,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider(role));

    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyCourses(roleColor: roleColor),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final course = courses[index];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 100 * (index + 2)),
                  child: _CourseCard(
                    course: course,
                    roleColor: roleColor,
                    onTap: () => _openCourseDetail(context, course, roleColor),
                  ),
                );
              },
              childCount: courses.length,
            ),
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: _LoadingCourses(),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: _ErrorCourses(error: e.toString()),
      ),
    );
  }

  void _openCourseDetail(
      BuildContext context, CourseModel course, Color color) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(
          courseId: course.id,
          courseColor: color,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA DE CURSO
// ═══════════════════════════════════════════════════════════════════════════

class _CourseCard extends StatefulWidget {
  final CourseModel course;
  final Color roleColor;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.roleColor,
    required this.onTap,
  });

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  Color get _courseColor {
    // Obtener color según categoría
    switch (widget.course.category.toLowerCase()) {
      case 'matemáticas':
      case 'math':
        return Colors.blue;
      case 'ciencias':
      case 'science':
        return Colors.green;
      case 'historia':
      case 'history':
        return Colors.orange;
      case 'literatura':
      case 'literature':
        return Colors.purple;
      case 'programación':
      case 'coding':
        return Colors.cyan;
      default:
        return widget.roleColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.08 : 0.05),
                blurRadius: _isPressed ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Color lateral
              Container(
                width: 6,
                height: 100,
                decoration: BoxDecoration(
                  color: _courseColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icono
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _courseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.school,
                          color: _courseColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Texto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.course.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.course.teacherName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _courseColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.course.category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _courseColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.people_outline,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.course.enrollmentCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Flecha
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ESTADOS DE LA LISTA DE CURSOS
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyCourses extends StatelessWidget {
  final Color roleColor;

  const _EmptyCourses({required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.school_outlined,
              size: 40,
              color: roleColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay cursos disponibles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pronto tendrás acceso a tus cursos',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCourses extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CourseCardSkeleton(),
          ),
        ),
      ),
    );
  }
}

class _CourseCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SkeletonBox(width: 56, height: 56, borderRadius: 14),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonBox(width: 150, height: 14),
                        const SizedBox(height: 8),
                        SkeletonBox(width: 100, height: 12),
                        const SizedBox(height: 8),
                        SkeletonBox(width: 80, height: 20, borderRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCourses extends StatelessWidget {
  final String error;

  const _ErrorCourses({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar cursos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA DE "PRÓXIMAMENTE"
// ═══════════════════════════════════════════════════════════════════════════

class _ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _ComingSoonScreen({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                icon,
                size: 60,
                color: color.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Módulo en desarrollo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA DE CURSOS - Usa la API para mostrar cursos
// ═══════════════════════════════════════════════════════════════════════════

class _CoursesTab extends ConsumerWidget {
  final String rol;
  final Color roleColor;

  const _CoursesTab({
    required this.rol,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usar el provider de cursos
    final coursesAsync = ref.watch(coursesProvider(rol));

    return Scaffold(
      appBar: AppBar(
        title: Text(rol == 'teacher' ? 'Mis Cursos' : 'Cursos'),
        backgroundColor: roleColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay cursos disponibles',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _HomeCourseCard(
                course: course,
                color: roleColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseDetailScreen(
                        courseId: course.id,
                        courseColor: roleColor,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error: ${e.toString()}'),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA DE CURSO
// ═══════════════════════════════════════════════════════════════════════════

class _HomeCourseCard extends StatelessWidget {
  final CourseModel course;
  final Color color;
  final VoidCallback onTap;

  const _HomeCourseCard({
    required this.course,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen o color de cabecera
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        course.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.school, size: 40, color: color),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.school, size: 40, color: color),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (course.description.isNotEmpty)
                    Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        course.teacherName,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course.category,
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA DE BIENVENIDA
// ═══════════════════════════════════════════════════════════════════════════

class _WelcomeCard extends StatelessWidget {
  final String firstName;
  final String initial;
  final String role;
  final Color roleColor;

  const _WelcomeCard({
    required this.firstName,
    required this.initial,
    required this.role,
    required this.roleColor,
  });

  String get _roleLabel {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'teacher':
        return 'Profesor';
      default:
        return 'Estudiante';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            roleColor,
            roleColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: roleColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Texto de bienvenida
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $firstName! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _roleLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Icono decorativo
          Icon(
            _getRoleIcon(),
            color: Colors.white.withOpacity(0.3),
            size: 48,
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon() {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'teacher':
        return Icons.school_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO DE DATOS
// ═══════════════════════════════════════════════════════════════════════════

class NavigationItem {
  final IconData icon;
  final String label;
  final int index;

  NavigationItem(this.icon, this.label, this.index);
}
