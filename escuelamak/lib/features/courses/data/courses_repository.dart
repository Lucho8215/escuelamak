import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/main.dart';
import 'package:escuelamak/shared/models/course_model.dart';
import 'package:escuelamak/shared/models/lesson_model.dart';
import 'package:escuelamak/shared/models/quiz_model.dart';

/// Repositorio para gestionar cursos y módulos usando la API Edge Functions
class CoursesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════════════
  // LLAMADAS A LA API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Llama a una función edge de Supabase
  Future<Map<String, dynamic>> _callApi(
      String action, Map<String, dynamic> body) async {
    try {
      final response = await supabase.functions.invoke('mobile-api', body: {
        'action': action,
        ...body,
      });

      if (response.data != null && response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data?['error'] ?? 'Error en la API');
      }
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OBTENER MÓDULOS (PERMISOS) DEL USUARIO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene los módulos/permisos del usuario según su rol
  Future<List<ModulePermission>> getModules(String userId) async {
    try {
      final response = await _callApi('get-modules', {'user_id': userId});

      final modules = response['data']['modules'] as List<dynamic>? ?? [];
      return modules.map((m) => ModulePermission.fromJson(m)).toList();
    } catch (e) {
      print('Error getting modules: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OBTENER CURSOS SEGÚN ROL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene los cursos del usuario según su rol
  Future<List<CourseModel>> getCoursesByRole(String userId, String role) async {
    try {
      final response = await _callApi('get-courses', {
        'user_id': userId,
      });

      final courses = response['data']['courses'] as List<dynamic>? ?? [];
      return courses
          .map((c) => CourseModel.fromApiJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting courses: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OBTENER DETALLE DE UN CURSO (con clases)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene el detalle de un curso con sus clases
  Future<CourseWithClasses?> getCourseDetail(
      String courseId, String userId) async {
    try {
      final response = await _callApi('get-course-detail', {
        'course_id': courseId,
        'user_id': userId,
      });

      return CourseWithClasses.fromJson(response['data']);
    } catch (e) {
      print('Error getting course detail: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OBTENER DETALLE DE UNA CLASE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene el detalle de una clase específica
  Future<ClassWithCourse?> getClass(String classId, String userId) async {
    try {
      final response = await _callApi('get-class', {
        'class_id': classId,
        'user_id': userId,
      });

      return ClassWithCourse.fromJson(response['data']);
    } catch (e) {
      print('Error getting class: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OBTENER MIS CLASES (clases inscritas)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene las clases donde está inscrito el usuario
  Future<List<ClassModel>> getMyClasses(String userId) async {
    try {
      final response = await _callApi('get-my-classes', {
        'user_id': userId,
      });

      final classes = response['data']['classes'] as List<dynamic>? ?? [];
      return classes
          .map((c) => ClassModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting my classes: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INSCRIBIRSE EN UNA CLASE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inscribe al usuario en una clase
  Future<bool> enrollInClass(String userId, String classId) async {
    try {
      await _callApi('enroll-class', {
        'user_id': userId,
        'class_id': classId,
      });
      return true;
    } catch (e) {
      print('Error enrolling in class: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPLETAR UNA CLASE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Marca una clase como completada
  Future<bool> completeClass(String userId, String classId,
      {int? progressPct, int? lastPosition}) async {
    try {
      await _callApi('complete-class', {
        'user_id': userId,
        'class_id': classId,
        'progress_pct': progressPct,
        'last_position': lastPosition,
      });
      return true;
    } catch (e) {
      print('Error completing class: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REPORTAR ESTADO DE CLASE (desde app móvil)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reporta el estado de una clase (en progreso, completada, pausada)
  Future<bool> reportClassStatus({
    required String userId,
    required String classId,
    required String status,
    int? progressPct,
    int? lastPosition,
  }) async {
    try {
      await _callApi('report-class-status', {
        'user_id': userId,
        'class_id': classId,
        'status': status,
        'progress_pct': progressPct,
        'last_position': lastPosition,
      });
      return true;
    } catch (e) {
      print('Error reporting class status: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OBTENER PROGRESO DEL USUARIO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene el progreso del usuario
  Future<UserProgressInfo?> getUserProgress(String userId) async {
    try {
      final response = await _callApi('get-user-progress', {'user_id': userId});
      return UserProgressInfo.fromJson(response['data']);
    } catch (e) {
      print('Error getting user progress: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OBTENER PERFIL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene el perfil del usuario
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final response = await _callApi('get-profile', {'user_id': userId});
      return UserProfile.fromJson(response['data']['user']);
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTUALIZAR PERFIL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Actualiza el perfil del usuario
  Future<bool> updateProfile(String userId,
      {String? name, String? cedula}) async {
    try {
      await _callApi('update-profile', {
        'user_id': userId,
        'name': name,
        'cedula': cedula,
      });
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE COMPATIBILIDAD (para pantallas existentes)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene un curso por ID (compatibilidad)
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      // Obtener el primer usuario para demostración
      final profiles = await supabase.from('app_users').select('id').limit(1);

      if (profiles.isEmpty) return null;

      final userId = profiles[0]['id'] as String;
      final detail = await getCourseDetail(courseId, userId);
      return detail?.course;
    } catch (e) {
      print('Error getting course by id: $e');
      return null;
    }
  }

  /// Obtiene módulos por curso (compatibilidad - retorna clases como módulos)
  Future<List<ModuleModel>> getModulesByCourse(String courseId) async {
    try {
      final profiles = await supabase.from('app_users').select('id').limit(1);

      if (profiles.isEmpty) return [];

      final userId = profiles[0]['id'] as String;
      final detail = await getCourseDetail(courseId, userId);

      // Convertir clases a módulos para compatibilidad
      return detail?.classes
              .map((c) => ModuleModel(
                    id: c.id,
                    courseId: c.courseId,
                    title: c.title,
                    description: c.description ?? '',
                    orderIndex: c.classNumber,
                    contentType: c.hasVideo ? 'video' : 'text',
                    contentUrl: c.resourceLink,
                    content: c.content,
                    durationMinutes: c.duration ?? 0,
                    isPublished: c.isActive,
                    createdAt: c.createdAt,
                  ))
              .toList() ??
          [];
    } catch (e) {
      print('Error getting modules by course: $e');
      return [];
    }
  }

  /// Obtiene categorías (compatibilidad)
  Future<List<String>> getCategories() async {
    try {
      final data = await supabase.from('courses').select('category');

      if (data.isEmpty) return [];

      final categories = data
          .map((c) => c['category'] as String?)
          .where((c) => c != null && c.isNotEmpty)
          .toSet()
          .toList()
          .cast<String>();

      return categories;
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  /// Busca cursos (compatibilidad)
  Future<List<CourseModel>> searchCourses(
      String query, String? category) async {
    try {
      var queryBuilder =
          supabase.from('courses').select().eq('is_active', true);

      if (query.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('title', '%$query%');
      }

      if (category != null && category.isNotEmpty) {
        queryBuilder = queryBuilder.eq('category', category);
      }

      final data = await queryBuilder;
      return data.map((c) => CourseModel.fromApiJson(c)).toList();
    } catch (e) {
      print('Error searching courses: $e');
      return [];
    }
  }

  /// Matricula en un curso (compatibilidad - ahora matricula en clase)
  Future<bool> enrollInCourse(String userId, String courseId) async {
    // Obtener primera clase del curso
    try {
      final classes = await supabase
          .from('classes')
          .select('id')
          .eq('course_id', courseId)
          .limit(1);

      if (classes.isEmpty) {
        return false;
      }

      final classId = classes[0]['id'] as String;
      return await enrollInClass(userId, classId);
    } catch (e) {
      print('Error enrolling in course: $e');
      return false;
    }
  }

  /// Completa un módulo (compatibilidad - ahora completa clase)
  Future<bool> completeModule(String userId, String moduleId,
      {int? score}) async {
    return await completeClass(userId, moduleId, progressPct: score ?? 100);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LECCIONES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene las lecciones de una clase con progreso del usuario
  Future<List<LessonModel>> getLessons(String classId, String userId) async {
    try {
      final response = await _callApi('get-lessons', {
        'class_id': classId,
        'user_id': userId,
      });
      final lessons = response['data']['lessons'] as List<dynamic>? ?? [];
      return lessons
          .map((l) => LessonModel.fromJson(l as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting lessons: $e');
      return [];
    }
  }

  /// Obtiene el detalle de una lección
  Future<LessonModel?> getLessonDetail(String lessonId, String userId) async {
    try {
      final response = await _callApi('get-lesson-detail', {
        'lesson_id': lessonId,
        'user_id': userId,
      });
      final lessonJson = response['data']['lesson'] as Map<String, dynamic>?;
      final progressJson = response['data']['progress'] as Map<String, dynamic>?;
      if (lessonJson == null) return null;
      final lesson = LessonModel.fromJson(lessonJson);
      if (progressJson != null) {
        lesson.progress = LessonProgressData.fromJson(progressJson);
      }
      return lesson;
    } catch (e) {
      print('Error getting lesson detail: $e');
      return null;
    }
  }

  /// Actualiza el progreso de una lección
  Future<bool> updateLessonProgress(
    String lessonId,
    String userId, {
    required int progressPct,
    bool? completed,
    int? lastPosition,
  }) async {
    try {
      await _callApi('update-lesson-progress', {
        'lesson_id': lessonId,
        'user_id': userId,
        'progress_pct': progressPct,
        'completed': completed,
        'last_position': lastPosition,
      });
      return true;
    } catch (e) {
      print('Error updating lesson progress: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUIZZES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene los quizzes del usuario
  Future<List<QuizModel>> getQuizzes(String userId) async {
    try {
      final response = await _callApi('get-quizzes', {'user_id': userId});
      final quizzes = response['data']['quizzes'] as List<dynamic>? ?? [];
      return quizzes
          .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting quizzes: $e');
      return [];
    }
  }

  /// Obtiene el detalle de un quiz con preguntas
  Future<QuizDetail?> getQuizDetail(String quizId, String userId) async {
    try {
      final response = await _callApi('get-quiz-detail', {
        'quiz_id': quizId,
        'user_id': userId,
      });
      return QuizDetail.fromJson(response['data']);
    } catch (e) {
      print('Error getting quiz detail: $e');
      return null;
    }
  }

  /// Envía las respuestas de un quiz y retorna el resultado
  Future<QuizResult?> submitQuiz(
    String quizId,
    String userId,
    Map<String, String> answers, {
    int? timeSpentSeconds,
  }) async {
    try {
      final response = await _callApi('submit-quiz', {
        'quiz_id': quizId,
        'user_id': userId,
        'answers': answers,
        'time_spent_seconds': timeSpentSeconds,
      });
      return QuizResult.fromJson(response['data']);
    } catch (e) {
      print('Error submitting quiz: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAREAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene las tareas del estudiante (lecciones + quizzes asignados)
  Future<List<TaskItem>> getTasks(String userId) async {
    try {
      final response = await _callApi('get-tasks', {'user_id': userId});
      final tasks = response['data']['tasks'] as List<dynamic>? ?? [];
      return tasks
          .map((t) => TaskItem.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELOS PARA LA API
// ═══════════════════════════════════════════════════════════════════════════

/// Permiso de módulo
class ModulePermission {
  final String key;
  final String name;
  final String? description;
  final String icon;
  final String route;
  final bool isGranted;

  ModulePermission({
    required this.key,
    required this.name,
    this.description,
    required this.icon,
    required this.route,
    required this.isGranted,
  });

  factory ModulePermission.fromJson(Map<String, dynamic> json) {
    return ModulePermission(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'folder',
      route: json['route'] as String? ?? '/',
      isGranted: json['is_granted'] as bool? ?? false,
    );
  }
}

/// Contenido de un curso desde la API
class CourseContent {
  final CourseModel course;
  final List<LessonApi> lessons;

  CourseContent({required this.course, required this.lessons});

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    final courseJson = json['course'] as Map<String, dynamic>? ?? {};
    final lessonsJson = json['lessons'] as List<dynamic>? ?? [];

    return CourseContent(
      course: CourseModel.fromApiJson(courseJson),
      lessons: lessonsJson.map((l) => LessonApi.fromJson(l)).toList(),
    );
  }
}

/// Lección desde la API
class LessonApi {
  final String id;
  final String titulo;
  final String? contenido;
  final String? videoUrl;
  final int orden;
  final List<dynamic> tasks;
  final List<dynamic> quizzes;
  final LessonProgress? progress;

  LessonApi({
    required this.id,
    required this.titulo,
    this.contenido,
    this.videoUrl,
    required this.orden,
    this.tasks = const [],
    this.quizzes = const [],
    this.progress,
  });

  factory LessonApi.fromJson(Map<String, dynamic> json) {
    return LessonApi(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      contenido: json['contenido'] as String?,
      videoUrl: json['video_url'] as String?,
      orden: json['orden'] as int? ?? 0,
      tasks: json['tasks'] as List<dynamic>? ?? [],
      quizzes: json['quizzes'] as List<dynamic>? ?? [],
      progress: json['progress'] != null
          ? LessonProgress.fromJson(json['progress'])
          : null,
    );
  }
}

/// Progreso de una lección
class LessonProgress {
  final bool completed;
  final int progressPct;
  final int lastPosition;

  LessonProgress({
    required this.completed,
    required this.progressPct,
    required this.lastPosition,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      completed: json['completed'] as bool? ?? false,
      progressPct: json['progress_pct'] as int? ?? 0,
      lastPosition: json['last_position'] as int? ?? 0,
    );
  }
}

/// Detalle de una lección
class LessonDetail {
  final String id;
  final String titulo;
  final String? contenido;
  final String? videoUrl;
  final LessonProgress? progress;
  final List<dynamic> tasks;
  final List<dynamic> quizzes;

  LessonDetail({
    required this.id,
    required this.titulo,
    this.contenido,
    this.videoUrl,
    this.progress,
    this.tasks = const [],
    this.quizzes = const [],
  });

  factory LessonDetail.fromJson(Map<String, dynamic> json) {
    return LessonDetail(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      contenido: json['contenido'] as String?,
      videoUrl: json['video_url'] as String?,
      progress: json['progress'] != null
          ? LessonProgress.fromJson(json['progress'])
          : null,
      tasks: json['tasks'] as List<dynamic>? ?? [],
      quizzes: json['quizzes'] as List<dynamic>? ?? [],
    );
  }
}

/// Progreso del usuario
class UserProgress {
  final List<CourseProgress> courses;
  final int totalLessonsCompleted;
  final int totalCourses;

  UserProgress({
    required this.courses,
    required this.totalLessonsCompleted,
    required this.totalCourses,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final coursesJson = json['courses'] as List<dynamic>? ?? [];
    return UserProgress(
      courses: coursesJson.map((c) => CourseProgress.fromJson(c)).toList(),
      totalLessonsCompleted: json['total_lessons_completed'] as int? ?? 0,
      totalCourses: json['total_courses'] as int? ?? 0,
    );
  }
}

/// Progreso en un curso
class CourseProgress {
  final String courseId;
  final String courseTitle;
  final int totalLessons;
  final int completedLessons;
  final int progressPct;
  final String status;

  CourseProgress({
    required this.courseId,
    required this.courseTitle,
    required this.totalLessons,
    required this.completedLessons,
    required this.progressPct,
    required this.status,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['course_id'] as String? ?? '',
      courseTitle: json['course_title'] as String? ?? '',
      totalLessons: json['total_lessons'] as int? ?? 0,
      completedLessons: json['completed_lessons'] as int? ?? 0,
      progressPct: json['progress_pct'] as int? ?? 0,
      status: json['status'] as String? ?? 'activo',
    );
  }
}
