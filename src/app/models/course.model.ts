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
  enrolledStudents: string[]; // IDs de estudiantes
}

export interface CourseEnrollment {
  id: string;
  courseId: string;
  studentId: string;
  classId: string; // Agregado para vincular la inscripción con una clase específica
  enrollmentDate: Date;
  status: 'active' | 'completed' | 'cancelled';
}