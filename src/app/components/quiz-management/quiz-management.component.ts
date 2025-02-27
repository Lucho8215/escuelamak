import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { QuizService } from '../../services/quiz.service';
import { Quiz, Question } from '../../models/quiz.model';

@Component({
  selector: 'app-quiz-management',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="module-container">
      <a routerLink="/dashboard" class="btn btn-back">
        <i class="fas fa-arrow-left"></i> Volver al Panel
      </a>

      <h1>
        <i class="fas fa-question-circle text-purple"></i>
        ¡Gestión de Cuestionarios!
        <i class="fas fa-question-circle text-purple"></i>
      </h1>

      <!-- Formulario de Cuestionario -->
      <div class="kid-card">
        <div class="kid-card-content">
          <h2>{{ editingQuiz ? '¡Editar Cuestionario!' : '¡Crear Cuestionario!' }}</h2>
          
          <form (ngSubmit)="saveQuiz()" #quizForm="ngForm">
            <div class="form-group">
              <label for="title">Título del Cuestionario</label>
              <input
                type="text"
                id="title"
                name="title"
                [(ngModel)]="newQuiz.title"
                required
                class="kid-input"
                placeholder="Ej: ¡Sumas Divertidas!"
              >
            </div>

            <div class="form-group">
              <label for="description">Descripción</label>
              <textarea
                id="description"
                name="description"
                [(ngModel)]="newQuiz.description"
                required
                class="kid-input"
                rows="3"
                placeholder="Describe el cuestionario..."
              ></textarea>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label for="category">Categoría</label>
                <select
                  id="category"
                  name="category"
                  [(ngModel)]="newQuiz.category"
                  required
                  class="kid-input"
                >
                  <option value="mathematics">Matemáticas</option>
                  <option value="logic">Lógica</option>
                  <option value="geometry">Geometría</option>
                </select>
              </div>

              <div class="form-group">
                <label for="difficulty">Dificultad</label>
                <select
                  id="difficulty"
                  name="difficulty"
                  [(ngModel)]="newQuiz.difficulty"
                  required
                  class="kid-input"
                >
                  <option value="easy">Fácil</option>
                  <option value="medium">Medio</option>
                  <option value="hard">Difícil</option>
                </select>
              </div>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label for="timeLimit">Tiempo Límite (minutos)</label>
                <input
                  type="number"
                  id="timeLimit"
                  name="timeLimit"
                  [(ngModel)]="newQuiz.timeLimit"
                  class="kid-input"
                  min="1"
                >
              </div>

              <div class="form-group">
                <label for="passingScore">Puntaje para Aprobar (%)</label>
                <input
                  type="number"
                  id="passingScore"
                  name="passingScore"
                  [(ngModel)]="newQuiz.passingScore"
                  required
                  class="kid-input"
                  min="0"
                  max="100"
                >
              </div>
            </div>

            <!-- Sección de Preguntas -->
            <div class="questions-section">
              <h3>Preguntas</h3>
              
              <div class="question-list">
                <div *ngFor="let question of newQuiz.questions; let i = index" class="question-item kid-card">
                  <div class="kid-card-content">
                    <div class="form-group">
                      <label>Pregunta {{i + 1}}</label>
                      <input
                        type="text"
                        [(ngModel)]="question.text"
                        [name]="'question-' + i"
                        required
                        class="kid-input"
                        placeholder="Escribe la pregunta..."
                      >
                    </div>

                    <div class="options-list">
                      <div *ngFor="let option of question.options; let j = index" class="option-item">
                        <input
                          type="text"
                          [(ngModel)]="question.options[j]"
                          [name]="'question-' + i + '-option-' + j"
                          required
                          class="kid-input"
                          placeholder="Opción {{j + 1}}"
                        >
                        <input
                          type="radio"
                          [name]="'correct-' + i"
                          [value]="j"
                          [(ngModel)]="question.correctAnswer"
                          required
                        >
                      </div>
                    </div>

                    <div class="form-group">
                      <label>Explicación (opcional)</label>
                      <textarea
                        [(ngModel)]="question.explanation"
                        [name]="'explanation-' + i"
                        class="kid-input"
                        rows="2"
                        placeholder="Explica la respuesta correcta..."
                      ></textarea>
                    </div>

                    <div class="form-group">
                      <label>Puntos</label>
                      <input
                        type="number"
                        [(ngModel)]="question.points"
                        [name]="'points-' + i"
                        required
                        class="kid-input"
                        min="1"
                      >
                    </div>

                    <button type="button" class="btn btn-kid btn-danger" (click)="removeQuestion(i)">
                      <i class="fas fa-trash"></i> Eliminar Pregunta
                    </button>
                  </div>
                </div>
              </div>

              <button type="button" class="btn btn-kid" (click)="addQuestion()">
                <i class="fas fa-plus"></i> Agregar Pregunta
              </button>
            </div>

            <div class="button-group">
              <button type="submit" class="btn btn-kid" [disabled]="!quizForm.form.valid">
                {{ editingQuiz ? '¡Guardar Cambios!' : '¡Crear Cuestionario!' }}
              </button>
              <button type="button" class="btn btn-kid btn-secondary" (click)="resetForm()">
                Cancelar
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- Lista de Cuestionarios -->
      <div class="quiz-list">
        <div *ngFor="let quiz of quizzes" class="kid-card">
          <div class="kid-card-content">
            <h3>{{quiz.title}}</h3>
            <p>{{quiz.description}}</p>
            
            <div class="quiz-details">
              <p><strong>Categoría:</strong> {{quiz.category}}</p>
              <p><strong>Dificultad:</strong> {{quiz.difficulty}}</p>
              <p><strong>Preguntas:</strong> {{quiz.questions.length}}</p>
              <p><strong>Estado:</strong> {{quiz.isEnabled ? 'Habilitado' : 'Deshabilitado'}}</p>
            </div>

            <div class="button-group">
              <button class="btn btn-kid" (click)="editQuiz(quiz)">
                <i class="fas fa-edit"></i> Editar
              </button>
              <button class="btn btn-kid" (click)="toggleQuiz(quiz)">
                <i class="fas" [class.fa-eye]="!quiz.isEnabled" [class.fa-eye-slash]="quiz.isEnabled"></i>
                {{quiz.isEnabled ? 'Deshabilitar' : 'Habilitar'}}
              </button>
              <button class="btn btn-kid btn-danger" (click)="deleteQuiz(quiz.id)">
                <i class="fas fa-trash"></i> Eliminar
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .form-row {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem;
    }

    .questions-section {
      margin: 2rem 0;
    }

    .question-list {
      display: grid;
      gap: 1rem;
      margin: 1rem 0;
    }

    .question-item {
      background: rgba(255, 255, 255, 0.1);
      padding: 1rem;
      border-radius: 10px;
    }

    .options-list {
      display: grid;
      gap: 0.5rem;
      margin: 1rem 0;
    }

    .option-item {
      display: flex;
      align-items: center;
      gap: 1rem;
    }

    .option-item input[type="radio"] {
      width: 20px;
      height: 20px;
      cursor: pointer;
    }

    .quiz-details {
      margin: 1rem 0;
      color: white;
      font-family: 'Comic Sans MS', cursive;
    }

    .quiz-details p {
      margin: 0.5rem 0;
    }

    .button-group {
      display: flex;
      gap: 1rem;
      margin-top: 1rem;
      flex-wrap: wrap;
    }

    .btn-danger {
      background-color: #ff6b6b !important;
    }

    .btn-danger:hover {
      background-color: #ff5252 !important;
    }

    .quiz-list {
      margin-top: 2rem;
      display: grid;
      gap: 1rem;
    }

    h3 {
      color: white;
      font-family: 'Comic Sans MS', cursive;
      margin-bottom: 1rem;
    }
  `]
})
export class QuizManagementComponent implements OnInit {
  quizzes: Quiz[] = [];
  editingQuiz: boolean = false;
  newQuiz: Partial<Quiz> = this.getEmptyQuiz();

  constructor(private quizService: QuizService) {}

  ngOnInit() {
    this.loadQuizzes();
  }

  private getEmptyQuiz(): Partial<Quiz> {
    return {
      title: '',
      description: '',
      questions: [],
      isEnabled: true,
      category: 'mathematics',
      difficulty: 'easy',
      timeLimit: 10,
      passingScore: 60
    };
  }

  private getEmptyQuestion(): Question {
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
    this.quizService.getQuizzes().subscribe(quizzes => {
      this.quizzes = quizzes;
    });
  }

  addQuestion() {
    if (!this.newQuiz.questions) {
      this.newQuiz.questions = [];
    }
    this.newQuiz.questions.push(this.getEmptyQuestion());
  }

  removeQuestion(index: number) {
    if (this.newQuiz.questions) {
      this.newQuiz.questions.splice(index, 1);
    }
  }

  saveQuiz() {
    if (this.editingQuiz && this.newQuiz.id) {
      this.quizService.updateQuiz(this.newQuiz.id, this.newQuiz as Quiz).subscribe(() => {
        this.resetForm();
        this.loadQuizzes();
      });
    } else {
      this.quizService.createQuiz(this.newQuiz as Quiz).subscribe(() => {
        this.resetForm();
        this.loadQuizzes();
      });
    }
  }

  editQuiz(quiz: Quiz) {
    this.editingQuiz = true;
    this.newQuiz = { ...quiz };
  }

  toggleQuiz(quiz: Quiz) {
    this.quizService.toggleQuizStatus(quiz.id).subscribe(() => {
      this.loadQuizzes();
    });
  }

  deleteQuiz(id: string) {
    if (confirm('¿Estás seguro de que deseas eliminar este cuestionario?')) {
      this.quizService.deleteQuiz(id).subscribe(() => {
        this.loadQuizzes();
      });
    }
  }

  resetForm() {
    this.editingQuiz = false;
    this.newQuiz = this.getEmptyQuiz();
  }
}