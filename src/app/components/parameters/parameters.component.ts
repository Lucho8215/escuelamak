import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../../environments/environment';
interface AppUser {
  id: string; name: string; email: string; role: string;
  created_at?: string; password_hash?: string;
}
interface PermissionCard {
  id: string; title: string; description: string; icon: string;
  color: string; roles: string[]; enabled: boolean; category: string;
}
interface ThemeOption {
  id: string; name: string; primary: string; secondary: string;
  accent: string; bg: string; preview: string[];
}
@Component({
  selector: 'app-parameters',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './parameters.component.html',
  styleUrls: ['./parameters.component.css']
})
export class ParametersComponent implements OnInit {
  private supabase: SupabaseClient = createClient(environment.supabaseUrl, environment.supabaseKey);
  activeSection = 'users';
  loading = false;
  successMsg = '';
  errorMsg = '';
  users: AppUser[] = [];
  filteredUsers: AppUser[] = [];
  searchUser = '';
  filterRole = '';
  showUserModal = false;
  editingUser: AppUser | null = null;
  userForm: any = this.emptyUserForm();
  userFormErrors: Record<string, string> = {};
  classes: any[] = [];
  filteredClasses: any[] = [];
  searchClass = '';
  showClassModal = false;
  editingClass: any = null;
  classForm: any = this.emptyClassForm();
  courses: any[] = [];
  selectedTheme = 'default';
  themes: ThemeOption[] = [
    { id: 'default', name: 'Arcoíris Mágico', primary: '#667eea', secondary: '#764ba2', accent: '#f093fb', bg: '#f0f2ff', preview: ['#667eea','#764ba2','#f093fb','#4facfe'] },
    { id: 'ocean',   name: 'Océano Profundo', primary: '#0093E9', secondary: '#80D0C7', accent: '#00f5d4', bg: '#e8f8ff', preview: ['#0093E9','#80D0C7','#00f5d4','#43e97b'] },
    { id: 'sunset',  name: 'Atardecer Tropical', primary: '#f7971e', secondary: '#ffd200', accent: '#ff6b6b', bg: '#fff8e7', preview: ['#f7971e','#ffd200','#ff6b6b','#ff9a9e'] },
    { id: 'forest',  name: 'Bosque Encantado', primary: '#11998e', secondary: '#38ef7d', accent: '#56ab2f', bg: '#efffef', preview: ['#11998e','#38ef7d','#56ab2f','#a8ff78'] },
    { id: 'galaxy',  name: 'Galaxia Espacial', primary: '#2c3e50', secondary: '#4ca1af', accent: '#c0392b', bg: '#f0f4f8', preview: ['#2c3e50','#4ca1af','#c0392b','#8e44ad'] },
    { id: 'candy',   name: 'Dulcería Feliz', primary: '#ff758c', secondary: '#ff7eb3', accent: '#ffd6e0', bg: '#fff0f5', preview: ['#ff758c','#ff7eb3','#a78bfa','#fbbf24'] }
  ];
  permissionCards: PermissionCard[] = [
    { id: 'card_courses',  title: 'Ver Cursos',          description: 'Acceso a la lista de cursos disponibles',      icon: 'fas fa-book-open',           color: '#667eea', roles: ['admin','teacher','tutor','estudiante'], enabled: true, category: 'Contenido' },
    { id: 'card_classes',  title: 'Gestión de Clases',   description: 'Crear, editar y eliminar clases',              icon: 'fas fa-chalkboard-teacher',  color: '#f7971e', roles: ['admin','teacher'],                     enabled: true, category: 'Gestión' },
    { id: 'card_quiz',     title: 'Quizzes',             description: 'Crear y gestionar evaluaciones',               icon: 'fas fa-brain',               color: '#11998e', roles: ['admin','teacher'],                     enabled: true, category: 'Evaluación' },
    { id: 'card_takequiz', title: 'Tomar Quiz',          description: 'Resolver evaluaciones y quizzes',              icon: 'fas fa-pencil-alt',          color: '#ff758c', roles: ['admin','teacher','tutor','estudiante'], enabled: true, category: 'Evaluación' },
    { id: 'card_reports',  title: 'Informes',            description: 'Ver reportes y estadísticas de alumnos',       icon: 'fas fa-chart-bar',           color: '#4ca1af', roles: ['admin','tutor'],                       enabled: true, category: 'Informes' },
    { id: 'card_users',    title: 'Gestión Usuarios',    description: 'Administrar cuentas de usuarios',              icon: 'fas fa-users-cog',           color: '#764ba2', roles: ['admin'],                               enabled: true, category: 'Administración' },
    { id: 'card_settings', title: 'Parámetros',          description: 'Configurar parámetros del sistema',            icon: 'fas fa-sliders-h',           color: '#2c3e50', roles: ['admin'],                               enabled: true, category: 'Administración' },
    { id: 'card_lessons',  title: 'Lecciones',           description: 'Ver y completar lecciones asignadas',          icon: 'fas fa-graduation-cap',      color: '#56ab2f', roles: ['admin','teacher','tutor','estudiante'], enabled: true, category: 'Contenido' },
    { id: 'card_review',   title: 'Practicar',           description: 'Área de práctica y ejercicios',                icon: 'fas fa-star',                color: '#ffd200', roles: ['admin','teacher','tutor','estudiante'], enabled: true, category: 'Contenido' }
  ];
  filterCardCategory = 'all';
  filterCardRole = 'all';
  cardCategories: string[] = [];
  roles = ['admin', 'teacher', 'tutor', 'estudiante'];
  deleteConfirm: { type: string; id: string; name: string } | null = null;
  ngOnInit() {
    const saved = localStorage.getItem('app_theme');
    if (saved) this.selectedTheme = saved;
    this.applyTheme(this.selectedTheme);
    this.cardCategories = [...new Set(this.permissionCards.map(c => c.category))];
    this.loadPermissions();
    this.loadUsers();
    this.loadCourses();
    this.loadClasses();
  }
  setSection(s: string) { this.activeSection = s; this.clearMessages(); }
  clearMessages() { this.successMsg = ''; this.errorMsg = ''; }
  showSuccess(msg: string) { this.successMsg = msg; this.errorMsg = ''; setTimeout(() => this.successMsg = '', 3500); }
  showError(msg: string)   { this.errorMsg = msg; this.successMsg = ''; setTimeout(() => this.errorMsg = '', 4000); }
  emptyUserForm() { return { name: '', email: '', role: 'estudiante', password: '' }; }
  async loadUsers() {
    this.loading = true;
    try {
      const { data, error } = await this.supabase.from('app_users').select('id,name,email,role,created_at').order('name');
      if (error) throw error;
      this.users = data || [];
      this.applyUserFilters();
    } catch (e: any) { this.showError('Error cargando usuarios: ' + e.message); }
    finally { this.loading = false; }
  }
  applyUserFilters() {
    this.filteredUsers = this.users.filter(u => {
      const ms = !this.searchUser || u.name.toLowerCase().includes(this.searchUser.toLowerCase()) || u.email.toLowerCase().includes(this.searchUser.toLowerCase());
      const mr = !this.filterRole || u.role === this.filterRole;
      return ms && mr;
    });
  }
  openCreateUser() { this.editingUser = null; this.userForm = this.emptyUserForm(); this.userFormErrors = {}; this.showUserModal = true; }
  openEditUser(user: AppUser) { this.editingUser = { ...user }; this.userForm = { name: user.name, email: user.email, role: user.role, password: '' }; this.userFormErrors = {}; this.showUserModal = true; }
  closeUserModal() { this.showUserModal = false; this.editingUser = null; this.userFormErrors = {}; }
  validateUserForm(): boolean {
    this.userFormErrors = {};
    if (!this.userForm.name?.trim())  this.userFormErrors['name']  = 'El nombre es requerido';
    if (!this.userForm.email?.trim()) this.userFormErrors['email'] = 'El email es requerido';
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.userForm.email)) this.userFormErrors['email'] = 'Email inválido';
    if (!this.editingUser && !this.userForm.password?.trim()) this.userFormErrors['password'] = 'La contraseña es requerida';
    if (!this.userForm.role) this.userFormErrors['role'] = 'El rol es requerido';
    return Object.keys(this.userFormErrors).length === 0;
  }
  async saveUser() {
    if (!this.validateUserForm()) return;
    this.loading = true;
    try {
      if (this.editingUser) {
        const { error } = await this.supabase.from('app_users').update({ name: this.userForm.name, email: this.userForm.email, role: this.userForm.role }).eq('id', this.editingUser.id);
        if (error) throw error;
        this.showSuccess('✅ Usuario "' + this.userForm.name + '" actualizado');
      } else {
        const { error } = await this.supabase.from('app_users').insert([{ name: this.userForm.name, email: this.userForm.email, role: this.userForm.role }]);
        if (error) throw error;
        this.showSuccess('✅ Usuario "' + this.userForm.name + '" creado');
      }
      this.closeUserModal(); await this.loadUsers();
    } catch (e: any) { this.showError('Error guardando: ' + e.message); }
    finally { this.loading = false; }
  }
  confirmDelete(type: string, id: string, name: string) { this.deleteConfirm = { type, id, name }; }
  cancelDelete() { this.deleteConfirm = null; }
  async executeDelete() {
    if (!this.deleteConfirm) return;
    this.loading = true;
    try {
      const table = this.deleteConfirm.type === 'user' ? 'app_users' : 'classes';
      const { error } = await this.supabase.from(table).delete().eq('id', this.deleteConfirm.id);
      if (error) throw error;
      this.showSuccess('✅ "' + this.deleteConfirm.name + '" eliminado');
      if (this.deleteConfirm.type === 'user') await this.loadUsers(); else await this.loadClasses();
    } catch (e: any) { this.showError('Error eliminando: ' + e.message); }
    finally { this.loading = false; this.deleteConfirm = null; }
  }
  getRoleBadgeClass(role: string): string {
    const m: Record<string,string> = { admin:'badge-admin', teacher:'badge-teacher', tutor:'badge-tutor', estudiante:'badge-student', student:'badge-student' };
    return m[role] || 'badge-default';
  }
  getRoleIcon(role: string): string {
    const m: Record<string,string> = { admin:'fas fa-crown', teacher:'fas fa-chalkboard-teacher', tutor:'fas fa-user-tie', estudiante:'fas fa-user-graduate', student:'fas fa-user-graduate' };
    return m[role] || 'fas fa-user';
  }
  getUserCountByRole(role: string): number { return this.users.filter(u => u.role === role || (role === 'estudiante' && u.role === 'student')).length; }
  emptyClassForm() { return { name: '', course_id: '', status: 'open', max_students: 30, start_date: '', end_date: '' }; }
  async loadCourses() { const { data } = await this.supabase.from('courses').select('id,title').order('title'); this.courses = data || []; }
  async loadClasses() {
    this.loading = true;
    try {
      const { data, error } = await this.supabase.from('classes').select('id,name,title,status,course_id,max_students,enrollment_count,start_date,end_date').order('created_at', { ascending: false });
      if (error) throw error;
      this.classes = data || []; this.applyClassFilters();
    } catch (e: any) { this.showError('Error cargando clases: ' + e.message); }
    finally { this.loading = false; }
  }
  applyClassFilters() { this.filteredClasses = this.classes.filter(c => !this.searchClass || (c.name||c.title||'').toLowerCase().includes(this.searchClass.toLowerCase())); }
  openCreateClass() { this.editingClass = null; this.classForm = this.emptyClassForm(); this.showClassModal = true; }
  openEditClass(cls: any) { this.editingClass = { ...cls }; this.classForm = { name: cls.name||cls.title||'', course_id: cls.course_id||'', status: cls.status||'open', max_students: cls.max_students||30, start_date: cls.start_date||'', end_date: cls.end_date||'' }; this.showClassModal = true; }
  closeClassModal() { this.showClassModal = false; this.editingClass = null; }
  async saveClass() {
    if (!this.classForm.name?.trim()) { this.showError('El nombre es requerido'); return; }
    this.loading = true;
    try {
      const p: any = { name: this.classForm.name, title: this.classForm.name, course_id: this.classForm.course_id||null, status: this.classForm.status, max_students: this.classForm.max_students||30, start_date: this.classForm.start_date||null, end_date: this.classForm.end_date||null };
      if (this.editingClass) {
        const { error } = await this.supabase.from('classes').update(p).eq('id', this.editingClass.id);
        if (error) throw error; this.showSuccess('✅ Clase "' + p.name + '" actualizada');
      } else {
        const { error } = await this.supabase.from('classes').insert([p]);
        if (error) throw error; this.showSuccess('✅ Clase "' + p.name + '" creada');
      }
      this.closeClassModal(); await this.loadClasses();
    } catch (e: any) { this.showError('Error guardando clase: ' + e.message); }
    finally { this.loading = false; }
  }
  getCourseTitle(courseId: string): string { return this.courses.find(c => c.id === courseId)?.title || '—'; }
  getClassStatusLabel(s: string): string { const m: Record<string,string> = { open:'Abierta', closed:'Cerrada', active:'Activa', inactive:'Inactiva' }; return m[s] || s; }
  selectTheme(id: string) { this.selectedTheme = id; localStorage.setItem('app_theme', id); this.applyTheme(id); this.showSuccess('✅ Tema aplicado'); }
  applyTheme(id: string) { const t = this.themes.find(th => th.id === id); if (!t) return; document.documentElement.style.setProperty('--color-primary', t.primary); document.documentElement.style.setProperty('--color-secondary', t.secondary); document.documentElement.style.setProperty('--color-accent', t.accent); document.documentElement.style.setProperty('--color-bg', t.bg); }
  getTheme(id: string) { return this.themes.find(t => t.id === id); }
  get filteredCards(): PermissionCard[] { return this.permissionCards.filter(c => (this.filterCardCategory === 'all' || c.category === this.filterCardCategory) && (this.filterCardRole === 'all' || c.roles.includes(this.filterCardRole))); }
  toggleCardEnabled(card: PermissionCard) { card.enabled = !card.enabled; this.savePermissions(); this.showSuccess(card.enabled ? '✅ "' + card.title + '" activado' : '⚠️ "' + card.title + '" desactivado'); }
  toggleRoleOnCard(card: PermissionCard, role: string) { const i = card.roles.indexOf(role); if (i >= 0) card.roles.splice(i, 1); else card.roles.push(role); this.savePermissions(); }
  hasRole(card: PermissionCard, role: string): boolean { return card.roles.includes(role); }
  savePermissions() { localStorage.setItem('app_permissions', JSON.stringify(this.permissionCards)); }
  loadPermissions() { const s = localStorage.getItem('app_permissions'); if (s) { try { JSON.parse(s).forEach((sv: PermissionCard) => { const c = this.permissionCards.find(x => x.id === sv.id); if (c) { c.enabled = sv.enabled; c.roles = sv.roles; } }); } catch {} } }
  resetPermissions() { localStorage.removeItem('app_permissions'); this.permissionCards.forEach(c => c.enabled = true); this.showSuccess('✅ Permisos restablecidos'); }
  getEnabledCount(): number { return this.permissionCards.filter(c => c.enabled).length; }
  getTotalUsers()   { return this.users.length; }
  getTotalClasses() { return this.classes.length; }
}
