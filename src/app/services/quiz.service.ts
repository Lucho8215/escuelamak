import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { Quiz, Question, QuizAttempt } from '../models/quiz.model';

@Injectable({
  providedIn: 'root'
})
export class QuizService {
  private quizzes: Quiz[] = [];

  constructor() {
    // Datos de ejemplo
    this.quizzes = [
      {
        id: '1',
        title: '¡Sumas Divertidas!',
        description: 'Practica sumas básicas con números del 1 al 10',
        questions: [
          {
            id: '1',
            text: '¿Cuánto es 2 + 3?',
            options: ['4', '5', '6', '7'],
            correctAnswer: 1,
            explanation: '2 + 3 = 5 porque al contar 2 números más después del 3 llegamos a 5',
            points: 10
          }
        ],
        isEnabled: true,
        createdAt: new Date(),
        updatedAt: new Date(),
        createdBy: 'teacher1',
        category: 'mathematics',
        difficulty: 'easy',
        timeLimit: 10,
        passingScore: 60
      }
    ];
  }

  getQuizzes(): Observable<Quiz[]> {
    return of(this.quizzes).pipe(delay(500));
  }

  getQuiz(id: string): Observable<Quiz | undefined> {
    return of(this.quizzes.find(q => q.id === id)).pipe(delay(500));
  }

  createQuiz(quiz: Omit<Quiz, 'id' | 'createdAt' | 'updatedAt'>): Observable<Quiz> {
    const newQuiz: Quiz = {
      ...quiz,
      id: (this.quizzes.length + 1).toString(),
      createdAt: new Date(),
      updatedAt: new Date()
    };
    this.quizzes.push(newQuiz);
    return of(newQuiz).pipe(delay(500));
  }

  updateQuiz(id: string, quiz: Partial<Quiz>): Observable<Quiz> {
    const index = this.quizzes.findIndex(q => q.id === id);
    if (index === -1) {
      throw new Error('Cuestionario no encontrado');
    }

    this.quizzes[index] = {
      ...this.quizzes[index],
      ...quiz,
      updatedAt: new Date()
    };

    return of(this.quizzes[index]).pipe(delay(500));
  }

  deleteQuiz(id: string): Observable<void> {
    const index = this.quizzes.findIndex(q => q.id === id);
    if (index === -1) {
      throw new Error('Cuestionario no encontrado');
    }

    this.quizzes.splice(index, 1);
    return of(void 0).pipe(delay(500));
  }

  toggleQuizStatus(id: string): Observable<Quiz> {
    const quiz = this.quizzes.find(q => q.id === id);
    if (!quiz) {
      throw new Error('Cuestionario no encontrado');
    }

    quiz.isEnabled = !quiz.isEnabled;
    quiz.updatedAt = new Date();

    return of(quiz).pipe(delay(500));
  }
}