import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { User, UserRole } from '../../models/user.model';

/**
 * Configuración visual por rol.
 * Esto nos permite centralizar:
 * - etiqueta del rol
 * - icono
 * - clase CSS asociada
 */
type RoleConfig = {
  label: string;
  icon: string;
  className: string;
};

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit {
  /**
   * Usuario actual que inició sesión.
   */
  currentUser: User | null = null;

  /**
   * Configuración visual de cada rol.
   */
  private readonly roleConfig: Record<UserRole, RoleConfig> = {
    [UserRole.ADMIN]: {
      label: 'Administrador',
      icon: 'fa-crown',
      className: 'admin'
    },
    [UserRole.TEACHER]: {
      label: 'Profesor',
      icon: 'fa-chalkboard-teacher',
      className: 'teacher'
    },
    [UserRole.TUTOR]: {
      label: 'Tutor',
      icon: 'fa-user-tie',
      className: 'tutor'
    },
    [UserRole.STUDENT]: {
      label: 'Alumno',
      icon: 'fa-graduation-cap',
      className: 'student'
    }
  };

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  /**
   * Al iniciar:
   * 1. obtenemos el usuario actual
   * 2. si no hay usuario, lo mandamos a login
   */
  ngOnInit(): void {
    this.currentUser = this.authService.getCurrentUser();

    if (!this.currentUser) {
      this.router.navigate(['/login']);
    }
  }

  /**
   * Devuelve la etiqueta legible del rol actual.
   */
  get roleLabel(): string {
    if (!this.currentUser) {
      return 'Usuario';
    }

    return this.roleConfig[this.currentUser.role]?.label ?? 'Usuario';
  }

  /**
   * Devuelve el icono del rol actual.
   */
  get roleIcon(): string {
    if (!this.currentUser) {
      return 'fa-user';
    }

    return this.roleConfig[this.currentUser.role]?.icon ?? 'fa-user';
  }

  /**
   * Devuelve la clase CSS según rol.
   */
  get roleClass(): string {
    if (!this.currentUser) {
      return 'student';
    }

    return this.roleConfig[this.currentUser.role]?.className ?? 'student';
  }

  /**
   * Permite saber si el usuario puede administrar usuarios.
   * Solo el admin puede hacerlo.
   */
  canManageUsers(): boolean {
    return this.currentUser?.role === UserRole.ADMIN;
  }

  /**
   * Permite saber si el usuario puede ver cursos.
   */
  canViewCourses(): boolean {
    return this.authService.hasPermission('view_courses');
  }

  /**
   * Permite saber si el usuario puede revisar ejercicios.
   */
  canReviewExercises(): boolean {
    return this.authService.hasPermission('review_exercises');
  }

  /**
   * Permite gestionar quizzes.
   */
  canManageQuizzes(): boolean {
    return (
      this.authService.hasPermission('create_quizzes') ||
      this.authService.hasPermission('edit_quizzes')
    );
  }

  /**
   * Permite gestionar cursos.
   */
  canManageCourses(): boolean {
    return (
      this.authService.hasPermission('create_courses') ||
      this.authService.hasPermission('edit_courses')
    );
  }

  /**
   * Permite entrar al módulo de parámetros.
   */
  canManageParameters(): boolean {
    return this.authService.hasPermission('manage_permissions');
  }
}