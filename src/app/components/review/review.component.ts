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
        ¡Ejercicios y Cuestionarios!
        <i class="fas fa-star text-yellow"></i>
      </h1>

      <div class="card-grid">
        <!-- Tarjeta de Gestión de Cuestionarios -->
        <div class="kid-card pending-card" *ngIf="isTeacher">
          <div class="kid-card-content">
            <i class="fas fa-pencil-alt card-icon"></i>
            <h3>¡Gestión de Cuestionarios!</h3>
            <p>Crea y administra cuestionarios para tus estudiantes</p>
            <div class="button-group">
              <a routerLink="/quiz-management" class="btn btn-kid">¡Crear Cuestionario!</a>
              <a routerLink="/course-management" class="btn btn-kid">¡Gestión de Cursos!</a>
            </div>
          </div>
        </div>

        <!-- Tarjeta de Cuestionarios Disponibles -->
        <div class="kid-card quiz-card" *ngIf="availableQuizzes.length > 0">
          <div class="kid-card-content">
            <i class="fas fa-question-circle card-icon"></i>
            <h3>¡Cuestionarios Disponibles!</h3>
            <p>Tienes {{availableQuizzes.length}} cuestionarios para practicar</p>
            <button class="btn btn-kid" (click)="showQuizzes()">¡Vamos a Practicar!</button>
          </div>
        </div>

        <!-- Mensaje cuando no hay cuestionarios -->
        <div class="kid-card quiz-card" *ngIf="availableQuizzes.length === 0 && !isTeacher">
          <div class="kid-card-content">
            <i class="fas fa-info-circle card-icon"></i>
            <h3>¡No hay cuestionarios disponibles!</h3>
            <p>Pronto tendrás nuevos cuestionarios para practicar</p>
          </div>
        </div>

        <div class="kid-card completed-card">
          <div class="kid-card-content">
            <i class="fas fa-trophy card-icon"></i>
            <h3>¡Mis Logros!</h3>
            <p>Mira todos los ejercicios que has completado</p>
            <button class="btn btn-kid">Ver Mis Logros</button>
          </div>
        </div>
      </div>

      <!-- Modal de Cuestionarios -->
      <div class="modal" *ngIf="showQuizModal">
        <div class="modal-content kid-card">
          <div class="kid-card-content">
            <h2>¡Cuestionarios Disponibles!</h2>
            
            <div class="quiz-list">
              <div *ngFor="let quiz of availableQuizzes" class="quiz-item kid-card">
                <div class="kid-card-content">
                  <div class="quiz-header">
                    <h3>{{quiz.title}}</h3>
                    <span class="difficulty-badge" [class]="quiz.difficulty">
                      {{quiz.difficulty | titlecase}}
                    </span>
                  </div>
                  
                  <p class="quiz-description">{{quiz.description}}</p>
                  
                  <div class="quiz-info">
                    <div class="info-item">
                      <i class="fas fa-clock"></i>
                      <span>{{quiz.timeLimit}} minutos</span>
                    </div>
                    <div class="info-item">
                      <i class="fas fa-star"></i>
                      <span>{{quiz.passingScore}}% para aprobar</span>
                    </div>
                    <div class="info-item">
                      <i class="fas fa-question-circle"></i>
                      <span>{{quiz.questions.length}} preguntas</span>
                    </div>
                    <div class="info-item">
                      <i class="fas fa-graduation-cap"></i>
                      <span>{{quiz.category | titlecase}}</span>
                    </div>
                  </div>

                  <div class="quiz-preview" *ngIf="quiz.questions.length > 0">
                    <h4>Ejemplo de Pregunta:</h4>
                    <div class="question-preview">
                      <p>{{quiz.questions[0].text}}</p>
                      <div class="options-preview">
                        <div *ngFor="let option of quiz.questions[0].options; let i = index" 
                             class="option-item">
                          <span class="option-letter">{{['A', 'B', 'C', 'D'][i]}}</span>
                          <span class="option-text">{{option}}</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <a [routerLink]="['/quiz', quiz.id]" class="btn btn-kid">
                    <i class="fas fa-play"></i> ¡Comenzar!
                  </a>
                </div>
              </div>
            </div>

            <button class="btn btn-kid btn-secondary" (click)="closeQuizModal()">
              Cerrar
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .button-group {
      display: flex;
      gap: 1rem;
      flex-wrap: wrap;
      justify-content: center;
    }

    .button-group .btn {
      flex: 1;
      min-width: 200px;
    }

    .modal {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0, 0, 0, 0.5);
      display: flex;
      justify-content: center;
      align-items: center;
      z-index: 1000;
    }

    .modal-content {
      max-width: 800px;
      width: 90%;
      max-height: 90vh;
      overflow-y: auto;
      margin: 2rem;
    }

    .quiz-list {
      display: grid;
      gap: 1rem;
      margin: 1rem 0;
    }

    .quiz-item {
      background: rgba(255, 255, 255, 0.1);
      padding: 1rem;
      border-radius: 10px;
    }

    .quiz-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1rem;
    }

    .difficulty-badge {
      padding: 0.5rem 1rem;
      border-radius: 20px;
      font-size: 0.9rem;
      font-weight: bold;
      color: white;
    }

    .difficulty-badge.easy {
      background-color: #40c057;
    }

    .difficulty-badge.medium {
      background-color: #fab005;
    }

    .difficulty-badge.hard {
      background-color: #ff6b6b;
    }

    .quiz-info {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 1rem;
      margin: 1rem 0;
      background: rgba(255, 255, 255, 0.1);
      padding: 1rem;
      border-radius: 10px;
    }

    .info-item {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      color: white;
      font-family: 'Comic Sans MS', cursive;
    }

    .quiz-preview {
      margin: 1rem 0;
      padding: 1rem;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 10px;
    }

    .options-preview {
      display: grid;
      gap: 0.5rem;
      margin-top: 1rem;
    }

    .option-item {
      display: flex;
      align-items: center;
      gap: 1rem;
      padding: 0.5rem;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 8px;
    }

    .option-letter {
      width: 30px;
      height: 30px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: white;
      color: #333;
      border-radius: 50%;
      font-weight: bold;
    }

    .option-text {
      color: white;
      font-family: 'Comic Sans MS', cursive;
    }

    @media (max-width: 768px) {
      .button-group {
        flex-direction: column;
      }

      .button-group .btn {
        width: 100%;
      }

      .quiz-info {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class ReviewComponent implements OnInit {
  availableQuizzes: Quiz[] = [];
  showQuizModal: boolean = false;
  isTeacher: boolean = false;
  isStudent: boolean = false;

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
    this.quizService.getQuizzes().subscribe(quizzes => {
      this.availableQuizzes = quizzes.filter(quiz => quiz.isEnabled);
    });
  }

  showQuizzes() {
    this.showQuizModal = true;
  }

  closeQuizModal() {
    this.showQuizModal = false;
  }
}