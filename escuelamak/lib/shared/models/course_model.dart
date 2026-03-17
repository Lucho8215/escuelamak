// ═══════════════════════════════════════════════════════════════════════════
// MODELO DE CURSO - Datos de un curso desde Supabase
// ═══════════════════════════════════════════════════════════════════════════

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String teacherId;
  final String teacherName;
  final String category;
  final int enrollmentCount;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.teacherId,
    required this.teacherName,
    required this.category,
    required this.enrollmentCount,
    required this.isPublished,
    required this.createdAt,
    this.updatedAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Sin título',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      teacherId: json['teacher_id'] as String? ?? '',
      teacherName: json['teacher_name'] as String? ?? 'Profesor',
      category: json['category'] as String? ?? 'General',
      enrollmentCount: json['enrollment_count'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  // Constructor desde la API (nombres en español)
  factory CourseModel.fromApiJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String? ?? json['course_id'] as String? ?? '',
      title:
          json['titulo'] as String? ?? json['title'] as String? ?? 'Sin título',
      description: json['descripcion'] as String? ??
          json['description'] as String? ??
          '',
      imageUrl:
          json['image_url'] as String? ?? json['thumbnail_url'] as String?,
      teacherId: json['teacher_id'] as String? ?? '',
      teacherName: json['teacher_name'] as String? ??
          json['docente'] as String? ??
          'Profesor',
      category: json['categoria'] as String? ??
          json['category'] as String? ??
          'General',
      enrollmentCount: json['enrollment_count'] as int? ??
          json['total_estudiantes'] as int? ??
          0,
      isPublished:
          json['is_published'] as bool? ?? json['publico'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'category': category,
      'enrollment_count': enrollmentCount,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Obtener color según categoría
  String get categoryColor {
    switch (category.toLowerCase()) {
      case 'matemáticas':
      case 'math':
        return '#2196F3'; // Azul
      case 'ciencias':
      case 'science':
        return '#4CAF50'; // Verde
      case 'historia':
      case 'history':
        return '#FF9800'; // Naranja
      case 'literatura':
      case 'literature':
        return '#9C27B0'; // Púrpura
      case 'programación':
      case 'coding':
        return '#00BCD4'; // Cyan
      case 'idiomas':
      case 'languages':
        return '#E91E63'; // Rosa
      default:
        return '#6750A4'; // Primary
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO DE MÓDULO - Datos de un módulo dentro de un curso
// ═══════════════════════════════════════════════════════════════════════════

class ModuleModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int orderIndex;
  final String contentType; // video, text, quiz, assignment
  final String? contentUrl;
  final String? content;
  final int durationMinutes;
  final bool isPublished;
  final DateTime createdAt;

  ModuleModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.contentType,
    this.contentUrl,
    this.content,
    required this.durationMinutes,
    required this.isPublished,
    required this.createdAt,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String? ?? 'Sin título',
      description: json['description'] as String? ?? '',
      orderIndex: json['order_index'] as int? ?? 0,
      contentType: json['content_type'] as String? ?? 'text',
      contentUrl: json['content_url'] as String?,
      content: json['content'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // Icono según tipo de contenido
  String get contentTypeIcon {
    switch (contentType.toLowerCase()) {
      case 'video':
        return 'play_circle';
      case 'quiz':
        return 'quiz';
      case 'assignment':
        return 'assignment';
      case 'document':
        return 'description';
      case 'link':
        return 'link';
      default:
        return 'article';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO DE INSCRIPCIÓN - Relación usuario-curso
// ═══════════════════════════════════════════════════════════════════════════

class EnrollmentModel {
  final String id;
  final String userId;
  final String courseId;
  final String role; // student, teacher, admin
  final DateTime enrolledAt;
  final DateTime? completedAt;
  final double progress; // 0.0 a 1.0

  EnrollmentModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.role,
    required this.enrolledAt,
    this.completedAt,
    required this.progress,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String,
      role: json['role'] as String? ?? 'student',
      enrolledAt: DateTime.tryParse(json['enrolled_at'] as String? ?? '') ??
          DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO DE PROGRESO DEL MÓDULO
// ═══════════════════════════════════════════════════════════════════════════

class ModuleProgressModel {
  final String id;
  final String userId;
  final String moduleId;
  final bool isCompleted;
  final DateTime? completedAt;
  final int score; // Para quizzes

  ModuleProgressModel({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.isCompleted,
    this.completedAt,
    required this.score,
  });

  factory ModuleProgressModel.fromJson(Map<String, dynamic> json) {
    return ModuleProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      moduleId: json['module_id'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      score: json['score'] as int? ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO DE CLASE - Datos de una clase desde la tabla classes
// ═══════════════════════════════════════════════════════════════════════════

class ClassModel {
  final String id;
  final String courseId;
  final String title;
  final String? name;
  final String? description;
  final String? content;
  final int classNumber;
  final int? duration;
  final bool isActive;
  final String? teacherId;
  final String status;
  final int enrollmentCount;
  final int maxStudents;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? imageUrl;
  final String? resourceLink;
  final String? resourceFileUrl;
  final String? observation;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.name,
    this.description,
    this.content,
    required this.classNumber,
    this.duration,
    required this.isActive,
    this.teacherId,
    required this.status,
    required this.enrollmentCount,
    required this.maxStudents,
    this.startDate,
    this.endDate,
    this.imageUrl,
    this.resourceLink,
    this.resourceFileUrl,
    this.observation,
    required this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      title:
          json['title'] as String? ?? json['name'] as String? ?? 'Sin título',
      name: json['name'] as String?,
      description: json['description'] as String?,
      content: json['content'] as String?,
      classNumber: json['class_number'] as int? ?? 1,
      duration: json['duration'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      teacherId: json['teacher_id'] as String?,
      status: json['status'] as String? ?? 'open',
      enrollmentCount: json['enrollment_count'] as int? ?? 0,
      maxStudents: json['max_students'] as int? ?? 30,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      imageUrl: json['image_url'] as String?,
      resourceLink: json['resource_link'] as String?,
      resourceFileUrl: json['resource_file_url'] as String?,
      observation: json['observation'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // Obtener icono según estado
  String get statusIcon {
    switch (status) {
      case 'open':
        return 'play_circle';
      case 'in_progress':
        return 'pending';
      case 'completed':
        return 'check_circle';
      case 'closed':
        return 'lock';
      default:
        return 'class';
    }
  }

  // Verificar si tiene video
  bool get hasVideo => resourceLink != null && resourceLink!.isNotEmpty;

  // Verificar si tiene archivo
  bool get hasFile => resourceFileUrl != null && resourceFileUrl!.isNotEmpty;
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO: CURSO CON CLASES - Para get-course-detail
// ═══════════════════════════════════════════════════════════════════════════

class CourseWithClasses {
  final CourseModel course;
  final List<ClassModel> classes;
  final dynamic enrollment;
  final Map<String, dynamic> userProgress;

  CourseWithClasses({
    required this.course,
    required this.classes,
    this.enrollment,
    this.userProgress = const {},
  });

  factory CourseWithClasses.fromJson(Map<String, dynamic> json) {
    final courseJson = json['course'] as Map<String, dynamic>? ?? {};
    final classesJson = json['classes'] as List<dynamic>? ?? [];

    return CourseWithClasses(
      course: CourseModel.fromApiJson(courseJson),
      classes: classesJson
          .map((c) => ClassModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      enrollment: json['enrollment'],
      userProgress: json['userProgress'] as Map<String, dynamic>? ?? {},
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO: CLASE CON CURSO - Para get-class
// ═══════════════════════════════════════════════════════════════════════════

class ClassWithCourse {
  final ClassModel classData;
  final Map<String, String> course;
  final dynamic progress;

  ClassWithCourse({
    required this.classData,
    required this.course,
    this.progress,
  });

  factory ClassWithCourse.fromJson(Map<String, dynamic> json) {
    return ClassWithCourse(
      classData: ClassModel.fromJson(json['class'] as Map<String, dynamic>),
      course: json['course'] as Map<String, String>? ?? {},
      progress: json['progress'],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO: INFORMACIÓN DE PROGRESO DEL USUARIO
// ═══════════════════════════════════════════════════════════════════════════

class UserProgressInfo {
  final int coursesEnrolled;
  final int classesEnrolled;
  final int classesCompleted;
  final List<dynamic> progressList;

  UserProgressInfo({
    required this.coursesEnrolled,
    required this.classesEnrolled,
    required this.classesCompleted,
    required this.progressList,
  });

  factory UserProgressInfo.fromJson(Map<String, dynamic> json) {
    return UserProgressInfo(
      coursesEnrolled: json['courses_enrolled'] as int? ?? 0,
      classesEnrolled: json['classes_enrolled'] as int? ?? 0,
      classesCompleted: json['classes_completed'] as int? ?? 0,
      progressList: json['progress_list'] as List<dynamic>? ?? [],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO: PERFIL DE USUARIO
// ═══════════════════════════════════════════════════════════════════════════

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? cedula;
  final String? authUserId;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.cedula,
    this.authUserId,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      cedula: json['cedula'] as String?,
      authUserId: json['auth_user_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
