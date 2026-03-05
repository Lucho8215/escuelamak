const fs = require('fs');

const ts = `import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { CourseService } from '../../services/course.service';
import { AuthService } from '../../services/auth.service';
import { Class, Course, CourseEnrollment, Lesson } from '../../models/course.model';

@Component({
  selector: 'app-class-management',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './class-management.component.html',
  styleUrls: ['./class-management.component.css']
})
export class ClassManagementComponent implements OnInit {
  activeTab: string = 'clases';
  classes: Class[] = [];
  courses: Course[] = [];
  enrollments: CourseEnrollment[] = [];
  lessons: Lesson[] = [];
  selectedClass: Class | null = null;
  loading: boolean = false;
  successMessage: string = '';
  errorMessage: string = '';
  newClass: Partial<Class> = this.getEmptyClass();
  editingClass: boolean = false;

  constructor(
    private courseService: CourseService,
    private authService: AuthService
  ) {}

  ngOnInit() {
    this.loadCourses();
    this.loadClasses();
  }

  getEmptyClass(): Partial<Class> {
    return {
      name: '', courseId: '', teacherId: '',
      status: 'open', classNumber: 1,
      enrollmentCount: 0, maxStudents: 30,
      startDate: new Date(), endDate: new Date(),
      enrolledStudents: []
    };
  }

  async loadCourses() {
    try {
      this.courses = await this.courseService.getCourses();
    } catch(e: any) {
      this.errorMessage = 'Error cargando cursos: ' + e.message;
    }
  }

  async loadClasses() {
    this.loading = true;
    try {
      this.classes = await this.courseService.getClasses('');
      this.loading = false;
    } catch(e: any) {
      this.errorMessage = 'Error cargando clases: ' + e.message;
      this.loading = false;
    }
  }

  async selectClass(clase: Class) {
    this.selectedClass = clase;
    this.activeTab = 'clases';
    await this.loadEnrollments(clase.id);
  }

  async loadEnrollments(classId: string) {
    try {
      this.enrollments = await this.courseService.getEnrollments(classId);
    } catch(e) {
      this.enrollments = [];
    }
  }

  getCourseTitle(courseId: string): string {
    const course = this.courses.find(c => c.id === courseId);
    return course ? course.title : 'Sin curso';
  }

  async saveClass() {
    this.loading = true;
    this.successMessage = '';
    this.errorMessage = '';
    try {
      if (this.editingClass && this.newClass.id) {
        await this.courseService.updateClass(this.newClass.id, this.newClass as Class);
        this.successMessage = 'Clase actualizada correctamente';
      } else {
        await this.courseService.createClass(this.newClass as Class);
        this.successMessage = 'Clase creada correctamente';
      }
      this.loading = false;
      this.resetClassForm();
      await this.loadClasses();
      setTimeout(() => this.successMessage = '', 3000);
    } catch(e: any) {
      this.loading = false;
      this.errorMessage = 'Error: ' + e.message;
    }
  }

  editClass(clase: Class) {
    this.editingClass = true;
    this.newClass = { ...clase };
    this.activeTab = 'clases';
    window.scrollTo(0, 0);
  }

  async deleteClass(id: string) {
    if (confirm('Eliminar esta clase?')) {
      try {
        await this.courseService.deleteClass(id);
        this.successMessage = 'Clase eliminada';
        if (this.selectedClass?.id === id) this.selectedClass = null;
        await this.loadClasses();
        setTimeout(() => this.successMessage = '', 3000);
      } catch(e: any) {
        this.errorMessage = 'Error: ' + e.message;
      }
    }
  }

  resetClassForm() {
    this.editingClass = false;
    this.newClass = this.getEmptyClass();
  }

  setTab(tab: string) {
    this.activeTab = tab;
  }

  getStatusLabel(status: string): string {
    return status === 'open' ? 'Abierta' : 'Cerrada';
  }

  getStatusColor(status: string): string {
    return status === 'open' ? '#40c057' : '#ff6b6b';
  }
}`;

const fs2 = require('fs');
fs2.writeFileSync('src/app/components/class-management/class-management.component.ts', ts, 'utf8');
console.log('LISTO - componente corregido con async/await');
