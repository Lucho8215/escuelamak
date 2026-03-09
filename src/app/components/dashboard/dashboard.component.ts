import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { User, UserRole } from '../../models/user.model';

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
  currentUser: User | null = null;

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
    public authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.currentUser = this.authService.getCurrentUser();
      if (!this.currentUser) {
    this.router.navigate(['/login']);
   }
  }
  get roleLabel(): string {
    if (!this.currentUser) {
      return 'Usuario';
    }

    return this.roleConfig[this.currentUser.role]?.label ?? 'Usuario';
  }

  get roleIcon(): string {
    if (!this.currentUser) {
      return 'fa-user';
    }

    return this.roleConfig[this.currentUser.role]?.icon ?? 'fa-user';
  }

  get roleClass(): string {
    if (!this.currentUser) {
      return 'student';
    }

    return this.roleConfig[this.currentUser.role]?.className ?? 'student';
  }

  canManageCourses(): boolean {
    return (
      this.authService.hasPermission('create_courses') ||
      this.authService.hasPermission('edit_courses')
    );
  }
  canManageUsers(): boolean {
  return this.currentUser?.role === UserRole.ADMIN;
}

canViewCourses(): boolean {
  return this.authService.hasPermission('view_courses');
}

canReviewExercises(): boolean {
  return this.authService.hasPermission('review_exercises');
}

canManageQuizzes(): boolean {
  return this.authService.hasPermission('create_quizzes');
}

canManageParameters(): boolean {
  return this.authService.hasPermission('manage_permissions');
}
isRole(role: UserRole): boolean {
  return this.currentUser?.role === role;
}
  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}