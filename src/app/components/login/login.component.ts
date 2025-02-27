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
            ¡Bienvenido!
            <i class="fas fa-door-open text-yellow"></i>
          </h1>
          
          <form (ngSubmit)="onSubmit()" #loginForm="ngForm" class="login-form">
            <div class="form-group">
              <label for="email">Tu Correo Mágico</label>
              <div class="input-container">
                <i class="fas fa-envelope input-icon"></i>
                <input
                  type="email"
                  id="email"
                  name="email"
                  [(ngModel)]="email"
                  required
                  class="form-control kid-input"
                  placeholder="ejemplo@correo.com"
                  [disabled]="isLoading"
                  #emailInput="ngModel"
                >
              </div>
              <div *ngIf="emailInput.invalid && (emailInput.dirty || emailInput.touched)" class="validation-error">
                Por favor, ingresa un correo válido
              </div>
            </div>

            <div class="form-group">
              <label for="password">Tu Palabra Secreta</label>
              <div class="input-container">
                <i class="fas fa-lock input-icon"></i>
                <input
                  [type]="showPassword ? 'text' : 'password'"
                  id="password"
                  name="password"
                  [(ngModel)]="password"
                  required
                  class="form-control kid-input"
                  placeholder="••••••••"
                  [disabled]="isLoading"
                  #passwordInput="ngModel"
                >
                <button 
                  type="button" 
                  class="password-toggle"
                  (click)="togglePasswordVisibility()"
                >
                  <i class="fas" [class.fa-eye]="!showPassword" [class.fa-eye-slash]="showPassword"></i>
                </button>
              </div>
              <div *ngIf="passwordInput.invalid && (passwordInput.dirty || passwordInput.touched)" class="validation-error">
                Por favor, ingresa tu contraseña
              </div>
            </div>

            <button type="submit" class="btn btn-kid" [disabled]="isLoading || !loginForm.form.valid">
              <i class="fas fa-magic"></i>
              {{ isLoading ? 'Iniciando...' : '¡Comenzar Aventura!' }}
            </button>
            
            <div class="login-actions">
              <button type="button" class="btn btn-link" (click)="recoverPassword()">
                <i class="fas fa-key"></i>
                ¿Olvidaste tu contraseña?
              </button>
            </div>

            <div *ngIf="errorMessage" class="error-message">
              <i class="fas fa-exclamation-circle"></i>
              {{ errorMessage }}
            </div>
          </form>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .login-card {
      max-width: 400px;
      margin: 2rem auto;
    }

    .error-message {
      color: #ff6b6b;
      margin-top: 1rem;
      text-align: center;
      font-family: 'Comic Sans MS', cursive;
      padding: 1rem;
      background: rgba(255, 0, 0, 0.1);
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 0.5rem;
    }

    .validation-error {
      color: #ff6b6b;
      font-size: 0.9rem;
      margin-top: 0.5rem;
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
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .btn-link:hover {
      transform: scale(1.05);
      text-shadow: 0 0 8px rgba(255, 255, 255, 0.5);
    }

    .input-container {
      position: relative;
      display: flex;
      align-items: center;
    }

    .input-icon {
      position: absolute;
      left: 12px;
      color: #666;
      font-size: 1.1rem;
    }

    .kid-input {
      padding: 0.75rem;
      padding-left: 2.5rem;
      width: 100%;
      border: 3px solid white;
      border-radius: 15px;
      font-size: 1rem;
      font-family: 'Comic Sans MS', cursive;
      background-color: rgba(255, 255, 255, 0.9);
      transition: all 0.3s ease;
    }

    .password-toggle {
      position: absolute;
      right: 10px;
      background: none;
      border: none;
      color: #666;
      cursor: pointer;
      padding: 5px;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.3s ease;
    }

    .password-toggle:hover {
      color: #333;
    }

    .btn-kid {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 0.5rem;
      width: 100%;
      margin-top: 1.5rem;
    }

    .btn-kid i {
      font-size: 1.2rem;
    }

    .form-group {
      margin-bottom: 1.5rem;
    }

    .form-group label {
      margin-bottom: 0.5rem;
      display: block;
      color: white;
      font-size: 1.1rem;
      font-family: 'Comic Sans MS', cursive;
    }
  `]
})
export class LoginComponent {
  email: string = '';
  password: string = '';
  isLoading: boolean = false;
  errorMessage: string = '';
  showPassword: boolean = false;

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  togglePasswordVisibility() {
    this.showPassword = !this.showPassword;
  }

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

    setTimeout(() => {
      this.isLoading = false;
      alert('Se ha enviado un correo con instrucciones para recuperar tu contraseña');
    }, 1000);
  }
}