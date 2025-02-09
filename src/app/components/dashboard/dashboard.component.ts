import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="module-container">
      <div class="dashboard-header">
        <h1>
          <i class="fas fa-hat-wizard text-purple"></i>
          Mi Panel Mágico
          <i class="fas fa-hat-wizard text-purple"></i>
        </h1>
        <button class="btn btn-logout" (click)="logout()">
          <i class="fas fa-sign-out-alt"></i>
          Salir
        </button>
      </div>

      <div class="card-grid">
        <div class="kid-card theme-card" *ngIf="authService.hasPermission('manage_users')">
          <div class="kid-card-content">
            <i class="fas fa-users card-icon"></i>
            <h3>¡Gestión de Usuarios!</h3>
            <p>Administra los usuarios del sistema</p>
            <a routerLink="/user-management" class="btn btn-kid">¡Gestionar!</a>
          </div>
        </div>

        <div class="kid-card completed-card" *ngIf="authService.hasPermission('review_exercises')">
          <div class="kid-card-content">
            <i class="fas fa-star card-icon"></i>
            <h3>¡Mis Tareas!</h3>
            <p>Revisa tus ejercicios mágicos</p>
            <a routerLink="/review" class="btn btn-kid">¡Revisar!</a>
          </div>
        </div>

        <div class="kid-card numbers-card" *ngIf="authService.hasPermission('view_courses')">
          <div class="kid-card-content">
            <i class="fas fa-book-open card-icon"></i>
            <h3>¡A Aprender!</h3>
            <p>Explora el mundo de las matemáticas</p>
            <a routerLink="/courses" class="btn btn-kid">¡Aventura!</a>
          </div>
        </div>

        <div class="kid-card avatar-card" *ngIf="authService.hasPermission('manage_permissions')">
          <div class="kid-card-content">
            <i class="fas fa-wand-magic-sparkles card-icon"></i>
            <h3>¡Mi Espacio!</h3>
            <p>Personaliza tu mundo mágico</p>
            <a routerLink="/settings" class="btn btn-kid">¡Personalizar!</a>
          </div>
        </div>

        <div class="kid-card theme-card" *ngIf="authService.hasPermission('manage_users')">
          <div class="kid-card-content">
            <i class="fas fa-chalkboard-teacher card-icon"></i>
            <h3>¡Gestión de Cursos!</h3>
            <p>Administra los cursos y clases</p>
            <a routerLink="/course-management" class="btn btn-kid">¡Gestionar Cursos!</a>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .dashboard-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 2rem;
    }

    .btn-logout {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      background-color: #ff6b6b;
      color: white;
      padding: 0.5rem 1rem;
      border: none;
      border-radius: 20px;
      font-family: 'Comic Sans MS', cursive;
      cursor: pointer;
      transition: all 0.3s ease;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .btn-logout:hover {
      transform: scale(1.05);
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      background-color: #ff5252;
    }

    .btn-logout i {
      font-size: 1.1rem;
    }
  `]
})
export class DashboardComponent {
  constructor(
    public authService: AuthService,
    private router: Router
  ) {}

  logout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}