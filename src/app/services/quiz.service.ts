import { Injectable } from '@angular/core';
import { Observable, from, throwError } from 'rxjs';
import { map, catchError, switchMap } from 'rxjs/operators';
import { Quiz, Question, QuizAttempt } from '../models/quiz.model';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class QuizService {

  private supabase: SupabaseClient = createClient(
    environment.supabaseUrl,
    environment.supabaseKey
  );

  // ─── Obtener todos los quizzes con sus preguntas ─────────────────────────
  getQuizzes(): Observable<Quiz[]> {
    return from(
      this.supabase
        .from('quizzes')
        .select(`*, questions (*)`)
        .order('created_at', { ascending: false })
    ).pipe(
      map(({ data, error }) => {
        if (error) throw new Error(error.message);
        return (data || []).map((q: any) => this.mapToQuiz(q));
      }),
      catchError(error => throwError(() => new Error(error.message)))
    );
  }

  // ─── Obtener un quiz por ID con sus preguntas ────────────────────────────
  getQuiz(id: string): Observable<Quiz | undefined> {
    return from(
      this.supabase
        .from('quizzes')
        .select(`*, questions (*)`)
        .eq('id', id)
        .single()
    ).pipe(
      map(({ data, error }) => {
        if (error) return undefined;
        return data ? this.mapToQuiz(data) : undefined;
      }),
      catchError(() => from([undefined]))
    );
  }

  // ─── Crear quiz y guardar preguntas en Supabase ──────────────────────────
  createQuiz(quiz: Omit<Quiz, 'id' | 'createdAt' | 'updatedAt'>): Observable<Quiz> {
    return from(
      // Paso 1: Crear el quiz
      this.supabase
        .from('quizzes')
        .insert([{
          title:         quiz.title,
          description:   quiz.description,
          category:      quiz.category,
          difficulty:    quiz.difficulty,
          time_limit:    quiz.timeLimit,
          passing_score: quiz.passingScore,
          is_enabled:    quiz.isEnabled,
          created_by:    quiz.createdBy
        }])
        .select()
        .single()
    ).pipe(
      switchMap(({ data, error }) => {
        if (error) throw new Error(error.message);
        const quizId = data.id;

        // Paso 2: Guardar las preguntas si existen
        if (!quiz.questions || quiz.questions.length === 0) {
          return from(Promise.resolve({ ...data, questions: [] }));
        }

        const questionsToInsert = quiz.questions.map((q, index) => ({
          quiz_id:        quizId,
          text:           q.text,
          options:        JSON.stringify(q.options),
          correct_answer: q.correctAnswer,
          explanation:    q.explanation || '',
          points:         q.points || 10,
          order_number:   index + 1
        }));

        return from(
          this.supabase
            .from('questions')
            .insert(questionsToInsert)
            .select()
            .then(({ data: qData, error: qError }) => {
              if (qError) throw new Error(qError.message);
              return { ...data, questions: qData || [] };
            })
        );
      }),
      map((data: any) => this.mapToQuiz(data)),
      catchError(error => throwError(() => new Error(error.message)))
    );
  }

  // ─── Actualizar quiz y sus preguntas ─────────────────────────────────────
  updateQuiz(id: string, quiz: Partial<Quiz>): Observable<Quiz> {
    return from(
      // Paso 1: Actualizar el quiz
      this.supabase
        .from('quizzes')
        .update({
          title:         quiz.title,
          description:   quiz.description,
          category:      quiz.category,
          difficulty:    quiz.difficulty,
          time_limit:    quiz.timeLimit,
          passing_score: quiz.passingScore,
          is_enabled:    quiz.isEnabled,
          updated_at:    new Date().toISOString()
        })
        .eq('id', id)
        .select()
        .single()
    ).pipe(
      switchMap(({ data, error }) => {
        if (error) throw new Error(error.message);

        if (!quiz.questions || quiz.questions.length === 0) {
          return from(Promise.resolve({ ...data, questions: [] }));
        }

        // Paso 2: Borrar preguntas viejas y guardar las nuevas
        return from(
          this.supabase
            .from('questions')
            .delete()
            .eq('quiz_id', id)
            .then(async () => {
              const questionsToInsert = quiz.questions!.map((q, index) => ({
                quiz_id:        id,
                text:           q.text,
                options:        JSON.stringify(q.options),
                correct_answer: q.correctAnswer,
                explanation:    q.explanation || '',
                points:         q.points || 10,
                order_number:   index + 1
              }));

              const { data: qData, error: qError } = await this.supabase
                .from('questions')
                .insert(questionsToInsert)
                .select();

              if (qError) throw new Error(qError.message);
              return { ...data, questions: qData || [] };
            })
        );
      }),
      map((data: any) => this.mapToQuiz(data)),
      catchError(error => throwError(() => new Error(error.message)))
    );
  }

  // ─── Eliminar un quiz ────────────────────────────────────────────────────
  deleteQuiz(id: string): Observable<void> {
    return from(
      this.supabase
        .from('quizzes')
        .delete()
        .eq('id', id)
    ).pipe(
      map(({ error }) => {
        if (error) throw new Error(error.message);
      }),
      catchError(error => throwError(() => new Error(error.message)))
    );
  }

  // ─── Activar o desactivar un quiz ───────────────────────────────────────
  toggleQuizStatus(id: string): Observable<Quiz> {
    return from(
      this.supabase
        .from('quizzes')
        .select('id, is_enabled')
        .eq('id', id)
        .single()
        .then(async ({ data, error }) => {
          if (error || !data) throw new Error('Quiz no encontrado');
          const { data: updated, error: updateError } = await this.supabase
            .from('quizzes')
            .update({
              is_enabled: !data.is_enabled,
              updated_at: new Date().toISOString()
            })
            .eq('id', id)
            .select(`*, questions (*)`)
            .single();
          if (updateError) throw new Error(updateError.message);
          return updated;
        })
    ).pipe(
      map((data: any) => this.mapToQuiz(data)),
      catchError(error => throwError(() => new Error(error.message)))
    );
  }

  // ─── Guardar resultado del alumno ────────────────────────────────────────
  saveAttempt(attempt: Omit<QuizAttempt, 'id'>): Observable<QuizAttempt> {
    return from(
      this.supabase
        .from('quiz_attempts')
        .insert([{
          quiz_id:      attempt.quizId,
          student_id:   attempt.userId,
          score:        attempt.score,
          answers:      JSON.stringify(attempt.answers),
          started_at:   attempt.startedAt,
          completed_at: attempt.completedAt,
          passed:       attempt.status === 'completed' && attempt.score >= 60
        }])
        .select()
        .single()
    ).pipe(
      map(({ data, error }) => {
        if (error) throw new Error(error.message);
        return {
          id:          data.id,
          quizId:      data.quiz_id,
          userId:      data.student_id,
          score:       data.score,
          answers:     JSON.parse(data.answers || '[]'),
          startedAt:   new Date(data.started_at),
          completedAt: data.completed_at ? new Date(data.completed_at) : undefined,
          status:      data.passed ? 'completed' : 'in-progress'
        } as QuizAttempt;
      }),
      catchError(error => throwError(() => new Error(error.message)))
    );
  }

  // ─── Obtener resultados de un alumno ─────────────────────────────────────
  getStudentAttempts(userId: string): Observable<any[]> {
    return from(
      this.supabase
        .from('quiz_attempts')
        .select(`*, quizzes (title, passing_score)`)
        .eq('student_id', userId)
        .order('completed_at', { ascending: false })
    ).pipe(
      map(({ data, error }) => {
        if (error) throw new Error(error.message);
        return data || [];
      }),
      catchError(error => throwError(() => new Error(error.message)))
    );
  }

  // ─── Convertir datos de Supabase al modelo Quiz ──────────────────────────
  private mapToQuiz(data: any): Quiz {
    return {
      id:           data.id,
      title:        data.title,
      description:  data.description,
      category:     data.category,
      difficulty:   data.difficulty as 'easy' | 'medium' | 'hard',
      timeLimit:    data.time_limit,
      passingScore: data.passing_score,
      isEnabled:    data.is_enabled,
      createdBy:    data.created_by,
      createdAt:    new Date(data.created_at),
      updatedAt:    new Date(data.updated_at),
      questions:    (data.questions || []).map((q: any) => ({
        id:            q.id,
        text:          q.text,
        options:       Array.isArray(q.options)
                         ? q.options
                         : JSON.parse(q.options || '[]'),
        correctAnswer: q.correct_answer,
        explanation:   q.explanation,
        points:        q.points
      } as Question))
    };
  }
}
