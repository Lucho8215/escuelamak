// ═══════════════════════════════════════════════════════════════════════════
// MODELOS DE QUIZ
// ═══════════════════════════════════════════════════════════════════════════

class QuizModel {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final String difficulty; // easy, medium, hard
  final int? timeLimit; // minutos
  final int passingScore;
  final bool isEnabled;
  final DateTime? dueDate;
  final bool isCompleted;
  final QuizAttemptSummary? lastAttempt;

  QuizModel({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.difficulty,
    this.timeLimit,
    required this.passingScore,
    required this.isEnabled,
    this.dueDate,
    required this.isCompleted,
    this.lastAttempt,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final lastAttemptJson = json['last_attempt'] as Map<String, dynamic>?;
    return QuizModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Sin título',
      description: json['description'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String? ?? 'medium',
      timeLimit: json['time_limit'] as int?,
      passingScore: json['passing_score'] as int? ?? 60,
      isEnabled: json['is_enabled'] as bool? ?? true,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      lastAttempt: lastAttemptJson != null
          ? QuizAttemptSummary.fromJson(lastAttemptJson)
          : null,
    );
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 'easy': return 'Fácil';
      case 'hard': return 'Difícil';
      default: return 'Medio';
    }
  }
}

class QuizDetail {
  final QuizModel quiz;
  final List<QuizQuestion> questions;
  final QuizAttemptSummary? lastAttempt;

  QuizDetail({
    required this.quiz,
    required this.questions,
    this.lastAttempt,
  });

  factory QuizDetail.fromJson(Map<String, dynamic> json) {
    final quizJson = json['quiz'] as Map<String, dynamic>? ?? {};
    final questionsJson = json['questions'] as List<dynamic>? ?? [];
    final lastAttemptJson = json['last_attempt'] as Map<String, dynamic>?;
    return QuizDetail(
      quiz: QuizModel.fromJson(quizJson),
      questions: questionsJson
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      lastAttempt: lastAttemptJson != null
          ? QuizAttemptSummary.fromJson(lastAttemptJson)
          : null,
    );
  }
}

class QuizQuestion {
  final String id;
  final String text;
  final List<QuizOption> options;
  final int points;
  final int orderNumber;
  String? selectedAnswer; // para estado local

  QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.points,
    required this.orderNumber,
    this.selectedAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final optionsRaw = json['options'];
    List<QuizOption> options = [];

    if (optionsRaw is List) {
      options = optionsRaw.map((o) {
        if (o is Map<String, dynamic>) {
          return QuizOption.fromJson(o);
        }
        return QuizOption(key: o.toString(), label: o.toString());
      }).toList();
    } else if (optionsRaw is Map<String, dynamic>) {
      options = optionsRaw.entries
          .map((e) => QuizOption(key: e.key, label: e.value.toString()))
          .toList();
    }

    return QuizQuestion(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      options: options,
      points: json['points'] as int? ?? 1,
      orderNumber: json['order_number'] as int? ?? 0,
    );
  }
}

class QuizOption {
  final String key;
  final String label;

  QuizOption({required this.key, required this.label});

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      key: json['key'] as String? ?? json['value'] as String? ?? '',
      label: json['label'] as String? ?? json['text'] as String? ?? '',
    );
  }
}

class QuizAttemptSummary {
  final String? id;
  final int score;
  final bool passed;
  final DateTime? completedAt;
  final String status;

  QuizAttemptSummary({
    this.id,
    required this.score,
    required this.passed,
    this.completedAt,
    required this.status,
  });

  factory QuizAttemptSummary.fromJson(Map<String, dynamic> json) {
    return QuizAttemptSummary(
      id: json['id'] as String?,
      score: json['score'] as int? ?? 0,
      passed: json['passed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      status: json['status'] as String? ?? 'completed',
    );
  }
}

class QuizResult {
  final int score;
  final bool passed;
  final int earnedPoints;
  final int totalPoints;
  final String? attemptId;
  final List<QuizCorrectAnswer> correctAnswers;

  QuizResult({
    required this.score,
    required this.passed,
    required this.earnedPoints,
    required this.totalPoints,
    this.attemptId,
    required this.correctAnswers,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    final answersJson = json['correct_answers'] as List<dynamic>? ?? [];
    return QuizResult(
      score: json['score'] as int? ?? 0,
      passed: json['passed'] as bool? ?? false,
      earnedPoints: json['earned_points'] as int? ?? 0,
      totalPoints: json['total_points'] as int? ?? 0,
      attemptId: json['attempt_id'] as String?,
      correctAnswers: answersJson
          .map((a) => QuizCorrectAnswer.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizCorrectAnswer {
  final String id;
  final String correctAnswer;
  final String? explanation;

  QuizCorrectAnswer({
    required this.id,
    required this.correctAnswer,
    this.explanation,
  });

  factory QuizCorrectAnswer.fromJson(Map<String, dynamic> json) {
    return QuizCorrectAnswer(
      id: json['id'] as String? ?? '',
      correctAnswer: json['correct_answer'] as String? ?? '',
      explanation: json['explanation'] as String?,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO DE TAREA (combinado: lección o quiz)
// ═══════════════════════════════════════════════════════════════════════════

class TaskItem {
  final String type; // lesson | quiz
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final int progressPct;
  final bool completed;
  final DateTime? dueDate;
  final DateTime? assignedAt;
  final int estimatedMinutes;
  final Map<String, dynamic>? meta;

  TaskItem({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.progressPct,
    required this.completed,
    this.dueDate,
    this.assignedAt,
    required this.estimatedMinutes,
    this.meta,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      type: json['type'] as String? ?? 'lesson',
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      status: json['status'] as String? ?? 'assigned',
      progressPct: json['progress_pct'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      assignedAt: json['assigned_at'] != null
          ? DateTime.tryParse(json['assigned_at'] as String)
          : null,
      estimatedMinutes: json['estimated_minutes'] as int? ?? 0,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  bool get isLesson => type == 'lesson';
  bool get isQuiz => type == 'quiz';

  String get statusLabel {
    switch (status) {
      case 'completed': return 'Completado';
      case 'in_progress': return 'En progreso';
      default: return 'Pendiente';
    }
  }
}
