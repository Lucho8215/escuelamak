export interface Course {
  id: string;

  title: string;
  description: string;

  category: 'education' | 'mathematics';

  imageUrl?: string;

  videoUrl?: string;

  price: number;

  hidePrice?: boolean;

  duration?: number;
  durationMonths?: number;

  isVisible: boolean;
}

export interface Class {
  id: string;

  courseId: string;

  name: string;

  teacherId: string;

  status: 'open' | 'closed';

  classNumber: number;

  maxStudents: number;

  enrollmentCount: number;

  startDate: Date;
  endDate: Date;

  imageUrl?: string;

  resourceLink?: string;

  resourceFileUrl?: string;

  enrolledStudents?: string[];
}

export interface CourseEnrollment {
  id: string;

  courseId: string;
  classId: string;

  studentId: string;
  studentName?: string;
  studentEmail?: string;

  status?: 'active' | 'inactive' | 'pending';

  enrollmentDate?: Date;
  enrolledAt?: Date;
}