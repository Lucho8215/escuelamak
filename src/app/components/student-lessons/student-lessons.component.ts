import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { LessonService } from '../../services/lesson.service';
import { SupabaseService } from '../../services/supabase.service';
import { StudentLesson } from '../../models/lesson.model';

@Component({
  selector: 'app-student-lessons',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './student-lessons.component.html',
  styleUrls: ['./student-lessons.component.css']
})
export class StudentLessonsComponent implements OnInit {

  // Lista de lecciones del alumno
  lessons: StudentLesson[] = [];

  // Lección que el alumno abrió para estudiar
  selectedLesson: StudentLesson | null = null;

  // Estados de carga
  loading = false;
  actionLoading = false;

  // Mensajes
  errorMessage = '';
  successMessage = '';

  constructor(
    private lessonService: LessonService,
    private supabaseService: SupabaseService,
    private sanitizer: DomSanitizer
  ) {}

  async ngOnInit(): Promise<void> {
    await this.loadMyLessons();
  }

  // Carga todas las lecciones asignadas al alumno
  async loadMyLessons(): Promise<void> {
    try {
      this.loading = true;
      this.errorMessage = '';

      const { data: { user } } = await this.supabaseService.getClient().auth.getUser();

      if (!user) {
        this.errorMessage = 'No hay sesión activa';
        return;
      }

      const appUserId = await this.lessonService.getAppUserIdByAuthUserId(user.id);

      if (!appUserId) {
        this.errorMessage = 'No se encontró el alumno';
        return;
      }

      this.lessons = await this.lessonService.getStudentLessonsByStudent(appUserId);

    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : 'Error al cargar lecciones';
    } finally {
      this.loading = false;
    }
  }

  // Abre una lección para estudiarla
  openLesson(lesson: StudentLesson): void {
    this.selectedLesson = lesson;
    // Si nunca la inició, la marcamos como en progreso
    if (lesson.status === 'assigned') {
      this.startLesson(lesson);
    }
  }

  // Cierra el modal de la lección
  closeLesson(): void {
    this.selectedLesson = null;
    this.successMessage = '';
  }

  // Convierte URL de YouTube a formato embebible
  getVideoEmbedUrl(url: string): SafeResourceUrl {
    if (!url) return '';
    let videoId = '';

    // Soporta youtube.com/watch?v=ID y youtu.be/ID
    if (url.includes('watch?v=')) {
      videoId = url.split('watch?v=')[1].split('&')[0];
    } else if (url.includes('youtu.be/')) {
      videoId = url.split('youtu.be/')[1].split('?')[0];
    } else if (url.includes('embed/')) {
      videoId = url.split('embed/')[1].split('?')[0];
    }

    if (videoId) {
      return this.sanitizer.bypassSecurityTrustResourceUrl(
        `https://www.youtube.com/embed/${videoId}`
      );
    }

    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  }

  // Marca la lección como iniciada
  async startLesson(lesson: StudentLesson): Promise<void> {
    try {
      this.actionLoading = true;
      await this.lessonService.updateStudentLessonStatus(
        lesson.id, 'in_progress',
        lesson.progressPercent > 0 ? lesson.progressPercent : 10
      );
      await this.loadMyLessons();
      // Actualizamos también la lección seleccionada
      if (this.selectedLesson?.id === lesson.id) {
        this.selectedLesson = this.lessons.find(l => l.id === lesson.id) || null;
      }
    } catch (error) {
      this.errorMessage = 'No se pudo iniciar la lección';
    } finally {
      this.actionLoading = false;
    }
  }

  // Avanza el progreso en 20%
  async continueLesson(lesson: StudentLesson): Promise<void> {
    try {
      this.actionLoading = true;
      const next = Math.min(100, lesson.progressPercent + 20);
      await this.lessonService.updateStudentLessonProgress(lesson.id, next);
      await this.loadMyLessons();
      if (this.selectedLesson?.id === lesson.id) {
        this.selectedLesson = this.lessons.find(l => l.id === lesson.id) || null;
      }
      this.successMessage = `¡Progreso actualizado a ${next}%!`;
    } catch (error) {
      this.errorMessage = 'No se pudo actualizar el progreso';
    } finally {
      this.actionLoading = false;
    }
  }

  // Marca la lección como completada al 100%
  async completeLesson(lesson: StudentLesson): Promise<void> {
    try {
      this.actionLoading = true;
      await this.lessonService.updateStudentLessonStatus(lesson.id, 'completed');
      await this.loadMyLessons();
      if (this.selectedLesson?.id === lesson.id) {
        this.selectedLesson = this.lessons.find(l => l.id === lesson.id) || null;
      }
      this.successMessage = '¡Lección completada! 🎉';
    } catch (error) {
      this.errorMessage = 'No se pudo completar la lección';
    } finally {
      this.actionLoading = false;
    }
  }

  // Etiqueta legible del estado
  getStatusLabel(status: string): string {
    const labels: any = {
      'assigned': 'Por iniciar',
      'in_progress': 'En progreso',
      'completed': 'Completada',
      'inactive': 'Inactiva'
    };
    return labels[status] || status;
  }

  // Color de la barra de progreso
  getProgressColor(value: number): string {
    if (value >= 100) return '#16a34a';
    if (value >= 50) return '#2563eb';
    if (value > 0) return '#f59e0b';
    return '#94a3b8';
  }

  // Progreso general del alumno
  getOverallProgress(): number {
    if (this.lessons.length === 0) return 0;
    const total = this.lessons.reduce((sum, l) => sum + l.progressPercent, 0);
    return Math.round(total / this.lessons.length);
  }

  // Contadores para el resumen
  getCompletedCount(): number {
    return this.lessons.filter(l => l.status === 'completed').length;
  }

  getInProgressCount(): number {
    return this.lessons.filter(l => l.status === 'in_progress').length;
  }

  getPendingCount(): number {
    return this.lessons.filter(l => l.status === 'assigned').length;
  }
}