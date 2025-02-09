import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { Role, AVAILABLE_PERMISSIONS } from '../models/role.model';

@Injectable({
  providedIn: 'root'
})
export class RoleService {
  private roles: Role[] = [
    {
      id: '1',
      name: 'Administrador',
      description: 'Control total del sistema',
      permissions: ['manage_users', 'review_exercises', 'view_courses', 'manage_permissions']
    },
    {
      id: '2',
      name: 'Profesor',
      description: 'Gestión de cursos y estudiantes',
      permissions: ['view_courses', 'review_exercises']
    },
    {
      id: '3',
      name: 'Tutor',
      description: 'Revisión de ejercicios',
      permissions: ['review_exercises', 'view_courses']
    },
    {
      id: '4',
      name: 'Estudiante',
      description: 'Acceso a cursos y ejercicios',
      permissions: ['view_courses']
    }
  ];

  getRoles(): Observable<Role[]> {
    return of(this.roles);
  }

  updateRolePermissions(roleId: string, permissions: string[]): Observable<Role> {
    const role = this.roles.find(r => r.id === roleId);
    if (role) {
      role.permissions = permissions;
    }
    return of(role!);
  }

  getAvailablePermissions() {
    return of(AVAILABLE_PERMISSIONS);
  }
}