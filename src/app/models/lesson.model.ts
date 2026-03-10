export interface Lesson {
  id: string;
  courseId: string;
  title: string;
  summary?: string;
  objective?: string;
  content?: string;
  videoUrl?: string;
  coverImageUrl?: string;
  resourceLink?: string;
  resourceFileUrl?: string;
  estimatedMinutes: number;
  orderIndex: number;
  isPublished: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export type StudentLessonStatus =
  | 'assigned'
  | 'in_progress'
  | 'completed'
  | 'inactive';

export interface StudentLesson {
  id: string;
  lessonId: string;
  classId: string;
  studentId: string;
  status: StudentLessonStatus;
  progressPercent: number;
  score?: number | null;
  isActive: boolean;
  assignedAt: Date;
  startedAt?: Date | null;
  lastAccessedAt?: Date | null;
  completedAt?: Date | null;
  createdAt?: Date;
  updatedAt?: Date;

  lessonTitle?: string;
  studentName?: string;
  studentEmail?: string;
  className?: string;
  summary?: string;
  objective?: string;
  content?: string;
  videoUrl?: string;
  coverImageUrl?: string;
  resourceLink?: string;
  resourceFileUrl?: string;
}

export type CreateLessonInput = {
  courseId: string;
  title: string;
  summary?: string;
  objective?: string;
  content?: string;
  videoUrl?: string;
  coverImageUrl?: string;
  resourceLink?: string;
  resourceFileUrl?: string;
  estimatedMinutes: number;
  orderIndex: number;
  isPublished: boolean;
};