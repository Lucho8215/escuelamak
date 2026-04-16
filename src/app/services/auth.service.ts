// ============================================================
// SERVICIO DE AUTENTICACIÓN - Gestiona el inicio de sesión y control de acceso
// ============================================================

// Importa el decorador Injectable de Angular
import { Injectable } from '@angular/core';

// Importa herramientas de RxJS para manejar observables (flujos de datos asíncronos)
// BehaviorSubject: guarda el estado actual y notifica a los componentes cuando cambia
// Observable: representa un flujo de datos que puede ser escuchado
// from: convierte promesas en observables
// throwError: para lanzar errores
// of: para devolver valores inmediatos
import { BehaviorSubject, Observable, from, throwError, of } from 'rxjs';

// Importa operadores de RxJS para transformar datos
import { catchError, map, switchMap } from 'rxjs/operators';

// Importa los modelos de usuario
import { User, UserRole } from '../models/user.model';

// Importa el servicio de usuarios para buscar información del usuario en la base de datos
import { UserService } from './user.service';

// Importa el servicio de Supabase para conectar con la base de datos
import { SupabaseService } from './supabase.service';

// ============================================================
// Decorador que hace este servicio disponible en toda la aplicación
// ============================================================
@Injectable({
  providedIn: 'root'
})

// ============================================================
// Clase que maneja toda la lógica de autenticación
// Maneja: login, logout, recuperación de contraseña, permisos
// ============================================================
export class AuthService {
  // ============================================================
  // BehaviorSubject para almacenar el usuario actual
  // Permite que los componentes se suscriban y reciban actualizaciones cuando cambia el usuario
  // Inicia como null (nadie logueado)
  // ============================================================
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  
  // Observable público para que los componentes puedan escuchar cambios del usuario
  currentUser$ = this.currentUserSubject.asObservable();

  // ============================================================
  // BehaviorSubject para el estado de conexión (si hay internet o no)
  // Inicia como true (asumimos que hay conexión)
  // ============================================================
  private connectionStatus = new BehaviorSubject<boolean>(true);
  
  // Observable público para el estado de conexión
  connectionStatus$ = this.connectionStatus.asObservable();

  // ============================================================
  // Constructor: se ejecuta al cargar el servicio
  // Carga el usuario guardado previamente en el navegador (localStorage)
  // ============================================================
  constructor(
    private userService: UserService,       // Servicio para buscar usuarios en la base de datos
    private supabaseService: SupabaseService // Servicio de conexión a Supabase
  ) {
    // Al iniciar, intentamos cargar el usuario guardado en el navegador
    this.loadSavedUser();
  }

  // ============================================================
  // Método privado que carga el usuario guardado en localStorage
  // Se ejecuta automáticamente al iniciar la app para mantener la sesión
  // ============================================================
  private loadSavedUser(): void {
    try {
      // Busca en el almacenamiento local del navegador la clave 'currentUser'
      const savedUser = localStorage.getItem('currentUser');
      
      // Si existe un usuario guardado, lo parseamos y guardamos en el BehaviorSubject
      if (savedUser) {
        const user = JSON.parse(savedUser) as User;
        this.currentUserSubject.next(user);  // Notifica a todos los suscriptores
      }
    } catch (error) {
      // Si hay error (ej: datos corruptos), mostramos error y limpiamos
      console.error('Error loading saved user:', error);
      localStorage.removeItem('currentUser');
    }
  }

  // ============================================================
  // Método principal para iniciar sesión
  // Recibe email y contraseña, devuelve un Observable con el usuario
  // ============================================================
  login(email: string, password: string): Observable<User> {
    // Validación: si no hay email o contraseña, error inmediato
    if (!email || !password) {
      return throwError(() => new Error('Por favor, ingresa tu email y contraseña.'));
    }

    // Obtiene el cliente de Supabase para hacer la autenticación
    const supabase = this.supabaseService.getClient();

    // Crea un observable desde la promesa de autenticación de Supabase
    return from(
      // signInWithPassword es el método de Supabase para iniciar sesión con email/contraseña
      supabase.auth.signInWithPassword({ email, password })
    ).pipe(
      // switchMap: procesa la respuesta de la autenticación
      switchMap(({ data, error }) => {
        // Si hay error de Supabase, lo lanzamos
        if (error) {
          throw new Error(error.message);
        }

        // Si no hay usuario en la respuesta, error
        if (!data.user) {
          throw new Error('Usuario no encontrado');
        }

        // Obtenemos el ID del usuario de autenticación (auth)
        const authUserId = data.user.id;

        // ============================================================
        // SINCRONIZACIÓN: Actualiza el auth_user_id en la tabla app_users
        // Esto permite que la app móvil pueda encontrar al usuario
        // usando el ID de autenticación en las conversaciones
        // (participant_ids)
        // ============================================================
        supabase.from('app_users')
          .update({ auth_user_id: authUserId })
          .eq('email', email)
          .then(() => {});  // No necesitamos esperar el resultado

        // Busca el usuario completo en la tabla app_users usando su email
        return from(this.userService.getUserByEmail(email));
      }),
      
      // map: transforma la respuesta al formato de nuestro modelo User
      map(user => {
        if (!user) {
          throw new Error('Usuario no encontrado en la base de datos');
        }

        // Guarda el usuario en localStorage para mantener la sesión
        localStorage.setItem('currentUser', JSON.stringify(user));
        
        // Actualiza el BehaviorSubject con el usuario logueado
        this.currentUserSubject.next(user);
        
        // Marca la conexión como activa
        this.connectionStatus.next(true);

        // Devuelve el usuario
        return user;
      }),
      
      // catchError: maneja cualquier error que ocurra en el proceso
      catchError(error => {
        console.error('Error de inicio de sesión:', error);
        return throwError(() => new Error(
          error.message || 'Error al iniciar sesión. Por favor, intenta de nuevo.'
        ));
      })
    );
  }

  // ============================================================
  // Solicita un correo para restablecer la contraseña
  // Envia un email con enlace para cambiar la contraseña
  // ============================================================
  requestPasswordReset(email: string): Observable<void> {
    return from(
      // resetPasswordForEmail envía el correo de recuperación
      this.supabaseService.getClient().auth.resetPasswordForEmail(email)
    ).pipe(
      map(({ error }) => {
        if (error) {
          throw new Error(error.message);
        }
      }),
      catchError(error => throwError(() => new Error(error.message)))
    );
  }

  // ============================================================
  // Verifica si el token de recuperación de contraseña es válido
  // El token viene en la URL cuando el usuario hace click en el enlace
  // ============================================================
  verifyResetToken(token: string): Observable<boolean> {
    return from(
      // verifyOtp verifica el tokenhash que llegó por email
      this.supabaseService.getClient().auth.verifyOtp({
        token_hash: token,
        type: 'recovery'  // Tipo de verificación: recuperación de contraseña
      })
    ).pipe(
      // Devuelve true si no hay error, false si lo hay
      map(({ error }) => !error),
      catchError(() => of(false))
    );
  }

  // ============================================================
  // Cambia la contraseña del usuario después de verificar el token
  // Se usa después de que el usuario ingresa su nueva contraseña
  // ============================================================
  resetPassword(token: string, newPassword: string): Observable<void> {
    void token;  // Token no se usa aquí porque Supabase usa la sesión activa

    return from(
      // updateUser permite cambiar la contraseña directamente
      this.supabaseService.getClient().auth.updateUser({ password: newPassword })
    ).pipe(
      map(({ error }) => {
        if (error) {
          throw new Error(error.message);
        }
      }),
      catchError(error => throwError(() => new Error(error.message)))
    );
  }

  // ============================================================
  // Cierra la sesión del usuario
  // Elimina los datos de localStorage y limpia el estado
  // ============================================================
  logout(): void {
    // Cierra la sesión en Supabase (invalida el token)
    this.supabaseService.getClient().auth.signOut();
    
    // Elimina el usuario guardado en el navegador
    localStorage.removeItem('currentUser');
    
    // Limpia el BehaviorSubject (pone null)
    this.currentUserSubject.next(null);
  }

  // ============================================================
  // Devuelve el usuario actual sin ser un observable
  // Útil para obtener el usuario inmediatamente (sin suscripción)
  // ============================================================
  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  // ============================================================
  // Verifica si el usuario tiene un permiso específico
  // Recibe el nombre del permiso y devuelve true/false
  // ============================================================
  hasPermission(permission: string): boolean {
    // Obtiene el usuario actual
    const user = this.getCurrentUser();

    // Si no hay usuario, no tiene permisos
    if (!user) {
      return false;
    }

    // ============================================================
    // Definición de permisos por rol
    // Cada rol tiene una lista de permisos disponibles
    // ============================================================
    const permissions: Record<UserRole, string[]> = {
      // Administrador: tiene todos los permisos del sistema
      [UserRole.ADMIN]: [
        'manage_users',           // Gestionar usuarios
        'manage_permissions',     // Gestionar permisos
        'view_courses',           // Ver cursos
        'review_exercises',       // Revisar ejercicios
        'create_courses',         // Crear cursos
        'edit_courses',          // Editar cursos
        'create_quizzes',        // Crear quizzes
        'edit_quizzes',         // Editar quizzes
        'submit_exercises'       // Enviar ejercicios
      ],
      
      // Profesor: puede gestionar cursos y quizzes
      [UserRole.TEACHER]: [
        'view_courses',
        'create_courses',
        'edit_courses',
        'create_quizzes',
        'edit_quizzes',
        'review_exercises'
      ],
      
      // Tutor: puede revisar ejercicios y crear quizzes básicos
      [UserRole.TUTOR]: [
        'view_courses',
        'review_exercises',
        'create_quizzes'
      ],
      
      // Estudiante: puede ver cursos y realizar actividades
      [UserRole.STUDENT]: [
        'view_courses',
        'submit_exercises',
        'take_quizzes'
      ]
    };

    // Busca si el rol del usuario tiene el permiso solicitado
    return permissions[user.role]?.includes(permission) || false;
  }
}