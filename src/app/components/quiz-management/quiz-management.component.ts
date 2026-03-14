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

  activeTab: 'list' | 'create' | 'assign' | 'results' | 'requests' | 'import' = 'list';
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

  // PDF Import
  selectedFile: File | null = null;
  importText = '';
  importQuestionCount = 10;
  importDifficulty = 'medium';
  importCategory = 'general';
  importing = false;
  generatedQuestions: Question[] = [];
  isDragOver = false;

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
    console.log('Guardando quiz:', this.newQuiz);
    
    if (!this.newQuiz.title || this.newQuiz.title.trim() === '') {
      this.errorMessage = 'El título es obligatorio';
      return;
    }

    if (!this.newQuiz.questions || this.newQuiz.questions.length === 0) {
      this.errorMessage = 'Agrega al menos una pregunta';
      return;
    }

    // Validar preguntas - permitir opciones vacías pero warning
    const questionsWithoutText = this.newQuiz.questions.filter(q => !q.text || q.text.trim() === '');
    if (questionsWithoutText.length > 0) {
      this.errorMessage = 'Todas las preguntas deben tener texto';
      return;
    }

    // Asegurar que cada pregunta tenga al menos 2 opciones
    this.newQuiz.questions.forEach(q => {
      if (!q.options || q.options.length < 2) {
        q.options = ['', '', '', ''];
      }
      // Llenar opciones vacías con texto placeholder
      q.options = q.options.map((opt, idx) => opt || `Opción ${idx + 1}`);
    });

    this.loading = true;
    this.successMessage = '';
    this.errorMessage = '';

    const quizData = {
      ...this.newQuiz,
      title: this.newQuiz.title.trim(),
      description: (this.newQuiz.description || '').trim()
    };

    const operation = this.editingQuiz && this.newQuiz.id
      ? this.quizService.updateQuiz(this.newQuiz.id, quizData as Quiz)
      : this.quizService.createQuiz(quizData as Quiz);

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
        this.errorMessage = 'Error: ' + (e.message || 'Error desconocido');
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
    this.selectedFile = null;
    this.importText = '';
    this.generatedQuestions = [];
    this.importing = false;
  }

  // =====================
  // PDF Import Methods
  // =====================
  onDragOver(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver = true;
  }

  onDragLeave(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver = false;
  }

  onDrop(event: DragEvent) {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver = false;
    
    const files = event.dataTransfer?.files;
    if (files && files.length > 0) {
      this.selectedFile = files[0];
    }
  }

  onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.selectedFile = input.files[0];
    }
  }

  removeFile() {
    this.selectedFile = null;
  }

  async generateFromPDF() {
    this.importing = true;
    this.generatedQuestions = [];
    
    try {
      // Parse the text content (from file or manual input)
      let textContent = this.importText;
      
      if (this.selectedFile) {
        // For now, we'll use the text input method
        // In a real app, you'd use a PDF parsing library
        this.showError('Por favor, copia y pega el contenido del PDF en el campo de texto');
        this.importing = false;
        return;
      }

      // Parse questions from text
      this.generatedQuestions = this.parseQuestions(textContent, this.importQuestionCount);
      
      if (this.generatedQuestions.length === 0) {
        this.showError('No se pudieron generar preguntas. Verifica el formato del texto.');
      } else {
        this.showSuccess(`✅ Se generaron ${this.generatedQuestions.length} preguntas`);
      }
    } catch (e) {
      this.showError('Error al procesar el contenido: ' + (e as Error).message);
    } finally {
      this.importing = false;
    }
  }

  parseQuestions(text: string, maxQuestions: number): Question[] {
    const questions: Question[] = [];
    if (!text || text.trim() === '') {
      return questions;
    }
    
    // Different split patterns to try
    let blocks = text.split(/\n\n+/).filter(b => b.trim());
    if (blocks.length === 1) {
      // Try splitting by numbered questions
      blocks = text.split(/\n?(?:\d+[\.\)]|¿)\s*/).filter(b => b.trim());
    }
    
    for (const block of blocks) {
      if (questions.length >= maxQuestions) break;
      
      const lines = block.split('\n').map(l => l.trim()).filter(l => l);
      if (lines.length < 2) continue; // Need at least question + options
      
      // Try to extract question and options
      let questionText = lines[0].replace(/^\d+[\.\)]\s*/, '').replace(/^¿/, '').trim();
      if (!questionText) continue;
      
      const options: string[] = [];
      let correctAnswer = 0;
      
      for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        // Match option patterns like A) ..., B) ..., a. ..., Opción 1:, etc.
        const optionMatch = line.match(/^([A-Za-d]|Opción)\s*[\.\)\:]?\s*(.+)$/);
        if (optionMatch) {
          options.push(optionMatch[2].trim());
        }
      }
      
      // Alternative: look for "Respuesta: X" line anywhere in the block
      const answerMatch = block.match(/respuesta\s*:\s*([A-Za-d])/i);
      if (answerMatch) {
        const answerLetter = answerMatch[1].toUpperCase();
        correctAnswer = options.length > 0 ? Math.min(answerLetter.charCodeAt(0) - 65, options.length - 1) : 0;
      }
      
      // Ensure we have at least 2 options
      if (options.length >= 2) {
        // Fill remaining slots to get 4 options
        while (options.length < 4) {
          options.push(`Opción ${options.length + 1}`);
        }
        
        questions.push({
          id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
          text: questionText,
          options: options.slice(0, 4),
          correctAnswer: correctAnswer,
          explanation: '',
          points: 10
        });
      }
    }
    
    return questions;
  }

  saveGeneratedQuiz() {
    if (this.generatedQuestions.length === 0) {
      this.showError('No hay preguntas para guardar');
      return;
    }
    
    this.newQuiz = {
      title: 'Cuestionario importado ' + new Date().toLocaleDateString(),
      description: 'Cuestionario generado automáticamente',
      questions: this.generatedQuestions,
      isEnabled: true,
      isVisible: true,
      category: this.importCategory,
      difficulty: this.importDifficulty as 'easy' | 'medium' | 'hard',
      timeLimit: Math.max(10, this.generatedQuestions.length),
      passingScore: 60,
      createdBy: this.authService.getCurrentUser()?.id || ''
    };
    
    this.activeTab = 'create';
    this.showSuccess('✅ Cuestionario cargado. Revisa y guarda.');
  }

  private showError(message: string) {
    this.errorMessage = message;
    setTimeout(() => this.errorMessage = '', 5000);
  }

  private showSuccess(message: string) {
    this.successMessage = message;
    setTimeout(() => this.successMessage = '', 5000);
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