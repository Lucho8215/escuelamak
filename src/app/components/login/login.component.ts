import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="module-container">
      <div class="kid-card login-card">
        <div class="kid-card-content">
          <h1>
            <i class="fas fa-door-open text-yellow"></i>
            ¡Bienvenido a tu EscuelaMAK!
            <i class="fas fa-door-open text-yellow"></i>
          </h1>
          <form (ngSubmit)="onSubmit()" #loginForm="ngForm" class="login-form">
            <div class="form-group">
              <label for="email">Tu Correo Mágico</label>
              <input
                type="email"
                id="email"
                name="email"
                [(ngModel)]="email"
                required
                class="form-control kid-input"
                placeholder="ejemplo@correo.com"
                [disabled]="isLoading"
              >
            </div>
            <div class="form-group">
              <label for="password">Tu Palabra Secreta</label>
              <input
                type="password"
                id="password"
                name="password"
                [(ngModel)]="password"
                required
                class="form-control kid-input"
                placeholder="••••••••"
                [disabled]="isLoading"
              >
            </div>
            <button type="submit" class="btn btn-kid" [disabled]="isLoading">
              {{ isLoading ? 'Iniciando...' : '¡Comenzar Aventura!' }}
            </button>
            
            <div class="login-actions">
              <button type="button" class="btn btn-link" (click)="recoverPassword()">
                ¿Olvidaste tu contraseña?
              </button>
            </div>

            <p *ngIf="errorMessage" class="error-message">
              {{ errorMessage }}
            </p>
          </form>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .error-message {
      color: #ff6b6b;
      margin-top: 1rem;
      text-align: center;
      font-family: 'Comic Sans MS', cursive;
    }

    .login-actions {
      display: flex;
      justify-content: center;
      margin-top: 1rem;
      padding: 0 1rem;
    }

    .btn-link {
      background: none;
      border: none;
      color: white;
      text-decoration: underline;
      font-family: 'Comic Sans MS', cursive;
      cursor: pointer;
      padding: 0.5rem;
      font-size: 0.9rem;
      transition: all 0.3s ease;
    }

    .btn-link:hover {
      transform: scale(1.05);
      text-shadow: 0 0 8px rgba(255, 255, 255, 0.5);
    }
  `]
})
export class LoginComponent {
  email: string = '';
  password: string = '';
  isLoading: boolean = false;
  errorMessage: string = '';

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  onSubmit() {
    if (!this.email || !this.password) {
      this.errorMessage = 'Por favor, completa todos los campos';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    this.authService.login(this.email, this.password).subscribe({
      next: () => {
        this.isLoading = false;
        this.router.navigate(['/dashboard']);
      },
      error: (error) => {
        this.isLoading = false;
        this.errorMessage = error.message || 'Error al iniciar sesión';
        console.error('Error de inicio de sesión:', error);
      }
    });
  }

  recoverPassword() {
    if (!this.email) {
      this.errorMessage = 'Por favor, ingresa tu correo electrónico para recuperar tu contraseña';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    // Aquí implementaremos la lógica de recuperación de contraseña
    // Por ahora, solo mostraremos un mensaje
    setTimeout(() => {
      this.isLoading = false;
      alert('Se ha enviado un correo con instrucciones para recuperar tu contraseña');
    }, 1000);
  }
}