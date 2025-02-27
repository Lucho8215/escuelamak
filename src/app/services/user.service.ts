import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { User, UserRole } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class UserService {
  // Simulación de base de datos local
  private users: User[] = [
    {
      id: '1',
      name: 'Luis Moreno',
      email: 'luis.moreno@example.com',
      role: UserRole.ADMIN,
      password: 'Luism*'
    },
    {
      id: '2',
      name: 'Carmen Andrade',
      email: 'carmen.andrade@gmail.com',
      role: UserRole.STUDENT,
      password: 'student123'
    },
    {
      id: '3',
      name: 'Carlos Peña',
      email: 'carlos.peña@gmail.com',
      role: UserRole.TEACHER,
      password: 'teacher123'
    }
  ];

  async getUserByEmail(email: string): Promise<User | null> {
    const user = this.users.find(u => u.email === email);
    return user || null;
  }

  async verifyPassword(email: string, password: string): Promise<boolean> {
    const user = await this.getUserByEmail(email);
    return user?.password === password;
  }

  getUsers(): Observable<User[]> {
    return of(this.users).pipe(delay(500));
  }

  createUser(user: Omit<User, 'id'> & { password: string }): Observable<User> {
    const newUser: User = {
      ...user,
      id: (this.users.length + 1).toString()
    };

    this.users.push(newUser);
    return of(newUser).pipe(delay(500));
  }

  updateUser(user: User): Observable<User> {
    const index = this.users.findIndex(u => u.id === user.id);
    if (index === -1) {
      throw new Error('Usuario no encontrado');
    }

    this.users[index] = { ...user };
    return of(user).pipe(delay(500));
  }

  updatePassword(userId: string, newPassword: string): Observable<void> {
    const user = this.users.find(u => u.id === userId);
    if (!user) {
      throw new Error('Usuario no encontrado');
    }

    user.password = newPassword;
    return of(void 0).pipe(delay(500));
  }
}