import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { QuizService } from '../../services/quiz.service';
import { LessonService } from '../../services/lesson.service';
import { AuthService } from '../../services/auth.service';
import { Quiz } from '../../models/quiz.model';
import { UserRole } from '../../models/user.model';

@Component({
  selector: 'app-review',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './review.component.html',
  styleUrls: ['./review.component.css']
})
export class ReviewComponent implements OnInit {

  // ─── DATOS ───────────────────────────────────────────
  // Lista de todos los quizzes disponibles
  quizzes: Quiz[] = [];

  // Intentos/logros de todos los estudiantes (para admin/profesor)
  todosLosLogros: any[] = [];

  // Logros filtrados por búsqueda
  logrosFiltrados: any[] = [];

  // Progreso de lecciones de todos los estudiantes
  progresoLecciones: any[] = [];

  // ─── MODAL ACTIVO ────────────────────────────────────
  // Puede ser: '' | 'quizzes' | 'logros' | 'quiz-detalle'
  modalActivo: string = '';

  // Quiz seleccionado para ver su detalle
  quizSeleccionado: Quiz | null = null;

  // ─── FILTROS ─────────────────────────────────────────
  // Texto para filtrar logros por nombre de estudiante
  filtroEstudiante: string = '';

  // Filtro por resultado: 'todos' | 'aprobado' | 'reprobado'
  filtroResultado: string = 'todos';

  // ─── ESTADOS ─────────────────────────────────────────
  cargando: boolean = false;
  cargandoLogros: boolean = false;

  // ─── ROL DEL USUARIO ─────────────────────────────────
  // true si es admin o profesor (ve todo)
  isAdminOrTeacher: boolean = false;

  // true si es estudiante (ve solo sus cosas)
  isStudent: boolean = false;

  // ID del usuario actual
  currentUserId: string = '';

  constructor(
    private quizService: QuizService,
    private lessonService: LessonService,
    private authService: AuthService
  ) {}

  async ngOnInit(): Promise<void> {
    const user = this.authService.getCurrentUser();
    if (!user) return;

    this.currentUserId = user.id;
    this.isAdminOrTeacher = user.role === UserRole.ADMIN || user.role === UserRole.TEACHER;
    this.isStudent = user.role === UserRole.STUDENT;

    // Cargamos los quizzes al inicio
    await this.loadQuizzes();
  }

  // ─── CARGAR QUIZZES ──────────────────────────────────
  // Trae todos los quizzes habilitados de Supabase
  // Carga quizzes usando getVisibleQuizzes para evitar
  // el error 400 de quiz_assignments
  async loadQuizzes(): Promise<void> {
    this.cargando = true;
    this.quizService.getVisibleQuizzes().subscribe({
      next: (data) => {
        this.quizzes = data;
        this.cargando = false;
      },
      error: (err) => {
        console.error('Error cargando quizzes:', err);
        this.cargando = false;
      }
    });
  
  }

  // ─── ABRIR MODAL QUIZZES ─────────────────────────────
  abrirModalQuizzes(): void {
    this.modalActivo = 'quizzes';
  }

  // ─── ABRIR DETALLE DE UN QUIZ ────────────────────────
  // Muestra las preguntas y opciones de un quiz específico
  verDetalleQuiz(quiz: Quiz): void {
    this.quizSeleccionado = quiz;
    this.modalActivo = 'quiz-detalle';
  }

  // ─── VOLVER AL LISTADO DE QUIZZES ───────────────────
  volverAQuizzes(): void {
    this.quizSeleccionado = null;
    this.modalActivo = 'quizzes';
  }

  // ─── ABRIR MODAL LOGROS / PROGRESO ──────────────────
  // Si es admin/profesor → ve logros de TODOS los estudiantes
  // Si es estudiante → ve solo sus propios logros
  async abrirModalLogros(): Promise<void> {
    this.modalActivo = 'logros';
    this.cargandoLogros = true;

    if (this.isAdminOrTeacher) {
      // Admin ve todos los intentos de todos los alumnos
      this.quizService.getAllAttempts().subscribe({
        next: (data) => {
          this.todosLosLogros = data;
          this.aplicarFiltros();
          this.cargandoLogros = false;
        },
        error: () => { this.cargandoLogros = false; }
      });
    } else {
      // Estudiante ve solo sus intentos
      this.quizService.getStudentQuizzes(this.currentUserId).subscribe({
       next: (data: any[]) => {
          this.todosLosLogros = data;
          this.aplicarFiltros();
          this.cargandoLogros = false;
        },
        error: () => { this.cargandoLogros = false; }
      });
    }
  }

  // ─── APLICAR FILTROS A LOS LOGROS ───────────────────
  // Filtra por nombre de estudiante y por resultado
  aplicarFiltros(): void {
    let resultado = [...this.todosLosLogros];

    // Filtrar por nombre si hay texto en la búsqueda
    if (this.filtroEstudiante.trim()) {
      const texto = this.filtroEstudiante.toLowerCase();
      resultado = resultado.filter(l =>
        (l.student_name || l.studentName || '').toLowerCase().includes(texto) ||
        (l.student_email || l.studentEmail || '').toLowerCase().includes(texto)
      );
    }

    // Filtrar por resultado aprobado/reprobado
    if (this.filtroResultado === 'aprobado') {
      resultado = resultado.filter(l => l.passed);
    } else if (this.filtroResultado === 'reprobado') {
      resultado = resultado.filter(l => !l.passed);
    }

    this.logrosFiltrados = resultado;
  }

  // ─── CERRAR CUALQUIER MODAL ──────────────────────────
  cerrarModal(): void {
    this.modalActivo = '';
    this.quizSeleccionado = null;
    this.filtroEstudiante = '';
    this.filtroResultado = 'todos';
  }

  // ─── HELPERS DE DISPLAY ─────────────────────────────
  // Convierte la dificultad en texto legible
  getDificultadLabel(dif: string): string {
    const labels: any = { easy: 'Fácil', medium: 'Medio', hard: 'Difícil' };
    return labels[dif] || dif;
  }

  // Color según dificultad
  getDificultadColor(dif: string): string {
    const colors: any = { easy: '#22c55e', medium: '#f59e0b', hard: '#ef4444' };
    return colors[dif] || '#94a3b8';
  }

  // Color según puntaje
  getScoreColor(score: number): string {
    if (score >= 80) return '#22c55e';
    if (score >= 60) return '#f59e0b';
    return '#ef4444';
  }

  // Estadísticas rápidas para el panel de logros
  getTotalAprobados(): number {
    return this.logrosFiltrados.filter(l => l.passed).length;
  }

  getTotalReprobados(): number {
    return this.logrosFiltrados.filter(l => !l.passed).length;
  }

  getPromedioGeneral(): number {
    if (this.logrosFiltrados.length === 0) return 0;
    const suma = this.logrosFiltrados.reduce((acc, l) => acc + (l.score || 0), 0);
    return Math.round(suma / this.logrosFiltrados.length);
  }

  // Quizzes activos/inactivos para el resumen
  getQuizzesActivos(): number {
    return this.quizzes.filter(q => q.isEnabled).length;
  }
}