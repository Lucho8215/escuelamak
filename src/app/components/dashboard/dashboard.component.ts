import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { User, UserRole } from '../../models/user.model';
@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="module-container">
      <div class="welcome-card" [ngClass]="getRoleClass()">
        <div class="welcome-content">
          <div class="welcome-left">
            <div class="role-badge">
              <i class="fas" [ngClass]="getRoleIcon()"></i>
              {{ getRoleLabel() }}
            </div>
            <h1 class="welcome-name">Hola, {{ currentUser?.name || 'Usuario' }}!</h1>
            <p class="welcome-email">{{ currentUser?.email }}</p>
          </div>
          <div class="welcome-avatar">
            <i class="fas fa-user-circle"></i>
          </div>
        </div>
        <button class="btn btn-logout" (click)="logout()">
          <i class="fas fa-sign-out-alt"></i> Salir
        </button>
      </div>
      <div class="card-grid">
        <div class="kid-card theme-card" *ngIf="authService.hasPermission('manage_users')">
          <div class="kid-card-content">
            <i class="fas fa-users card-icon"></i>
            <h3>Gestion de Usuarios</h3>
            <p>Administra los usuarios del sistema</p>
            <a routerLink="/user-management" class="btn btn-kid">Gestionar</a>
          </div>
        </div>
        <div class="kid-card completed-card" *ngIf="authService.hasPermission('review_exercises')">
          <div class="kid-card-content">
            <i class="fas fa-star card-icon"></i>
            <h3>Ejercicios y Quizzes</h3>
            <p>Practica y responde cuestionarios</p>
            <a routerLink="/review" class="btn btn-kid">Practicar</a>
          </div>
        </div>
        <div class="kid-card numbers-card" *ngIf="authService.hasPermission('view_courses')">
          <div class="kid-card-content">
            <i class="fas fa-book-open card-icon"></i>
            <h3>Mis Cursos</h3>
            <p>Explora el mundo de las matematicas</p>
            <a routerLink="/courses" class="btn btn-kid">Ver Cursos</a>
          </div>
        </div>
        <div class="kid-card quiz-card" *ngIf="authService.hasPermission('create_courses')">
          <div class="kid-card-content">
            <i class="fas fa-question-circle card-icon"></i>
            <h3>Gestion de Quizzes</h3>
            <p>Crea y administra cuestionarios</p>
            <a routerLink="/quiz-management" class="btn btn-kid">Gestionar Quizzes</a>
          </div>
        </div>
        <div class="kid-card pending-card" *ngIf="authService.hasPermission('manage_courses')">
          <div class="kid-card-content">
            <i class="fas fa-chalkboard-teacher card-icon"></i>
            <h3>Gestion de Cursos</h3>
            <p>Administra los cursos de la plataforma</p>
            <a routerLink="/course-management" class="btn btn-kid">Gestionar Cursos</a>
          </div>
        </div>
        <div class="kid-card theme-card" *ngIf="authService.hasPermission('manage_users')">
          <div class="kid-card-content">
            <i class="fas fa-flask card-icon"></i>
            <h3>Test Supabase</h3>
            <p>Verificar conexion con la base de datos</p>
            <a routerLink="/supabase-test" class="btn btn-kid">Probar</a>
          </div>
        </div>
        <div class='kid-card' style='background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);' *ngIf="authService.hasPermission('manage_users')">
          <div class='kid-card-content'>
            <i class='fas fa-chalkboard-teacher card-icon'></i>
            <h3>Gestion de Clases</h3>
            <p>Clases, alumnos, inscripciones y lecciones</p>
            <a routerLink='/class-management' class='btn btn-kid'>Ver Clases</a>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .welcome-card { border-radius: 20px; padding: 2rem; margin-bottom: 2rem; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem; color: white; box-shadow: 0 8px 32px rgba(0,0,0,0.2); }
    .admin { background: linear-gradient(135deg, #764ba2 0%, #667eea 100%); }
    .teacher { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); }
    .student { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
    .tutor { background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); }
    .welcome-content { display: flex; align-items: center; gap: 2rem; flex: 1; }
    .welcome-left { flex: 1; }
    .welcome-name { font-size: 2.5rem; font-weight: 900; margin: 0.5rem 0; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
    .welcome-email { font-size: 1rem; opacity: 0.9; margin: 0; }
    .role-badge { display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.4rem 1.2rem; border-radius: 50px; font-size: 0.9rem; font-weight: bold; background: rgba(255,255,255,0.25); margin-bottom: 0.5rem; }
    .welcome-avatar { font-size: 5rem; opacity: 0.3; }
    .btn-logout { background: rgba(255,255,255,0.2); color: white; border: 2px solid rgba(255,255,255,0.5); padding: 0.75rem 1.5rem; border-radius: 25px; cursor: pointer; font-size: 1rem; font-weight: bold; display: flex; align-items: center; gap: 0.5rem; transition: all 0.2s; }
    .btn-logout:hover { background: rgba(255,255,255,0.35); transform: scale(1.05); }
    .quiz-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
  `]
})
export class DashboardComponent implements OnInit {
  currentUser: User | null = null;
  constructor(public authService: AuthService, private router: Router) {}
  ngOnInit() { this.currentUser = this.authService.getCurrentUser(); }
  getRoleLabel(): string {
    switch(this.currentUser?.role) {
      case UserRole.ADMIN: return 'Administrador';
      case UserRole.TEACHER: return 'Profesor';
      case UserRole.TUTOR: return 'Tutor';
      case UserRole.STUDENT: return 'Alumno';
      default: return 'Usuario';
    }
  }
  getRoleIcon(): string {
    switch(this.currentUser?.role) {
      case UserRole.ADMIN: return 'fa-crown';
      case UserRole.TEACHER: return 'fa-chalkboard-teacher';
      case UserRole.TUTOR: return 'fa-user-tie';
      case UserRole.STUDENT: return 'fa-graduation-cap';
      default: return 'fa-user';
    }
  }
  getRoleClass(): string {
    switch(this.currentUser?.role) {
      case UserRole.ADMIN: return 'admin';
      case UserRole.TEACHER: return 'teacher';
      case UserRole.TUTOR: return 'tutor';
      case UserRole.STUDENT: return 'student';
      default: return 'student';
    }
  }
  logout() { this.authService.logout(); this.router.navigate(['/login']); }
}
