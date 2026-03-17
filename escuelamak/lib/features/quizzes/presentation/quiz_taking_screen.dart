import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/features/courses/data/courses_repository.dart';
import 'package:escuelamak/shared/models/quiz_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA: Toma de quiz (preguntas + resultado)
// ═══════════════════════════════════════════════════════════════════════════

class QuizTakingScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final Color color;

  const QuizTakingScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.color,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  final _repo = CoursesRepository();
  QuizDetail? _detail;
  bool _loading = true;

  // Estado del quiz
  int _currentPage = 0;
  final Map<String, String> _answers = {};
  bool _submitted = false;
  QuizResult? _result;
  bool _submitting = false;

  // Timer
  Timer? _timer;
  int _secondsLeft = 0;
  bool _timerActive = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() => _loading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final detail = await _repo.getQuizDetail(widget.quizId, userId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
      });
      if (detail?.quiz.timeLimit != null && detail!.quiz.timeLimit! > 0) {
        _secondsLeft = detail.quiz.timeLimit! * 60;
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timerActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        _submitQuiz(autoSubmit: true);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _timerWarning => _secondsLeft < 60 && _timerActive;

  Future<void> _submitQuiz({bool autoSubmit = false}) async {
    if (_submitting || _submitted) return;
    final detail = _detail!;

    // Confirmación si es manual y no están todas respondidas
    if (!autoSubmit && _answers.length < detail.questions.length) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Entregar examen'),
          content: Text(
            'Tienes ${detail.questions.length - _answers.length} pregunta(s) sin responder. ¿Deseas entregar de todas formas?',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: widget.color),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Entregar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    _timer?.cancel();
    setState(() => _submitting = true);

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final timeSpent = (detail.quiz.timeLimit ?? 0) * 60 - _secondsLeft;

    final result = await _repo.submitQuiz(
      widget.quizId,
      userId,
      Map<String, String>.from(_answers),
      timeSpentSeconds: timeSpent,
    );

    if (mounted) {
      setState(() {
        _submitting = false;
        _submitted = true;
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quizTitle),
          backgroundColor: widget.color,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_detail == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quizTitle),
          backgroundColor: widget.color,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('No se pudo cargar el examen')),
      );
    }

    if (_submitted && _result != null) {
      return _QuizResultScreen(
        result: _result!,
        detail: _detail!,
        answers: _answers,
        color: widget.color,
        onBack: () => Navigator.pop(context),
      );
    }

    return _buildQuizUI();
  }

  Widget _buildQuizUI() {
    final detail = _detail!;
    final questions = detail.questions;
    final q = questions[_currentPage];
    final totalAnswered = _answers.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        title: Text(widget.quizTitle, style: const TextStyle(fontSize: 15)),
        actions: [
          if (_timerActive)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _timerWarning
                    ? Colors.red.withOpacity(0.2)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer,
                      size: 14,
                      color: _timerWarning ? Colors.red[100] : Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _timerLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _timerWarning ? Colors.red[100] : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progreso
          LinearProgressIndicator(
            value: (_currentPage + 1) / questions.length,
            backgroundColor: widget.color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(widget.color),
            minHeight: 4,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contador de pregunta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pregunta ${_currentPage + 1} de ${questions.length}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$totalAnswered respondidas',
                        style: TextStyle(
                            color: widget.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Texto de la pregunta
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: widget.color.withOpacity(0.15)),
                    ),
                    child: Text(
                      q.text,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Opciones
                  ...q.options.map((option) {
                    final selected = _answers[q.id] == option.key;
                    return _OptionCard(
                      option: option,
                      selected: selected,
                      color: widget.color,
                      onTap: () {
                        setState(() => _answers[q.id] = option.key);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),

          // Botones de navegación
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _currentPage--),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Anterior'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _currentPage < questions.length - 1
                      ? ElevatedButton.icon(
                          onPressed: () => setState(() => _currentPage++),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Siguiente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _submitting ? null : () => _submitQuiz(),
                          icon: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(_submitting ? 'Entregando...' : 'Entregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Opción de respuesta
// ─────────────────────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  final QuizOption option;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 6)]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                    color: selected ? color : Colors.grey.withOpacity(0.5),
                    width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label.isNotEmpty ? option.label : option.key,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? color : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANTALLA DE RESULTADO
// ═══════════════════════════════════════════════════════════════════════════

class _QuizResultScreen extends StatelessWidget {
  final QuizResult result;
  final QuizDetail detail;
  final Map<String, String> answers;
  final Color color;
  final VoidCallback onBack;

  const _QuizResultScreen({
    required this.result,
    required this.detail,
    required this.answers,
    required this.color,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final passed = result.passed;
    final resultColor = passed ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.close, color: Colors.white),
            label: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Resultado principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: resultColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: resultColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: resultColor.withOpacity(0.15),
                    ),
                    child: Icon(
                      passed ? Icons.emoji_events_rounded : Icons.replay_rounded,
                      size: 40,
                      color: resultColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    passed ? '¡Aprobado!' : 'No aprobado',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: resultColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.score}%',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: resultColor),
                  ),
                  Text(
                    '${result.earnedPoints} / ${result.totalPoints} puntos',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Estadísticas
            Row(
              children: [
                _StatCard(
                  label: 'Correctas',
                  value: result.earnedPoints.toString(),
                  color: Colors.green,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Incorrectas',
                  value:
                      (result.totalPoints - result.earnedPoints).toString(),
                  color: Colors.red,
                  icon: Icons.cancel_outlined,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Puntaje',
                  value: '${detail.quiz.passingScore}%',
                  color: color,
                  icon: Icons.flag_outlined,
                  subtitle: 'mín',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Revisión de respuestas
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Revisión de respuestas',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey[800])),
            ),
            const SizedBox(height: 12),

            ...detail.questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              final userAnswer = answers[q.id];
              final correctData = result.correctAnswers
                  .where((a) => a.id == q.id)
                  .firstOrNull;
              final correctAnswer = correctData?.correctAnswer ?? '';
              final isCorrect = userAnswer == correctAnswer;

              return _ReviewCard(
                number: i + 1,
                question: q.text,
                userAnswer: q.options
                    .where((o) => o.key == userAnswer)
                    .firstOrNull
                    ?.label ?? userAnswer ?? 'Sin responder',
                correctAnswer: q.options
                    .where((o) => o.key == correctAnswer)
                    .firstOrNull
                    ?.label ?? correctAnswer,
                isCorrect: isCorrect,
                explanation: correctData?.explanation,
              );
            }),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver a exámenes',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            if (subtitle != null)
              Text(subtitle!,
                  style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int number;
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String? explanation;

  const _ReviewCard({
    required this.number,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isCorrect ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor.withOpacity(0.12),
                ),
                child: Center(
                  child: Text('$number',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: borderColor)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(question,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: borderColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AnswerRow(
              label: 'Tu respuesta',
              answer: userAnswer,
              correct: isCorrect),
          if (!isCorrect) ...[
            const SizedBox(height: 6),
            _AnswerRow(
                label: 'Respuesta correcta',
                answer: correctAnswer,
                correct: true),
          ],
          if (explanation != null && explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(explanation!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.blue, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String answer;
  final bool correct;

  const _AnswerRow(
      {required this.label, required this.answer, required this.correct});

  @override
  Widget build(BuildContext context) {
    final color = correct ? Colors.green : Colors.red;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(answer,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
