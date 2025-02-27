import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { QuizService } from '../../services/quiz.service';
import { Quiz, Question, QuizAttempt } from '../../models/quiz.model';

@Component({
  selector: 'app-quiz-taking',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  template: `
    <div class="module-container">
      <div *ngIf="!quizStarted" class="kid-card">
        <div class="kid-card-content">
          <h1>
            <i class="fas fa-question-circle text-yellow"></i>
            {{quiz?.title}}
            <i class="fas fa-question-circle text-yellow"></i>
          </h1>

          <div class="quiz-info">
            <p class="description">{{quiz?.description}}</p>
            <div class="details">
              <div class="detail-item">
                <i class="fas fa-clock"></i>
                <span>Tiempo: {{quiz?.timeLimit}} minutos</span>
              </div>
              <div class="detail-item">
                <i class="fas fa-star"></i>
                <span>Puntaje para aprobar: {{quiz?.passingScore}}%</span>
              </div>
              <div class="detail-item">
                <i class="fas fa-question"></i>
                <span>Preguntas: {{quiz?.questions?.length}}</span>
              </div>
            </div>
          </div>

          <button class="btn btn-kid" (click)="startQuiz()">
            <i class="fas fa-play"></i> ¡Comenzar!
          </button>
        </div>
      </div>

      <div *ngIf="quizStarted && !quizCompleted" class="kid-card">
        <div class="kid-card-content">
          <div class="quiz-header">
            <div class="timer" [class.warning]="timeLeft <= 60">
              <i class="fas fa-clock"></i>
              <span>{{formatTime(timeLeft)}}</span>
            </div>
            <div class="progress">
              Pregunta {{currentQuestionIndex + 1}} de {{quiz?.questions?.length}}
            </div>
          </div>

          <div class="question-container">
            <h2>{{currentQuestion?.text}}</h2>
            
            <div class="options-list">
              <div *ngFor="let option of currentQuestion?.options; let i = index"
                   class="option-item"
                   [class.selected]="selectedOption === i"
                   (click)="selectOption(i)">
                <span class="option-letter">{{['A', 'B', 'C', 'D'][i]}}</span>
                <span class="option-text">{{option}}</span>
              </div>
            </div>

            <div class="navigation-buttons">
              <button *ngIf="currentQuestionIndex > 0" 
                      class="btn btn-kid" 
                      (click)="previousQuestion()">
                <i class="fas fa-arrow-left"></i> Anterior
              </button>
              
              <button *ngIf="currentQuestionIndex < quiz!.questions.length - 1" 
                      class="btn btn-kid"
                      [disabled]="selectedOption === null"
                      (click)="nextQuestion()">
                Siguiente <i class="fas fa-arrow-right"></i>
              </button>
              
              <button *ngIf="currentQuestionIndex === quiz!.questions.length - 1"
                      class="btn btn-kid"
                      [disabled]="selectedOption === null"
                      (click)="finishQuiz()">
                ¡Terminar! <i class="fas fa-check"></i>
              </button>
            </div>
          </div>
        </div>
      </div>

      <div *ngIf="quizCompleted" class="kid-card results-card">
        <div class="kid-card-content">
          <h1>
            <i class="fas fa-trophy text-yellow"></i>
            ¡Resultados!
            <i class="fas fa-trophy text-yellow"></i>
          </h1>

          <div class="results-container">
            <div class="score-circle" [class.passed]="score >= quiz!.passingScore">
              <div class="score-value">{{score}}%</div>
              <div class="score-label">{{score >= quiz!.passingScore ? '¡Aprobado!' : 'Intenta de nuevo'}}</div>
            </div>

            <div class="stats">
              <div class="stat-item">
                <i class="fas fa-check-circle"></i>
                <span>Correctas: {{correctAnswers}}</span>
              </div>
              <div class="stat-item">
                <i class="fas fa-times-circle"></i>
                <span>Incorrectas: {{quiz!.questions.length - correctAnswers}}</span>
              </div>
              <div class="stat-item">
                <i class="fas fa-clock"></i>
                <span>Tiempo: {{formatTime(quiz!.timeLimit! * 60 - timeLeft)}}</span>
              </div>
            </div>

            <div class="answers-review">
              <h3>Revisión de Respuestas</h3>
              <div *ngFor="let question of quiz!.questions; let i = index" class="review-item">
                <div class="question-header">
                  <span class="question-number">Pregunta {{i + 1}}</span>
                  <span class="result-icon" [class.correct]="userAnswers[i] === question.correctAnswer">
                    <i class="fas" [class.fa-check]="userAnswers[i] === question.correctAnswer" 
                       [class.fa-times]="userAnswers[i] !== question.correctAnswer"></i>
                  </span>
                </div>
                <p class="question-text">{{question.text}}</p>
                <div class="answer-details">
                  <p class="selected-answer">
                    Tu respuesta: {{question.options[userAnswers[i]]}}
                  </p>
                  <p class="correct-answer" *ngIf="userAnswers[i] !== question.correctAnswer">
                    Respuesta correcta: {{question.options[question.correctAnswer]}}
                  </p>
                  <p class="explanation" *ngIf="question.explanation">
                    {{question.explanation}}
                  </p>
                </div>
              </div>
            </div>

            <div class="button-group">
              <button class="btn btn-kid" (click)="retryQuiz()">
                <i class="fas fa-redo"></i> Intentar de nuevo
              </button>
              <button class="btn btn-kid" routerLink="/review">
                <i class="fas fa-arrow-left"></i> Volver a Mis Tareas
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .quiz-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 2rem;
      background: rgba(255, 255, 255, 0.1);
      padding: 1rem;
      border-radius: 10px;
    }

    .timer {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      font-size: 1.2rem;
      color: white;
      font-family: 'Comic Sans MS', cursive;
    }

    .timer.warning {
      color: #ff6b6b;
      animation: pulse 1s infinite;
    }

    .progress {
      color: white;
      font-family: 'Comic Sans MS', cursive;
    }

    .question-container {
      text-align: center;
    }

    .question-container h2 {
      color: white;
      font-family: 'Comic Sans MS', cursive;
      margin-bottom: 2rem;
      font-size: 1.5rem;
    }

    .options-list {
      display: grid;
      gap: 1rem;
      margin: 2rem 0;
    }

    .option-item {
      display: flex;
      align-items: center;
      gap: 1rem;
      background: rgba(255, 255, 255, 0.1);
      padding: 1rem;
      border-radius: 10px;
      cursor: pointer;
      transition: all 0.3s ease;
    }

    .option-item:hover {
      transform: translateX(10px);
      background: rgba(255, 255, 255, 0.2);
    }

    .option-item.selected {
      background: rgba(255, 255, 255, 0.3);
      transform: translateX(20px);
    }

    .option-letter {
      background: white;
      color: #333;
      width: 30px;
      height: 30px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 50%;
      font-weight: bold;
      font-family: 'Comic Sans MS', cursive;
    }

    .option-text {
      color: white;
      font-family: 'Comic Sans MS', cursive;
      flex: 1;
    }

    .navigation-buttons {
      display: flex;
      justify-content: center;
      gap: 1rem;
      margin-top: 2rem;
    }

    .results-container {
      text-align: center;
    }

    .score-circle {
      width: 150px;
      height: 150px;
      border-radius: 50%;
      background: rgba(255, 0, 0, 0.2);
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      margin: 2rem auto;
      border: 4px solid #ff6b6b;
    }

    .score-circle.passed {
      background: rgba(0, 255, 0, 0.2);
      border-color: #40c057;
    }

    .score-value {
      font-size: 2.5rem;
      font-weight: bold;
      color: white;
      font-family: 'Comic Sans MS', cursive;
    }

    .score-label {
      color: white;
      font-family: 'Comic Sans MS', cursive;
      font-size: 1.2rem;
    }

    .stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 1rem;
      margin: 2rem 0;
      background: rgba(255, 255, 255, 0.1);
      padding: 1rem;
      border-radius: 10px;
    }

    .stat-item {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      color: white;
      font-family: 'Comic Sans MS', cursive;
    }

    .answers-review {
      margin: 2rem 0;
      text-align: left;
    }

    .answers-review h3 {
      color: white;
      font-family: 'Comic Sans MS', cursive;
      margin-bottom: 1rem;
      text-align: center;
    }

    .review-item {
      background: rgba(255, 255, 255, 0.1);
      padding: 1rem;
      border-radius: 10px;
      margin-bottom: 1rem;
    }

    .question-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 0.5rem;
    }

    .question-number {
      color: white;
      font-family: 'Comic Sans MS', cursive;
      font-weight: bold;
    }

    .result-icon {
      color: #ff6b6b;
    }

    .result-icon.correct {
      color: #40c057;
    }

    .question-text {
      color: white;
      font-family: 'Comic Sans MS', cursive;
      margin-bottom: 1rem;
    }

    .answer-details {
      background: rgba(255, 255, 255, 0.05);
      padding: 1rem;
      border-radius: 8px;
    }

    .answer-details p {
      color: white;
      font-family: 'Comic Sans MS', cursive;
      margin: 0.5rem 0;
    }

    .explanation {
      font-style: italic;
      opacity: 0.9;
    }

    @keyframes pulse {
      0% { opacity: 1; }
      50% { opacity: 0.5; }
      100% { opacity: 1; }
    }

    @media (max-width: 768px) {
      .navigation-buttons {
        flex-direction: column;
      }

      .stats {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class QuizTakingComponent implements OnInit, OnDestroy {
  quiz: Quiz | null = null;
  quizStarted: boolean = false;
  quizCompleted: boolean = false;
  currentQuestionIndex: number = 0;
  selectedOption: number | null = null;
  userAnswers: number[] = [];
  timeLeft: number = 0;
  timerInterval: any;
  score: number = 0;
  correctAnswers: number = 0;

  constructor(
    private quizService: QuizService,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  get currentQuestion(): Question | undefined {
    return this.quiz?.questions[this.currentQuestionIndex];
  }

  ngOnInit() {
    const quizId = this.route.snapshot.paramMap.get('id');
    if (quizId) {
      this.quizService.getQuiz(quizId).subscribe(quiz => {
        if (quiz) {
          this.quiz = quiz;
          this.userAnswers = new Array(quiz.questions.length).fill(null);
        } else {
          this.router.navigate(['/review']);
        }
      });
    }
  }

  ngOnDestroy() {
    this.stopTimer();
  }

  startQuiz() {
    this.quizStarted = true;
    this.timeLeft = this.quiz!.timeLimit! * 60; // Convertir minutos a segundos
    this.startTimer();
  }

  startTimer() {
    this.timerInterval = setInterval(() => {
      if (this.timeLeft > 0) {
        this.timeLeft--;
      } else {
        this.finishQuiz();
      }
    }, 1000);
  }

  stopTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
    }
  }

  formatTime(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  }

  selectOption(index: number) {
    this.selectedOption = index;
    this.userAnswers[this.currentQuestionIndex] = index;
  }

  previousQuestion() {
    if (this.currentQuestionIndex > 0) {
      this.currentQuestionIndex--;
      this.selectedOption = this.userAnswers[this.currentQuestionIndex];
    }
  }

  nextQuestion() {
    if (this.currentQuestionIndex < this.quiz!.questions.length - 1) {
      this.currentQuestionIndex++;
      this.selectedOption = this.userAnswers[this.currentQuestionIndex];
    }
  }

  finishQuiz() {
    this.stopTimer();
    this.calculateScore();
    this.quizCompleted = true;
  }

  calculateScore() {
    let correct = 0;
    let totalPoints = 0;
    let earnedPoints = 0;

    this.quiz!.questions.forEach((question, index) => {
      totalPoints += question.points;
      if (this.userAnswers[index] === question.correctAnswer) {
        correct++;
        earnedPoints += question.points;
      }
    });

    this.correctAnswers = correct;
    this.score = Math.round((earnedPoints / totalPoints) * 100);
  }

  retryQuiz() {
    this.quizStarted = false;
    this.quizCompleted = false;
    this.currentQuestionIndex = 0;
    this.selectedOption = null;
    this.userAnswers = new Array(this.quiz!.questions.length).fill(null);
    this.score = 0;
    this.correctAnswers = 0;
  }
}