import { Injectable } from '@angular/core';
import { Observable, from, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { User, UserRole } from '../models/user.model';
import { SupabaseService } from './supabase.service';

type AppUserRow = {
  id: string;
  name: string;
  email: string;
  role: string;
};

export type CreateUserInput = {
  name: string;
  email: string;
  role: UserRole;
  password: string;
};

@Injectable({
  providedIn: 'root'
})
export class UserService {
  constructor(private supabaseService: SupabaseService) {}

  async getUserByEmail(email: string): Promise<User | null> {
    const { data, error } = await this.supabaseService
      .getClient()
      .from('app_users')
      .select('*')
      .eq('email', email)
      .single();

    if (error || !data) {
      return null;
    }

    return this.mapToUser(data as AppUserRow);
  }

  getUsers(): Observable<User[]> {
    return from(
      this.supabaseService
        .getClient()
        .from('app_users')
        .select('*')
    ).pipe(
      map(({ data, error }) => {
        if (error) {
          throw new Error(error.message);
        }

        const rows = (data ?? []) as AppUserRow[];
        return rows.map((row: AppUserRow) => this.mapToUser(row));
      }),
      catchError(error =>
        throwError(() => new Error(error.message || 'Error al obtener usuarios'))
      )
    );
  }

  createUser(user: CreateUserInput): Observable<User> {
    return from(
      this.supabaseService
        .getClient()
        .from('app_users')
        .insert([
          {
            name: user.name,
            email: user.email,
            role: user.role
          }
        ])
        .select()
        .single()
    ).pipe(
      map(({ data, error }) => {
        if (error || !data) {
          throw new Error(error?.message || 'No se pudo crear el usuario');
        }

        return this.mapToUser(data as AppUserRow);
      }),
      catchError(error =>
        throwError(() => new Error(error.message || 'Error al crear usuario'))
      )
    );
  }

  updateUser(user: User): Observable<User> {
    return from(
      this.supabaseService
        .getClient()
        .from('app_users')
        .update({
          name: user.name,
          email: user.email,
          role: user.role
        })
        .eq('id', user.id)
        .select()
        .single()
    ).pipe(
      map(({ data, error }) => {
        if (error || !data) {
          throw new Error(error?.message || 'No se pudo actualizar el usuario');
        }

        return this.mapToUser(data as AppUserRow);
      }),
      catchError(error =>
        throwError(() => new Error(error.message || 'Error al actualizar usuario'))
      )
    );
  }

  updatePassword(userId: string, newPassword: string): Observable<void> {
    void userId;
    void newPassword;

    return throwError(() => new Error(
      'La actualización de contraseñas de otros usuarios requiere un backend seguro o una Edge Function de Supabase.'
    ));
  }

  private mapToUser(data: AppUserRow): User {
    return {
      id: data.id,
      name: data.name,
      email: data.email,
      role: data.role as UserRole
    };
  }
}