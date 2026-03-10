import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { User, UserRole } from '../../models/user.model';

/**
 * Configuración visual y descriptiva por rol.
 * Aquí centralizamos:
 * - etiqueta amigable
 * - icono
 * - clase CSS
 * - descripción principal del dashboard
 */
type RoleConfig = {
  label: string;
  icon: string;
  className: string;
  description: string;
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
   * Usuario autenticado actual.
   */
  currentUser: User | null = null;

  /**
   * Configuración central por rol.
   * Esto evita repetir lógica en distintos métodos.
   */
  private readonly roleConfig: Record<UserRole, RoleConfig> = {
    [UserRole.ADMIN]: {
      label: 'Administrador',
      icon: 'fa-crown',
      className: 'admin',
      description: 'Administra usuarios, cursos, quizzes y la configuración general de la plataforma.'
    },
    [UserRole.TEACHER]: {
      label: 'Profesor',
      icon: 'fa-chalkboard-teacher',
      className: 'teacher',
      description: 'Gestiona cursos, clases y cuestionarios para acompañar el aprendizaje.'
    },
    [UserRole.TUTOR]: {
      label: 'Tutor',
      icon: 'fa-user-tie',
      className: 'tutor',
      description: 'Revisa actividades, apoya el seguimiento y participa en la gestión de quizzes.'
    },
    [UserRole.STUDENT]: {
      label: 'Estudiante',
      icon: 'fa-graduation-cap',
      className: 'student',
      description: 'Accede a tus cursos, realiza actividades y continúa tu aprendizaje.'
    }
  };

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  /**
   * Al iniciar el componente:
   * 1. obtenemos el usuario actual
   * 2. si no existe, volvemos al login
   */
  ngOnInit(): void {
    this.currentUser = this.authService.getCurrentUser();

    if (!this.currentUser) {
      this.router.navigate(['/login']);
    }
  }

  /**
   * Etiqueta legible del rol.
   */
  get roleLabel(): string {
    if (!this.currentUser) {
      return 'Usuario';
    }

    return this.roleConfig[this.currentUser.role]?.label ?? 'Usuario';
  }

  /**
   * Icono asociado al rol.
   */
  get roleIcon(): string {
    if (!this.currentUser) {
      return 'fa-user';
    }

    return this.roleConfig[this.currentUser.role]?.icon ?? 'fa-user';
  }

  /**
   * Clase CSS asociada al rol.
   */
  get roleClass(): string {
    if (!this.currentUser) {
      return 'student';
    }

    return this.roleConfig[this.currentUser.role]?.className ?? 'student';
  }

  /**
   * Descripción principal del dashboard según rol.
   */
  get roleDescription(): string {
    if (!this.currentUser) {
      return 'Bienvenido a la plataforma.';
    }

    return this.roleConfig[this.currentUser.role]?.description ?? 'Bienvenido a la plataforma.';
  }

  /**
   * Título secundario del panel.
   */
  get dashboardTitle(): string {
    return 'Accesos disponibles';
  }

  /**
   * Solo el admin puede gestionar usuarios.
   */
  canManageUsers(): boolean {
    return this.currentUser?.role === UserRole.ADMIN;
  }

  /**
   * Ver cursos.
   */
  canViewCourses(): boolean {
    return this.authService.hasPermission('view_courses');
  }

  /**
   * Revisar ejercicios.
   */
  canReviewExercises(): boolean {
    return this.authService.hasPermission('review_exercises');
  }

  /**
   * Gestionar quizzes.
   */
  canManageQuizzes(): boolean {
    return (
      this.authService.hasPermission('create_quizzes') ||
      this.authService.hasPermission('edit_quizzes')
    );
  }

  /**
   * Gestionar cursos.
   */
  canManageCourses(): boolean {
    return (
      this.authService.hasPermission('create_courses') ||
      this.authService.hasPermission('edit_courses')
    );
  }

  /**
   * Entrar a parámetros.
   */
  canManageParameters(): boolean {
    return this.authService.hasPermission('manage_permissions');
  }
}