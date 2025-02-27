import { Routes } from '@angular/router';
import { LoginComponent } from './components/login/login.component';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { CoursesComponent } from './components/courses/courses.component';
import { UsersComponent } from './components/users/users.component';
import { ReviewComponent } from './components/review/review.component';
import { SettingsComponent } from './components/settings/settings.component';
import { UserManagementComponent } from './components/user-management/user-management.component';
import { CourseManagementComponent } from './components/course-management/course-management.component';
import { SupabaseTestComponent } from './components/supabase-test/supabase-test.component';
import { QuizManagementComponent } from './components/quiz-management/quiz-management.component';
import { QuizTakingComponent } from './components/quiz-taking/quiz-taking.component';

export const routes: Routes = [
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { path: 'dashboard', component: DashboardComponent },
  { path: 'courses', component: CoursesComponent },
  { path: 'users', component: UsersComponent },
  { path: 'review', component: ReviewComponent },
  { path: 'settings', component: SettingsComponent },
  { path: 'user-management', component: UserManagementComponent },
  { path: 'course-management', component: CourseManagementComponent },
  { path: 'supabase-test', component: SupabaseTestComponent },
  { path: 'quiz-management', component: QuizManagementComponent },
  { path: 'quiz/:id', component: QuizTakingComponent }
];