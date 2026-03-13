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
      // Si no hay lecciones pero la clase tiene imagen, PDF o enlace, crear una "lección virtual"
      // para que el estudiante vea el contenido asignado a la clase.
      if (allLessons.length === 0 && this.classHasResources(clase)) {
        this.lessons = [this.classAsVirtualLesson(clase)];
      }
    } catch (error) {
      console.error('Error al cargar lecciones:', error);
    } finally {
      this.loadingLessons = false;
    }
  }

  /** Indica si la clase tiene recursos (imagen, PDF, enlace) para mostrar */
  classHasResources(clase: Class): boolean {
    return !!(clase.imageUrl || clase.resourceFileUrl || clase.resourceLink);
  }

  /** Convierte la clase en un objeto tipo lección para mostrarla en la vista */
  classAsVirtualLesson(clase: Class): any {
    return {
      id: `class-${clase.id}`,
      title: clase.name,
      name: clase.name,
      resourceLink: clase.resourceLink,
      resource_link: clase.resourceLink,
      resourceFileUrl: clase.resourceFileUrl,
      resource_file_url: clase.resourceFileUrl,
      coverImageUrl: clase.imageUrl,
      cover_image_url: clase.imageUrl,
      imageUrl: clase.imageUrl,
      videoUrl: clase.resourceLink,
      video_url: clase.resourceLink,
      observation: clase.observation,
      summary: clase.observation,
      order: 1,
      orderIndex: 1
    };
  }
  // --- SELECCIONAR LECCION ---
  selectLesson(lesson: any) {
    if (this.selectedLesson?.id === lesson.id) {
      this.selectedLesson = null;
    } else {
      this.selectedLesson = lesson;
      // Auto-seleccionar la pestaña multimedia si hay video o PDF
      if (this.lessonHasVideo(lesson) || this.lessonHasPdf(lesson)) {
        this.activeTab = 'multimedia';
      } else {
        this.activeTab = 'info';
      }
    }
  }
  // --- PESTANAS ---
  setTab(tab: 'info' | 'multimedia' | 'imagen' | 'recurso') {
    this.activeTab = tab;
  }
  // --- DETECTAR CONTENIDO DE LECCION ---
  lessonHasVideo(lesson: any): boolean {
    const link = lesson.resource_link || lesson.resourceLink || '';
    const video = lesson.video_url || lesson.videoUrl || '';
    const url = link || video;
    return !!(url.includes('youtube') || url.includes('vimeo') || url.includes('embed') ||
              url.match(/\.(mp4|webm|ogg)(\?|$)/i));
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
    const link = lesson.resource_link || lesson.resourceLink || '';
    const video = lesson.video_url || lesson.videoUrl || '';
    const file = lesson.resource_file_url || lesson.resourceFileUrl || '';
    if (link && (link.includes('youtube') || link.includes('vimeo') || link.includes('embed') || link.match(/\.(mp4|webm|ogg)(\?|$)/i)))
      return link;
    if (video) return video;
    if (file && file.match(/\.(mp4|webm|ogg)(\?|$)/i)) return file;
    return link || video;
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
  /* --- CHIPS DE CLASE (basado en sus lecciones) ---
  hasVideo(clase: Class): boolean {
    return this.lessons.some(l => this.lessonHasVideo(l));
  }*/
    // Considera que hay video si resource_link contiene YouTube
  // o si tiene videoUrl directo
  
  hasVideo(clase: Class): boolean {
    const link = clase.resourceLink || '';
    const video = clase.videoUrl || '';
    return link.includes('youtube') || link.includes('youtu.be') ||
           link.includes('embed') || video.includes('youtube') ||
           video.includes('youtu.be');
  }
  hasPdf(clase: Class): boolean {
    return this.lessons.some(l => this.lessonHasPdf(l));
  }
  hasImage(clase: Class): boolean {
    return this.lessons.some(l => this.lessonHasImage(l));
  }
  /**
   * Obtiene la URL embebida del video (YouTube, Vimeo o MP4 directo).
   * Evita redirigir a URLs externas: todo se ve dentro del modal.
   */
  getVideoEmbedUrl(url: string): SafeResourceUrl {
    if (!url || !url.trim()) return this.sanitizer.bypassSecurityTrustResourceUrl('');
    const u = url.trim();
    // YouTube
    let videoId = '';
    if (u.includes('youtube.com/watch?v=')) {
      videoId = u.split('watch?v=')[1]?.split('&')[0] || '';
    } else if (u.includes('youtu.be/')) {
      videoId = u.split('youtu.be/')[1]?.split('?')[0] || '';
    } else if (u.includes('youtube.com/embed/')) {
      videoId = u.split('embed/')[1]?.split('?')[0] || '';
    }
    if (videoId) {
      return this.sanitizer.bypassSecurityTrustResourceUrl(
        `https://www.youtube.com/embed/${videoId}?rel=0`
      );
    }
    // Vimeo
    const vimeoMatch = u.match(/vimeo\.com\/(?:video\/)?(\d+)/);
    if (vimeoMatch) {
      return this.sanitizer.bypassSecurityTrustResourceUrl(
        `https://player.vimeo.com/video/${vimeoMatch[1]}`
      );
    }
    // Video directo (MP4, WebM, etc.)
    if (u.match(/\.(mp4|webm|ogg)(\?|$)/i)) {
      return this.sanitizer.bypassSecurityTrustResourceUrl(u);
    }
    return this.sanitizer.bypassSecurityTrustResourceUrl(u);
  }

  /**
   * Indica si la URL es un video directo (MP4, WebM) para usar <video> en lugar de <iframe>.
   */
  isDirectVideoUrl(url: string): boolean {
    return !!url?.match(/\.(mp4|webm|ogg)(\?|$)/i);
  }

  /**
   * URL embebida del PDF: se muestra directamente en iframe, sin redirigir a Google Viewer.
   * El PDF se visualiza dentro del mismo modal.
   */
  getPdfEmbedUrl(url: string): SafeResourceUrl {
    if (!url || !url.trim()) return this.sanitizer.bypassSecurityTrustResourceUrl('');
    return this.sanitizer.bypassSecurityTrustResourceUrl(url.trim());
  }
  isPdf(url: string): boolean {
    return url?.toLowerCase().includes('.pdf') || false;
  }

  /**
   * Detecta si el recurso/link es un video (YouTube, Vimeo, o archivo de video directo)
   */
  isVideoResource(url: string | undefined): boolean {
    if (!url) return false;
    const u = url.toLowerCase();
    return u.includes('youtube.com') || 
           u.includes('youtu.be') || 
           u.includes('vimeo.com') || 
           u.match(/\.(mp4|webm|ogg)(\?|$)/i) !== null;
  }

  /**
   * Obtiene la URL embedida para el recurso (si es un video)
   */
  getVideoEmbedUrlFromResource(url: string | undefined): SafeResourceUrl {
    return this.getVideoEmbedUrl(url || '');
  }

  /**
   * Indica si la URL del recurso es un video directo (MP4, WebM) para usar video en lugar de iframe
   */
  isDirectVideoResource(url: string | undefined): boolean {
    return this.isDirectVideoUrl(url || '');
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