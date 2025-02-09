import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-courses',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="module-container">
      <a routerLink="/dashboard" class="btn btn-back">
        <i class="fas fa-arrow-left"></i> Volver al Panel
      </a>
      
      <h1>
        <i class="fas fa-magic text-purple"></i>
        Aventuras Matemáticas
        <i class="fas fa-magic text-purple"></i>
      </h1>
      <div class="card-grid">
        <div class="kid-card numbers-card">
          <div class="kid-card-content">
            <i class="fas fa-dice card-icon"></i>
            <h3>¡Números Mágicos!</h3>
            <p>Aprende a contar y jugar con números</p>
            <button class="btn btn-kid">¡Empezar Aventura!</button>
          </div>
        </div>
        <div class="kid-card shapes-card">
          <div class="kid-card-content">
            <i class="fas fa-shapes card-icon"></i>
            <h3>¡Formas Divertidas!</h3>
            <p>Descubre círculos, cuadrados y más</p>
            <button class="btn btn-kid">¡Jugar con Formas!</button>
          </div>
        </div>
        <div class="kid-card games-card">
          <div class="kid-card-content">
            <i class="fas fa-puzzle-piece card-icon"></i>
            <h3>¡Juegos Matemáticos!</h3>
            <p>Resuelve puzzles y gana estrellas</p>
            <button class="btn btn-kid">¡A Jugar!</button>
          </div>
        </div>
      </div>
    </div>
  `
})
export class CoursesComponent {}