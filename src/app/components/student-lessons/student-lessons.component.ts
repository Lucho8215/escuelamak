import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LessonService } from '../../services/lesson.service';
import { SupabaseService } from '../../services/supabase.service';
import { StudentLesson } from '../../models/lesson.model';

@Component({
  selector: 'app-student-lessons',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './student-lessons.component.html',
  styleUrls: ['./student-lessons.component.css']
})
export class StudentLessonsComponent implements OnInit {
  lessons: StudentLesson[] = [];
  loading = false;
  errorMessage = '';
  successMessage = '';

  constructor(
    private lessonService: LessonService,
    private supabaseService: SupabaseService
  ) {}

  async ngOnInit(): Promise<void> {
    await this.loadMyLessons();
  }

  async loadMyLessons(): Promise<void> {
    try {
      this.loading = true;
      this.errorMessage = '';

      const {
        data: { user }
      } = await this.supabaseService.getClient().auth.getUser();

      if (!user) {
        this.errorMessage = 'No hay sesión activa';
        return;
      }

      const appUserId = await this.lessonService.getAppUserIdByAuthUserId(user.id);

      if (!appUserId) {
        this.errorMessage = 'No se encontró el alumno en app_users';
        return;
      }

      this.lessons = await this.lessonService.getStudentLessonsByStudent(appUserId);
    } catch (error) {
      console.error(error);
      this.errorMessage = error instanceof Error ? error.message : 'Error al cargar tus lecciones';
    } finally {
      this.loading = false;
    }
  }

  async startLesson(row: StudentLesson): Promise<void> {
    try {
      this.loading = true;
      await this.lessonService.updateStudentLessonStatus(
        row.id,
        'in_progress',
        row.progressPercent > 0 ? row.progressPercent : 10
      );
      await this.loadMyLessons();
      this.successMessage = 'Lección iniciada';
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : 'No se pudo iniciar la lección';
    } finally {
      this.loading = false;
    }
  }

  async continueLesson(row: StudentLesson): Promise<void> {
    try {
      this.loading = true;
      const next = Math.min(100, row.progressPercent + 20);
      await this.lessonService.updateStudentLessonProgress(row.id, next);
      await this.loadMyLessons();
      this.successMessage = 'Progreso actualizado';
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : 'No se pudo continuar la lección';
    } finally {
      this.loading = false;
    }
  }

  async completeLesson(row: StudentLesson): Promise<void> {
    try {
      this.loading = true;
      await this.lessonService.updateStudentLessonStatus(row.id, 'completed');
      await this.loadMyLessons();
      this.successMessage = 'Lección completada';
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : 'No se pudo completar la lección';
    } finally {
      this.loading = false;
    }
  }

  getStatusLabel(status: string): string {
    if (status === 'assigned') return 'No iniciada';
    if (status === 'in_progress') return 'En progreso';
    if (status === 'completed') return 'Completada';
    return 'Inactiva';
  }

  getProgressColor(value: number): string {
    if (value >= 100) return '#16a34a';
    if (value >= 50) return '#2563eb';
    if (value > 0) return '#f59e0b';
    return '#94a3b8';
  }

  getOverallProgress(): number {
    if (this.lessons.length === 0) return 0;
    const total = this.lessons.reduce((sum, item) => sum + item.progressPercent, 0);
    return Math.round(total / this.lessons.length);
  }
}