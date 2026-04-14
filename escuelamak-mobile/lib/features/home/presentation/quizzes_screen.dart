// ============================================================
// QUIZZES SCREEN — Módulo de Evaluaciones
// ============================================================
// Pantallas:
//   1. QuizzesScreen   — Lista de quizzes asignados
//   2. QuizDetailScreen — Detalle antes de comenzar
//   3. QuizPlayScreen  — Realizar el quiz con temporizador
//   4. QuizResultScreen — Resultados al terminar
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:escuelamak/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────

class QuizModel {
  final String id;
  final String titulo;
  final String? descripcion;
  final String? categoria;
  final String? dificultad;
  final int tiempoLimite; // minutos
  final int puntajeMinimo; // para aprobar
  final bool isEnabled;
  final bool isActive;

  // Datos del assignment (si fue asignado al estudiante)
  final String? assignmentId;
  final bool isCompleted;
  final DateTime? dueDate;

  // Datos del intento (si ya lo hizo)
  final int? score;
  final bool? passed;

  const QuizModel({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.categoria,
    this.dificultad,
    required this.tiempoLimite,
    required this.puntajeMinimo,
    required this.isEnabled,
    required this.isActive,
    this.assignmentId,
    required this.isCompleted,
    this.dueDate,
    this.score,
    this.passed,
  });

  factory QuizModel.fromJson(Map<String, dynamic> j) => QuizModel(
        id: j['id'] as String,
        titulo: j['title'] as String? ?? 'Sin título',
        descripcion: j['description'] as String?,
        categoria: j['category'] as String?,
        dificultad: j['difficulty'] as String?,
        tiempoLimite: j['time_limit'] as int? ?? 30,
        puntajeMinimo: j['passing_score'] as int? ?? 70,
        isEnabled: j['is_enabled'] as bool? ?? true,
        isActive: j['is_active'] as bool? ?? true,
        assignmentId: j['assignment_id'] as String?,
        isCompleted: j['is_completed'] as bool? ?? false,
        dueDate: j['due_date'] != null
            ? DateTime.tryParse(j['due_date'] as String)
            : null,
        score: j['score'] as int?,
        passed: j['passed'] as bool?,
      );

  // Color según dificultad
  Color get difficultyColor {
    switch (dificultad?.toLowerCase()) {
      case 'easy':
      case 'facil':
        return Colors.green;
      case 'medium':
      case 'medio':
        return Colors.orange;
      case 'hard':
      case 'dificil':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String get difficultyLabel {
    switch (dificultad?.toLowerCase()) {
      case 'easy':
        return 'Fácil';
      case 'medium':
        return 'Medio';
      case 'hard':
        return 'Difícil';
      default:
        return dificultad ?? 'Normal';
    }
  }

  bool get venceHoy {
    if (dueDate == null) return false;
    final hoy = DateTime.now();
    return dueDate!.year == hoy.year &&
        dueDate!.month == hoy.month &&
        dueDate!.day == hoy.day;
  }
}

class QuestionModel {
  final String id;
  final String texto;
  final List<String> opciones;
  final int respuestaCorrecta; // índice de la opción correcta
  final String? explicacion;
  final int puntos;
  final int orden;

  const QuestionModel({
    required this.id,
    required this.texto,
    required this.opciones,
    required this.respuestaCorrecta,
    this.explicacion,
    required this.puntos,
    required this.orden,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> j) {
    final opts = j['options'];
    List<String> opciones = [];
    if (opts is List) {
      opciones = opts.map((o) => o.toString()).toList();
    }
    return QuestionModel(
      id: j['id'] as String,
      texto: j['text'] as String? ?? '',
      opciones: opciones,
      respuestaCorrecta: j['correct_answer'] as int? ?? 0,
      explicacion: j['explanation'] as String?,
      puntos: j['points'] as int? ?? 1,
      orden: j['order_number'] as int? ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PANTALLA 1: QuizzesScreen — Lista de quizzes
// ─────────────────────────────────────────────────────────────
class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  final _supabase = Supabase.instance.client;
  List<QuizModel> _quizzes = [];
  bool _loading = true;

  String get _myId => _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _loading = true);
    try {
      // Obtener quizzes asignados al estudiante
      final assignments = await _supabase
          .from('quiz_assignments')
          .select('id, quiz_id, is_completed, due_date')
          .eq('student_id', _myId);

      if ((assignments as List).isEmpty) {
        // Si no hay asignaciones, mostrar todos los quizzes activos
        final res = await _supabase
            .from('quizzes')
            .select()
            .eq('is_active', true)
            .eq('is_enabled', true)
            .order('created_at', ascending: false);

        setState(() {
          _quizzes = (res as List).map((j) => QuizModel.fromJson(j)).toList();
          _loading = false;
        });
        return;
      }

      // Para cada asignación, obtener el quiz y el intento
      final List<QuizModel> lista = [];
      for (final a in assignments) {
        try {
          final quiz = await _supabase
              .from('quizzes')
              .select()
              .eq('id', a['quiz_id'] as String)
              .maybeSingle();

          if (quiz == null) continue;

          // Buscar intento previo
          final attempt = await _supabase
              .from('quiz_attempts')
              .select('score, passed')
              .eq('quiz_id', a['quiz_id'] as String)
              .eq('student_id', _myId)
              .order('completed_at', ascending: false)
              .limit(1)
              .maybeSingle();

          lista.add(QuizModel.fromJson({
            ...quiz,
            'assignment_id': a['id'],
            'is_completed': a['is_completed'] ?? false,
            'due_date': a['due_date'],
            'score': attempt?['score'],
            'passed': attempt?['passed'],
          }));
        } catch (_) {}
      }

      setState(() {
        _quizzes = lista;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? _buildVacio()
              : RefreshIndicator(
                  onRefresh: _loadQuizzes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _quizzes.length,
                    itemBuilder: (ctx, i) => FadeSlideIn(
                      delay: Duration(milliseconds: i * 60),
                      child: _QuizCard(
                        quiz: _quizzes[i],
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => QuizDetailScreen(quiz: _quizzes[i]),
                          ),
                        ).then((_) => _loadQuizzes()),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildVacio() => Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No tienes quizzes asignados',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ));
}

// ─────────────────────────────────────────────────────────────
// WIDGET: Tarjeta de quiz
// ─────────────────────────────────────────────────────────────
class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback onTap;
  const _QuizCard({required this.quiz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Color del estado
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (quiz.isCompleted && quiz.passed == true) {
      statusColor = Colors.green;
      statusLabel = 'Aprobado ${quiz.score}%';
      statusIcon = Icons.check_circle_rounded;
    } else if (quiz.isCompleted && quiz.passed == false) {
      statusColor = Colors.red;
      statusLabel = 'Reprobado ${quiz.score}%';
      statusIcon = Icons.cancel_rounded;
    } else if (quiz.venceHoy) {
      statusColor = Colors.orange;
      statusLabel = 'Vence hoy';
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = Colors.blue;
      statusLabel = 'Pendiente';
      statusIcon = Icons.pending_rounded;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(quiz.titulo,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(statusLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            // Tiempo límite
            Icon(Icons.timer_rounded, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text('${quiz.tiempoLimite} min',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(width: 12),
            // Puntaje mínimo
            Icon(Icons.star_rounded, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text('Min: ${quiz.puntajeMinimo}%',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const Spacer(),
            // Dificultad
            if (quiz.dificultad != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: quiz.difficultyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(quiz.difficultyLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: quiz.difficultyColor,
                        fontWeight: FontWeight.w600)),
              ),
          ]),
          if (quiz.dueDate != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13,
                  color: quiz.venceHoy ? Colors.orange : Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'Vence: ${DateFormat('dd MMM yyyy', 'es').format(quiz.dueDate!)}',
                style: TextStyle(
                    fontSize: 12,
                    color: quiz.venceHoy ? Colors.orange : Colors.grey.shade600,
                    fontWeight:
                        quiz.venceHoy ? FontWeight.w600 : FontWeight.normal),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PANTALLA 2: QuizDetailScreen — Detalle antes de comenzar
// ─────────────────────────────────────────────────────────────
class QuizDetailScreen extends StatelessWidget {
  final QuizModel quiz;
  const QuizDetailScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Quiz'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Título
          FadeSlideIn(
              child: Text(quiz.titulo,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700))),
          const SizedBox(height: 12),

          // Descripción
          if (quiz.descripcion != null)
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade100)),
                child: Text(quiz.descripcion!,
                    style: const TextStyle(fontSize: 14, height: 1.6)),
              ),
            ),
          const SizedBox(height: 20),

          // Info cards
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Row(children: [
              Expanded(
                  child: _InfoCard(
                      Icons.timer_rounded,
                      '${quiz.tiempoLimite} min',
                      'Tiempo límite',
                      Colors.blue)),
              const SizedBox(width: 12),
              Expanded(
                  child: _InfoCard(Icons.star_rounded, '${quiz.puntajeMinimo}%',
                      'Para aprobar', Colors.green)),
              const SizedBox(width: 12),
              Expanded(
                  child: _InfoCard(Icons.speed_rounded, quiz.difficultyLabel,
                      'Dificultad', quiz.difficultyColor)),
            ]),
          ),
          const SizedBox(height: 32),

          // Resultado previo
          if (quiz.isCompleted) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (quiz.passed == true ? Colors.green : Colors.red)
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: (quiz.passed == true ? Colors.green : Colors.red)
                          .withOpacity(0.3)),
                ),
                child: Column(children: [
                  Icon(
                      quiz.passed == true
                          ? Icons.emoji_events_rounded
                          : Icons.sentiment_dissatisfied_rounded,
                      size: 48,
                      color: quiz.passed == true ? Colors.green : Colors.red),
                  const SizedBox(height: 8),
                  Text(quiz.passed == true ? '¡Aprobado!' : 'No aprobado',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color:
                              quiz.passed == true ? Colors.green : Colors.red)),
                  const SizedBox(height: 4),
                  Text('Puntaje: ${quiz.score}%',
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Botón comenzar
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: ElevatedButton.icon(
              icon: Icon(quiz.isCompleted
                  ? Icons.replay_rounded
                  : Icons.play_arrow_rounded),
              label: Text(
                  quiz.isCompleted ? 'Intentar de nuevo' : 'Comenzar Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuizPlayScreen(quiz: quiz)),
              ).then((_) => Navigator.pop(context)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String label;
  final Color color;
  const _InfoCard(this.icono, this.valor, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 6),
          Text(valor,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// PANTALLA 3: QuizPlayScreen — Realizar el quiz
// ─────────────────────────────────────────────────────────────
class QuizPlayScreen extends StatefulWidget {
  final QuizModel quiz;
  const QuizPlayScreen({super.key, required this.quiz});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final _supabase = Supabase.instance.client;

  List<QuestionModel> _preguntas = [];
  int _actual = 0;
  Map<String, int> _respuestas = {}; // preguntaId → índice seleccionado
  bool _loading = true;
  late int _segundos;
  Timer? _timer;
  String get _myId => _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _segundos = widget.quiz.tiempoLimite * 60;
    _loadPreguntas();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPreguntas() async {
    try {
      final res = await _supabase
          .from('questions')
          .select()
          .eq('quiz_id', widget.quiz.id)
          .order('order_number', ascending: true);

      setState(() {
        _preguntas =
            (res as List).map((j) => QuestionModel.fromJson(j)).toList();
        _loading = false;
      });

      // Iniciar temporizador
      _iniciarTimer();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_segundos <= 0) {
        t.cancel();
        _enviarQuiz(tiempoAgotado: true);
      } else {
        setState(() => _segundos--);
      }
    });
  }

  String get _tiempoFormateado {
    final m = _segundos ~/ 60;
    final s = _segundos % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _tiempoCritico => _segundos <= 60;

  // Responder pregunta actual
  void _responder(int indice) {
    setState(() => _respuestas[_preguntas[_actual].id] = indice);
  }

  // Siguiente pregunta o enviar
  void _siguiente() {
    if (_actual < _preguntas.length - 1) {
      setState(() => _actual++);
    } else {
      _enviarQuiz();
    }
  }

  // Anterior pregunta
  void _anterior() {
    if (_actual > 0) setState(() => _actual--);
  }

  // Calcular puntaje y guardar resultado
  Future<void> _enviarQuiz({bool tiempoAgotado = false}) async {
    _timer?.cancel();

    // Calcular puntaje
    int correctas = 0;
    int totalPuntos = 0;
    int misPuntos = 0;

    for (final p in _preguntas) {
      totalPuntos += p.puntos;
      final resp = _respuestas[p.id];
      if (resp != null && resp == p.respuestaCorrecta) {
        correctas++;
        misPuntos += p.puntos;
      }
    }

    final score = totalPuntos > 0 ? (misPuntos * 100 / totalPuntos).round() : 0;
    final passed = score >= widget.quiz.puntajeMinimo;
    final tiempoUsado = widget.quiz.tiempoLimite * 60 - _segundos;

    // Guardar intento en Supabase
    try {
      await _supabase.from('quiz_attempts').insert({
        'quiz_id': widget.quiz.id,
        'student_id': _myId,
        'score': score,
        'answers': _respuestas,
        'passed': passed,
        'status': 'completed',
        'time_spent_seconds': tiempoUsado,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Actualizar assignment si existe
      if (widget.quiz.assignmentId != null) {
        await _supabase.from('quiz_assignments').update({
          'is_completed': true,
          'completed_at': DateTime.now().toIso8601String()
        }).eq('id', widget.quiz.assignmentId!);
      }
    } catch (_) {}

    if (!mounted) return;

    // Ir a pantalla de resultados
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          quiz: widget.quiz,
          preguntas: _preguntas,
          respuestas: _respuestas,
          score: score,
          passed: passed,
          correctas: correctas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_preguntas.isEmpty)
      return Scaffold(
        appBar: AppBar(
            title: const Text('Quiz'),
            backgroundColor: Colors.purple.shade700,
            foregroundColor: Colors.white),
        body: const Center(child: Text('No hay preguntas disponibles')),
      );

    final pregunta = _preguntas[_actual];
    final respuesta = _respuestas[pregunta.id];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final salir = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text('Salir del quiz'),
                  content: const Text(
                      'Si sales perderás tu progreso. ¿Estás seguro?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Continuar')),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Salir'))
                  ],
                ));
        if (salir == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
          title: Text('Pregunta ${_actual + 1} de ${_preguntas.length}'),
          actions: [
            // Temporizador
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _tiempoCritico
                    ? Colors.red.withOpacity(0.3)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Icon(Icons.timer_rounded,
                    size: 16,
                    color: _tiempoCritico ? Colors.red.shade200 : Colors.white),
                const SizedBox(width: 4),
                Text(_tiempoFormateado,
                    style: TextStyle(
                        color:
                            _tiempoCritico ? Colors.red.shade200 : Colors.white,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
        body: Column(children: [
          // Barra de progreso
          LinearProgressIndicator(
            value: (_actual + 1) / _preguntas.length,
            backgroundColor: Colors.purple.shade100,
            valueColor: AlwaysStoppedAnimation(Colors.purple.shade700),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pregunta
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.purple.shade100)),
                      child: Text(pregunta.texto,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.5)),
                    ),
                    const SizedBox(height: 20),

                    // Opciones
                    ...pregunta.opciones.asMap().entries.map((e) {
                      final i = e.key;
                      final opcion = e.value;
                      final selected = respuesta == i;

                      return GestureDetector(
                        onTap: () => _responder(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.purple.shade50
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: selected
                                    ? Colors.purple.shade700
                                    : Colors.grey.shade300,
                                width: selected ? 2 : 1),
                          ),
                          child: Row(children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.purple.shade700
                                    : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                  child: Text(
                                String.fromCharCode(65 + i), // A, B, C, D
                                style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              )),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(opcion,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: selected
                                            ? Colors.purple.shade800
                                            : null,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.normal))),
                            if (selected)
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.purple.shade700, size: 20),
                          ]),
                        ),
                      );
                    }).toList(),
                  ]),
            ),
          ),

          // Botones de navegación
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(children: [
              if (_actual > 0)
                Expanded(
                    child: OutlinedButton(
                        onPressed: _anterior,
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text('Anterior'))),
              if (_actual > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: respuesta != null ? _siguiente : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade300),
                  child: Text(
                      _actual < _preguntas.length - 1
                          ? 'Siguiente'
                          : 'Enviar Quiz',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PANTALLA 4: QuizResultScreen — Resultados
// ─────────────────────────────────────────────────────────────
class QuizResultScreen extends StatelessWidget {
  final QuizModel quiz;
  final List<QuestionModel> preguntas;
  final Map<String, int> respuestas;
  final int score;
  final bool passed;
  final int correctas;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.preguntas,
    required this.respuestas,
    required this.score,
    required this.passed,
    required this.correctas,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Header con resultado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            color: color.withOpacity(0.08),
            child: Column(children: [
              Icon(
                  passed
                      ? Icons.emoji_events_rounded
                      : Icons.sentiment_dissatisfied_rounded,
                  size: 72,
                  color: color),
              const SizedBox(height: 12),
              Text(passed ? '¡Aprobado!' : 'No aprobado',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 8),
              Text('$score%',
                  style: TextStyle(
                      fontSize: 48, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 4),
              Text('$correctas de ${preguntas.length} correctas',
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ]),
          ),

          // Revisión de preguntas
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Revisión de respuestas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...preguntas.asMap().entries.map((e) {
                final p = e.value;
                final resp = respuestas[p.id];
                final correcto = resp == p.respuestaCorrecta;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: correcto ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: correcto
                            ? Colors.green.shade200
                            : Colors.red.shade200),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(
                              correcto
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: correcto ? Colors.green : Colors.red,
                              size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text('${e.key + 1}. ${p.texto}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600))),
                        ]),
                        const SizedBox(height: 8),
                        if (resp != null && resp < p.opciones.length)
                          Text('Tu respuesta: ${p.opciones[resp]}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: correcto
                                      ? Colors.green.shade700
                                      : Colors.red.shade700)),
                        Text(
                            'Respuesta correcta: ${p.opciones[p.respuestaCorrecta]}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600)),
                        if (p.explicacion != null) ...[
                          const SizedBox(height: 6),
                          Text(p.explicacion!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ]),
                );
              }).toList(),
            ]),
          ),

          // Botón volver
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: color, foregroundColor: Colors.white),
              child: const Text('Volver al inicio'),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}
