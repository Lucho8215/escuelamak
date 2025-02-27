import { Component } from '@angular/core';
import { bootstrapApplication } from '@angular/platform-browser';
import { provideRouter, RouterOutlet, Routes } from '@angular/router';
import { LoginComponent } from './app/components/login/login.component';
import { DashboardComponent } from './app/components/dashboard/dashboard.component';
import { CoursesComponent } from './app/components/courses/courses.component';
import { UsersComponent } from './app/components/users/users.component';
import { ReviewComponent } from './app/components/review/review.component';
import { SettingsComponent } from './app/components/settings/settings.component';
import { UserManagementComponent } from './app/components/user-management/user-management.component';
import { CourseManagementComponent } from './app/components/course-management/course-management.component';
import { SupabaseTestComponent } from './app/components/supabase-test/supabase-test.component';
import { provideHttpClient } from '@angular/common/http';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  template: `
    <router-outlet></router-outlet>
  `
})
export class App {}

const routes: Routes = [
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { path: 'dashboard', component: DashboardComponent },
  { path: 'courses', component: CoursesComponent },
  { path: 'users', component: UsersComponent },
  { path: 'review', component: ReviewComponent },
  { path: 'settings', component: SettingsComponent },
  { path: 'user-management', component: UserManagementComponent },
  { path: 'course-management', component: CourseManagementComponent },
  { path: 'supabase-test', component: SupabaseTestComponent }
];

bootstrapApplication(App, {
  providers: [
    provideRouter(routes),
    provideHttpClient()
  ]
}).catch(err => console.error(err));