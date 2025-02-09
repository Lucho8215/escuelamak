import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { CourseService } from '../../services/course.service';
import { Course, Class } from '../../models/course.model';
import { UserService } from '../../services/user.service';
import { User, UserRole } from '../../models/user.model';

@Component({
  selector: 'app-course-management',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './course-management.component.html',
  styleUrls: ['./course-management.component.css']
})
export class CourseManagementComponent implements OnInit {
  courses: Course[] = [];
  classes: Class[] = [];
  teachers: User[] = [];
  isLoading: boolean = false;
  
  newCourse: Partial<Course> = {
    title: '',
    description: '',
    category: 'education',
    isVisible: true,
    videoUrl: '',
    price: 0,
    duration: 1
  };

  newClass: Partial<Class> = {
    name: '',
    teacherId: '',
    status: 'open',
    classNumber: 1,
    maxStudents: 20,
    enrollmentCount: 0,
    startDate: new Date(),
    endDate: new Date(),
    enrolledStudents: []
  };

  editingCourse: boolean = false;
  editingClass: boolean = false;
  showClassModal: boolean = false;
  selectedCourse: Course | null = null;
  errorMessage: string = '';

  constructor(
    private courseService: CourseService,
    private userService: UserService
  ) {}

  ngOnInit() {
    this.loadInitialData();
  }

  private async loadInitialData() {
    try {
      this.isLoading = true;
      await Promise.all([
        this.loadCourses(),
        this.loadTeachers()
      ]);
    } catch (error) {
      this.handleError('Error al cargar los datos iniciales', error);
    } finally {
      this.isLoading = false;
    }
  }

  private handleError(message: string, error: any) {
    this.errorMessage = message;
    console.error(message, error);
    setTimeout(() => {
      this.errorMessage = '';
    }, 5000);
  }

  async loadCourses() {
    try {
      this.courses = await this.courseService.getCourses();
    } catch (error) {
      this.handleError('Error al cargar los cursos', error);
    }
  }

  async loadTeachers() {
    this.userService.getUsers().subscribe({
      next: (users) => {
        this.teachers = users.filter(user => user.role === UserRole.TEACHER);
      },
      error: (error) => {
        this.handleError('Error al cargar los profesores', error);
      }
    });
  }

  async saveCourse() {
    try {
      this.isLoading = true;
      if (this.editingCourse && this.selectedCourse) {
        await this.courseService.updateCourse(this.selectedCourse.id, this.newCourse as Course);
      } else {
        await this.courseService.createCourse(this.newCourse as Course);
      }
      
      this.resetCourseForm();
      await this.loadCourses();
    } catch (error) {
      this.handleError('Error al guardar el curso', error);
    } finally {
      this.isLoading = false;
    }
  }

  editCourse(course: Course) {
    this.editingCourse = true;
    this.selectedCourse = course;
    this.newCourse = { ...course };
  }

  async deleteCourse(id: string) {
    if (confirm('¿Estás seguro de que deseas eliminar este curso?')) {
      try {
        this.isLoading = true;
        await this.courseService.deleteCourse(id);
        await this.loadCourses();
      } catch (error) {
        this.handleError('Error al eliminar el curso', error);
      } finally {
        this.isLoading = false;
      }
    }
  }

  async manageClasses(course: Course) {
    this.selectedCourse = course;
    this.showClassModal = true;
    await this.loadClasses(course.id);
  }

  async loadClasses(courseId: string) {
    try {
      this.isLoading = true;
      this.classes = await this.courseService.getClasses(courseId);
    } catch (error) {
      this.handleError('Error al cargar las clases', error);
    } finally {
      this.isLoading = false;
    }
  }

  async saveClass() {
    if (!this.selectedCourse) return;

    try {
      this.isLoading = true;
      if (this.editingClass) {
        // Actualizar clase existente
      } else {
        await this.courseService.createClass({
          ...this.newClass as Class,
          courseId: this.selectedCourse.id
        });
      }
      
      this.resetClassForm();
      await this.loadClasses(this.selectedCourse.id);
    } catch (error) {
      this.handleError('Error al guardar la clase', error);
    } finally {
      this.isLoading = false;
    }
  }

  editClass(class_: Class) {
    this.editingClass = true;
    this.newClass = { ...class_ };
  }

  async deleteClass(id: string) {
    if (confirm('¿Estás seguro de que deseas eliminar esta clase?')) {
      try {
        this.isLoading = true;
        await this.courseService.deleteClass(id);
        if (this.selectedCourse) {
          await this.loadClasses(this.selectedCourse.id);
        }
      } catch (error) {
        this.handleError('Error al eliminar la clase', error);
      } finally {
        this.isLoading = false;
      }
    }
  }

  manageEnrollments(class_: Class) {
    // Implementar gestión de inscripciones
  }

  closeClassModal() {
    this.showClassModal = false;
    this.resetClassForm();
  }

  resetCourseForm() {
    this.newCourse = {
      title: '',
      description: '',
      category: 'education',
      isVisible: true,
      videoUrl: '',
      price: 0,
      duration: 1
    };
    this.editingCourse = false;
    this.selectedCourse = null;
    this.errorMessage = '';
  }

  resetClassForm() {
    this.newClass = {
      name: '',
      teacherId: '',
      status: 'open',
      classNumber: 1,
      maxStudents: 20,
      enrollmentCount: 0,
      startDate: new Date(),
      endDate: new Date(),
      enrolledStudents: []
    };
    this.editingClass = false;
    this.errorMessage = '';
  }
}