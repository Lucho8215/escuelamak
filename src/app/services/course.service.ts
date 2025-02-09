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
  private timeoutDuration = 15000; // 15 segundos de timeout

  constructor() {
    this.supabase = createClient(environment.supabaseUrl, environment.supabaseKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true
      },
      db: {
        schema: 'public'
      },
      global: {
        headers: { 'x-custom-timeout': this.timeoutDuration.toString() }
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

  // Clases
  async createClass(classData: Omit<Class, 'id'>): Promise<Class> {
    return this.retryOperation(async () => {
      const snakeCaseData = this.transformToSnakeCase(classData);

      const { data, error } = await this.supabase
        .from('classes')
        .insert([snakeCaseData])
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

  async getClasses(courseId: string): Promise<Class[]> {
    return this.retryOperation(async () => {
      const { data, error } = await this.supabase
        .from('classes')
        .select('*')
        .eq('course_id', courseId)
        .order('class_number', { ascending: true });

      if (error) throw error;
      return this.transformToCamelCase(data || []);
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

  async getEnrollments(courseId: string): Promise<CourseEnrollment[]> {
    return this.retryOperation(async () => {
      const { data, error } = await this.supabase
        .from('course_enrollments')
        .select('*')
        .eq('course_id', courseId);

      if (error) throw error;
      return this.transformToCamelCase(data || []);
    });
  }
}