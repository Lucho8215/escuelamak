import { Injectable } from '@angular/core';
import { Observable, from, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import {
  User,
  UserRole,
  CreateUserRequest,
  UpdateUserRequest
} from '../models/user.model';
import { SupabaseService } from './supabase.service';

type AppUserRow = {
  id: string;
  auth_user_id?: string | null;
  name: string;
  email: string;
  cedula: string;
  role: string;
};

type AdminFunctionCreateResponse = {
  user: AppUserRow;
};

type AdminFunctionUpdateResponse = {
  user: AppUserRow;
};

type AdminFunctionPasswordResponse = {
  success: boolean;
};

@Injectable({
  providedIn: 'root'
})
export class UserService {
  constructor(private supabaseService: SupabaseService) {}

  private getFunctionEndpoint(name: string): string {
    return `${this.supabaseService.getUrl()}/functions/v1/${name}`;
  }

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
        .order('name')
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

  createUser(user: CreateUserRequest): Observable<User> {
    return from(
      this.callAdminFunction<AdminFunctionCreateResponse>('create-user', {
        name: user.name,
        email: user.email,
        cedula: user.cedula,
        role: user.role,
        password: user.password
      })
    ).pipe(
      map(response => this.mapToUser(response.user)),
      catchError(error =>
        throwError(() => new Error(error.message || 'Error al crear usuario'))
      )
    );
  }

  updateUser(user: UpdateUserRequest | User): Observable<User> {
    return from(
      this.callAdminFunction<AdminFunctionUpdateResponse>('update-user', {
        id: user.id,
        name: user.name,
        email: user.email,
        cedula: user.cedula,
        role: user.role
      })
    ).pipe(
      map(response => this.mapToUser(response.user)),
      catchError(error =>
        throwError(() => new Error(error.message || 'Error al actualizar usuario'))
      )
    );
  }

  updatePassword(userId: string, newPassword: string): Observable<void> {
    return from(
      this.callAdminFunction<AdminFunctionPasswordResponse>('update-password', {
        userId,
        password: newPassword
      })
    ).pipe(
      map(() => void 0),
      catchError(error =>
        throwError(() => new Error(error.message || 'Error al actualizar contraseña'))
      )
    );
  }

  private async callAdminFunction<T>(
    action: string,
    payload: {
      id?: string;
      userId?: string;
      name?: string;
      email?: string;
      cedula?: string;
      role?: UserRole;
      password?: string;
    }
  ): Promise<T> {
    const {
      data: { session }
    } = await this.supabaseService.getClient().auth.getSession();

    if (!session?.access_token) {
      throw new Error('No hay sesión activa');
    }

    const response = await fetch(this.getFunctionEndpoint('admin-users'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${session.access_token}`
      },
      body: JSON.stringify({
        action,
        ...payload
      })
    });

    let result: unknown;

try {
  result = await response.json();
} catch {
  result = null;
}

if (!response.ok) {
  const message =
    typeof result === 'object' &&
    result !== null &&
    'error' in result &&
    typeof (result as { error: unknown }).error === 'string'
      ? (result as { error: string }).error
      : `Error HTTP ${response.status} en la función administrativa`;

  throw new Error(message);
}

    return result as T;
  }

  private mapToUser(data: AppUserRow): User {
    return {
      id: data.id,
      auth_user_id: data.auth_user_id ?? null,
      name: data.name,
      email: data.email,
      cedula: data.cedula,
      role: data.role as UserRole
    };
    
  }
  deleteUser(userId: string) {
  return from(
    this.callAdminFunction('delete-user', { id: userId })
  );
}
}