import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router, RouterOutlet } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { User, UserRole } from '../../models/user.model';

/**
 * Tipo para definir cada opción del menú lateral.
 * Así evitamos usar objetos "sueltos" sin estructura.
 */
type NavItem = {
  label: string;
  route: string;
  icon: string;
  roles: UserRole[];
};

@Component({
  selector: 'app-layout',
  standalone: true,
  imports: [CommonModule, RouterModule, RouterOutlet],
  templateUrl: './app-layout.component.html',
  styleUrls: ['./app-layout.component.css']
})
export class AppLayoutComponent implements OnInit {
  /**
   * Usuario autenticado actual.
   * Lo obtenemos desde AuthService.
   */
  currentUser: User | null = null;

  /**
   * Lista de opciones del menú lateral.
   * Cada opción tiene:
   * - texto
   * - ruta
   * - icono
   * - roles permitidos
   */
  readonly navItems: NavItem[] = [
    {
      label: 'Dashboard',
      route: '/dashboard',
      icon: 'fas fa-house',
      roles: [UserRole.ADMIN, UserRole.TEACHER, UserRole.TUTOR, UserRole.STUDENT]
    },
    {
      label: 'Cursos',
      route: '/courses',
      icon: 'fas fa-book-open',
      roles: [UserRole.ADMIN, UserRole.TEACHER, UserRole.TUTOR, UserRole.STUDENT]
    },
    {
      label: 'Revisión',
      route: '/review',
      icon: 'fas fa-star',
      roles: [UserRole.ADMIN, UserRole.TEACHER, UserRole.TUTOR]
    },
    {
      label: 'Gestión de Usuarios',
      route: '/user-management',
      icon: 'fas fa-users-cog',
      roles: [UserRole.ADMIN]
    },
    {
      label: 'Gestión de Cursos',
      route: '/course-management',
      icon: 'fas fa-chalkboard-teacher',
      roles: [UserRole.ADMIN, UserRole.TEACHER]
    },
    {
      label: 'Gestión de Quizzes',
      route: '/quiz-management',
      icon: 'fas fa-circle-question',
      roles: [UserRole.ADMIN, UserRole.TEACHER, UserRole.TUTOR]
    },
    {
      label: 'Generador de Gradientes',
      route: '/gradient-generator',
      icon: 'fas fa-palette',
      roles: [UserRole.ADMIN, UserRole.TEACHER]
    },
    {
      label: 'Parámetros',
      route: '/parameters',
      icon: 'fas fa-sliders-h',
      roles: [UserRole.ADMIN]
    }
  ];

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  /**
   * Al iniciar el componente:
   * 1. cargamos el usuario actual
   * 2. si no existe, lo mandamos a login
   */
  ngOnInit(): void {
    this.currentUser = this.authService.getCurrentUser();

    if (!this.currentUser) {
      this.router.navigate(['/login']);
    }
  }

  /**
   * Devuelve solo los ítems del menú que el usuario actual puede ver.
   */
  get visibleNavItems(): NavItem[] {
    if (!this.currentUser) {
      return [];
    }

    return this.navItems.filter(item => item.roles.includes(this.currentUser!.role));
  }

  /**
   * Traduce el rol a un texto amigable para mostrarlo en pantalla.
   */
  get roleLabel(): string {
    switch (this.currentUser?.role) {
      case UserRole.ADMIN:
        return 'Administrador';
      case UserRole.TEACHER:
        return 'Profesor';
      case UserRole.TUTOR:
        return 'Tutor';
      case UserRole.STUDENT:
        return 'Estudiante';
      default:
        return 'Usuario';
    }
  }

  /**
   * Cierra sesión y regresa al login.
   */
  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}