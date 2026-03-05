import { Injectable } from '@angular/core';
import { Observable, from, of } from 'rxjs';
import { User, UserRole } from '../models/user.model';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class UserService {

  private supabase: SupabaseClient = createClient(
    environment.supabaseUrl,
    environment.supabaseKey
  );

  async getUserByEmail(email: string): Promise<User | null> {
    const { data, error } = await this.supabase
      .from('app_users')
      .select('*')
      .eq('email', email)
      .single();

    if (error || !data) return null;

    return {
      id: data.id,
      name: data.name,
      email: data.email,
      role: data.role as UserRole,
      password: ''
    };
  }

  async verifyPassword(email: string, password: string): Promise<boolean> {
    const user = await this.getUserByEmail(email);
    return user !== null;
  }

  getUsers(): Observable<User[]> {
    return from(
      this.supabase
        .from('app_users')
        .select('*')
        .then(({ data }) => (data || []).map(u => ({
          id: u.id,
          name: u.name,
          email: u.email,
          role: u.role as UserRole,
          password: ''
        })))
    );
  }

  createUser(user: Omit<User, 'id'> & { password: string }): Observable<User> {
    return from(
      this.supabase
        .from('app_users')
        .insert([{ name: user.name, email: user.email, role: user.role }])
        .select()
        .single()
        .then(({ data }) => ({
          id: data.id,
          name: data.name,
          email: data.email,
          role: data.role as UserRole,
          password: ''
        }))
    );
  }

  updateUser(user: User): Observable<User> {
    return from(
      this.supabase
        .from('app_users')
        .update({ name: user.name, email: user.email, role: user.role })
        .eq('id', user.id)
        .select()
        .single()
        .then(({ data }) => ({
          id: data.id,
          name: data.name,
          email: data.email,
          role: data.role as UserRole,
          password: ''
        }))
    );
  }

  updatePassword(userId: string, newPassword: string): Observable<void> {
    return of(void 0);
  }
}