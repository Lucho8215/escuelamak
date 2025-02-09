import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-review',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="module-container">
      <a routerLink="/dashboard" class="btn btn-back">
        <i class="fas fa-arrow-left"></i> Volver al Panel
      </a>
      
      <h1>
        <i class="fas fa-star text-yellow"></i>
        Mis Ejercicios
        <i class="fas fa-star text-yellow"></i>
      </h1>
      <div class="card-grid">
        <div class="kid-card pending-card">
          <div class="kid-card-content">
            <i class="fas fa-pencil-alt card-icon"></i>
            <h3>¡Ejercicios Nuevos!</h3>
            <p>¡Tienes ejercicios divertidos esperándote!</p>
            <button class="btn btn-kid">¡Vamos a Practicar!</button>
          </div>
        </div>
        <div class="kid-card completed-card">
          <div class="kid-card-content">
            <i class="fas fa-trophy card-icon"></i>
            <h3>¡Muy Bien!</h3>
            <p>Mira todos los ejercicios que has completado</p>
            <button class="btn btn-kid">Ver Mis Logros</button>
          </div>
        </div>
        <div class="kid-card feedback-card">
          <div class="kid-card-content">
            <i class="fas fa-magic card-icon"></i>
            <h3>¡Sorpresas!</h3>
            <p>Mensajes especiales de tu profesor</p>
            <button class="btn btn-kid">Ver Mensajes</button>
          </div>
        </div>
      </div>
    </div>
  `
})
export class ReviewComponent {}