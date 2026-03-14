import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { SupabaseService } from '../../services/supabase.service';

interface AppUser {
  id: string;
  name: string;
  email: string;
  role: string;
  created_at?: string;
  password_hash?: string;
}

interface PermissionCard {
  id: string;
  title: string;
  description: string;
  icon: string;
  color: string;
  roles: string[];
  enabled: boolean;
  category: string;
}

interface PlatformPermission {
  id: string;
  key: string;
  name: string;
  description: string;
  category: string;
  admin_enabled: boolean;
  teacher_enabled: boolean;
  tutor_enabled: boolean;
  student_enabled: boolean;
}

interface SchoolConfig {
  id: string;
  school_name: string;
  school_description: string;
  school_logo_url: string;
  school_address: string;
  school_phone: string;
  school_email: string;
  primary_color: string;
  secondary_color: string;
  accent_color: string;
  background_color: string;
  active_theme: string;
}

interface PlatformMetric {
  id: string;
  metric_key: string;
  metric_name: string;
  metric_value: string;
  metric_type: string;
  is_visible: boolean;
  display_order: number;
}

interface ThemeOption {
  id: string;
  name: string;
  primary: string;
  secondary: string;
  accent: string;
  bg: string;
  preview: string[];
}

interface CourseOption {
  id: string;
  title: string;
}

interface ClassItem {
  id: string;
  name?: string;
  title?: string;
  status: string;
  course_id?: string | null;
  max_students?: number;
  enrollment_count?: number;
  start_date?: string | null;
  end_date?: string | null;
}

interface UserForm {
  name: string;
  email: string;
  role: string;
  password: string;
}

interface ClassForm {
  name: string;
  course_id: string;
  status: string;
  max_students: number;
  start_date: string;
  end_date: string;
}

interface SchoolForm {
  school_name: string;
  school_description: string;
  school_logo_url: string;
  school_address: string;
  school_phone: string;
  school_email: string;
  primary_color: string;
  secondary_color: string;
  accent_color: string;
  background_color: string;
}

interface MetricForm {
  metric_key: string;
  metric_name: string;
  metric_value: string;
  metric_type: string;
  is_visible: boolean;
  display_order: number;
}

interface DeleteConfirm {
  type: string;
  id: string;
  name: string;
}

@Component({
  selector: 'app-parameters',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './parameters.component.html',
  styleUrls: ['./parameters.component.css']
})
export class ParametersComponent implements OnInit {
  activeSection = 'users';
  loading = false;
  successMsg = '';
  errorMsg = '';

  // Datos de usuarios
  users: AppUser[] = [];
  filteredUsers: AppUser[] = [];
  searchUser = '';
  filterRole = '';
  showUserModal = false;
  editingUser: AppUser | null = null;
  userForm: UserForm = this.emptyUserForm();
  userFormErrors: Record<string, string> = {};

  // Datos de clases
  classes: ClassItem[] = [];
  filteredClasses: ClassItem[] = [];
  searchClass = '';
  showClassModal = false;
  editingClass: ClassItem | null = null;
  classForm: ClassForm = this.emptyClassForm();

  courses: CourseOption[] = [];

  // Configuración de temas
  selectedTheme = 'default';
  themes: ThemeOption[] = [
    { id: 'default', name: 'Arcoíris Mágico', primary: '#667eea', secondary: '#764ba2', accent: '#f093fb', bg: '#f0f2ff', preview: ['#667eea', '#764ba2', '#f093fb', '#4facfe'] },
    { id: 'ocean', name: 'Océano Profundo', primary: '#0093E9', secondary: '#80D0C7', accent: '#00f5d4', bg: '#e8f8ff', preview: ['#0093E9', '#80D0C7', '#00f5d4', '#43e97b'] },
    { id: 'sunset', name: 'Atardecer Tropical', primary: '#f7971e', secondary: '#ffd200', accent: '#ff6b6b', bg: '#fff8e7', preview: ['#f7971e', '#ffd200', '#ff6b6b', '#ff9a9e'] },
    { id: 'forest', name: 'Bosque Encantado', primary: '#11998e', secondary: '#38ef7d', accent: '#56ab2f', bg: '#efffef', preview: ['#11998e', '#38ef7d', '#56ab2f', '#a8ff78'] },
    { id: 'galaxy', name: 'Galaxia Espacial', primary: '#2c3e50', secondary: '#4ca1af', accent: '#c0392b', bg: '#f0f4f8', preview: ['#2c3e50', '#4ca1af', '#c0392b', '#8e44ad'] },
    { id: 'candy', name: 'Dulcería Feliz', primary: '#ff758c', secondary: '#ff7eb3', accent: '#ffd6e0', bg: '#fff0f5', preview: ['#ff758c', '#ff7eb3', '#a78bfa', '#fbbf24'] }
  ];

  // Permisos de tarjetas (locales)
  permissionCards: PermissionCard[] = [
    { id: 'card_courses', title: 'Ver Cursos', description: 'Acceso a la lista de cursos disponibles', icon: 'fas fa-book-open', color: '#667eea', roles: ['admin', 'teacher', 'tutor', 'student'], enabled: true, category: 'Contenido' },
    { id: 'card_classes', title: 'Gestión de Clases', description: 'Crear, editar y eliminar clases', icon: 'fas fa-chalkboard-teacher', color: '#f7971e', roles: ['admin', 'teacher'], enabled: true, category: 'Gestión' },
    { id: 'card_quiz', title: 'Quizzes', description: 'Crear y gestionar evaluaciones', icon: 'fas fa-brain', color: '#11998e', roles: ['admin', 'teacher'], enabled: true, category: 'Evaluación' },
    { id: 'card_takequiz', title: 'Tomar Quiz', description: 'Resolver evaluaciones y quizzes', icon: 'fas fa-pencil-alt', color: '#ff758c', roles: ['admin', 'teacher', 'tutor', 'student'], enabled: true, category: 'Evaluación' },
    { id: 'card_reports', title: 'Informes', description: 'Ver reportes y estadísticas de alumnos', icon: 'fas fa-chart-bar', color: '#4ca1af', roles: ['admin', 'tutor'], enabled: true, category: 'Informes' },
    { id: 'card_users', title: 'Gestión Usuarios', description: 'Administrar cuentas de usuarios', icon: 'fas fa-users-cog', color: '#764ba2', roles: ['admin'], enabled: true, category: 'Administración' },
    { id: 'card_settings', title: 'Parámetros', description: 'Configurar parámetros del sistema', icon: 'fas fa-sliders-h', color: '#2c3e50', roles: ['admin'], enabled: true, category: 'Administración' },
    { id: 'card_lessons', title: 'Lecciones', description: 'Ver y completar lecciones asignadas', icon: 'fas fa-graduation-cap', color: '#56ab2f', roles: ['admin', 'teacher', 'tutor', 'student'], enabled: true, category: 'Contenido' },
    { id: 'card_review', title: 'Practicar', description: 'Área de práctica y ejercicios', icon: 'fas fa-star', color: '#ffd200', roles: ['admin', 'teacher', 'tutor', 'student'], enabled: true, category: 'Contenido' }
  ];

  // Permisos desde Supabase (backend)
  platformPermissions: PlatformPermission[] = [];
  
  // Configuración de la escuela
  schoolConfig: SchoolConfig | null = null;
  showSchoolModal = false;
  schoolForm: SchoolForm = this.emptySchoolForm();
  
  // Métricas
  platformMetrics: PlatformMetric[] = [];
  showMetricModal = false;
  editingMetric: PlatformMetric | null = null;
  metricForm: MetricForm = this.emptyMetricForm();
  
  // Upload
  uploadingFile = false;
  uploadedFileUrl = '';

  filterCardCategory = 'all';
  filterCardRole = 'all';
  cardCategories: string[] = [];
  roles = ['admin', 'teacher', 'tutor', 'student'];
  deleteConfirm: DeleteConfirm | null = null;

  constructor(private supabaseService: SupabaseService) {}

  ngOnInit(): void {
    const saved = localStorage.getItem('app_theme');

    if (saved) {
      this.selectedTheme = saved;
    }

    this.applyTheme(this.selectedTheme);
    this.cardCategories = [...new Set(this.permissionCards.map(card => card.category))];

    this.loadPermissions();
    this.loadUsers();
    this.loadCourses();
    this.loadClasses();
    this.loadPlatformPermissions();
    this.loadSchoolConfig();
    this.loadMetrics();
  }

  // ─── CARGAR PERMISOS DESDE SUPABASE ───────────────────────
  async loadPlatformPermissions(): Promise<void> {
    try {
      const { data, error } = await this.supabase
        .from('platform_permissions')
        .select('*')
        .order('category');

      if (error) {
        console.log('Error cargando permisos (tabla puede no existir):', error);
        return;
      }

      this.platformPermissions = (data ?? []) as PlatformPermission[];
    } catch (e) {
      console.log('Error cargando permisos:', e);
    }
  }

  // ─── GUARDAR PERMISO ─────────────────────────────────────
  async savePermission(perm: PlatformPermission): Promise<void> {
    this.loading = true;
    try {
      const { error } = await this.supabase
        .from('platform_permissions')
        .update({
          admin_enabled: perm.admin_enabled,
          teacher_enabled: perm.teacher_enabled,
          tutor_enabled: perm.tutor_enabled,
          student_enabled: perm.student_enabled,
          updated_at: new Date().toISOString()
        })
        .eq('id', perm.id);

      if (error) throw error;
      this.showSuccess('✅ Permiso actualizado');
    } catch (e: unknown) {
      this.showError('Error guardando permiso: ' + this.getErrorMessage(e));
    } finally {
      this.loading = false;
    }
  }

  // ─── CARGAR CONFIGURACIÓN DE LA ESCUELA ──────────────────
  async loadSchoolConfig(): Promise<void> {
    try {
      const { data, error } = await this.supabase
        .from('school_config')
        .select('*')
        .limit(1)
        .single();

      if (error) {
        console.log('Error cargando config (tabla puede no existir):', error);
        return;
      }

      this.schoolConfig = data as SchoolConfig;
      this.applySchoolColors();
    } catch (e) {
      console.log('Error cargando config:', e);
    }
  }

  applySchoolColors(): void {
    if (!this.schoolConfig) return;
    
    document.documentElement.style.setProperty('--color-primary', this.schoolConfig.primary_color);
    document.documentElement.style.setProperty('--color-secondary', this.schoolConfig.secondary_color);
    document.documentElement.style.setProperty('--color-accent', this.schoolConfig.accent_color);
    document.documentElement.style.setProperty('--color-bg', this.schoolConfig.background_color);
  }

  // ─── ABRIR MODAL ESCUELA ─────────────────────────────────
  openSchoolModal(): void {
    if (this.schoolConfig) {
      this.schoolForm = {
        school_name: this.schoolConfig.school_name,
        school_description: this.schoolConfig.school_description || '',
        school_logo_url: this.schoolConfig.school_logo_url || '',
        school_address: this.schoolConfig.school_address || '',
        school_phone: this.schoolConfig.school_phone || '',
        school_email: this.schoolConfig.school_email || '',
        primary_color: this.schoolConfig.primary_color,
        secondary_color: this.schoolConfig.secondary_color,
        accent_color: this.schoolConfig.accent_color,
        background_color: this.schoolConfig.background_color
      };
    } else {
      this.schoolForm = this.emptySchoolForm();
    }
    this.showSchoolModal = true;
  }

  closeSchoolModal(): void {
    this.showSchoolModal = false;
  }

  // ─── GUARDAR CONFIGURACIÓN ESCUELA ───────────────────────
  async saveSchoolConfig(): Promise<void> {
    if (!this.schoolForm.school_name.trim()) {
      this.showError('El nombre de la escuela es requerido');
      return;
    }

    this.loading = true;
    try {
      const payload = {
        school_name: this.schoolForm.school_name,
        school_description: this.schoolForm.school_description,
        school_logo_url: this.schoolForm.school_logo_url,
        school_address: this.schoolForm.school_address,
        school_phone: this.schoolForm.school_phone,
        school_email: this.schoolForm.school_email,
        primary_color: this.schoolForm.primary_color,
        secondary_color: this.schoolForm.secondary_color,
        accent_color: this.schoolForm.accent_color,
        background_color: this.schoolForm.background_color,
        updated_at: new Date().toISOString()
      };

      if (this.schoolConfig) {
        const { error } = await this.supabase
          .from('school_config')
          .update(payload)
          .eq('id', this.schoolConfig.id);

        if (error) throw error;
      } else {
        const { error } = await this.supabase
          .from('school_config')
          .insert([payload]);

        if (error) throw error;
      }

      this.showSuccess('✅ Configuración de escuela guardada');
      this.closeSchoolModal();
      await this.loadSchoolConfig();
    } catch (e: unknown) {
      this.showError('Error guardando: ' + this.getErrorMessage(e));
    } finally {
      this.loading = false;
    }
  }

  // ─── CARGAR MÉTRICAS ─────────────────────────────────────
  async loadMetrics(): Promise<void> {
    try {
      const { data, error } = await this.supabase
        .from('platform_metrics')
        .select('*')
        .order('display_order');

      if (error) {
        console.log('Error cargando métricas (tabla puede no existir):', error);
        return;
      }

      this.platformMetrics = (data ?? []) as PlatformMetric[];
    } catch (e) {
      console.log('Error cargando métricas:', e);
    }
  }

  // ─── ABRIR MODAL MÉTRICA ─────────────────────────────────
  openMetricModal(metric?: PlatformMetric): void {
    if (metric) {
      this.editingMetric = metric;
      this.metricForm = {
        metric_key: metric.metric_key,
        metric_name: metric.metric_name,
        metric_value: metric.metric_value || '',
        metric_type: metric.metric_type,
        is_visible: metric.is_visible,
        display_order: metric.display_order
      };
    } else {
      this.editingMetric = null;
      this.metricForm = this.emptyMetricForm();
    }
    this.showMetricModal = true;
  }

  closeMetricModal(): void {
    this.showMetricModal = false;
    this.editingMetric = null;
  }

  // ─── GUARDAR MÉTRICA ─────────────────────────────────────
  async saveMetric(): Promise<void> {
    if (!this.metricForm.metric_name.trim() || !this.metricForm.metric_key.trim()) {
      this.showError('El nombre y clave de la métrica son requeridos');
      return;
    }

    this.loading = true;
    try {
      const payload = {
        metric_key: this.metricForm.metric_key,
        metric_name: this.metricForm.metric_name,
        metric_value: this.metricForm.metric_value,
        metric_type: this.metricForm.metric_type,
        is_visible: this.metricForm.is_visible,
        display_order: this.metricForm.display_order,
        updated_at: new Date().toISOString()
      };

      if (this.editingMetric) {
        const { error } = await this.supabase
          .from('platform_metrics')
          .update(payload)
          .eq('id', this.editingMetric.id);

        if (error) throw error;
        this.showSuccess('✅ Métrica actualizada');
      } else {
        const { error } = await this.supabase
          .from('platform_metrics')
          .insert([payload]);

        if (error) throw error;
        this.showSuccess('✅ Métrica creada');
      }

      this.closeMetricModal();
      await this.loadMetrics();
    } catch (e: unknown) {
      this.showError('Error guardando: ' + this.getErrorMessage(e));
    } finally {
      this.loading = false;
    }
  }

  // ─── ELIMINAR MÉTRICA ────────────────────────────────────
  async deleteMetric(id: string): Promise<void> {
    if (!confirm('¿Estás seguro de eliminar esta métrica?')) return;

    this.loading = true;
    try {
      const { error } = await this.supabase
        .from('platform_metrics')
        .delete()
        .eq('id', id);

      if (error) throw error;
      this.showSuccess('✅ Métrica eliminada');
      await this.loadMetrics();
    } catch (e: unknown) {
      this.showError('Error eliminando: ' + this.getErrorMessage(e));
    } finally {
      this.loading = false;
    }
  }

  // ─── SUBIR ARCHIVO ────────────────────────────────────────
  async uploadFile(event: Event): Promise<void> {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const file = input.files[0];
    this.uploadingFile = true;

    try {
      const fileName = `${Date.now()}_${file.name}`;
      const { data, error } = await this.supabase.storage
        .from('files')
        .upload(fileName, file);

      if (error) throw error;

      const { data: urlData } = this.supabase.storage
        .from('files')
        .getPublicUrl(fileName);

      this.uploadedFileUrl = urlData.publicUrl;
      this.schoolForm.school_logo_url = this.uploadedFileUrl;
      this.showSuccess('✅ Archivo subido correctamente');
    } catch (e: unknown) {
      this.showError('Error subiendo archivo: ' + this.getErrorMessage(e));
    } finally {
      this.uploadingFile = false;
    }
  }

  // ─── HELPERS DE MÉTRICAS ────────────────────────────────
  getMetricIcon(type: string): string {
    const icons: Record<string, string> = {
      number: 'fas fa-hashtag',
      percentage: 'fas fa-percent',
      text: 'fas fa-font',
      currency: 'fas fa-dollar-sign',
      date: 'fas fa-calendar'
    };
    return icons[type] || 'fas fa-chart-bar';
  }

  async toggleMetricVisibility(metric: PlatformMetric): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('platform_metrics')
        .update({ is_visible: !metric.is_visible, updated_at: new Date().toISOString() })
        .eq('id', metric.id);

      if (error) throw error;
      await this.loadMetrics();
    } catch (e: unknown) {
      this.showError('Error actualizando métrica: ' + this.getErrorMessage(e));
    }
  }

  private get supabase() {
    return this.supabaseService.getClient();
  }

  setSection(section: string): void {
    this.activeSection = section;
    this.clearMessages();
  }

  clearMessages(): void {
    this.successMsg = '';
    this.errorMsg = '';
  }

  showSuccess(message: string): void {
    this.successMsg = message;
    this.errorMsg = '';
    setTimeout(() => {
      this.successMsg = '';
    }, 3500);
  }

  showError(message: string): void {
    this.errorMsg = message;
    this.successMsg = '';
    setTimeout(() => {
      this.errorMsg = '';
    }, 4000);
  }

  emptyUserForm(): UserForm {
    return {
      name: '',
      email: '',
      role: 'student',
      password: ''
    };
  }

  emptySchoolForm(): SchoolForm {
    return {
      school_name: '',
      school_description: '',
      school_logo_url: '',
      school_address: '',
      school_phone: '',
      school_email: '',
      primary_color: '#667eea',
      secondary_color: '#764ba2',
      accent_color: '#f093fb',
      background_color: '#f0f2ff'
    };
  }

  emptyMetricForm(): MetricForm {
    return {
      metric_key: '',
      metric_name: '',
      metric_value: '',
      metric_type: 'text',
      is_visible: true,
      display_order: 0
    };
  }

  async loadUsers(): Promise<void> {
    this.loading = true;

    try {
      const { data, error } = await this.supabase
        .from('app_users')
        .select('id,name,email,role,created_at')
        .order('name');

      if (error) {
        throw error;
      }

      this.users = (data ?? []) as AppUser[];
      this.applyUserFilters();
    } catch (e: unknown) {
      this.showError('Error cargando usuarios: ' + this.getErrorMessage(e));
    } finally {
      this.loading = false;
    }
  }

  applyUserFilters(): void {
    this.filteredUsers = this.users.filter(user => {
      const matchesSearch =
        !this.searchUser ||
        user.name.toLowerCase().includes(this.searchUser.toLowerCase()) ||
        user.email.toLowerCase().includes(this.searchUser.toLowerCase());

      const matchesRole = !this.filterRole || this.normalizeRole(user.role) === this.filterRole;

      return matchesSearch && matchesRole;
    });
  }

  openCreateUser(): void {
    this.editingUser = null;
    this.userForm = this.emptyUserForm();
    this.userFormErrors = {};
    this.showUserModal = true;
  }

  openEditUser(user: AppUser): void {
    this.editingUser = { ...user };
    this.userForm = {
      name: user.name,
      email: user.email,
      role: this.normalizeRole(user.role),
      password: ''
    };
    this.userFormErrors = {};
    this.showUserModal = true;
  }

  closeUserModal(): void {
    this.showUserModal = false;
    this.editingUser = null;
    this.userFormErrors = {};
  }

  validateUserForm(): boolean {
    this.userFormErrors = {};

    if (!this.userForm.name.trim()) {
      this.userFormErrors['name'] = 'El nombre es requerido';
    }

    if (!this.userForm.email.trim()) {
      this.userFormErrors['email'] = 'El email es requerido';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.userForm.email)) {
      this.userFormErrors['email'] = 'Email inválido';
    }

    if (!this.editingUser && !this.userForm.password.trim()) {
      this.userFormErrors['password'] = 'La contraseña es requerida';
    }

    if (!this.userForm.role) {
      this.userFormErrors['role'] = 'El rol es requerido';
    }

    return Object.keys(this.userFormErrors).length === 0;
  }

  async saveUser(): Promise<void> {
    if (!this.validateUserForm()) {
      return;
    }

    this.loading = true;

    try {
      const payload = {
        name: this.userForm.name,
        email: this.userForm.email,
        role: this.normalizeRole(this.userForm.role)
      };

      if (this.editingUser) {
        const { error } = await this.supabase
          .from('app_users')
          .update(payload)
          .eq('id', this.editingUser.id);

        if (error) {
          throw error;
        }

        this.showSuccess(`✅ Usuario "${this.userForm.name}" actualizado`);
      } else {
        const { error } = await this.supabase
          .from('app_users')
          .insert([payload]);

        if (error) {
          throw error;
        }

        this.showSuccess(`✅ Usuario "${this.userForm.name}" creado`);
      }

      this.closeUserModal();
      await this.loadUsers();
    } catch (e: unknown) {
      this.showError('Error guardando: ' + this.getErrorMessage(e));
    } finally {
      this.loading = false;
    }
  }

   confirmDelete(type: string, id: string, name?: string | null): void {
    this.deleteConfirm = {
      type,
      id,
      name: name ?? 'Sin nombre'
    };
  }

  cancelDelete(): void {
    this.deleteConfirm = null;
  }

  async executeDelete(): Promise<void> {
    if (!this.deleteConfirm) {
      return;
    }

    this.loading = true;

    try {
      const table = this.deleteConfirm.type === 'user' ? 'app_users' : 'classes';
      const { error } = await this.supabase.from(table).delete().eq('id', this.deleteConfirm.id);

      if (error) {
        throw error;
      }

      this.showSuccess(`✅ "${this.deleteConfirm.name}" eliminado`);

      if (this.deleteConfirm.type === 'user') {
        await this.loadUsers();
      } else {
        await this.loadClasses();
      }
    } catch (e: unknown) {
      this.showError('Error eliminando: ' + this.getErrorMessage(e));
    } finally {
      this.loading = false;
      this.deleteConfirm = null;
    }
  }

  getRoleBadgeClass(role: string): string {
    const normalizedRole = this.normalizeRole(role);

    const map: Record<string, string> = {
      admin: 'badge-admin',
      teacher: 'badge-teacher',
      tutor: 'badge-tutor',
      student: 'badge-student'
    };

    return map[normalizedRole] || 'badge-default';
  }

  getRoleIcon(role: string): string {
    const normalizedRole = this.normalizeRole(role);

    const map: Record<string, string> = {
      admin: 'fas fa-crown',
      teacher: 'fas fa-chalkboard-teacher',
      tutor: 'fas fa-user-tie',
      student: 'fas fa-user-graduate'
    };

    return map[normalizedRole] || 'fas fa-user';
  }

  getUserCountByRole(role: string): number {
    const normalizedRole = this.normalizeRole(role);
    return this.users.filter(user => this.normalizeRole(user.role) === normalizedRole).length;
  }

  emptyClassForm(): ClassForm {
    return {
      name: '',
      course_id: '',
      status: 'open',
      max_students: 30,
      start_date: '',
      end_date: ''
    };
  }

  async loadCourses(): Promise<void> {
    const { data } = await this.supabase
      .from('courses')
      .select('id,title')
      .order('title');

    this.courses = (data ?? []) as CourseOption[];
  }

  async loadClasses(): Promise<void> {
    this.loading = true;

    try {
      const { data, error } = await this.supabase
        .from('classes')
        .select('id,name,title,status,course_id,max_students,enrollment_count,start_date,end_date')
        .order('created_at', { ascending: false });

      if (error) {
        throw error;
      }

      this.classes = (data ?? []) as ClassItem[];
      this.applyClassFilters();
    } catch (e: unknown) {
      this.showError('Error cargando clases: ' + this.getErrorMessage(e));
    } finally {
      this.loading = false;
    }
  }

  applyClassFilters(): void {
    this.filteredClasses = this.classes.filter(item => {
      const text = (item.name || item.title || '').toLowerCase();
      return !this.searchClass || text.includes(this.searchClass.toLowerCase());
    });
  }

  openCreateClass(): void {
    this.editingClass = null;
    this.classForm = this.emptyClassForm();
    this.showClassModal = true;
  }

  openEditClass(cls: ClassItem): void {
    this.editingClass = { ...cls };
    this.classForm = {
      name: cls.name || cls.title || '',
      course_id: cls.course_id || '',
      status: cls.status || 'open',
      max_students: cls.max_students || 30,
      start_date: cls.start_date || '',
      end_date: cls.end_date || ''
    };
    this.showClassModal = true;
  }

  closeClassModal(): void {
    this.showClassModal = false;
    this.editingClass = null;
  }

  async saveClass(): Promise<void> {
    if (!this.classForm.name.trim()) {
      this.showError('El nombre es requerido');
      return;
    }

    this.loading = true;

    try {
      const payload = {
        name: this.classForm.name,
        title: this.classForm.name,
        course_id: this.classForm.course_id || null,
        status: this.classForm.status,
        max_students: this.classForm.max_students || 30,
        start_date: this.classForm.start_date || null,
        end_date: this.classForm.end_date || null
      };

      if (this.editingClass) {
        const { error } = await this.supabase
          .from('classes')
          .update(payload)
          .eq('id', this.editingClass.id);

        if (error) {
          throw error;
        }

        this.showSuccess(`✅ Clase "${payload.name}" actualizada`);
      } else {
        const { error } = await this.supabase
          .from('classes')
          .insert([payload]);

        if (error) {
          throw error;
        }

        this.showSuccess(`✅ Clase "${payload.name}" creada`);
      }

      this.closeClassModal();
      await this.loadClasses();
    } catch (e: unknown) {
      this.showError('Error guardando clase: ' + this.getErrorMessage(e));
    } finally {
      this.loading = false;
    }
  }

  getCourseTitle(courseId?: string | null): string {
    if (!courseId) {
      return '—';
    }

    return this.courses.find(course => course.id === courseId)?.title || '—';
  }
  getClassStatusLabel(status: string): string {
    const map: Record<string, string> = {
      open: 'Abierta',
      closed: 'Cerrada',
      active: 'Activa',
      inactive: 'Inactiva'
    };

    return map[status] || status;
  }

  selectTheme(id: string): void {
    this.selectedTheme = id;
    localStorage.setItem('app_theme', id);
    this.applyTheme(id);
    this.showSuccess('✅ Tema aplicado');
  }

  applyTheme(id: string): void {
    const theme = this.themes.find(item => item.id === id);

    if (!theme) {
      return;
    }

    document.documentElement.style.setProperty('--color-primary', theme.primary);
    document.documentElement.style.setProperty('--color-secondary', theme.secondary);
    document.documentElement.style.setProperty('--color-accent', theme.accent);
    document.documentElement.style.setProperty('--color-bg', theme.bg);
  }

  getTheme(id: string): ThemeOption | undefined {
    return this.themes.find(theme => theme.id === id);
  }

  get filteredCards(): PermissionCard[] {
    return this.permissionCards.filter(card => {
      const matchesCategory =
        this.filterCardCategory === 'all' || card.category === this.filterCardCategory;

      const matchesRole =
        this.filterCardRole === 'all' || card.roles.includes(this.filterCardRole);

      return matchesCategory && matchesRole;
    });
  }

  toggleCardEnabled(card: PermissionCard): void {
    card.enabled = !card.enabled;
    this.savePermissions();
    this.showSuccess(card.enabled ? `✅ "${card.title}" activado` : `⚠️ "${card.title}" desactivado`);
  }

  toggleRoleOnCard(card: PermissionCard, role: string): void {
    const normalizedRole = this.normalizeRole(role);
    const index = card.roles.indexOf(normalizedRole);

    if (index >= 0) {
      card.roles.splice(index, 1);
    } else {
      card.roles.push(normalizedRole);
    }

    this.savePermissions();
  }

  hasRole(card: PermissionCard, role: string): boolean {
    return card.roles.includes(this.normalizeRole(role));
  }

  savePermissions(): void {
    localStorage.setItem('app_permissions', JSON.stringify(this.permissionCards));
  }

  loadPermissions(): void {
    const saved = localStorage.getItem('app_permissions');

    if (!saved) {
      return;
    }

    try {
      const savedCards = JSON.parse(saved) as PermissionCard[];

      savedCards.forEach(savedCard => {
        const currentCard = this.permissionCards.find(card => card.id === savedCard.id);

        if (currentCard) {
          currentCard.enabled = savedCard.enabled;
          currentCard.roles = savedCard.roles.map(role => this.normalizeRole(role));
        }
      });
    } catch {
      this.showError('No se pudieron cargar los permisos guardados');
    }
  }

  // ═══════════════════════════════════════════════════════
  // MÉTODOS AUXILIARES FALTANTES
  // ═══════════════════════════════════════════════════════

  normalizeRole(role: string): string {
    if (!role) return 'student';
    const normalized = role.toLowerCase();
    if (normalized === 'estudiante') return 'student';
    return normalized;
  }

  getTotalUsers(): number {
    return this.users.length;
  }

  getTotalClasses(): number {
    return this.classes.length;
  }

  getEnabledCount(): number {
    return this.permissionCards.filter(c => c.enabled).length;
  }

  resetPermissions(): void {
    if (confirm('¿Restablecer todos los permisos a valores predeterminados?')) {
      this.permissionCards = [
        { id: 'card_courses', title: 'Ver Cursos', description: 'Acceso a la lista de cursos disponibles', icon: 'fas fa-book-open', color: '#667eea', roles: ['admin', 'teacher', 'tutor', 'student'], enabled: true, category: 'Contenido' },
        { id: 'card_classes', title: 'Gestión de Clases', description: 'Crear, editar y eliminar clases', icon: 'fas fa-chalkboard-teacher', color: '#f7971e', roles: ['admin', 'teacher'], enabled: true, category: 'Gestión' },
        { id: 'card_quiz', title: 'Quizzes', description: 'Crear y gestionar evaluaciones', icon: 'fas fa-brain', color: '#11998e', roles: ['admin', 'teacher'], enabled: true, category: 'Evaluación' },
        { id: 'card_takequiz', title: 'Tomar Quiz', description: 'Resolver evaluaciones y quizzes', icon: 'fas fa-pencil-alt', color: '#ff758c', roles: ['admin', 'teacher', 'tutor', 'student'], enabled: true, category: 'Evaluación' },
        { id: 'card_reports', title: 'Informes', description: 'Ver reportes y estadísticas de alumnos', icon: 'fas fa-chart-bar', color: '#4ca1af', roles: ['admin', 'tutor'], enabled: true, category: 'Informes' },
        { id: 'card_users', title: 'Gestión Usuarios', description: 'Administrar cuentas de usuarios', icon: 'fas fa-users-cog', color: '#764ba2', roles: ['admin'], enabled: true, category: 'Administración' },
        { id: 'card_settings', title: 'Parámetros', description: 'Configurar parámetros del sistema', icon: 'fas fa-sliders-h', color: '#2c3e50', roles: ['admin'], enabled: true, category: 'Administración' },
        { id: 'card_lessons', title: 'Lecciones', description: 'Ver y completar lecciones asignadas', icon: 'fas fa-graduation-cap', color: '#56ab2f', roles: ['admin', 'teacher', 'tutor', 'student'], enabled: true, category: 'Contenido' },
        { id: 'card_review', title: 'Practicar', description: 'Área de práctica y ejercicios', icon: 'fas fa-star', color: '#ffd200', roles: ['admin', 'teacher', 'tutor', 'student'], enabled: true, category: 'Contenido' }
      ];
      this.showSuccess('✅ Permisos restablecidos');
    }
  }

  private getErrorMessage(error: unknown): string {
    if (error instanceof Error) return error.message;
    if (typeof error === 'object' && error !== null && 'message' in error) {
      return String((error as { message: unknown }).message);
    }
    return 'Error desconocido';
  }
}