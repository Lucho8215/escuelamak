import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/features/courses/data/courses_repository.dart';
import 'package:escuelamak/shared/models/quiz_model.dart';
import 'package:escuelamak/features/quizzes/presentation/quiz_taking_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA: Lista de quizzes del usuario
// ═══════════════════════════════════════════════════════════════════════════

class QuizzesScreen extends StatefulWidget {
  final Color color;

  const QuizzesScreen({super.key, required this.color});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen>
    with SingleTickerProviderStateMixin {
  final _repo = CoursesRepository();
  List<QuizModel> _quizzes = [];
  bool _loading = true;
  late TabController _tabController;

  List<QuizModel> get _pending =>
      _quizzes.where((q) => !q.isCompleted).toList();
  List<QuizModel> get _completed =>
      _quizzes.where((q) => q.isCompleted).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuizzes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _loading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final quizzes = await _repo.getQuizzes(userId);
    if (mounted) setState(() { _quizzes = quizzes; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Exámenes'),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Pendientes (${_pending.length})'),
            Tab(text: 'Completados (${_completed.length})'),
          ],
        ),
      ),
      body: _loading
          ? _buildSkeleton()
          : TabBarView(
              controller: _tabController,
              children: [
                _QuizList(
                  quizzes: _pending,
                  color: widget.color,
                  emptyMessage: 'No tienes exámenes pendientes',
                  emptyIcon: Icons.check_circle_outline,
                  onTap: _openQuiz,
                ),
                _QuizList(
                  quizzes: _completed,
                  color: widget.color,
                  emptyMessage: 'Aún no has completado exámenes',
                  emptyIcon: Icons.quiz_outlined,
                  onTap: _openQuiz,
                ),
              ],
            ),
    );
  }

  Future<void> _openQuiz(QuizModel quiz) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizTakingScreen(
          quizId: quiz.id,
          quizTitle: quiz.title,
          color: widget.color,
        ),
      ),
    );
    _loadQuizzes();
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(3, (_) => const _QuizSkeleton()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista de quizzes
// ─────────────────────────────────────────────────────────────────────────────

class _QuizList extends StatelessWidget {
  final List<QuizModel> quizzes;
  final Color color;
  final String emptyMessage;
  final IconData emptyIcon;
  final void Function(QuizModel) onTap;

  const _QuizList({
    required this.quizzes,
    required this.color,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizzes.length,
        itemBuilder: (ctx, i) => _QuizCard(
          quiz: quizzes[i],
          color: color,
          onTap: () => onTap(quizzes[i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de quiz
// ─────────────────────────────────────────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final Color color;
  final VoidCallback onTap;

  const _QuizCard({
    required this.quiz,
    required this.color,
    required this.onTap,
  });

  Color get _difficultyColor {
    switch (quiz.difficulty) {
      case 'easy': return Colors.green;
      case 'hard': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = quiz.isCompleted;
    final lastAttempt = quiz.lastAttempt;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
        border: completed
            ? Border.all(color: Colors.green.withOpacity(0.4))
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: completed
                          ? Colors.green.withOpacity(0.1)
                          : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      completed ? Icons.verified_rounded : Icons.quiz_rounded,
                      color: completed ? Colors.green : color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(quiz.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        if (quiz.category != null) ...[
                          const SizedBox(height: 2),
                          Text(quiz.category!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500])),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              // Chips de info
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Chip(
                    label: quiz.difficultyLabel,
                    color: _difficultyColor,
                    icon: Icons.signal_cellular_alt,
                  ),
                  if (quiz.timeLimit != null)
                    _Chip(
                      label: '${quiz.timeLimit} min',
                      color: Colors.blue,
                      icon: Icons.timer_outlined,
                    ),
                  _Chip(
                    label: 'Aprobación: ${quiz.passingScore}%',
                    color: Colors.purple,
                    icon: Icons.flag_outlined,
                  ),
                ],
              ),
              // Resultado del último intento
              if (lastAttempt != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: lastAttempt.passed
                        ? Colors.green.withOpacity(0.08)
                        : Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        lastAttempt.passed
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 14,
                        color: lastAttempt.passed ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        lastAttempt.passed
                            ? 'Aprobado — ${lastAttempt.score}%'
                            : 'No aprobado — ${lastAttempt.score}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: lastAttempt.passed ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Fecha límite
              if (quiz.dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Vence: ${_formatDate(quiz.dueDate!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Chip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _QuizSkeleton extends StatelessWidget {
  const _QuizSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 160, color: Colors.grey[200]),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 100, color: Colors.grey[200]),
                ]),
          ),
        ],
      ),
    );
  }
}
