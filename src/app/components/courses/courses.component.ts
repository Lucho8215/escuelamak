import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { CourseService } from '../../services/course.service';
import { AuthService } from '../../services/auth.service';
import { Course, Class, CourseEnrollment } from '../../models/course.model';
import { SafePipe } from '../../pipes/safe.pipe';

@Component({
  selector: 'app-courses',
  standalone: true,
  imports: [CommonModule, RouterModule, SafePipe],
  templateUrl: './courses.component.html',
  styleUrls: ['./courses.component.css']
})
export class CoursesComponent implements OnInit {
  courses: Course[] = [];
  classes: Class[] = [];
  selectedCourse: Course | null = null;

  constructor(
    private courseService: CourseService,
    private authService: AuthService
  ) {}

  async ngOnInit() {
    await this.loadCourses();
  }

  async loadCourses() {
    try {
      const courses = await this.courseService.getCourses();
      this.courses = courses.filter(course => course.isVisible);
    } catch (error) {
      console.error('Error al cargar los cursos:', error);
    }
  }

  async viewCourseDetails(course: Course) {
    this.selectedCourse = course;
    await this.loadCourseClasses(course.id);
  }

  async loadCourseClasses(courseId: string) {
    try {
      this.classes = await this.courseService.getClasses(courseId);
    } catch (error) {
      console.error('Error al cargar las clases:', error);
    }
  }

  async enrollInClass(classData: Class) {
    if (!this.authService.getCurrentUser()) {
      alert('Por favor, inicia sesión para inscribirte en una clase');
      return;
    }

    const enrollment: Omit<CourseEnrollment, 'id'> = {
      courseId: this.selectedCourse!.id,
      studentId: this.authService.getCurrentUser()!.id,
      classId: classData.id,
      status: 'active',
      enrollmentDate: new Date()
    };

    try {
      await this.courseService.enrollStudent(enrollment);
      alert('¡Te has inscrito exitosamente!');
      await this.loadCourseClasses(this.selectedCourse!.id);
    } catch (error) {
      console.error('Error al inscribirse:', error);
      alert('Hubo un error al inscribirte. Por favor, intenta de nuevo.');
    }
  }

  closeModal() {
    this.selectedCourse = null;
    this.classes = [];
  }
}