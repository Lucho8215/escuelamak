// ═══════════════════════════════════════════════════════════════════════════
// MODELOS DE LECCIÓN
// ═══════════════════════════════════════════════════════════════════════════

class LessonModel {
  final String id;
  final String courseId;
  final String title;
  final String? summary;
  final String? objective;
  final String? content;
  final String? videoUrl;
  final String? coverImageUrl;
  final String? resourceLink;
  final String? resourceFileUrl;
  final int estimatedMinutes;
  final int orderIndex;
  final bool isPublished;
  final DateTime? createdAt;
  LessonProgressData? progress;

  LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.summary,
    this.objective,
    this.content,
    this.videoUrl,
    this.coverImageUrl,
    this.resourceLink,
    this.resourceFileUrl,
    required this.estimatedMinutes,
    required this.orderIndex,
    required this.isPublished,
    this.createdAt,
    this.progress,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final progressJson = json['progress'] as Map<String, dynamic>?;
    // Support both old column names (resource_url) and new (resource_link)
    final resourceLink = (json['resource_link'] as String?)?.isNotEmpty == true
        ? json['resource_link'] as String
        : (json['resource_url'] as String?);
    final videoUrl = (json['video_url'] as String?)?.isNotEmpty == true
        ? json['video_url'] as String
        : null;
    return LessonModel(
      id: json['id'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Sin título',
      summary: json['summary'] as String?,
      objective: json['objective'] as String?,
      content: json['content'] as String?,
      videoUrl: videoUrl,
      coverImageUrl: json['cover_image_url'] as String?,
      resourceLink: resourceLink,
      resourceFileUrl: json['resource_file_url'] as String?,
      estimatedMinutes: json['estimated_minutes'] as int? ?? 0,
      orderIndex: (json['order_index'] ?? json['order']) as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      progress: progressJson != null
          ? LessonProgressData.fromJson(progressJson)
          : null,
    );
  }

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasFile => resourceFileUrl != null && resourceFileUrl!.isNotEmpty;
  bool get hasLink => resourceLink != null && resourceLink!.isNotEmpty;
  bool get isCompleted => progress?.completed ?? false;
  int get progressPct => progress?.progressPct ?? 0;
}

class LessonProgressData {
  final String status; // assigned, in_progress, completed
  final int progressPct;
  final bool completed;
  final int lastPosition;
  final DateTime? completedAt;

  LessonProgressData({
    required this.status,
    required this.progressPct,
    required this.completed,
    required this.lastPosition,
    this.completedAt,
  });

  factory LessonProgressData.fromJson(Map<String, dynamic> json) {
    return LessonProgressData(
      status: json['status'] as String? ?? 'assigned',
      progressPct: json['progress_pct'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      lastPosition: json['last_position'] as int? ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }
}
