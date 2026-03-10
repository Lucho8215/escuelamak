import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { QuizService } from '../../services/quiz.service';
import { AuthService } from '../../services/auth.service';
import { Quiz, Question, QuizAssignment } from '../../models/quiz.model';

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
  
  // UI States
  activeTab: 'list' | 'create' | 'assign' | 'results' = 'list';
  editingQuiz: boolean = false;
  loading: boolean = false;
  loadingAssignments: boolean = false;
  successMessage: string = '';
  errorMessage: string = '';
  
  // Form
  newQuiz: Partial<Quiz> = this.getEmptyQuiz();
  
  // Assignment
  selectedStudentIds: string[] = [];
  dueDate: string = '';
  
  // Search and filter
  searchTerm: string = '';
  filterCategory: string = '';
  filterDifficulty: string = '';

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
      createdBy: this.authService.getCurrentUser()?.email || 'admin'
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
      error: (e) => console.error('Error loading students:', e)
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

  // ─── CRUD Operations ───────────────────────────────────────────────────
  addQuestion() {
    if (!this.newQuiz.questions) this.newQuiz.questions = [];
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
      // Adjust correct answer if needed
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

    // Validate questions
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
      error: (e) => this.errorMessage = 'Error: ' + e.message
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
        error: (e) => this.errorMessage = 'Error: ' + e.message
      });
    }
  }

  resetForm() {
    this.editingQuiz = false;
    this.newQuiz = this.getEmptyQuiz();
  }

  // ─── Assignment Operations ─────────────────────────────────────────────
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

    this.loading = true;
    const dueDateObj = this.dueDate ? new Date(this.dueDate) : undefined;
    const assignedBy = this.authService.getCurrentUser()?.email || 'admin';

    this.quizService.assignQuizToStudents(
      this.selectedQuiz.id,
      this.selectedStudentIds,
      assignedBy,
      dueDateObj
    ).subscribe({
      next: () => {
        this.loading = false;
        this.successMessage = `¡Quiz asignado a ${this.selectedStudentIds.length} estudiante(s)!`;
        this.selectedStudentIds = [];
        this.loadAssignments(this.selectedQuiz!);
        setTimeout(() => this.successMessage = '', 3000);
      },
      error: (e) => {
        this.loading = false;
        this.errorMessage = 'Error: ' + e.message;
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
        error: (e) => this.errorMessage = 'Error: ' + e.message
      });
    }
  }

  // ─── Filtering ─────────────────────────────────────────────────────────
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

  // ─── Utility ──────────────────────────────────────────────────────────
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
}
