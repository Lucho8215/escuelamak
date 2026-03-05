import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { QuizService } from '../../services/quiz.service';
import { Quiz } from '../../models/quiz.model';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-review',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="module-container">
      <a routerLink="/dashboard" class="btn btn-back">
        <i class="fas fa-arrow-left"></i> Volver al Panel
      </a>

      <h1>
        <i class="fas fa-star text-yellow"></i>
        Ejercicios y Cuestionarios
        <i class="fas fa-star text-yellow"></i>
      </h1>

      <div class="card-grid">

        <!-- Tarjeta para Profesor/Admin -->
        <div class="kid-card pending-card" *ngIf="isTeacher">
          <div class="kid-card-content">
            <i class="fas fa-pencil-alt card-icon"></i>
            <h3>Gestion de Cuestionarios</h3>
            <p>Crea y administra cuestionarios para tus estudiantes</p>
            <div class="button-group">
              <a routerLink="/quiz-management" class="btn btn-kid">
                <i class="fas fa-plus"></i> Crear Cuestionario
              </a>
              <a routerLink="/course-management" class="btn btn-kid">
                <i class="fas fa-book"></i> Gestion de Cursos
              </a>
            </div>
          </div>
        </div>

        <!-- Tarjeta cuestionarios disponibles -->
        <div class="kid-card quiz-card" *ngIf="availableQuizzes.length > 0">
          <div class="kid-card-content">
            <i class="fas fa-question-circle card-icon"></i>
            <h3>Cuestionarios Disponibles</h3>
            <p>Tienes {{availableQuizzes.length}} cuestionarios para practicar</p>
            <button class="btn btn-kid" (click)="showQuizzes()">
              <i class="fas fa-play"></i> Vamos a Practicar
            </button>
          </div>
        </div>

        <!-- Sin cuestionarios para alumno -->
        <div class="kid-card quiz-card"
             *ngIf="availableQuizzes.length === 0 && !isTeacher">
          <div class="kid-card-content">
            <i class="fas fa-info-circle card-icon"></i>
            <h3>Sin cuestionarios disponibles</h3>
            <p>Pronto tendras nuevos cuestionarios para practicar</p>
          </div>
        </div>

        <!-- Mis Logros -->
        <div class="kid-card completed-card">
          <div class="kid-card-content">
            <i class="fas fa-trophy card-icon"></i>
            <h3>Mis Logros</h3>
            <p>Mira todos los ejercicios que has completado</p>
            <button class="btn btn-kid" (click)="verLogros()">
              <i class="fas fa-medal"></i> Ver Mis Logros
            </button>
          </div>
        </div>

      </div>

      <!-- Modal lista de quizzes -->
      <div class="modal" *ngIf="showQuizModal">
        <div class="modal-content kid-card">
          <div class="kid-card-content">
            <h2>
              <i class="fas fa-list"></i>
              Cuestionarios Disponibles
            </h2>

            <div *ngIf="cargando" style="text-align:center; padding:2rem;">
              <i class="fas fa-spinner fa-spin" style="font-size:2rem; color:white;"></i>
              <p style="color:white;">Cargando cuestionarios...</p>
            </div>

            <div class="quiz-list" *ngIf="!cargando">
              <div *ngFor="let quiz of availableQuizzes"
                   class="quiz-item kid-card">
                <div class="kid-card-content">

                  <div class="quiz-header">
                    <h3>{{quiz.title}}</h3>
                    <span class="difficulty-badge" [class]="quiz.difficulty">
                      {{quiz.difficulty === 'easy' ? 'Facil' :
                        quiz.difficulty === 'medium' ? 'Medio' : 'Dificil'}}
                    </span>
                  </div>

                  <p class="quiz-description">{{quiz.description}}</p>

                  <div class="quiz-info">
                    <div class="info-item">
                      <i class="fas fa-clock"></i>
                      <span>{{quiz.timeLimit}} min</span>
                    </div>
                    <div class="info-item">
                      <i class="fas fa-star"></i>
                      <span>Aprobar: {{quiz.passingScore}}%</span>
                    </div>
                    <div class="info-item">
                      <i class="fas fa-question-circle"></i>
                      <span>{{(quiz.questions ? quiz.questions.length : 0)}} preguntas</span>
                    </div>
                  </div>

                  <!-- Vista previa primera pregunta -->
                  <div class="quiz-preview"
                       *ngIf="quiz.questions && quiz.questions.length > 0">
                    <h4>Vista previa:</h4>
                    <p>{{quiz.questions[0].text}}</p>
                    <div class="options-preview">
                      <div *ngFor="let option of quiz.questions[0].options; let i = index"
                           class="option-item">
                        <span class="option-letter">{{['A','B','C','D'][i]}}</span>
                        <span class="option-text">{{option}}</span>
                      </div>
                    </div>
                  </div>

                  <!-- Sin preguntas -->
                  <div *ngIf="!quiz.questions || quiz.questions.length === 0"
                       style="text-align:center; color:#ffeb3b; padding:0.5rem;">
                    <i class="fas fa-exclamation-triangle"></i>
                    Sin preguntas todavia
                  </div>

                  <a [routerLink]="['/quiz', quiz.id]"
                     class="btn btn-kid"
                     style="display:block; text-align:center; margin-top:1rem;"
                     [class.disabled]="!quiz.questions || quiz.questions.length === 0">
                    <i class="fas fa-play"></i> Comenzar
                  </a>

                </div>
              </div>
            </div>

            <button class="btn btn-kid btn-secondary"
                    (click)="closeQuizModal()"
                    style="margin-top:1rem; width:100%;">
              <i class="fas fa-times"></i> Cerrar
            </button>
          </div>
        </div>
      </div>

      <!-- Modal Mis Logros -->
      <div class="modal" *ngIf="showLogrosModal">
        <div class="modal-content kid-card">
          <div class="kid-card-content">
            <h2>
              <i class="fas fa-trophy text-yellow"></i>
              Mis Logros
            </h2>

            <div *ngIf="logros.length === 0"
                 style="text-align:center; padding:2rem; color:white;">
              <i class="fas fa-inbox" style="font-size:3rem; color:#ccc;"></i>
              <p>Aun no has completado ningun cuestionario</p>
              <p>Practica y aqui veras tus resultados</p>
            </div>

            <div *ngFor="let logro of logros" class="logro-item">
              <div class="logro-header">
                <span>{{logro.quizzes?.title || 'Quiz'}}</span>
                <span class="score-badge"
                      [style.background]="logro.passed ? '#40c057' : '#ff6b6b'">
                  {{logro.score}}%
                </span>
              </div>
              <div class="logro-details">
                <span>
                  <i class="fas fa-calendar"></i>
                  {{logro.completed_at | date:'dd/MM/yyyy HH:mm'}}
                </span>
                <span [style.color]="logro.passed ? '#40c057' : '#ff6b6b'">
                  <i class="fas" [class.fa-check]="logro.passed"
                     [class.fa-times]="!logro.passed"></i>
                  {{logro.passed ? 'Aprobado' : 'No aprobado'}}
                </span>
              </div>
            </div>

            <button class="btn btn-kid btn-secondary"
                    (click)="showLogrosModal = false"
                    style="margin-top:1rem; width:100%;">
              Cerrar
            </button>
          </div>
        </div>
      </div>

    </div>
  `,
  styles: [`
    .button-group {
      display: flex; gap: 1rem; flex-wrap: wrap; justify-content: center;
    }
    .modal {
      position: fixed; top: 0; left: 0; width: 100%; height: 100%;
      background: rgba(0,0,0,0.5); display: flex;
      justify-content: center; align-items: center; z-index: 1000;
    }
    .modal-content {
      max-width: 800px; width: 90%; max-height: 90vh;
      overflow-y: auto; margin: 2rem;
    }
    .quiz-list { display: grid; gap: 1rem; margin: 1rem 0; }
    .quiz-item { background: rgba(255,255,255,0.1); padding: 1rem; border-radius: 10px; }
    .quiz-header {
      display: flex; justify-content: space-between;
      align-items: center; margin-bottom: 1rem;
    }
    .quiz-header h3 { color: white; font-family: 'Comic Sans MS', cursive; margin: 0; }
    .difficulty-badge {
      padding: 0.3rem 0.8rem; border-radius: 20px;
      font-size: 0.85rem; font-weight: bold; color: white;
    }
    .difficulty-badge.easy { background: #40c057; }
    .difficulty-badge.medium { background: #fab005; }
    .difficulty-badge.hard { background: #ff6b6b; }
    .quiz-description { color: white; font-family: 'Comic Sans MS', cursive; }
    .quiz-info {
      display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
      gap: 0.5rem; margin: 1rem 0;
      background: rgba(255,255,255,0.1); padding: 0.75rem; border-radius: 10px;
    }
    .info-item {
      display: flex; align-items: center; gap: 0.5rem;
      color: white; font-family: 'Comic Sans MS', cursive; font-size: 0.9rem;
    }
    .quiz-preview {
      margin: 1rem 0; padding: 1rem;
      background: rgba(255,255,255,0.1); border-radius: 10px;
    }
    .quiz-preview h4 { color: #ffeb3b; font-family: 'Comic Sans MS', cursive; margin: 0 0 0.5rem; }
    .quiz-preview p { color: white; font-family: 'Comic Sans MS', cursive; }
    .options-preview { display: grid; gap: 0.4rem; margin-top: 0.5rem; }
    .option-item {
      display: flex; align-items: center; gap: 0.75rem;
      padding: 0.4rem; background: rgba(255,255,255,0.1); border-radius: 8px;
    }
    .option-letter {
      width: 28px; height: 28px; display: flex; align-items: center;
      justify-content: center; background: white; color: #333;
      border-radius: 50%; font-weight: bold; font-size: 0.85rem; flex-shrink: 0;
    }
    .option-text { color: white; font-family: 'Comic Sans MS', cursive; font-size: 0.9rem; }
    .logro-item {
      background: rgba(255,255,255,0.1); padding: 1rem;
      border-radius: 10px; margin-bottom: 0.75rem;
    }
    .logro-header {
      display: flex; justify-content: space-between;
      align-items: center; color: white;
      font-family: 'Comic Sans MS', cursive; font-weight: bold;
    }
    .score-badge {
      padding: 0.3rem 0.8rem; border-radius: 20px;
      color: white; font-weight: bold; font-size: 1rem;
    }
    .logro-details {
      display: flex; gap: 1rem; margin-top: 0.5rem;
      color: rgba(255,255,255,0.8); font-family: 'Comic Sans MS', cursive; font-size: 0.85rem;
    }
    .disabled { opacity: 0.5; pointer-events: none; }
  `]
})
export class ReviewComponent implements OnInit {
  availableQuizzes: Quiz[] = [];
  showQuizModal: boolean = false;
  showLogrosModal: boolean = false;
  isTeacher: boolean = false;
  isStudent: boolean = false;
  cargando: boolean = false;
  logros: any[] = [];

  constructor(
    private quizService: QuizService,
    private authService: AuthService
  ) {}

  ngOnInit() {
    this.loadQuizzes();
    this.isTeacher = this.authService.hasPermission('create_courses');
    this.isStudent = this.authService.hasPermission('submit_exercises');
  }

  loadQuizzes() {
    this.cargando = true;
    this.quizService.getQuizzes().subscribe({
      next: (quizzes) => {
        this.availableQuizzes = quizzes.filter(q => q.isEnabled);
        this.cargando = false;
      },
      error: () => { this.cargando = false; }
    });
  }

  showQuizzes() {
    this.showQuizModal = true;
  }

  closeQuizModal() {
    this.showQuizModal = false;
  }

  verLogros() {
    const user = this.authService.getCurrentUser();
    if (!user) return;
    this.showLogrosModal = true;
    this.quizService.getStudentAttempts(user.id).subscribe({
      next: (data) => { this.logros = data; },
      error: () => { this.logros = []; }
    });
  }
}
