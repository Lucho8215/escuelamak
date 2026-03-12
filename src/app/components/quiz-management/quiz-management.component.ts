import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { QuizService } from '../../services/quiz.service';
import { AuthService } from '../../services/auth.service';
import { Quiz, Question, QuizAssignment, QuizResourceRequest } from '../../models/quiz.model';
import { forkJoin } from 'rxjs';

@Component({
  selector: 'app-quiz-management',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './quiz-management.component.html',
  styleUrls: ['./quiz-management.component.css']
})
export class QuizManagementComponent implements OnInit {
  quizzes: Quiz[] = [];
  students: any[] = [];
  assignments: QuizAssignment[] = [];
  selectedQuiz: Quiz | null = null;

  activeTab: 'list' | 'create' | 'assign' | 'results' | 'requests' = 'list';
  editingQuiz = false;
  loading = false;
  loadingAssignments = false;
  successMessage = '';
  errorMessage = '';

  newQuiz: Partial<Quiz> = this.getEmptyQuiz();

  selectedStudentIds: string[] = [];
  dueDate = '';

  // Resource requests
  resourceRequests: QuizResourceRequest[] = [];
  loadingRequests = false;
  selectedRequest: QuizResourceRequest | null = null;
  requestResponse = '';

  searchTerm = '';
  filterCategory = '';
  filterDifficulty = '';

  constructor(
    private quizService: QuizService,
    private authService: AuthService
  ) {}

  ngOnInit() {
    this.loadQuizzes();
    this.loadStudents();
  }

  getEmptyQuiz(): Partial<Quiz> {
    return {
      title: '',
      description: '',
      questions: [],
      isEnabled: true,
      isVisible: true,
      category: 'general',
      difficulty: 'easy',
      timeLimit: 10,
      passingScore: 60,
      createdBy: this.authService.getCurrentUser()?.id || ''
    };
  }

  getEmptyQuestion(): Question {
    return {
      id: Date.now().toString(),
      text: '',
      options: ['', '', '', ''],
      correctAnswer: 0,
      explanation: '',
      points: 10
    };
  }

  loadQuizzes() {
    this.loading = true;
    this.quizService.getQuizzes().subscribe({
      next: (quizzes) => {
        this.quizzes = quizzes;
        this.loading = false;
      },
      error: (e) => {
        this.errorMessage = 'Error: ' + e.message;
        this.loading = false;
      }
    });
  }

  loadStudents() {
    this.quizService.getStudents().subscribe({
      next: (students) => this.students = students,
      error: (e) => {
        console.error('Error loading students:', e);
        this.errorMessage = 'Error cargando estudiantes';
      }
    });
  }

  loadAssignments(quiz: Quiz) {
    this.loadingAssignments = true;
    this.selectedQuiz = quiz;

    this.quizService.getQuizAssignments(quiz.id).subscribe({
      next: (assignments) => {
        this.assignments = assignments;
        this.loadingAssignments = false;
      },
      error: (e) => {
        this.errorMessage = 'Error: ' + e.message;
        this.loadingAssignments = false;
      }
    });
  }

  addQuestion() {
    if (!this.newQuiz.questions) {
      this.newQuiz.questions = [];
    }
    this.newQuiz.questions.push(this.getEmptyQuestion());
  }

  removeQuestion(i: number) {
    this.newQuiz.questions?.splice(i, 1);
  }

  addOption(question: Question) {
    if (question.options) {
      question.options.push('');
    }
  }

  removeOption(question: Question, j: number) {
    if (question.options && question.options.length > 2) {
      question.options.splice(j, 1);
      if (question.correctAnswer >= j) {
        question.correctAnswer = Math.max(0, question.correctAnswer - 1);
      }
    }
  }

  saveQuiz() {
    if (!this.newQuiz.questions || this.newQuiz.questions.length === 0) {
      this.errorMessage = 'Agrega al menos una pregunta';
      return;
    }

    const invalidQuestions = this.newQuiz.questions.filter(q =>
      !q.text || !q.options || q.options.length < 2 || q.options.some(o => !o)
    );

    if (invalidQuestions.length > 0) {
      this.errorMessage = 'Todas las preguntas deben tener texto y al menos 2 opciones válidas';
      return;
    }

    this.loading = true;
    this.successMessage = '';
    this.errorMessage = '';

    const operation = this.editingQuiz && this.newQuiz.id
      ? this.quizService.updateQuiz(this.newQuiz.id, this.newQuiz as Quiz)
      : this.quizService.createQuiz(this.newQuiz as Quiz);

    operation.subscribe({
      next: () => {
        this.loading = false;
        this.successMessage = this.editingQuiz ? '¡Cuestionario actualizado!' : '¡Cuestionario creado!';
        this.resetForm();
        this.loadQuizzes();
        this.activeTab = 'list';
        setTimeout(() => this.successMessage = '', 3000);
      },
      error: (e) => {
        this.loading = false;
        this.errorMessage = 'Error: ' + e.message;
        console.error('Error guardando quiz:', e);
      }
    });
  }

  editQuiz(quiz: Quiz) {
    this.editingQuiz = true;
    this.newQuiz = {
      ...quiz,
      questions: quiz.questions?.map(q => ({
        ...q,
        options: [...q.options]
      })) || []
    };
    this.activeTab = 'create';
    window.scrollTo(0, 0);
  }

  toggleQuiz(quiz: Quiz) {
    this.quizService.toggleQuizStatus(quiz.id).subscribe({
      next: () => this.loadQuizzes(),
      error: (e) => {
        this.errorMessage = 'Error: ' + e.message;
        console.error('Error cambiando estado del quiz:', e);
      }
    });
  }

  deleteQuiz(id: string) {
    if (confirm('¿Eliminar este cuestionario? Esta acción no se puede deshacer.')) {
      this.quizService.deleteQuiz(id).subscribe({
        next: () => {
          this.successMessage = 'Cuestionario eliminado';
          this.loadQuizzes();
          setTimeout(() => this.successMessage = '', 3000);
        },
        error: (e) => {
          this.errorMessage = 'Error: ' + e.message;
          console.error('Error eliminando quiz:', e);
        }
      });
    }
  }

  resetForm() {
    this.editingQuiz = false;
    this.newQuiz = this.getEmptyQuiz();
  }

  openAssignTab(quiz: Quiz) {
    this.selectedQuiz = quiz;
    this.selectedStudentIds = [];
    this.dueDate = '';
    this.loadAssignments(quiz);
    this.activeTab = 'assign';
  }

  toggleStudentSelection(studentId: string) {
    const index = this.selectedStudentIds.indexOf(studentId);
    if (index > -1) {
      this.selectedStudentIds.splice(index, 1);
    } else {
      this.selectedStudentIds.push(studentId);
    }
  }

  selectAllStudents() {
    if (this.selectedStudentIds.length === this.students.length) {
      this.selectedStudentIds = [];
    } else {
      this.selectedStudentIds = this.students.map(s => s.id);
    }
  }

assignQuiz() {
  if (!this.selectedQuiz || this.selectedStudentIds.length === 0) {
    this.errorMessage = 'Selecciona al menos un estudiante';
    return;
  }

  const currentUser = this.authService.getCurrentUser();

  if (!currentUser?.id) {
    this.errorMessage = 'No se pudo identificar el usuario autenticado';
    return;
  }

  this.loading = true;
  this.errorMessage = '';
  this.successMessage = '';

  const dueDateObj = this.dueDate ? new Date(this.dueDate) : undefined;
  const assignedBy = currentUser.id;

  const requests = this.selectedStudentIds.map((studentId) =>
    this.quizService.assignQuizToStudent(
      this.selectedQuiz!.id,
      studentId,
      assignedBy,
      dueDateObj
    )
  );

  forkJoin(requests).subscribe({
    next: () => {
      this.loading = false;
      this.successMessage = `¡Quiz asignado a ${this.selectedStudentIds.length} estudiante(s)!`;
      this.selectedStudentIds = [];
      this.loadAssignments(this.selectedQuiz!);
      setTimeout(() => this.successMessage = '', 3000);
    },
    error: (e: any) => {
      this.loading = false;
      this.errorMessage = 'Error: ' + (e?.message || 'No se pudo asignar el cuestionario');
      console.error('Error asignando quiz:', e);
    }
  });
}

  removeAssignment(assignmentId: string) {
    if (confirm('¿Eliminar esta asignación?')) {
      this.quizService.removeQuizAssignment(assignmentId).subscribe({
        next: () => {
          this.successMessage = 'Asignación eliminada';
          if (this.selectedQuiz) {
            this.loadAssignments(this.selectedQuiz);
          }
          setTimeout(() => this.successMessage = '', 3000);
        },
        error: (e) => {
          this.errorMessage = 'Error: ' + e.message;
          console.error('Error eliminando asignación:', e);
        }
      });
    }
  }

  get filteredQuizzes(): Quiz[] {
    return this.quizzes.filter(quiz => {
      const matchesSearch = !this.searchTerm ||
        quiz.title.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        quiz.description.toLowerCase().includes(this.searchTerm.toLowerCase());

      const matchesCategory = !this.filterCategory || quiz.category === this.filterCategory;
      const matchesDifficulty = !this.filterDifficulty || quiz.difficulty === this.filterDifficulty;

      return matchesSearch && matchesCategory && matchesDifficulty;
    });
  }

  get categories(): string[] {
    return [...new Set(this.quizzes.map(q => q.category).filter(c => c))];
  }

  getDifficultyClass(difficulty: string): string {
    const classes: Record<string, string> = {
      easy: 'difficulty-easy',
      medium: 'difficulty-medium',
      hard: 'difficulty-hard'
    };
    return classes[difficulty] || '';
  }

  formatDate(date: Date | string | undefined): string {
    if (!date) return 'Sin fecha';
    return new Date(date).toLocaleDateString('es-CO', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    });
  }

  getStatusIcon(assignment: QuizAssignment): string {
    if (assignment.isCompleted) return 'fa-check-circle';
    if (assignment.bestScore !== undefined) return 'fa-clock';
    return 'fa-circle';
  }

  getStatusClass(assignment: QuizAssignment): string {
    if (assignment.isCompleted) return 'status-completed';
    if (assignment.bestScore !== undefined) return 'status-in-progress';
    return 'status-pending';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PARA SOLICITUDES DE RECURSOS
  // ═══════════════════════════════════════════════════════════════════════════

  /**
   * Abre la pestaña de solicitudes de recursos
   */
  openRequestsTab() {
    this.activeTab = 'requests';
    this.loadResourceRequests();
  }

  /**
   * Carga las solicitudes de recursos
   */
  loadResourceRequests() {
    this.loadingRequests = true;
    this.quizService.getAllResourceRequests().subscribe({
      next: (requests) => {
        this.resourceRequests = requests;
        this.loadingRequests = false;
      },
      error: (e) => {
        this.errorMessage = 'Error cargando solicitudes: ' + e.message;
        this.loadingRequests = false;
      }
    });
  }

  /**
   * Abre el modal para responder una solicitud
   */
  openRespondRequestModal(request: QuizResourceRequest) {
    this.selectedRequest = request;
    this.requestResponse = request.response || '';
  }

  /**
   * Cierra el modal de respuesta
   */
  closeRequestModal() {
    this.selectedRequest = null;
    this.requestResponse = '';
  }

  /**
   * Aprueba una solicitud
   */
  approveRequest() {
    if (!this.selectedRequest) return;
    
    const currentUser = this.authService.getCurrentUser();
    if (!currentUser?.id) {
      this.errorMessage = 'No se pudo identificar el usuario';
      return;
    }

    this.quizService.respondToResourceRequest(
      this.selectedRequest.id,
      this.requestResponse,
      'approved',
      currentUser.id
    ).subscribe({
      next: () => {
        this.successMessage = 'Solicitud aprobada';
        this.closeRequestModal();
        this.loadResourceRequests();
        setTimeout(() => this.successMessage = '', 3000);
      },
      error: (e) => {
        this.errorMessage = 'Error: ' + e.message;
      }
    });
  }

  /**
   * Rechaza una solicitud
   */
  rejectRequest() {
    if (!this.selectedRequest) return;
    
    const currentUser = this.authService.getCurrentUser();
    if (!currentUser?.id) {
      this.errorMessage = 'No se pudo identificar el usuario';
      return;
    }

    this.quizService.respondToResourceRequest(
      this.selectedRequest.id,
      this.requestResponse,
      'rejected',
      currentUser.id
    ).subscribe({
      next: () => {
        this.successMessage = 'Solicitud rechazada';
        this.closeRequestModal();
        this.loadResourceRequests();
        setTimeout(() => this.successMessage = '', 3000);
      },
      error: (e) => {
        this.errorMessage = 'Error: ' + e.message;
      }
    });
  }

  /**
   * Marca una solicitud como completada
   */
  completeRequest() {
    if (!this.selectedRequest) return;
    
    const currentUser = this.authService.getCurrentUser();
    if (!currentUser?.id) {
      this.errorMessage = 'No se pudo identificar el usuario';
      return;
    }

    this.quizService.respondToResourceRequest(
      this.selectedRequest.id,
      this.requestResponse,
      'completed',
      currentUser.id
    ).subscribe({
      next: () => {
        this.successMessage = 'Solicitud marcada como completada';
        this.closeRequestModal();
        this.loadResourceRequests();
        setTimeout(() => this.successMessage = '', 3000);
      },
      error: (e) => {
        this.errorMessage = 'Error: ' + e.message;
      }
    });
  }

  /**
   * Obtiene el tipo de solicitud en texto legible
   */
  getRequestTypeLabel(type: string): string {
    const labels: Record<string, string> = {
      'explanation': 'Explicación adicional',
      'material': 'Material de estudio',
      'clarification': 'Aclaración de pregunta',
      'technical': 'Problema técnico',
      'other': 'Otro'
    };
    return labels[type] || type;
  }

  /**
   * Obtiene la clase CSS para el estado de la solicitud
   */
  getRequestStatusClass(status: string): string {
    const classes: Record<string, string> = {
      'pending': 'status-pending',
      'approved': 'status-approved',
      'rejected': 'status-rejected',
      'completed': 'status-completed'
    };
    return classes[status] || '';
  }

  /**
   * Obtiene el icono para el tipo de solicitud
   */
  getRequestTypeIcon(type: string): string {
    const icons: Record<string, string> = {
      'explanation': 'fa-lightbulb',
      'material': 'fa-book',
      'clarification': 'fa-question-circle',
      'technical': 'fa-tools',
      'other': 'fa-comment'
    };
    return icons[type] || 'fa-comment';
  }
}