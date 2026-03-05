import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { Course, Class, CourseEnrollment } from '../models/course.model';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../environments/environment';

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

  async getStudents(): Promise<any[]> {
    return this.retryOperation(async () => {
      const { data, error } = await this.supabase
        .from('app_users')
        .select('id, name, email, role')
        .eq('role', ['student','alumno','teacher','profesor'])
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