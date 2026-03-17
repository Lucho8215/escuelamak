import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/features/courses/data/courses_repository.dart';
import 'package:escuelamak/shared/models/lesson_model.dart';
import 'package:escuelamak/features/lessons/presentation/lesson_detail_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA: Lista de lecciones de una clase
// ═══════════════════════════════════════════════════════════════════════════

class LessonsScreen extends StatefulWidget {
  final String classId;
  final String classTitle;
  final Color color;

  const LessonsScreen({
    super.key,
    required this.classId,
    required this.classTitle,
    required this.color,
  });

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final _repo = CoursesRepository();
  List<LessonModel> _lessons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() { _loading = true; _error = null; });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final lessons = await _repo.getLessons(widget.classId, userId);
      if (mounted) setState(() { _lessons = lessons; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classTitle),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? _buildSkeleton()
          : _error != null
              ? _buildError()
              : _lessons.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadLessons,
                      child: _buildList(),
                    ),
    );
  }

  Widget _buildList() {
    final completed = _lessons.where((l) => l.isCompleted).length;
    final total = _lessons.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Progreso general
        _ProgressHeader(
          completed: completed,
          total: total,
          color: widget.color,
        ),
        const SizedBox(height: 16),
        // Lista de lecciones
        ...List.generate(_lessons.length, (i) {
          final lesson = _lessons[i];
          return _LessonCard(
            lesson: lesson,
            index: i + 1,
            color: widget.color,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LessonDetailScreen(
                    lessonId: lesson.id,
                    lessonTitle: lesson.title,
                    color: widget.color,
                  ),
                ),
              );
              _loadLessons(); // Recargar progreso al volver
            },
          );
        }),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(4, (_) => const _LessonSkeleton()),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No hay lecciones disponibles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Las lecciones aparecerán aquí cuando estén publicadas',
              style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text('Error al cargar lecciones',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _loadLessons,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Encabezado de progreso general
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final int completed;
  final int total;
  final Color color;

  const _ProgressHeader({
    required this.completed,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? completed / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tu progreso', style: TextStyle(fontWeight: FontWeight.w600, color: color)),
              Text('$completed / $total lecciones',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text('${(pct * 100).round()}% completado',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de lección
// ─────────────────────────────────────────────────────────────────────────────

class _LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final int index;
  final Color color;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.index,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = lesson.isCompleted;
    final pct = lesson.progressPct;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
        ],
        border: completed
            ? Border.all(color: Colors.green.withOpacity(0.4))
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Número / check
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: completed
                      ? Colors.green.withOpacity(0.12)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: completed
                      ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24)
                      : Text('$index',
                          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (lesson.summary != null && lesson.summary!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(lesson.summary!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (lesson.estimatedMinutes > 0) ...[
                          Icon(Icons.timer_outlined, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text('${lesson.estimatedMinutes} min',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          const SizedBox(width: 10),
                        ],
                        if (lesson.hasVideo)
                          _TypeChip(icon: Icons.play_circle_outline, label: 'Video', color: Colors.blue),
                        if (lesson.hasFile)
                          _TypeChip(icon: Icons.attach_file, label: 'Archivo', color: Colors.orange),
                        if (!completed && pct > 0) ...[
                          const Spacer(),
                          Text('$pct%',
                              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                    // Barra mini de progreso si está en progreso
                    if (!completed && pct > 0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 4,
                          backgroundColor: color.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TypeChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _LessonSkeleton extends StatelessWidget {
  const _LessonSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 14, width: 180, color: Colors.grey[200]),
              const SizedBox(height: 8),
              Container(height: 12, width: 120, color: Colors.grey[200]),
            ]),
          ),
        ],
      ),
    );
  }
}
