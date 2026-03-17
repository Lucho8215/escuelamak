import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escuelamak/shared/models/course_model.dart';
import 'package:escuelamak/features/courses/presentation/courses_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA DE CONTENIDO DE MÓDULO
// ═══════════════════════════════════════════════════════════════════════════

class ModuleContentScreen extends ConsumerStatefulWidget {
  final ClassModel? classModel;
  final ModuleModel? module;
  final Color courseColor;

  const ModuleContentScreen({
    super.key,
    this.classModel,
    this.module,
    required this.courseColor,
  }) : assert(classModel != null || module != null,
            'Must provide either classModel or module');

  // Helper to get the title
  String get title => classModel?.title ?? module?.title ?? '';

  // Helper to get the id
  String get id => classModel?.id ?? module?.id ?? '';

  // Helper to get content type or status
  String get contentType => classModel?.status ?? module?.contentType ?? 'text';

  // Helper to get duration
  int get duration => classModel?.duration ?? module?.durationMinutes ?? 0;

  // Helper to get description
  String get description =>
      classModel?.description ?? module?.description ?? '';

  // Helper to get content
  String? get content => classModel?.content ?? module?.content;

  @override
  ConsumerState<ModuleContentScreen> createState() =>
      _ModuleContentScreenState();
}

class _ModuleContentScreenState extends ConsumerState<ModuleContentScreen> {
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.courseColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del módulo
            _ModuleHeader(
              contentType: widget.contentType,
              duration: widget.duration,
              title: widget.title,
              description: widget.description,
              color: widget.courseColor,
            ),
            const SizedBox(height: 24),

            // Contenido del módulo
            _ModuleContent(
              content: widget.content,
              description: widget.description,
              color: widget.courseColor,
            ),
            const SizedBox(height: 32),

            // Botón de completar
            _CompleteButton(
              id: widget.id,
              color: widget.courseColor,
              isLoading: _isCompleting,
              onComplete: _completeModule,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeModule() async {
    setState(() => _isCompleting = true);

    try {
      // Use class enrollment for classes
      if (widget.classModel != null) {
        final success = await ref
            .read(classEnrollmentProvider.notifier)
            .enrollInClass(widget.id);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Clase completada! 🎉'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Use module completion for modules
        final success = await ref
            .read(moduleCompletionProvider.notifier)
            .complete(widget.id);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Módulo completado! 🎉'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENCABEZADO DEL MÓDULO
// ═══════════════════════════════════════════════════════════════════════════

class _ModuleHeader extends StatelessWidget {
  final String contentType;
  final int duration;
  final String title;
  final String description;
  final Color color;

  const _ModuleHeader({
    required this.contentType,
    required this.duration,
    required this.title,
    required this.description,
    required this.color,
  });

  IconData get _contentTypeIcon {
    switch (contentType.toLowerCase()) {
      case 'video':
        return Icons.play_circle;
      case 'quiz':
        return Icons.quiz;
      case 'assignment':
        return Icons.assignment;
      case 'document':
        return Icons.description;
      case 'link':
        return Icons.link;
      default:
        return Icons.article;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_contentTypeIcon, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      contentType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (duration > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '$duration min',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTENIDO DEL MÓDULO
// ═══════════════════════════════════════════════════════════════════════════

class _ModuleContent extends StatelessWidget {
  final String? content;
  final String description;
  final Color color;
  final String contentType;

  const _ModuleContent({
    this.content,
    required this.description,
    required this.color,
    this.contentType = 'text',
  });

  @override
  Widget build(BuildContext context) {
    // Mostrar según el tipo de contenido
    if (contentType.toLowerCase() == 'video') {
      return _TextContent(
        content: content ?? description,
        color: color,
      );
    } else if (contentType.toLowerCase() == 'quiz') {
      return _TextContent(
        content: content ?? description,
        color: color,
      );
    } else {
      return _TextContent(
        content: content ?? description,
        color: color,
      );
    }
  }
}

class _TextContent extends StatelessWidget {
  final String content;
  final Color color;

  const _TextContent({
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(Icons.article, color: color),
              const SizedBox(width: 8),
              Text(
                'Contenido',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content.isNotEmpty ? content : 'Contenido no disponible',
            style: TextStyle(
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoContent extends StatelessWidget {
  final String? contentUrl;
  final String? content;
  final Color color;

  const _VideoContent({
    this.contentUrl,
    this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(Icons.play_circle, color: color),
              const SizedBox(width: 8),
              Text(
                'Video',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Placeholder para video
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: contentUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      contentUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildVideoPlaceholder(),
                    ),
                  )
                : _buildVideoPlaceholder(),
          ),

          if (content != null && content!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              content!,
              style: TextStyle(height: 1.5, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline,
              size: 64, color: color.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(
            'Video no disponible',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _QuizContent extends StatelessWidget {
  final String? content;
  final Color color;

  const _QuizContent({
    this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(Icons.quiz, color: color),
              const SizedBox(width: 8),
              Text(
                'Quiz / Examen',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (content != null && content!.isNotEmpty)
            Text(
              content!,
              style: TextStyle(height: 1.5, color: Colors.grey[700]),
            )
          else
            Center(
              child: Column(
                children: [
                  Icon(Icons.quiz_outlined,
                      size: 64, color: color.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  Text(
                    'Quiz disponible',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTÓN DE COMPLETAR
// ═══════════════════════════════════════════════════════════════════════════

class _CompleteButton extends StatelessWidget {
  final String id;
  final Color color;
  final bool isLoading;
  final VoidCallback onComplete;

  const _CompleteButton({
    required this.id,
    required this.color,
    required this.isLoading,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onComplete,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle),
        label: Text(
          isLoading ? 'Completando...' : 'Marcar como completado',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
