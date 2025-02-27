import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, from, throwError, timer, of } from 'rxjs';
import { catchError, map, switchMap, retryWhen, delayWhen, tap, timeout } from 'rxjs/operators';
import { User, UserRole } from '../models/user.model';
import { UserService } from './user.service';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  resetPassword(token: string, newPassword: string) {
    throw new Error('Method not implemented.');
  }
  verifyResetToken(token: string) {
    throw new Error('Method not implemented.');
  }
  requestPasswordReset(email: string) {
    throw new Error('Method not implemented.');
  }
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  currentUser$ = this.currentUserSubject.asObservable();
  
  private connectionStatus = new BehaviorSubject<boolean>(true);
  connectionStatus$ = this.connectionStatus.asObservable();

  private supabase: SupabaseClient = createClient(
    environment.supabaseUrl,
    environment.supabaseKey,
    {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true
      },
      realtime: {
        params: {
          eventsPerSecond: 10
        }
      },
      db: {
        schema: 'public'
      },
      global: {
        headers: {
          'apikey': environment.supabaseKey,
          'Authorization': `Bearer ${environment.supabaseKey}`
        }
      }
    }
  );

  private healthCheckInterval: any;
  private readonly maxRetries = 3;
  private readonly initialRetryDelay = 1000;
  private readonly maxRetryDelay = 5000;
  private readonly healthCheckInterval_ms = 30000;
  private readonly requestTimeout_ms = 30000;

  constructor(private userService: UserService) {
    this.startHealthCheck();
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

  private startHealthCheck() {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
    }

    this.checkConnection();

    this.healthCheckInterval = setInterval(() => {
      this.checkConnection();
    }, this.healthCheckInterval_ms);
  }

  private async checkConnection() {
    try {
      const { data, error } = await this.supabase.rpc('verify_connection');
      
      if (error) throw error;
      
      const isConnected = data?.status === 'connected';
      this.connectionStatus.next(isConnected);
      
      if (!isConnected) {
        console.warn('Connection check failed:', data?.message || 'Unknown error');
      }
    } catch (err: any) {
      console.error('Health check error:', err?.message || err);
      this.connectionStatus.next(false);
    }
  }

  private retryStrategy() {
    let retryAttempt = 0;
    return (errors: Observable<any>) => errors.pipe(
      delayWhen(() => {
        retryAttempt++;
        const delay = Math.min(
          this.initialRetryDelay * Math.pow(2, retryAttempt - 1),
          this.maxRetryDelay
        );
        console.log(`Retry attempt ${retryAttempt} after ${delay}ms`);
        return timer(delay);
      }),
      map(error => {
        if (retryAttempt === this.maxRetries) {
          throw new Error('No se pudo conectar al servidor. Por favor, intenta más tarde.');
        }
        return error;
      })
    );
  }

  login(email: string, password: string): Observable<User> {
    if (!this.connectionStatus.value) {
      return throwError(() => new Error('No hay conexión con el servidor. Por favor, verifica tu conexión a internet.'));
    }

    if (!email || !password) {
      return throwError(() => new Error('Por favor, ingresa tu email y contraseña.'));
    }

    return from(this.userService.verifyPassword(email, password)).pipe(
      timeout(this.requestTimeout_ms),
      retryWhen(this.retryStrategy()),
      switchMap(isValid => {
        if (!isValid) {
          throw new Error('Credenciales incorrectas. Por favor, verifica tu email y contraseña.');
        }
        return from(this.userService.getUserByEmail(email));
      }),
      map(user => {
        if (!user) {
          throw new Error('Usuario no encontrado');
        }
        localStorage.setItem('currentUser', JSON.stringify(user));
        this.currentUserSubject.next(user);
        return user;
      }),
      catchError(error => {
        console.error('Error de inicio de sesión:', error);
        if (error.name === 'TimeoutError') {
          return throwError(() => new Error('La solicitud ha tardado demasiado. Por favor, intenta de nuevo.'));
        }
        if (error.message) {
          return throwError(() => error);
        }
        return throwError(() => new Error('Error al iniciar sesión. Por favor, intenta de nuevo más tarde.'));
      })
    );
  }

  logout(): void {
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
        'manage_users',
        'manage_permissions',
        'view_courses',
        'review_exercises',
        'create_courses',
        'edit_courses',
        'create_quizzes',
        'edit_quizzes',
        'submit_exercises'
      ],
      [UserRole.TEACHER]: [
        'view_courses',
        'create_courses',
        'edit_courses',
        'create_quizzes',
        'edit_quizzes',
        'review_exercises'
      ],
      [UserRole.TUTOR]: [
        'view_courses',
        'review_exercises',
        'create_quizzes'
      ],
      [UserRole.STUDENT]: [
        'view_courses',
        'submit_exercises',
        'take_quizzes'
      ]
    };

    return permissions[user.role]?.includes(permission) || false;
  }

  ngOnDestroy() {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
    }
  }
}