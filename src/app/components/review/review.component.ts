import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { QuizService } from '../../services/quiz.service';
import { AuthService } from '../../services/auth.service';
import { SupabaseService } from '../../services/supabase.service';
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

  // ─── MENSAJES ────────────────────────────────────────
  conversations: any[] = [];
  loadingConversations = false;
  activeConversation: any | null = null;
  activeMessages: any[] = [];
  loadingMessages = false;
  replyInput = '';
  sendingReply = false;
  // Para nuevo mensaje a estudiante
  allStudents: any[] = [];
  selectedStudentId = '';
  newMsgInput = '';
  sendingNew = false;
  showNewMsg = false;

  constructor(
    private quizService: QuizService,
    private authService: AuthService,
    private supabaseService: SupabaseService
  ) {}

  private get supabase() { return this.supabaseService.getClient(); }

  async ngOnInit(): Promise<void> {
    const user = this.authService.getCurrentUser();
    if (!user) return;

    this.currentUserId = user.id;
    this.isAdminOrTeacher = user.role === UserRole.ADMIN || user.role === UserRole.TEACHER;
    this.isStudent = user.role === UserRole.STUDENT;

    // Cargamos los quizzes al inicio
    await this.loadQuizzes();

    await this.loadConversations();

    // Verificar si hay una señal para abrir el modal de mensajes
    const pendingModal = localStorage.getItem('open_modal');
    if (pendingModal === 'mensajes') {
      localStorage.removeItem('open_modal');
      this.abrirModalMensajes();
    }
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

  // ─── MENSAJES ────────────────────────────────────────
  abrirModalMensajes(): void {
    this.modalActivo = 'mensajes';
    this.loadConversations();
  }

  getTotalUnread(): number {
    return this.conversations.reduce((sum, c) => sum + c.unread, 0);
  }

  async loadConversations(): Promise<void> {
    this.loadingConversations = true;
    try {
      // 1. Cargar todos los mensajes sin join
      const { data: msgs, error } = await this.supabase
        .from('messages')
        .select('id, sender_id, receiver_id, contenido, is_read, created_at')
        .order('created_at', { ascending: false });
      if (error) { console.error('Error mensajes:', error); return; }
      if (!msgs || msgs.length === 0) return;

      // 2. Obtener IDs únicos de usuarios involucrados
      const userIds = [...new Set([
        ...msgs.map((m: any) => m.sender_id),
        ...msgs.map((m: any) => m.receiver_id).filter(Boolean)
      ])];

      // 3. Cargar info de usuarios
      const { data: users } = await this.supabase
        .from('app_users')
        .select('id, name, role')
        .in('id', userIds);
      const userMap = new Map((users || []).map((u: any) => [u.id, u]));

      // 4. Agrupar por estudiante
      const convMap = new Map<string, any>();
      for (const msg of msgs) {
        const sender = userMap.get(msg.sender_id);
        const receiver = msg.receiver_id ? userMap.get(msg.receiver_id) : null;
        // El estudiante es quien tiene role = 'student'
        let student = sender?.role === 'student' ? sender : (receiver?.role === 'student' ? receiver : null);
        // Si no tenemos info de roles, asumimos que el sender no-admin es el estudiante
        if (!student) {
          if (sender && sender.role !== 'admin' && sender.role !== 'teacher' && sender.role !== 'tutor') {
            student = sender;
          } else if (receiver && receiver.role !== 'admin' && receiver.role !== 'teacher' && receiver.role !== 'tutor') {
            student = receiver;
          } else {
            student = sender; // fallback
          }
        }
        if (!student) continue;

        const key = student.id;
        if (!convMap.has(key)) {
          convMap.set(key, { student, lastMessage: msg, unread: 0 });
        }
        const conv = convMap.get(key)!;
        if (new Date(msg.created_at) > new Date(conv.lastMessage.created_at)) {
          conv.lastMessage = msg;
        }
        if (sender?.role === 'student' && !msg.is_read) conv.unread++;
      }
      this.conversations = Array.from(convMap.values())
        .sort((a, b) => new Date(b.lastMessage.created_at).getTime() - new Date(a.lastMessage.created_at).getTime());

      // 5. Cargar lista de todos los estudiantes para enviar nuevo mensaje
      const { data: students } = await this.supabase
        .from('app_users').select('id, name').eq('role', 'student').order('name');
      this.allStudents = students || [];
    } finally {
      this.loadingConversations = false;
    }
  }

  async openConversation(conv: any): Promise<void> {
    this.activeConversation = conv;
    this.showNewMsg = false;
    this.loadingMessages = true;
    try {
      const { data } = await this.supabase
        .from('messages')
        .select('id, sender_id, receiver_id, contenido, is_read, created_at')
        .or(`sender_id.eq.${conv.student.id},receiver_id.eq.${conv.student.id}`)
        .order('created_at', { ascending: true });
      this.activeMessages = data || [];
      const unreadIds = this.activeMessages
        .filter((m: any) => m.sender_id === conv.student.id && !m.is_read)
        .map((m: any) => m.id);
      if (unreadIds.length > 0) {
        await this.supabase.from('messages').update({ is_read: true }).in('id', unreadIds);
        conv.unread = 0;
      }
    } finally {
      this.loadingMessages = false;
    }
  }

  async sendNewMessage(): Promise<void> {
    if (!this.newMsgInput.trim() || !this.selectedStudentId || this.sendingNew) return;
    this.sendingNew = true;
    try {
      const { error } = await this.supabase.from('messages').insert([{
        sender_id: this.currentUserId,
        receiver_id: this.selectedStudentId,
        contenido: this.newMsgInput.trim(),
        is_read: false
      }]);
      if (error) {
        console.error('Error enviando mensaje nuevo:', error);
        alert('Error al enviar: ' + error.message);
      } else {
        this.newMsgInput = '';
        this.showNewMsg = false;
        await this.loadConversations();
      }
    } finally {
      this.sendingNew = false;
    }
  }

  closeConversation(): void {
    this.activeConversation = null;
    this.activeMessages = [];
    this.replyInput = '';
  }

  async sendReply(): Promise<void> {
    if (!this.replyInput.trim() || !this.activeConversation || this.sendingReply) return;
    this.sendingReply = true;
    try {
      const { error } = await this.supabase.from('messages').insert([{
        sender_id: this.currentUserId,
        receiver_id: this.activeConversation.student.id,
        contenido: this.replyInput.trim(),
        is_read: false
      }]);
      if (error) {
        console.error('Error enviando respuesta:', error);
        alert('Error al enviar: ' + error.message);
      } else {
        this.replyInput = '';
        await this.openConversation(this.activeConversation);
      }
    } finally {
      this.sendingReply = false;
    }
  }
}