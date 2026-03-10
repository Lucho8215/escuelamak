import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { Course, Class, CourseEnrollment } from '../models/course.model';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../environments/environment';
import { ClassEnrollment } from '../models/course.model';


@Injectable({
  providedIn: 'root'
})
export class CourseService {
  private supabase: SupabaseClient;
  private retryCount = 3;
  private retryDelay = 1000;
  private timeoutDuration = 30000; // 30 segundos de timeout

  constructor() {
    this.supabase = createClient(environment.supabaseUrl, environment.supabaseKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true
      },
      realtime: {
        params: {
          eventsPerSecond: 10
        }
      },
      db: {
        schema: 'public'
      },
      global: {
        headers: { 'x-custom-timeout': this.timeoutDuration.toString() },
        fetch: (url, options = {}) => {
          return fetch(url, {
            ...options,
            signal: AbortSignal.timeout(this.timeoutDuration)
            
          });
          
        }
      }
    });
  }

  private async withTimeout<T>(promise: Promise<T>): Promise<T> {
    const timeout = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('Operation timed out')), this.timeoutDuration);
    });

    return Promise.race([promise, timeout]) as Promise<T>;
  }

  private async retryOperation<T>(operation: () => Promise<T>): Promise<T> {
    let lastError: any;
    
    for (let i = 0; i < this.retryCount; i++) {
      try {
        return await this.withTimeout(operation());
      } catch (error: any) {
        lastError = error;
        console.warn(`Retry ${i + 1}/${this.retryCount} failed:`, error.message);
        
        if (i < this.retryCount - 1) {
          const delay = this.retryDelay * Math.pow(2, i); // Exponential backoff
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }
    
    throw lastError;
  }

  private transformToSnakeCase(data: any): any {
    if (!data) return data;
    
    if (Array.isArray(data)) {
      return data.map(item => this.transformToSnakeCase(item));
    }
    
    if (data instanceof Date) {
      return data;
    }
    
    if (typeof data === 'object') {
      const transformed: any = {};
      for (const [key, value] of Object.entries(data)) {
        const snakeKey = key.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
        transformed[snakeKey] = this.transformToSnakeCase(value);
      }
      return transformed;
    }
    
    return data;
  }

  private transformToCamelCase(data: any): any {
    if (!data) return data;
    
    if (Array.isArray(data)) {
      return data.map(item => this.transformToCamelCase(item));
    }
    
    if (data instanceof Date) {
      return data;
    }
    
    if (typeof data === 'object') {
      const transformed: any = {};
      for (const [key, value] of Object.entries(data)) {
        const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
        transformed[camelKey] = this.transformToCamelCase(value);
      }
      return transformed;
    }
    
    return data;
  }

  // Cursos
  async getCourses(): Promise<Course[]> {
    return this.retryOperation(async () => {
      const { data, error } = await this.supabase
        .from('courses')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return this.transformToCamelCase(data || []);
    });
  }

  async createCourse(course: Omit<Course, 'id' | 'createdAt' | 'updatedAt'>): Promise<Course> {
    return this.retryOperation(async () => {
      const snakeCaseData = this.transformToSnakeCase({
        ...course,
        created_at: new Date(),
        updated_at: new Date()
      });

      const { data, error } = await this.supabase
        .from('courses')
        .insert([snakeCaseData])
        .select()
        .single();

      if (error) throw error;
      return this.transformToCamelCase(data);
    });
  }

  async updateCourse(id: string, course: Partial<Course>): Promise<Course> {
    return this.retryOperation(async () => {
      const snakeCaseData = this.transformToSnakeCase({
        ...course,
        updated_at: new Date()
      });

      const { data, error } = await this.supabase
        .from('courses')
        .update(snakeCaseData)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return this.transformToCamelCase(data);
    });
  }

  async deleteCourse(id: string): Promise<void> {
    return this.retryOperation(async () => {
      const { error } = await this.supabase
        .from('courses')
        .delete()
        .eq('id', id);

      if (error) throw error;
    });
  }

  // Clases
  async getClasses(courseId: string): Promise<Class[]> {
    return this.retryOperation(async () => {
      let query = this.supabase
        .from('classes')
        .select('*')
        .order('class_number', { ascending: true });
      if (courseId && courseId.trim() !== '') {
        query = query.eq('course_id', courseId);
      }
      const { data, error } = await query;
      if (error) throw error;
      return this.transformToCamelCase(data || []);
    });
  }
  async toggleLessonAssignment(lessonId: string, studentId: string) {
  // 1. Buscamos si ya existe el permiso
  const { data: existing } = await this.supabase
    .from('student_lesson_assignments')
    .select('*')
    .match({ lesson_id: lessonId, student_id: studentId })
    .single();

  if (existing) {
    // 2. Si existe, lo borramos (quitar acceso)
    return await this.supabase
      .from('student_lesson_assignments')
      .delete()
      .match({ lesson_id: lessonId, student_id: studentId });
  } else {
    // 3. Si no existe, lo creamos (dar acceso)
    return await this.supabase
      .from('student_lesson_assignments')
      .insert([{ lesson_id: lessonId, student_id: studentId }]);
  }
}
async getClassEnrollments(classId: string): Promise<ClassEnrollment[]> {
  const { data, error } = await this.supabase
    .from('class_enrollments')
    .select('*')
    .eq('class_id', classId)
    .order('enrollment_date', { ascending: false });

  if (error) {
    throw error;
  }

  return (data || []).map((item: any) => ({
    id: item.id,
    courseId: item.course_id,
    classId: item.class_id,
    studentId: item.student_id,
    status: item.status,
    enrollmentDate: item.enrollment_date ? new Date(item.enrollment_date) : new Date()
  }));
}

async createClassEnrollment(enrollment: Omit<ClassEnrollment, 'id'>): Promise<void> {
  const { error } = await this.supabase.from('class_enrollments').insert([
    {
      course_id: enrollment.courseId,
      class_id: enrollment.classId,
      student_id: enrollment.studentId,
      status: enrollment.status,
      enrollment_date: enrollment.enrollmentDate
    }
  ]);

  if (error) {
    throw error;
  }
}

async deleteClassEnrollment(enrollmentId: string): Promise<void> {
  const { error } = await this.supabase
    .from('class_enrollments')
    .delete()
    .eq('id', enrollmentId);

  if (error) {
    throw error;
  }
}

async updateClassEnrollmentStatus(
  enrollmentId: string,
  status: 'active' | 'inactive' | 'pending'
): Promise<void> {
  const { error } = await this.supabase
    .from('class_enrollments')
    .update({ status })
    .eq('id', enrollmentId);

  if (error) {
    throw error;
  }
}

async createClass(classData: Omit<Class, 'id'>): Promise<Class> {
    return this.retryOperation(async () => {
      const raw: any = {
        course_id: classData.courseId || null,
        name: classData.name || '',
        title: classData.name || '',
        teacher_id: classData.teacherId && classData.teacherId.trim() !== '' ? classData.teacherId : null,
        status: classData.status || 'open',
        class_number: classData.classNumber || 1,
        enrollment_count: classData.enrollmentCount || 0,
        max_students: classData.maxStudents || 30,
        start_date: classData.startDate || null,
        end_date: classData.endDate || null,
        enrolled_students: classData.enrolledStudents || []
      };

      const { data, error } = await this.supabase
        .from('classes')
        .insert([raw])
        .select()
        .single();

      if (error) throw error;
      return this.transformToCamelCase(data);
    });
  }


  async updateClass(id: string, classData: Partial<Class>): Promise<Class> {
    return this.retryOperation(async () => {
      const snakeCaseData = this.transformToSnakeCase(classData);

      const { data, error } = await this.supabase
        .from('classes')
        .update(snakeCaseData)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return this.transformToCamelCase(data);
    });
  }

  async deleteClass(id: string): Promise<void> {
    return this.retryOperation(async () => {
      const { error } = await this.supabase
        .from('classes')
        .delete()
        .eq('id', id);

      if (error) throw error;
    });
  }

  // Inscripciones
  async enrollStudent(enrollment: Omit<CourseEnrollment, 'id'>): Promise<CourseEnrollment> {
    return this.retryOperation(async () => {
      const snakeCaseData = this.transformToSnakeCase({
        ...enrollment,
        enrollment_date: new Date()
      });

      const { data, error } = await this.supabase
        .from('course_enrollments')
        .insert([snakeCaseData])
        .select()
        .single();

      if (error) throw error;
      return this.transformToCamelCase(data);
    });
  }

async getEnrollments(classId: string): Promise<CourseEnrollment[]> {
    return this.retryOperation(async () => {
      const { data, error } = await this.supabase
        .from('enrollment_details')
        .select('*')
        .eq('class_id', classId)
        .order('enrollment_date', { ascending: false });

      if (error) throw error;
      return this.transformToCamelCase(data || []);
    });
  }
// Asignar una lecciÃ³n a un alumno especÃ­fico
async assignLessonToStudent(lessonId: string, studentId: string) {
  return await this.supabase
    .from('student_lesson_assignments')
    .insert([{ lesson_id: lessonId, student_id: studentId }]);
}

// Obtener quÃ© alumnos tienen asignada una lecciÃ³n
async getLessonAssignments(lessonId: string): Promise<any[]> {
    return this.retryOperation(async () => {
      const { data, error } = await this.supabase
        .from('student_lesson_assignments')
        .select('student_id')
        .eq('lesson_id', lessonId);
      if (error) throw error;
      return data || [];
    });
  }

  async getStudents(): Promise<any[]> {
    return this.retryOperation(async () => {
       const { data, error } = await this.supabase
        .from('app_users')
        .select('id, name, email, role')
        .in('role', ['student', 'alumno', 'estudiante'])
        .order('name', { ascending: true });

      if (error) throw error;
      return data || [];
    });
  }

  async enrollStudentToClass(studentId: string, classId: string, courseId: string): Promise<any> {
    return this.retryOperation(async () => {
      const { data, error } = await this.supabase
        .from('course_enrollments')
        .insert([{
          student_id: studentId,
          class_id: classId,
          course_id: courseId,
          status: 'active',
          enrollment_date: new Date().toISOString()
        }])
        .select()
        .single();

      if (error) throw error;

      // Actualizar contador
      await this.supabase
        .from('classes')
        .update({ enrollment_count: (await this.supabase.from('classes').select('enrollment_count').eq('id', classId).single()).data?.enrollment_count + 1 })
        .eq('id', classId);

      return data;
    });
  }
  // AÃ±adir al final de CourseService
   async createLesson(lessonData: any): Promise<any> {
    return this.retryOperation(async () => {
      const { data, error } = await this.supabase
        .from('lessons')
        .insert([lessonData])
        .select()
        .single();
      if (error) throw error;
      return data;
    });
  }


async getLessonsByClass(classId: string): Promise<any[]> {
    return this.retryOperation(async () => {
      const { data, error } = await this.supabase
        .from('lessons')
        .select('*')
        .eq('class_id', classId)
        .order('order', { ascending: true });
      if (error) throw error;
      return data || [];
    });
  }

// AsegÃºra de que este mÃ©todo devuelva los usuarios correctamente formateados, especialmente si quieres mostrar solo profesores en la gestiÃ³n de clases
async getUsersByRole(roles: string[]): Promise<any[]> {
    return this.retryOperation(async () => {
      const { data, error } = await this.supabase
        .from('app_users')
        .select('id, name, email, role')
        .in('role', roles)
        .order('name', { ascending: true });
      if (error) throw error;
      return data || [];
    });
  }


  async removeEnrollment(enrollmentId: string, classId: string): Promise<void> {
    return this.retryOperation(async () => {
      const { error } = await this.supabase
        .from('course_enrollments')
        .delete()
        .eq('id', enrollmentId);

      if (error) throw error;

      // Actualizar contador
      const { data: cls } = await this.supabase
        .from('classes')
        .select('enrollment_count')
        .eq('id', classId)
        .single();

      if (cls && cls.enrollment_count > 0) {
        await this.supabase
          .from('classes')
          .update({ enrollment_count: cls.enrollment_count - 1 })
          .eq('id', classId);
      }
    });
  }
} 