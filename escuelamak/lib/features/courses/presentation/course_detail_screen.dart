import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escuelamak/shared/models/course_model.dart';
import 'package:escuelamak/features/courses/presentation/courses_providers.dart';
import 'package:escuelamak/core/theme/app_theme.dart';
import 'package:escuelamak/features/lessons/presentation/lessons_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA DE DETALLE DE CURSO
// ═══════════════════════════════════════════════════════════════════════════

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;
  final Color? courseColor;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.courseColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseWithClassesAsync = ref.watch(courseDetailProvider(courseId));
    final color = courseColor ?? AppTheme.seedColor;

    return Scaffold(
      body: courseWithClassesAsync.when(
        data: (courseWithClasses) {
          if (courseWithClasses == null) {
            return _buildNotFound(context);
          }
          return _buildContent(context, ref, courseWithClasses, color);
        },
        loading: () => _buildLoading(color),
        error: (e, _) => _buildError(context, e.toString()),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    CourseWithClasses courseWithClasses,
    Color color,
  ) {
    final course = courseWithClasses.course;
    final classes = courseWithClasses.classes;
    return CustomScrollView(
      slivers: [
        // AppBar con imagen
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: color,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              course.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            background: course.imageUrl != null
                ? Image.network(
                    course.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildHeaderBackground(color),
                  )
                : _buildHeaderBackground(color),
          ),
        ),

        // Información del curso
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: _CourseInfoCard(course: course, color: color),
          ),
        ),

        // Encabezado de módulos
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Contenido del Curso',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Lista de clases
        classes.isEmpty
            ? SliverToBoxAdapter(
                child: _buildEmptyModules(),
              )
            : _buildModulesList(context, ref, classes, color),

        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  Widget _buildModulesList(
    BuildContext context,
    WidgetRef ref,
    List<ClassModel> modules,
    Color color,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final module = modules[index];
            return FadeSlideIn(
              delay: Duration(milliseconds: 100 * (index + 3)),
              child: _ModuleCard(
                classModel: module,
                index: index + 1,
                color: color,
                onTap: () => _openClassContent(context, module, color),
              ),
            );
          },
          childCount: modules.length,
        ),
      ),
    );
  }

  void _openClassContent(
      BuildContext context, ClassModel classModel, Color color) {
    // Navegar a las lecciones de la clase
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonsScreen(
          classId: classModel.id,
          classTitle: classModel.title,
          color: color,
        ),
      ),
    );
  }


  Widget _buildHeaderBackground(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.school_rounded,
          size: 64,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildLoading(Color color) {
    return Scaffold(
      appBar: AppBar(backgroundColor: color),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Curso no encontrado')),
      body: const Center(child: Text('El curso no existe')),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Error: $error')),
    );
  }

  Widget _buildEmptyModules() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay módulos disponibles',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingModules() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ModuleCardSkeleton(),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA DE INFORMACIÓN DEL CURSO
// ═══════════════════════════════════════════════════════════════════════════

class _CourseInfoCard extends StatelessWidget {
  final CourseModel course;
  final Color color;

  const _CourseInfoCard({
    required this.course,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categoría
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              course.category,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Descripción
          Text(
            course.description,
            style: TextStyle(
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Información adicional
          Row(
            children: [
              _InfoChip(
                icon: Icons.person,
                label: course.teacherName,
                color: color,
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.people,
                label: '${course.enrollmentCount} estudiantes',
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETA DE MÓDULO
// ═══════════════════════════════════════════════════════════════════════════

class _ModuleCard extends StatelessWidget {
  final ClassModel classModel;
  final int index;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.classModel,
    required this.index,
    required this.color,
    required this.onTap,
  });

  String get _contentTypeText {
    // ClassModel doesn't have contentType, use status or default
    return classModel.status.isNotEmpty
        ? classModel.status.toUpperCase()
        : 'CLASE';
  }

  IconData get _contentTypeIcon {
    // Use class status or default icon
    return Icons.class_outlined;
  }

  int get _duration => classModel.duration ?? classModel.classNumber * 30;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Número de módulo
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classModel.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _contentTypeIcon,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _contentTypeText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_duration > 0) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_duration min',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SKELETON DE TARJETA DE MÓDULO
// ═══════════════════════════════════════════════════════════════════════════

class _ModuleCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SkeletonBox(width: 36, height: 36, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 180, height: 14),
                const SizedBox(height: 8),
                SkeletonBox(width: 120, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
