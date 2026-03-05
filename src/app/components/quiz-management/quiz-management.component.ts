import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { QuizService } from '../../services/quiz.service';
import { AuthService } from '../../services/auth.service';
import { Quiz, Question } from '../../models/quiz.model';

@Component({
  selector: 'app-quiz-management',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './quiz-management.component.html',
  styleUrls: ['./quiz-management.component.css']
})
export class QuizManagementComponent implements OnInit {
  quizzes: Quiz[] = [];
  editingQuiz: boolean = false;
  loading: boolean = false;
  successMessage: string = '';
  errorMessage: string = '';
  newQuiz: Partial<Quiz> = this.getEmptyQuiz();

  constructor(
    private quizService: QuizService,
    private authService: AuthService
  ) {}

  ngOnInit() { this.loadQuizzes(); }

  getEmptyQuiz(): Partial<Quiz> {
    return {
      title: '', description: '', questions: [],
      isEnabled: true, category: 'mathematics',
      difficulty: 'easy', timeLimit: 10, passingScore: 60,
      createdBy: this.authService?.getCurrentUser()?.email || 'admin'
    };
  }

  getEmptyQuestion(): Question {
    return {
      id: Date.now().toString(),
      text: '', options: ['', '', '', ''],
      correctAnswer: 0, explanation: '', points: 10
    };
  }

  loadQuizzes() {
    this.quizService.getQuizzes().subscribe({
      next: (q) => { this.quizzes = q; },
      error: (e) => { this.errorMessage = 'Error: ' + e.message; }
    });
  }

  addQuestion() {
    if (!this.newQuiz.questions) this.newQuiz.questions = [];
    this.newQuiz.questions.push(this.getEmptyQuestion());
  }

  removeQuestion(i: number) {
    this.newQuiz.questions?.splice(i, 1);
  }

  saveQuiz() {
    if (!this.newQuiz.questions || this.newQuiz.questions.length === 0) {
      this.errorMessage = 'Agrega al menos una pregunta';
      return;
    }
    this.loading = true;
    this.successMessage = '';
    this.errorMessage = '';
    const op = this.editingQuiz && this.newQuiz.id
      ? this.quizService.updateQuiz(this.newQuiz.id, this.newQuiz as Quiz)
      : this.quizService.createQuiz(this.newQuiz as Quiz);
    op.subscribe({
      next: () => {
        this.loading = false;
        this.successMessage = this.editingQuiz ? 'Actualizado!' : 'Creado!';
        this.resetForm();
        this.loadQuizzes();
        setTimeout(() => this.successMessage = '', 3000);
      },
      error: (e) => { this.loading = false; this.errorMessage = 'Error: ' + e.message; }
    });
  }

  editQuiz(quiz: Quiz) {
    this.editingQuiz = true;
    this.newQuiz = { ...quiz, questions: [...(quiz.questions || [])] };
    window.scrollTo(0, 0);
  }

  toggleQuiz(quiz: Quiz) {
    this.quizService.toggleQuizStatus(quiz.id).subscribe({
      next: () => this.loadQuizzes(),
      error: (e) => this.errorMessage = 'Error: ' + e.message
    });
  }

  deleteQuiz(id: string) {
    if (confirm('Eliminar este cuestionario?')) {
      this.quizService.deleteQuiz(id).subscribe({
        next: () => { this.successMessage = 'Eliminado'; this.loadQuizzes(); },
        error: (e) => this.errorMessage = 'Error: ' + e.message
      });
    }
  }

  resetForm() {
    this.editingQuiz = false;
    this.newQuiz = this.getEmptyQuiz();
  }
}