export interface Course {
  id: string;
  title: string;
  description: string;
  category: 'education' | 'mathematics';
  isVisible: boolean;
  videoUrl: string;
  price: number;
  duration: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface Class {
  id: string;
  courseId: string;
  name: string;
  teacherId: string;
  status: 'open' | 'closed';
  classNumber: number;
  enrollmentCount: number;
  maxStudents: number;
  startDate: Date;
  endDate: Date;
  enrolledStudents: string[];
  courseTitle?: string;
  teacherName?: string;
}

export interface CourseEnrollment {
  id: string;
  courseId: string;
  studentId: string;
  classId: string;
  enrollmentDate: Date;
  status: 'active' | 'completed' | 'cancelled';
  studentName?: string;
  studentEmail?: string;
}

export interface Lesson {
  id: string;
  classId: string;
  title: string;
  description?: string;
  order: number;
  isCompleted: boolean;
  videoUrl?: string;
  createdAt: Date;
}