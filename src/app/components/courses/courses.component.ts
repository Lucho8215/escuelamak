import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { CourseService } from '../../services/course.service';
import { AuthService } from '../../services/auth.service';
import { Course, Class } from '../../models/course.model';
import { UserRole } from '../../models/user.model';
@Component({
  selector: 'app-courses',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './courses.component.html',
  styleUrls: ['./courses.component.css']
})
export class CoursesComponent implements OnInit {
  // --- DATOS ---
  courses: Course[] = [];
  classes: Class[] = [];
  lessons: any[] = [];  // Lecciones de la clase seleccionada
  // --- SELECCION ---
  selectedCourse: Course | null = null;
  selectedClass: Class | null = null;
  selectedLesson: any | null = null;  // Leccion abierta para ver video/PDF
  activeTab: string = 'info';
  // --- ESTADOS ---
  isLoading = false;
  loadingClasses = false;
  loadingLessons = false;
  // --- USUARIO ---
  isStudent = false;
  currentUserId = '';
  constructor(
    private courseService: CourseService,
    private authService: AuthService,
    private sanitizer: DomSanitizer
  ) {}
  async ngOnInit() {
    const user = this.authService.getCurrentUser();
    if (!user) return;
    this.currentUserId = user.id;
    this.isStudent = user.role === UserRole.STUDENT;
    await this.loadCourses();
  }
  // --- EMOJIS ---
  getCourseEmoji(category: string): string {
    const emojis: any = {
      'mathematics': '🔢',
      'education': '📚',
      'algebra': '➗'
    };
    return emojis[category] || '📖';
  }
  // --- INSCRIPCIONES ---
  async getMyEnrollments(): Promise<any[]> {
    try {
      const supabase = (this.courseService as any).supabase;
      const { data } = await supabase
        .from('class_enrollments')
        .select('course_id, class_id')
        .eq('student_id', this.currentUserId)
        .eq('status', 'active');
      return (data || []).map((e: any) => ({
        courseId: e.course_id,
        classId: e.class_id
      }));
    } catch {
      return [];
    }
  }
  // --- CARGAR CURSOS ---
  async loadCourses() {
    try {
      this.isLoading = true;
      const all = await this.courseService.getCourses();
      if (this.isStudent) {
        const myEnrollments = await this.getMyEnrollments();
        const myCourseIds = [...new Set(myEnrollments.map((e: any) => e.courseId))];
        this.courses = all.filter(c => myCourseIds.includes(c.id) && c.isVisible);
      } else {
        this.courses = all.filter(c => c.isVisible);
      }
    } catch (error) {
      console.error('Error al cargar cursos:', error);
    } finally {
      this.isLoading = false;
    }
  }
  // --- ABRIR MODAL DE CLASES ---
  async viewCourseDetails(course: Course) {
    this.selectedCourse = course;
    this.selectedClass = null;
    this.selectedLesson = null;
    this.lessons = [];
    this.classes = [];
    try {
      this.loadingClasses = true;
      const allClasses = await this.courseService.getClasses(course.id);
      if (this.isStudent) {
        const myEnrollments = await this.getMyEnrollments();
        const myClassIds = myEnrollments
          .filter((e: any) => e.courseId === course.id)
          .map((e: any) => e.classId);
        this.classes = allClasses.filter(c => myClassIds.includes(c.id));
      } else {
        this.classes = allClasses;
      }
    } catch (error) {
      console.error('Error al cargar clases:', error);
    } finally {
      this.loadingClasses = false;
    }
  }
  // --- SELECCIONAR CLASE Y CARGAR LECCIONES ---
  async selectClass(clase: Class) {
    if (this.selectedClass?.id === clase.id) {
      this.selectedClass = null;
      this.lessons = [];
      this.selectedLesson = null;
      return;
    }
    this.selectedClass = clase;
    this.selectedLesson = null;
    this.activeTab = 'info';
    this.lessons = [];
    try {
      this.loadingLessons = true;
      const allLessons = await this.courseService.getLessonsByClass(clase.id);
      this.lessons = allLessons;
    } catch (error) {
      console.error('Error al cargar lecciones:', error);
    } finally {
      this.loadingLessons = false;
    }
  }
  // --- SELECCIONAR LECCION ---
  selectLesson(lesson: any) {
    if (this.selectedLesson?.id === lesson.id) {
      this.selectedLesson = null;
    } else {
      this.selectedLesson = lesson;
      // Auto-seleccionar la mejor pestana
      if (this.lessonHasVideo(lesson)) {
        this.activeTab = 'video';
      } else if (this.lessonHasPdf(lesson)) {
        this.activeTab = 'pdf';
      } else {
        this.activeTab = 'info';
      }
    }
  }
  // --- PESTANAS ---
  setTab(tab: string) {
    this.activeTab = tab;
  }
  // --- DETECTAR CONTENIDO DE LECCION ---
  lessonHasVideo(lesson: any): boolean {
    const link = lesson.resource_link || lesson.resourceLink || '';
    const video = lesson.video_url || lesson.videoUrl || '';
    return !!(link.includes('youtube') || link.includes('vimeo') || link.includes('embed') ||
              video.includes('youtube') || video.includes('vimeo') || video.includes('embed'));
  }
  lessonHasPdf(lesson: any): boolean {
    const file = lesson.resource_file_url || lesson.resourceFileUrl || '';
    return file.toLowerCase().includes('.pdf');
  }
  lessonHasImage(lesson: any): boolean {
    const img = lesson.image_url || lesson.imageUrl || lesson.cover_image_url || lesson.coverImageUrl || '';
    return !!img;
  }
  lessonHasLink(lesson: any): boolean {
    const link = lesson.resource_link || lesson.resourceLink || '';
    return !!link && !this.lessonHasVideo(lesson);
  }
  // --- OBTENER URLs DE LECCION ---
  getLessonVideoUrl(lesson: any): string {
    return lesson.resource_link || lesson.resourceLink ||
           lesson.video_url || lesson.videoUrl || '';
  }
  getLessonPdfUrl(lesson: any): string {
    return lesson.resource_file_url || lesson.resourceFileUrl || '';
  }
  getLessonImageUrl(lesson: any): string {
    return lesson.image_url || lesson.imageUrl ||
           lesson.cover_image_url || lesson.coverImageUrl || '';
  }
  getLessonLink(lesson: any): string {
    return lesson.resource_link || lesson.resourceLink || '';
  }
  getLessonObservation(lesson: any): string {
    return lesson.observation || lesson.summary || '';
  }
  getLessonName(lesson: any): string {
    return lesson.name || lesson.title || 'Sin nombre';
  }
  getLessonNumber(lesson: any): number {
    return lesson.order || lesson.order_index || lesson.orderIndex || 0;
  }
  // --- CHIPS DE CLASE (basado en sus lecciones) ---
  hasVideo(clase: Class): boolean {
    return this.lessons.some(l => this.lessonHasVideo(l));
  }
  hasPdf(clase: Class): boolean {
    return this.lessons.some(l => this.lessonHasPdf(l));
  }
  hasImage(clase: Class): boolean {
    return this.lessons.some(l => this.lessonHasImage(l));
  }
  // --- VIDEO YOUTUBE ---
  getVideoEmbedUrl(url: string): SafeResourceUrl {
    if (!url) return '';
    let videoId = '';
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
  // --- PDF ---
  getPdfViewerUrl(url: string): SafeResourceUrl {
    if (!url) return '';
    const viewerUrl = `https://docs.google.com/viewer?url=${encodeURIComponent(url)}&embedded=true`;
    return this.sanitizer.bypassSecurityTrustResourceUrl(viewerUrl);
  }
  isPdf(url: string): boolean {
    return url?.toLowerCase().includes('.pdf') || false;
  }
  // --- CERRAR MODALES ---
  closeModal() {
    this.selectedCourse = null;
    this.selectedClass = null;
    this.selectedLesson = null;
    this.classes = [];
    this.lessons = [];
  }
}