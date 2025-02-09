import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { User, UserRole } from '../../models/user.model';
import { UserService } from '../../services/user.service';

@Component({
  selector: 'app-user-management',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  template: `
    <div class="module-container">
      <a routerLink="/dashboard" class="btn btn-back">
        <i class="fas fa-arrow-left"></i> Volver al Panel
      </a>
      
      <h1>
        <i class="fas fa-users text-purple"></i>
        Panel de Usuarios
        <i class="fas fa-users text-purple"></i>
      </h1>

      <div class="card-grid">
        <div class="kid-card" *ngFor="let user of users; let i = index">
          <div class="kid-card-content">
            <i class="fas fa-user-circle card-icon"></i>
            <h3>{{user.name}}</h3>
            <div class="user-details">
              <p><strong>Email:</strong> {{user.email}}</p>
              
              <div class="form-group">
                <label for="role{{i}}">Rol:</label>
                <select 
                  id="role{{i}}"
                  [(ngModel)]="user.role"
                  (change)="updateUser(user)"
                  class="kid-input"
                >
                  <option [value]="UserRole.ADMIN">Administrador</option>
                  <option [value]="UserRole.TEACHER">Profesor</option>
                  <option [value]="UserRole.TUTOR">Tutor</option>
                  <option [value]="UserRole.STUDENT">Estudiante</option>
                </select>
              </div>

              <div class="form-group">
                <label for="password{{i}}">Nueva Contraseña:</label>
                <input
                  type="password"
                  id="password{{i}}"
                  [(ngModel)]="newPasswords[user.id]"
                  class="kid-input"
                  placeholder="Nueva contraseña"
                >
              </div>

              <button 
                class="btn btn-kid"
                (click)="updatePassword(user)"
                [disabled]="!newPasswords[user.id]"
              >
                Actualizar Contraseña
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .user-details {
      width: 100%;
      text-align: left;
      margin-top: 1rem;
    }

    .form-group {
      margin: 1rem 0;
    }

    .form-group label {
      display: block;
      margin-bottom: 0.5rem;
      color: white;
      font-family: 'Comic Sans MS', cursive;
    }

    .kid-input {
      width: 100%;
      padding: 0.5rem;
      border: 2px solid white;
      border-radius: 10px;
      background-color: rgba(255, 255, 255, 0.9);
      font-family: 'Comic Sans MS', cursive;
    }

    .btn-kid {
      margin-top: 1rem;
      width: 100%;
    }

    .btn-kid:disabled {
      opacity: 0.7;
      cursor: not-allowed;
    }
  `]
})
export class UserManagementComponent implements OnInit {
  users: User[] = [];
  UserRole = UserRole;
  newPasswords: { [key: string]: string } = {};

  constructor(private userService: UserService) {}

  ngOnInit() {
    this.loadUsers();
  }

  loadUsers() {
    this.userService.getUsers().subscribe(users => {
      this.users = users;
    });
  }

  updateUser(user: User) {
    this.userService.updateUser(user).subscribe(() => {
      console.log('Usuario actualizado con éxito');
    });
  }

  updatePassword(user: User) {
    if (this.newPasswords[user.id]) {
      this.userService.updatePassword(user.id, this.newPasswords[user.id]).subscribe(() => {
        console.log('Contraseña actualizada con éxito');
        this.newPasswords[user.id] = ''; // Limpiar el campo
      });
    }
  }
}