import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, from, throwError } from 'rxjs';
import { catchError, map, switchMap } from 'rxjs/operators';
import { User, UserRole } from '../models/user.model';
import { UserService } from './user.service';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  private currentUserSubject = new BehaviorSubject<User | null>(null);
  currentUser$ = this.currentUserSubject.asObservable();

  private connectionStatus = new BehaviorSubject<boolean>(true);
  connectionStatus$ = this.connectionStatus.asObservable();

  private supabase: SupabaseClient = createClient(
    environment.supabaseUrl,
    environment.supabaseKey
  );

  constructor(private userService: UserService) {
    this.loadSavedUser();
  }

  private loadSavedUser() {
    try {
      const savedUser = localStorage.getItem('currentUser');
      if (savedUser) {
        const user = JSON.parse(savedUser);
        this.currentUserSubject.next(user);
      }
    } catch (error) {
      console.error('Error loading saved user:', error);
      localStorage.removeItem('currentUser');
    }
  }

  login(email: string, password: string): Observable<User> {
    if (!email || !password) {
      return throwError(() => new Error('Por favor, ingresa tu email y contraseña.'));
    }

    return from(
      this.supabase.auth.signInWithPassword({ email, password })
    ).pipe(
      switchMap(({ data, error }) => {
        if (error) throw new Error(error.message);
        if (!data.user) throw new Error('Usuario no encontrado');
        return from(this.userService.getUserByEmail(email));
      }),
      map(user => {
        if (!user) throw new Error('Usuario no encontrado en la base de datos');
        localStorage.setItem('currentUser', JSON.stringify(user));
        this.currentUserSubject.next(user);
        this.connectionStatus.next(true);
        return user;
      }),
      catchError(error => {
        console.error('Error de inicio de sesión:', error);
        return throwError(() => new Error(
          error.message || 'Error al iniciar sesión. Por favor, intenta de nuevo.'
        ));
      })
    );
  }

  requestPasswordReset(email: string): Observable<void> {
    return from(
      this.supabase.auth.resetPasswordForEmail(email)
    ).pipe(
      map(({ error }) => {
        if (error) throw new Error(error.message);
      }),
      catchError(error => throwError(() => new Error(error.message)))
    );
  }

  verifyResetToken(token: string): Observable<boolean> {
    return from(
      this.supabase.auth.verifyOtp({ token_hash: token, type: 'recovery' })
    ).pipe(
      map(({ error }) => !error),
      catchError(() => from([false]))
    );
  }

  resetPassword(token: string, newPassword: string): Observable<void> {
    return from(
      this.supabase.auth.updateUser({ password: newPassword })
    ).pipe(
      map(({ error }) => {
        if (error) throw new Error(error.message);
      }),
      catchError(error => throwError(() => new Error(error.message)))
    );
  }

  logout(): void {
    this.supabase.auth.signOut();
    localStorage.removeItem('currentUser');
    this.currentUserSubject.next(null);
  }

  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  hasPermission(permission: string): boolean {
    const user = this.getCurrentUser();
    if (!user) return false;

    const permissions = {
      [UserRole.ADMIN]: [
        'manage_users', 'manage_permissions', 'view_courses',
        'review_exercises', 'create_courses', 'edit_courses',
        'create_quizzes', 'edit_quizzes', 'submit_exercises'
      ],
      [UserRole.TEACHER]: [
        'view_courses', 'create_courses', 'edit_courses',
        'create_quizzes', 'edit_quizzes', 'review_exercises'
      ],
      [UserRole.TUTOR]: [
        'view_courses', 'review_exercises', 'create_quizzes'
      ],
      [UserRole.STUDENT]: [
        'view_courses', 'submit_exercises', 'take_quizzes'
      ]
    };

    return permissions[user.role]?.includes(permission) || false;
  }
}
