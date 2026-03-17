import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:escuelamak/features/courses/data/courses_repository.dart';
import 'package:escuelamak/shared/models/lesson_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA: Detalle / visor de lección
// ═══════════════════════════════════════════════════════════════════════════

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final Color color;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.color,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final _repo = CoursesRepository();
  LessonModel? _lesson;
  bool _loading = true;
  bool _markingComplete = false;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    setState(() => _loading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final lesson = await _repo.getLessonDetail(widget.lessonId, userId);
    if (mounted) setState(() { _lesson = lesson; _loading = false; });
  }

  Future<void> _markComplete() async {
    if (_lesson == null) return;
    setState(() => _markingComplete = true);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final ok = await _repo.updateLessonProgress(
      widget.lessonId,
      userId,
      progressPct: 100,
      completed: true,
    );
    if (mounted) {
      setState(() => _markingComplete = false);
      if (ok) {
        setState(() {
          _lesson!.progress = LessonProgressData(
            status: 'completed',
            progressPct: 100,
            completed: true,
            lastPosition: 0,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Lección completada'),
            ]),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _loading
          ? _buildLoading()
          : _lesson == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        title: Text(widget.lessonTitle),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        title: Text(widget.lessonTitle),
      ),
      body: const Center(child: Text('No se pudo cargar la lección')),
    );
  }

  Widget _buildContent() {
    final lesson = _lesson!;
    final completed = lesson.isCompleted;

    return CustomScrollView(
      slivers: [
        // AppBar expandible con imagen si existe
        SliverAppBar(
          expandedHeight: lesson.coverImageUrl != null ? 200 : 120,
          pinned: true,
          backgroundColor: widget.color,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              lesson.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 2,
            ),
            background: lesson.coverImageUrl != null
                ? Image.network(
                    lesson.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: widget.color),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.color, widget.color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
          ),
          actions: [
            if (completed)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.check_circle, color: Colors.greenAccent),
              ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chips de info
                Wrap(
                  spacing: 8,
                  children: [
                    if (lesson.estimatedMinutes > 0)
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: '${lesson.estimatedMinutes} min',
                        color: widget.color,
                      ),
                    if (lesson.hasVideo)
                      _InfoChip(icon: Icons.play_circle_outline, label: 'Video', color: Colors.blue),
                    if (lesson.hasFile)
                      _InfoChip(icon: Icons.attach_file, label: 'Recurso', color: Colors.orange),
                    if (completed)
                      const _InfoChip(icon: Icons.verified, label: 'Completada', color: Colors.green),
                  ],
                ),

                const SizedBox(height: 20),

                // Objetivo
                if (lesson.objective != null && lesson.objective!.isNotEmpty) ...[
                  _SectionTitle('Objetivo'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.color.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.flag_outlined, color: widget.color, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(lesson.objective!,
                              style: const TextStyle(fontSize: 14, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Recursos multimedia
                if (lesson.hasVideo) ...[
                  _SectionTitle('Video de la lección'),
                  const SizedBox(height: 8),
                  _ResourceButton(
                    icon: Icons.play_circle_filled,
                    label: 'Ver video',
                    color: Colors.blue,
                    onTap: () => _openUrl(lesson.resourceLink ?? lesson.videoUrl!),
                  ),
                  const SizedBox(height: 16),
                ],

                if (lesson.hasLink && !lesson.hasVideo) ...[
                  _SectionTitle('Recurso externo'),
                  const SizedBox(height: 8),
                  _ResourceButton(
                    icon: Icons.open_in_new,
                    label: 'Abrir recurso',
                    color: Colors.indigo,
                    onTap: () => _openUrl(lesson.resourceLink!),
                  ),
                  const SizedBox(height: 16),
                ],

                if (lesson.hasFile) ...[
                  _SectionTitle('Archivo adjunto'),
                  const SizedBox(height: 8),
                  _ResourceButton(
                    icon: Icons.download_outlined,
                    label: 'Descargar archivo',
                    color: Colors.orange,
                    onTap: () => _openUrl(lesson.resourceFileUrl!),
                  ),
                  const SizedBox(height: 16),
                ],

                // Contenido de la lección
                if (lesson.content != null && lesson.content!.isNotEmpty) ...[
                  _SectionTitle('Contenido'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      lesson.content!,
                      style: const TextStyle(fontSize: 15, height: 1.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Botón marcar como completada
                if (!completed) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _markingComplete ? null : _markComplete,
                      icon: _markingComplete
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _markingComplete ? 'Guardando...' : 'Marcar como completada',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Lección completada',
                            style: TextStyle(
                                color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ResourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ResourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 14, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
