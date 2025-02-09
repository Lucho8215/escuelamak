export enum UserRole {
  ADMIN = 'admin',
  TEACHER = 'teacher',
  TUTOR = 'tutor',
  STUDENT = 'student'
}

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  password?: string;
}