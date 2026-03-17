import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/features/courses/data/courses_repository.dart';
import 'package:escuelamak/shared/models/quiz_model.dart';
import 'package:escuelamak/features/quizzes/presentation/quiz_taking_screen.dart';
import 'package:escuelamak/features/lessons/presentation/lesson_detail_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA: Tareas del estudiante (lecciones + quizzes asignados)
// ═══════════════════════════════════════════════════════════════════════════

class TasksScreen extends StatefulWidget {
  final Color color;

  const TasksScreen({super.key, required this.color});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  final _repo = CoursesRepository();
  List<TaskItem> _tasks = [];
  bool _loading = true;
  late TabController _tabController;

  List<TaskItem> get _pending => _tasks.where((t) => !t.completed).toList();
  List<TaskItem> get _done => _tasks.where((t) => t.completed).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final tasks = await _repo.getTasks(userId);
    if (mounted) setState(() { _tasks = tasks; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
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
            Tab(text: 'Completadas (${_done.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_pending),
                _buildList(_done),
              ],
            ),
    );
  }

  Widget _buildList(List<TaskItem> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0
                  ? 'No tienes tareas pendientes'
                  : 'Aún no tienes tareas completadas',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (ctx, i) => _TaskCard(
          task: tasks[i],
          color: widget.color,
          onTap: () => _openTask(tasks[i]),
        ),
      ),
    );
  }

  Future<void> _openTask(TaskItem task) async {
    if (task.isQuiz) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizTakingScreen(
            quizId: task.id,
            quizTitle: task.title,
            color: widget.color,
          ),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonDetailScreen(
            lessonId: task.id,
            lessonTitle: task.title,
            color: widget.color,
          ),
        ),
      );
    }
    _loadTasks();
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de tarea
// ─────────────────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final Color color;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.color,
    required this.onTap,
  });

  Color get _typeColor => task.isQuiz ? Colors.purple : Colors.blue;
  IconData get _typeIcon =>
      task.isQuiz ? Icons.quiz_rounded : Icons.menu_book_rounded;

  @override
  Widget build(BuildContext context) {
    final completed = task.completed;
    final hasDueDate = task.dueDate != null;
    final isOverdue =
        hasDueDate && task.dueDate!.isBefore(DateTime.now()) && !completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3)),
        ],
        border: completed
            ? Border.all(color: Colors.green.withOpacity(0.3))
            : isOverdue
                ? Border.all(color: Colors.red.withOpacity(0.4))
                : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icono de tipo
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: completed
                      ? Colors.green.withOpacity(0.1)
                      : _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  completed ? Icons.check_circle_rounded : _typeIcon,
                  color: completed ? Colors.green : _typeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.isQuiz ? 'Quiz' : 'Lección',
                            style: TextStyle(
                                fontSize: 10,
                                color: _typeColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (completed) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Completada',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                        if (isOverdue) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Vencida',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        task.subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (task.estimatedMinutes > 0) ...[
                          Icon(Icons.timer_outlined,
                              size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text('${task.estimatedMinutes} min',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500])),
                          const SizedBox(width: 10),
                        ],
                        if (hasDueDate) ...[
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: isOverdue ? Colors.red : Colors.grey[500],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatDate(task.dueDate!),
                            style: TextStyle(
                                fontSize: 11,
                                color: isOverdue ? Colors.red : Colors.grey[500],
                                fontWeight: isOverdue ? FontWeight.w600 : null),
                          ),
                        ],
                      ],
                    ),
                    // Barra de progreso (lecciones en progreso)
                    if (!completed && task.progressPct > 0 && task.isLesson) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: task.progressPct / 100,
                                minHeight: 4,
                                backgroundColor: color.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${task.progressPct}%',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600)),
                        ],
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
