import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { PlatformPermissionsService } from '../../services/platform-permissions.service';
import { AuthService } from '../../services/auth.service';
import { User, UserRole } from '../../models/user.model';
import { MenuModule, ModuleRole } from '../../models/platform-permission.model';

@Component({
  selector: 'app-module-permissions',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './module-permissions.component.html',
  styleUrls: ['./module-permissions.component.css']
})
export class ModulePermissionsComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  currentUser: User | null = null;
  modules: MenuModule[] = [];
  roles: ModuleRole[] = ['admin', 'teacher', 'tutor', 'student'];
  moduleStatuses: Map<string, { admin: boolean; teacher: boolean; tutor: boolean; student: boolean }> = new Map();
  
  loading = false;
  saving = false;
  successMessage = '';
  errorMessage = '';

  // Modal
  selectedModule: MenuModule | null = null;
  showModal = false;

  constructor(
    private permissionsService: PlatformPermissionsService,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.currentUser = this.authService.getCurrentUser();
    // Filtrar solo los 8 módulos principales (excluir el de permisos)
    this.modules = this.permissionsService.getMenuModules().filter(m => m.key !== 'menu_permissions');
    this.loadModuleStatuses();
    
    this.permissionsService.permissions$
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        this.loadModuleStatuses();
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadModuleStatuses(): void {
    this.modules.forEach(module => {
      this.moduleStatuses.set(module.key, this.permissionsService.getModuleStatus(module.key));
    });
  }

  getModuleStatus(moduleKey: string, role: ModuleRole): boolean {
    const status = this.moduleStatuses.get(moduleKey);
    return status ? status[role] : true;
  }

  async toggleModule(moduleKey: string, role: ModuleRole): Promise<void> {
    // Mostrar información del usuario en la interfaz
    const userInfo = document.getElementById('user-debug-info');
    if (userInfo) {
      userInfo.textContent = `Usuario: ${this.currentUser?.name || 'N/A'} | Rol: ${this.currentUser?.role || 'N/A'} | Es Admin: ${this.currentUser?.role === UserRole.ADMIN}`;
    }

    if (!this.currentUser) {
      this.errorMessage = '❌ No hay sesión activa';
      setTimeout(() => this.errorMessage = '', 5000);
      return;
    }

    if (this.currentUser.role !== UserRole.ADMIN) {
      this.errorMessage = `❌ Solo administradores pueden modificar permisos. Tu rol actual es: ${this.currentUser.role}`;
      setTimeout(() => this.errorMessage = '', 5000);
      return;
    }

    this.saving = true;
    const currentStatus = this.getModuleStatus(moduleKey, role);
    
    const success = await this.permissionsService.toggleModulePermission(
      moduleKey,
      role,
      !currentStatus
    );

    this.saving = false;

    if (success) {
      this.successMessage = '✅ Permiso actualizado correctamente';
      setTimeout(() => this.successMessage = '', 2000);
    } else {
      this.errorMessage = '❌ Error al actualizar el permiso. Verifica que eres administrador y que el módulo existe en la base de datos.';
      setTimeout(() => this.errorMessage = '', 5000);
    }
  }

  getRoleLabel(role: ModuleRole): string {
    return this.permissionsService.getRoleLabel(role);
  }

  getRoleStyle(role: ModuleRole): { icon: string; color: string } {
    return this.permissionsService.getRoleStyle(role);
  }

  getEnabledCount(moduleKey: string): number {
    const status = this.moduleStatuses.get(moduleKey);
    if (!status) return 0;
    return Object.values(status).filter(v => v).length;
  }

  openModuleDetails(module: MenuModule): void {
    this.selectedModule = module;
    this.showModal = true;
  }

  closeModal(): void {
    this.showModal = false;
    this.selectedModule = null;
  }

  isAdmin(): boolean {
    return this.currentUser?.role === UserRole.ADMIN;
  }
}
