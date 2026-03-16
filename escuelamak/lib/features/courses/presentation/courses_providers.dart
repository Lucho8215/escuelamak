import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escuelamak/shared/models/course_model.dart';
import 'package:escuelamak/features/courses/data/courses_repository.dart';
import 'package:escuelamak/main.dart';

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider del repositorio de cursos
final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepository();
});

// ═══════════════════════════════════════════════════════════════════════════
// USER INFO PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider para obtener el usuario actual
final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final session = supabase.auth.currentSession;
  if (session == null) {
    throw Exception('No hay sesión activa');
  }

  final userId = session.user.id;
  final perfiles = await supabase
      .from('app_users')
      .select('id, role, name')
      .eq('auth_user_id', userId)
      .limit(1);

  if (perfiles.isEmpty) {
    throw Exception('Usuario no encontrado');
  }

  return {
    'userId': perfiles[0]['id'], // Use the app_users id, not auth id
    'role': perfiles[0]['role'],
    'name': perfiles[0]['name'],
    'authUserId': userId,
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// COURSES PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider para obtener los cursos según el rol
final coursesProvider =
    FutureProvider.family<List<CourseModel>, String>((ref, role) async {
  final repository = ref.watch(coursesRepositoryProvider);

  // Obtener el userId del provider de usuario actual
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (userData) => repository.getCoursesByRole(
      userData['userId'] as String,
      role,
    ),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// COURSE DETAIL PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider para obtener un curso específico con sus clases
final courseDetailProvider =
    FutureProvider.family<CourseWithClasses?, String>((ref, courseId) async {
  final repository = ref.watch(coursesRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (userData) => repository.getCourseDetail(
      courseId,
      userData['userId'] as String,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// MY CLASSES PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider para obtener las clases del usuario
final myClassesProvider = FutureProvider<List<ClassModel>>((ref) async {
  final repository = ref.watch(coursesRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (userData) => repository.getMyClasses(userData['userId'] as String),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// CLASS DETAIL PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider para obtener una clase específica
final classDetailProvider =
    FutureProvider.family<ClassWithCourse?, String>((ref, classId) async {
  final repository = ref.watch(coursesRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (userData) => repository.getClass(
      classId,
      userData['userId'] as String,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// USER PROGRESS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider para obtener el progreso del usuario
final userProgressProvider = FutureProvider<UserProgressInfo?>((ref) async {
  final repository = ref.watch(coursesRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (userData) =>
        repository.getUserProgress(userData['userId'] as String),
    loading: () => null,
    error: (_, __) => null,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// PROFILE PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider para obtener el perfil del usuario
final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final repository = ref.watch(coursesRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (userData) => repository.getProfile(userData['userId'] as String),
    loading: () => null,
    error: (_, __) => null,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// ENROLLMENT STATE (for classes)
// ═══════════════════════════════════════════════════════════════════════════

/// Estado para manejar inscripción en clases
class EnrollmentNotifier extends StateNotifier<AsyncValue<bool>> {
  final CoursesRepository _repository;
  final Ref _ref;

  EnrollmentNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(false));

  Future<bool> enrollInClass(String classId) async {
    state = const AsyncValue.loading();

    try {
      final userData = await _ref.read(currentUserProvider.future);
      final userId = userData['userId'] as String;

      final success = await _repository.enrollInClass(userId, classId);

      if (success) {
        state = const AsyncValue.data(true);
        // Invalidar el provider de clases para recargar
        _ref.invalidate(myClassesProvider);
      } else {
        state = const AsyncValue.data(false);
      }

      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(false);
  }
}

final classEnrollmentProvider =
    StateNotifierProvider<EnrollmentNotifier, AsyncValue<bool>>((ref) {
  final repository = ref.watch(coursesRepositoryProvider);
  return EnrollmentNotifier(repository, ref);
});

// ═══════════════════════════════════════════════════════════════════════════
// CLASS COMPLETION STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Estado para completar clases
class ClassCompletionNotifier extends StateNotifier<AsyncValue<bool>> {
  final CoursesRepository _repository;
  final Ref _ref;

  ClassCompletionNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(false));

  Future<bool> complete(String classId,
      {int? progressPct, int? lastPosition}) async {
    state = const AsyncValue.loading();

    try {
      final userData = await _ref.read(currentUserProvider.future);
      final userId = userData['userId'] as String;

      final success = await _repository.completeClass(
        userId,
        classId,
        progressPct: progressPct,
        lastPosition: lastPosition,
      );

      if (success) {
        state = const AsyncValue.data(true);
      } else {
        state = const AsyncValue.data(false);
      }

      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reportStatus({
    required String classId,
    required String status,
    int? progressPct,
    int? lastPosition,
  }) async {
    state = const AsyncValue.loading();

    try {
      final userData = await _ref.read(currentUserProvider.future);
      final userId = userData['userId'] as String;

      final success = await _repository.reportClassStatus(
        userId: userId,
        classId: classId,
        status: status,
        progressPct: progressPct,
        lastPosition: lastPosition,
      );

      if (success) {
        state = const AsyncValue.data(true);
      } else {
        state = const AsyncValue.data(false);
      }

      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(false);
  }
}

final classCompletionProvider =
    StateNotifierProvider<ClassCompletionNotifier, AsyncValue<bool>>((ref) {
  final repository = ref.watch(coursesRepositoryProvider);
  return ClassCompletionNotifier(repository, ref);
});

/// Alias para compatibilidad con módulos
final moduleCompletionProvider = classCompletionProvider;
