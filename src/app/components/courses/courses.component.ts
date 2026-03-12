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

  // ─── DATOS ───────────────────────────────────────
  // Lista de cursos visibles para el usuario
  courses: Course[] = [];

  // Clases del curso que se abrió en el modal
  classes: Class[] = [];

  // ─── SELECCIÓN ───────────────────────────────────
  // Curso que el usuario abrió (muestra el modal)
  selectedCourse: Course | null = null;

  // Clase que el usuario abrió para ver su contenido
  selectedClass: Class | null = null;

  // Pestaña activa dentro del detalle de la clase
  // Puede ser: 'info' | 'video' | 'pdf' | 'imagen'
  activeTab: string = 'info';

  // ─── ESTADOS ─────────────────────────────────────
  isLoading = false;
  loadingClasses = false;

  // ─── USUARIO ─────────────────────────────────────
  // true si el usuario logueado es estudiante
  isStudent = false;

  // ID del usuario actual para filtrar inscripciones
  currentUserId = '';

  constructor(
    private courseService: CourseService,
    private authService: AuthService,
    // DomSanitizer: permite embeber URLs de video de forma segura
    private sanitizer: DomSanitizer
  ) {}

  // Se ejecuta automáticamente al cargar el componente
  async ngOnInit() {
    const user = this.authService.getCurrentUser();
    if (!user) return;
    this.currentUserId = user.id;
    this.isStudent = user.role === UserRole.STUDENT;
    await this.loadCourses();
  }

  // ─── EMOJIS ──────────────────────────────────────
  // Devuelve un emoji según la categoría del curso
  getCourseEmoji(category: string): string {
    const emojis: any = {
      'mathematics': '🔢',
      'education': '📚',
      'algebra': '➗'
    };
    return emojis[category] || '📖';
  }

  // ─── INSCRIPCIONES ───────────────────────────────
  // Consulta directamente en Supabase las clases
  // donde el alumno actual está inscrito y activo
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

  // ─── CARGAR CURSOS ───────────────────────────────
  // Si es alumno → solo ve sus cursos asignados
  // Si es admin/profesor → ve todos los cursos visibles
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

  // ─── ABRIR MODAL DE CLASES ───────────────────────
  // Al hacer clic en una tarjeta de curso:
  // 1. Guarda el curso seleccionado
  // 2. Carga sus clases desde Supabase
  // 3. Si es alumno, filtra solo sus clases
  async viewCourseDetails(course: Course) {
    this.selectedCourse = course;
    this.selectedClass = null;
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

  // ─── ABRIR DETALLE DE CLASE ──────────────────────
  // Al hacer clic en una clase de la lista:
  // - Si ya estaba abierta → la cierra
  // - Si es nueva → la abre y muestra la pestaña 'info'
  selectClass(clase: Class) {
    if (this.selectedClass?.id === clase.id) {
      this.selectedClass = null;
    } else {
      this.selectedClass = clase;
      this.activeTab = 'info'; // Siempre empieza en Info
    }
  }

  // ─── PESTAÑAS ────────────────────────────────────
  // Cambia la pestaña activa dentro del detalle de clase
  setTab(tab: string) {
    this.activeTab = tab;
  }

  // ─── VIDEO YOUTUBE ───────────────────────────────
  // Convierte una URL normal de YouTube en URL embebible
  // Ejemplo: youtube.com/watch?v=ABC → youtube.com/embed/ABC
  // DomSanitizer evita que Angular bloquee la URL como insegura
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
    // Si no es YouTube, embebe directamente (p.ej. Vimeo)
    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  }

  // ─── PDF ─────────────────────────────────────────
  // Convierte una URL de PDF en URL segura para el iframe
  // Usa Google Docs Viewer para mostrar el PDF en el navegador
  getPdfViewerUrl(url: string): SafeResourceUrl {
    if (!url) return '';
    // Google Docs Viewer permite ver PDFs sin descargarlos
    const viewerUrl = `https://docs.google.com/viewer?url=${encodeURIComponent(url)}&embedded=true`;
    return this.sanitizer.bypassSecurityTrustResourceUrl(viewerUrl);
  }

  // ─── DETECTAR TIPO DE RECURSO ────────────────────
  // Revisa si la URL termina en .pdf para saber cómo mostrarlo
  isPdf(url: string): boolean {
    return url?.toLowerCase().includes('.pdf') || false;
  }

  // ─── VERIFICAR PESTAÑAS DISPONIBLES ─────────────
  // Solo muestra la pestaña de video si hay videoUrl en la clase
  hasVideo(clase: Class): boolean {
    return !!(clase.videoUrl?.includes('youtube') || clase.videoUrl?.includes('vimeo') || clase.videoUrl);}

  // Solo muestra la pestaña de imagen si hay imageUrl
  hasImage(clase: Class): boolean {
    return !!clase.imageUrl;
  }

  // Solo muestra pestaña PDF si el archivo adjunto es un PDF
  hasPdf(clase: Class): boolean {
    return !!clase.resourceFileUrl && this.isPdf(clase.resourceFileUrl);
  }

  // ─── CERRAR MODALES ──────────────────────────────
  // Cierra el modal principal y limpia todo
  closeModal() {
    this.selectedCourse = null;
    this.selectedClass = null;
    this.classes = [];
  }
}