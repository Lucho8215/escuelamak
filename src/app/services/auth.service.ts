import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, from, throwError } from 'rxjs';
import { catchError, map, switchMap } from 'rxjs/operators';
import { User, UserRole } from '../models/user.model';
import { UserService } from './user.service';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  currentUser$ = this.currentUserSubject.asObservable();

  constructor(private userService: UserService) {
    const savedUser = localStorage.getItem('currentUser');
    if (savedUser) {
      this.currentUserSubject.next(JSON.parse(savedUser));
    }
  }

  login(email: string, password: string): Observable<User> {
    return from(this.userService.verifyPassword(email, password)).pipe(
      switchMap(isValid => {
        if (!isValid) {
          throw new Error('Credenciales incorrectas');
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
        return throwError(() => new Error('Error al iniciar sesión. Por favor, verifique sus credenciales.'));
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
      [UserRole.ADMIN]: ['manage_users', 'manage_permissions', 'view_courses', 'review_exercises'],
      [UserRole.TEACHER]: ['view_courses', 'create_courses', 'edit_courses'],
      [UserRole.TUTOR]: ['view_courses', 'review_exercises'],
      [UserRole.STUDENT]: ['view_courses', 'submit_exercises']
    };

    return permissions[user.role]?.includes(permission) || false;
  }
}