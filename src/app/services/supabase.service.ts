// ============================================================
// SERVICIO DE SUPABASE - Conexión con la base de datos
// ============================================================

// Importa el decorador Injectable de Angular para hacer el servicio disponible en toda la app
import { Injectable } from '@angular/core';
// Importa las funciones de Supabase para crear el cliente
import { createClient, SupabaseClient } from '@supabase/supabase-js';
// Importa la configuración del entorno (URL y clave de Supabase)
import { environment } from '../../environments/environment';

// ============================================================
// Decorador que marca esta clase como un servicio de Angular
// 'providedIn: root' significa que Angular crea una única instancia en toda la app
// ============================================================
@Injectable({
  providedIn: 'root'
})

// ============================================================
// Clase que gestiona la conexión con Supabase
// Es el servicio central para todas las operaciones de base de datos
// ============================================================
export class SupabaseService {
  // Cliente de Supabase que se usará para todas las operaciones
  private readonly client: SupabaseClient;

  // ============================================================
  // Constructor: se ejecuta al crear el servicio
  // Inicializa el cliente de Supabase con la URL y clave del entorno
  // ============================================================
  constructor() {
    // Crea el cliente de Supabase usando las credenciales del archivo environment.ts
    this.client = createClient(
      environment.supabaseUrl,  // URL del proyecto Supabase
      environment.supabaseKey   // Clave pública de Supabase
    );
  }

  // ============================================================
  // Devuelve el cliente de Supabase para hacer consultas
  // Se usa en otros servicios para interactuar con la base de datos
  // ============================================================
  getClient(): SupabaseClient {
    return this.client;
  }

  // ============================================================
  // Devuelve solo la URL de Supabase
  // Útil cuando se necesita la URL para otras operaciones (ej: funciones serverless)
  // ============================================================
  getUrl(): string {
    return environment.supabaseUrl;
  }
}