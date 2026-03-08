import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import {
  User,
  UserRole,
  CreateUserRequest,
  UpdateUserRequest
} from '../../models/user.model';
import { UserService } from '../../services/user.service';

type UserForm = {
  id: string | null;
  name: string;
  email: string;
  cedula: string;
  role: UserRole;
  password: string;
};

@Component({
  selector: 'app-user-management',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './user-management.component.html',
  styleUrls: ['./user-management.component.css']
})
export class UserManagementComponent implements OnInit {
  users: User[] = [];
  readonly UserRole = UserRole;

  loading = false;
  saving = false;
  updatingPasswordUserId: string | null = null;

  successMessage = '';
  errorMessage = '';

  showUserModal = false;
  editingUser: User | null = null;

  userForm: UserForm = this.getEmptyForm();
  newPasswords: Record<string, string> = {};

  constructor(private userService: UserService) {}

  ngOnInit(): void {
    this.loadUsers();
  }

  loadUsers(): void {
    this.loading = true;
    this.clearMessages();

    this.userService.getUsers().subscribe({
      next: (users: User[]) => {
        this.users = users;
        this.loading = false;
      },
      error: (error: Error) => {
        this.loading = false;
        this.errorMessage = error.message || 'No se pudieron cargar los usuarios';
      }
    });
  }

  openCreateUser(): void {
    this.editingUser = null;
    this.userForm = this.getEmptyForm();
    this.showUserModal = true;
    this.clearMessages();
  }

  openEditUser(user: User): void {
    this.editingUser = user;
    this.userForm = {
      id: user.id,
      name: user.name,
      email: user.email,
      cedula: user.cedula,
      role: user.role,
      password: ''
    };
    this.showUserModal = true;
    this.clearMessages();
  }

  closeUserModal(): void {
    this.showUserModal = false;
    this.editingUser = null;
    this.userForm = this.getEmptyForm();
  }

  saveUser(): void {
    this.clearMessages();

    if (!this.userForm.name.trim()) {
      this.errorMessage = 'El nombre es obligatorio';
      return;
    }

    if (!this.userForm.email.trim()) {
      this.errorMessage = 'El correo es obligatorio';
      return;
    }

    if (!this.userForm.cedula.trim()) {
      this.errorMessage = 'La cédula es obligatoria';
      return;
    }

    if (!this.userForm.role) {
      this.errorMessage = 'El rol es obligatorio';
      return;
    }

    if (!this.editingUser && !this.userForm.password.trim()) {
      this.errorMessage = 'La contraseña es obligatoria para crear usuario';
      return;
    }

    this.saving = true;

    if (this.editingUser) {
      const payload: UpdateUserRequest = {
        id: this.userForm.id as string,
        name: this.userForm.name.trim(),
        email: this.userForm.email.trim(),
        cedula: this.userForm.cedula.trim(),
        role: this.userForm.role
      };

      this.userService.updateUser(payload).subscribe({
        next: () => {
          this.saving = false;
          this.successMessage = 'Usuario actualizado correctamente';
          this.closeUserModal();
          this.loadUsers();
        },
        error: (error: Error) => {
          this.saving = false;
          this.errorMessage = error.message || 'No se pudo actualizar el usuario';
        }
      });

      return;
    }

    const createPayload: CreateUserRequest = {
      name: this.userForm.name.trim(),
      email: this.userForm.email.trim(),
      cedula: this.userForm.cedula.trim(),
      role: this.userForm.role,
      password: this.userForm.password.trim()
    };

    this.userService.createUser(createPayload).subscribe({
      next: () => {
        this.saving = false;
        this.successMessage = 'Usuario creado correctamente';
        this.closeUserModal();
        this.loadUsers();
      },
      error: (error: Error) => {
        this.saving = false;
        this.errorMessage = error.message || 'No se pudo crear el usuario';
      }
    });
  }

  updatePassword(user: User): void {
    const newPassword = this.newPasswords[user.id]?.trim();

    if (!newPassword) {
      this.errorMessage = 'Debes escribir una nueva contraseña';
      return;
    }

    this.clearMessages();
    this.updatingPasswordUserId = user.id;

    this.userService.updatePassword(user.id, newPassword).subscribe({
      next: () => {
        this.updatingPasswordUserId = null;
        this.newPasswords[user.id] = '';
        this.successMessage = `Contraseña actualizada para ${user.name}`;
      },
      error: (error: Error) => {
        this.updatingPasswordUserId = null;
        this.errorMessage = error.message || 'No se pudo actualizar la contraseña';
      }
    });
  }

  trackByUserId(_index: number, user: User): string {
    return user.id;
  }

  isUpdatingPassword(userId: string): boolean {
    return this.updatingPasswordUserId === userId;
  }

  private getEmptyForm(): UserForm {
    return {
      id: null,
      name: '',
      email: '',
      cedula: '',
      role: UserRole.STUDENT,
      password: ''
    };
  }

  private clearMessages(): void {
    this.successMessage = '';
    this.errorMessage = '';
  }
}