# DOCUMENTACIÓN COMPLETA — EscuelaMAK
> Última actualización: 2026-03-17
> Plataforma educativa con app web Angular 17 + app móvil Flutter + backend Supabase

---

## TABLA DE CONTENIDOS

1. [Visión General](#1-visión-general)
2. [Stack Tecnológico](#2-stack-tecnológico)
3. [Estructura del Proyecto](#3-estructura-del-proyecto)
4. [Base de Datos Supabase](#4-base-de-datos-supabase)
5. [App Web Angular — Servicios](#5-app-web-angular--servicios)
6. [App Web Angular — Componentes](#6-app-web-angular--componentes)
7. [App Web Angular — Rutas y Guards](#7-app-web-angular--rutas-y-guards)
8. [App Móvil Flutter](#8-app-móvil-flutter)
9. [Sistema de Mensajería](#9-sistema-de-mensajería)
10. [Roles y Permisos](#10-roles-y-permisos)
11. [Cómo Hacer Cambios — Guía Práctica](#11-cómo-hacer-cambios--guía-práctica)
12. [Errores Conocidos y Soluciones](#12-errores-conocidos-y-soluciones)

---

## 1. Visión General

EscuelaMAK es una plataforma educativa compuesta por tres partes que trabajan juntas:

```
┌─────────────────────┐     ┌──────────────────────┐
│   APP WEB (Angular) │     │  APP MÓVIL (Flutter) │
│   Para Admins,      │     │  Para Estudiantes    │
│   Profesores,       │────▶│  en sus teléfonos    │
│   Tutores y         │     │                      │
│   Estudiantes       │     └──────────────────────┘
└─────────────────────┘              │
          │                          │
          ▼                          ▼
┌──────────────────────────────────────────────┐
│              SUPABASE (Backend)              │
│  PostgreSQL + Auth + Realtime + Functions    │
└──────────────────────────────────────────────┘
```

**Flujo básico:**
1. El administrador crea cursos, clases, lecciones y quizzes desde la web.
2. Los estudiantes se conectan desde la app móvil para ver sus lecciones y tomar quizzes.
3. Admins/profesores pueden enviar mensajes a estudiantes desde la web; los estudiantes responden desde la app móvil.

---

## 2. Stack Tecnológico

### App Web
| Tecnología | Versión | Para qué se usa |
|-----------|---------|-----------------|
| Angular | 17 | Framework principal de la web |
| TypeScript | 5.x | Lenguaje de programación (JavaScript tipado) |
| RxJS | 7.x | Manejo de datos asíncronos (observables) |
| Supabase JS | 2.x | Cliente para conectarse a la base de datos |

### App Móvil
| Tecnología | Versión | Para qué se usa |
|-----------|---------|-----------------|
| Flutter | 3.x | Framework para iOS y Android desde un mismo código |
| Dart | 3.x | Lenguaje de programación |
| Supabase Flutter | 2.3.0 | Cliente Supabase para Flutter |
| Flutter Riverpod | 2.4.9 | Manejo de estado (como NgRx pero más simple) |
| Go Router | 13.2.0 | Navegación entre pantallas |

### Backend
| Tecnología | Para qué se usa |
|-----------|-----------------|
| Supabase | Plataforma backend completa |
| PostgreSQL | Base de datos relacional |
| Supabase Auth | Autenticación de usuarios |
| Row Level Security (RLS) | Seguridad a nivel de fila en la BD |
| Deno/TypeScript | Edge Functions (código serverless) |

---

## 3. Estructura del Proyecto

```
escuelamak/                          ← Raíz del repositorio
│
├── DOCUMENTACION.md                 ← Este archivo
│
├── src/                             ← APP WEB ANGULAR
│   └── app/
│       ├── app.routes.ts            ← Todas las rutas de la web
│       ├── components/              ← Pantallas y partes visuales
│       ├── services/                ← Lógica de negocio y acceso a BD
│       ├── models/                  ← Definición de tipos de datos
│       ├── guards/                  ← Protección de rutas
│       └── pipes/                   ← Transformaciones de datos en templates
│
├── escuelamak/                      ← APP MÓVIL FLUTTER
│   └── lib/
│       ├── main.dart                ← Punto de entrada de la app
│       ├── core/                    ← Configuración global
│       │   ├── constants/           ← Credenciales Supabase
│       │   ├── router/              ← Navegación Go Router
│       │   └── theme/               ← Colores y tipografía
│       ├── features/                ← Pantallas por funcionalidad
│       │   ├── auth/                ← Login
│       │   ├── home/                ← Pantalla principal / splash
│       │   ├── classes/             ← Vista de clases del estudiante
│       │   ├── lessons/             ← Vista de lecciones (nuevo)
│       │   ├── quizzes/             ← Vista de quizzes (nuevo)
│       │   ├── tasks/               ← Tareas
│       │   └── messages/            ← Mensajería
│       └── shared/                  ← Modelos y widgets reutilizables
│
└── supabase/                        ← BACKEND
    ├── config.toml                  ← Configuración del proyecto Supabase
    ├── migrations/                  ← Cambios a la base de datos (historial)
    └── functions/                   ← Edge Functions (API serverless)
        ├── admin-users/             ← API para gestión de usuarios
        └── mobile-api/              ← API para la app móvil
```

---

## 4. Base de Datos Supabase

### Tablas Principales

#### `auth.users` (manejada por Supabase Auth)
```
Columnas importantes:
  id          → UUID único del usuario EN EL SISTEMA DE AUTH
               ⚠️ Este es el ID que se usa en mensajes/conversaciones
  email       → Email del usuario
  created_at  → Fecha de registro
```

#### `app_users` (usuarios de la aplicación)
```
Columnas:
  id              → UUID interno de la app (diferente a auth.users.id)
  name            → Nombre completo
  email           → Email (debe coincidir con auth.users.email)
  role            → 'admin' | 'teacher' | 'tutor' | 'student'
  auth_user_id    → ← IMPORTANTE: vincula con auth.users.id
                    Se actualiza automáticamente al hacer login
  created_at      → Fecha de creación

⚠️ REGLA IMPORTANTE:
  - app_users.id       → Se usa para relacionar cursos, quizzes, etc.
  - app_users.auth_user_id → Se usa para mensajes y conversaciones
  - Son IDs DIFERENTES. No los confundas.
```

#### `courses` (cursos)
```
Columnas:
  id          → UUID
  title       → Título del curso
  description → Descripción
  image_url   → URL de la imagen del curso
  color       → Color del curso (para el fondo)
  is_active   → Si el curso está visible para estudiantes
  created_at  → Fecha de creación
```

#### `classes` (clases dentro de un curso)
```
Columnas:
  id          → UUID
  course_id   → Referencia a courses.id
  title       → Título de la clase
  description → Descripción
  order_index → Orden dentro del curso
  is_active   → Si la clase está visible
  created_at  → Fecha de creación
```

#### `lessons` (lecciones dentro de una clase)
```
Columnas:
  id          → UUID
  class_id    → Referencia a classes.id
  title       → Título de la lección
  content     → Contenido HTML de la lección
  video_url   → URL del video (YouTube, etc.)
  order_index → Orden dentro de la clase
  is_active   → Si la lección está visible
  created_at  → Fecha de creación
```

#### `quizzes` (cuestionarios)
```
Columnas:
  id          → UUID
  title       → Título del quiz
  description → Descripción
  difficulty  → 'easy' | 'medium' | 'hard'
  is_enabled  → Si el quiz está activo
  created_at  → Fecha de creación
```

#### `quiz_questions` (preguntas de un quiz)
```
Columnas:
  id          → UUID
  quiz_id     → Referencia a quizzes.id
  question    → Texto de la pregunta
  order_index → Orden dentro del quiz
```

#### `quiz_options` (opciones de respuesta)
```
Columnas:
  id          → UUID
  question_id → Referencia a quiz_questions.id
  text        → Texto de la opción
  is_correct  → Si esta opción es la correcta
```

#### `quiz_attempts` (intentos de quiz por estudiante)
```
Columnas:
  id          → UUID
  quiz_id     → Referencia a quizzes.id
  student_id  → Referencia a app_users.id
  score       → Puntaje obtenido (0-100)
  passed      → Si aprobó (true/false)
  answers     → JSON con las respuestas del estudiante
  created_at  → Fecha del intento
```

#### `conversations` (conversaciones de mensajería)
```
Columnas:
  id              → UUID
  participant_ids → ARRAY de auth.users.id de los participantes
                    Ejemplo: ['uuid-admin', 'uuid-estudiante']
  last_message_at → Fecha del último mensaje (para ordenar)

⚠️ IMPORTANTE: participant_ids contiene auth.users.id, NO app_users.id
```

#### `messages` (mensajes individuales)
```
Columnas:
  id              → UUID
  conversation_id → Referencia a conversations.id (puede ser NULL)
  sender_id       → auth.users.id del que envía
  receiver_id     → auth.users.id del que recibe
  contenido       → Texto del mensaje
  is_read         → Si fue leído (true/false)
  created_at      → Fecha de envío

⚠️ IMPORTANTE: sender_id y receiver_id son auth.users.id, NO app_users.id
```

#### `platform_permissions` (permisos de módulos por rol)
```
Columnas:
  id          → UUID
  module_key  → Identificador del módulo (ej: 'menu_courses')
  role        → Rol al que aplica ('admin', 'teacher', etc.)
  is_enabled  → Si el módulo está habilitado para ese rol
```

### Migraciones SQL

Las migraciones están en `supabase/migrations/`. Cada archivo es un cambio a la BD.
Para aplicar una migración nueva, ejecutarla en el **SQL Editor de Supabase**.

**Migraciones importantes recientes:**
- `20260317000000_messages_table.sql` — Crea las tablas `conversations` y `messages`
- `20260317010000_fix_messages_nullable.sql` — Hace nullable `conversation_id` y deshabilita RLS en mensajes
- `20260316040000_add_is_active_to_courses_and_classes.sql` — Agrega `is_active` a cursos y clases
- `20260314000000_platform_permissions.sql` — Sistema de permisos por módulo

---

## 5. App Web Angular — Servicios

Los servicios están en `src/app/services/` y contienen la lógica de negocio.

### `supabase.service.ts`
```typescript
// Crea y expone el cliente de Supabase
// Todos los demás servicios lo usan para hacer consultas a la BD

@Injectable({ providedIn: 'root' })
export class SupabaseService {
  private supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  getClient() {
    return this.supabase;  // Retorna el cliente para hacer queries
  }
}

// Cómo cambiarlo:
// - Las credenciales están en src/environments/environment.ts
// - O directamente en este archivo si no hay environments
```

### `auth.service.ts`
```typescript
// Maneja toda la autenticación: login, logout, usuario actual

currentUser$  // Observable que emite el usuario actual cuando cambia

login(email, password)
// 1. Llama supabase.auth.signInWithPassword()
// 2. Actualiza app_users.auth_user_id con el ID de auth ← CRÍTICO para mensajes
// 3. Busca el usuario en app_users por email
// 4. Guarda en localStorage y emite en currentUser$

logout()
// Cierra sesión en Supabase, borra localStorage, emite null

getCurrentUser()
// Retorna el usuario del BehaviorSubject (sincrono, sin espera)

hasPermission(permission)
// Verifica si el usuario actual tiene un permiso específico
// Los permisos están hardcodeados por rol en este mismo archivo
```

### `user.service.ts`
```typescript
// Operaciones CRUD de usuarios en app_users

getUserByEmail(email)   // Busca usuario por email
getAllUsers()           // Lista todos los usuarios (solo admin)
createUser(data)        // Crea nuevo usuario
updateUser(id, data)    // Actualiza datos del usuario
deleteUser(id)          // Elimina usuario
```

### `course.service.ts`
```typescript
// Operaciones CRUD de cursos

getCourses()            // Lista todos los cursos activos
getCourseById(id)       // Obtiene un curso por ID
createCourse(data)      // Crea nuevo curso
updateCourse(id, data)  // Actualiza un curso
deleteCourse(id)        // Elimina un curso
```

### `quiz.service.ts`
```typescript
// Operaciones de quizzes

getVisibleQuizzes()           // Quizzes habilitados (is_enabled = true)
getAllAttempts()               // Todos los intentos de todos los estudiantes
getStudentQuizzes(studentId)  // Intentos de un estudiante específico
submitQuiz(quizId, answers)   // Guarda un intento del estudiante
```

### `platform-permissions.service.ts`
```typescript
// Controla qué módulos/menús están visibles para cada rol

permissions$  // Observable con los permisos actuales

loadPermissions()
// Carga permisos desde la tabla platform_permissions

isModuleEnabled(moduleKey, role)
// Retorna true/false según si ese módulo está habilitado para ese rol
// Ejemplo: isModuleEnabled('menu_courses', 'student') → true/false
```

### `accessibility.service.ts`
```typescript
// Maneja configuraciones de accesibilidad: fuente, tamaño, etc.
// Aplica CSS custom properties (--font-family, --font-size) al documento
```

---

## 6. App Web Angular — Componentes

### Layout y Navegación

#### `components/layout/app-layout.component` (Contenedor Principal)
```typescript
// Es el "contenedor" de todas las páginas que requieren login.
// Renderiza el sidebar izquierdo + el contenido de la ruta actual.

// PROPIEDADES CLAVE:
currentUser: User | null    // Usuario autenticado
currentAuthId: string       // auth.users.id — capturado UNA VEZ en ngOnInit
                            // ⚠️ NUNCA llamar getUser() de nuevo después de esto
unreadCount: number         // Cantidad de mensajes sin leer para la campana

// MÉTODOS CLAVE:
ngOnInit()
// 1. Carga el usuario actual desde AuthService
// 2. Redirige a /login si no hay sesión
// 3. Se suscribe a cambios de permisos para actualizar el menú
// 4. Llama syncAuthUserId() para obtener y guardar el auth ID
// 5. Inicia polling de mensajes no leídos cada 30 segundos

syncAuthUserId()
// Llama supabase.auth.getUser() UNA SOLA VEZ
// Actualiza app_users.auth_user_id en la BD
// Guarda el ID en this.currentAuthId para no volver a pedirlo

loadUnreadCount()
// Cuenta mensajes no leídos usando this.currentAuthId
// Usa dos métodos y toma el mayor (Math.max) para mayor precisión

goToMessages()
// Navega al modal de mensajes
// Si ya estás en la página → dispara evento window ('escuelamak:open-mensajes')
// Si estás en otra página → guarda 'mensajes' en localStorage y navega

visibleNavItems (getter)
// Filtra los ítems del menú según:
// 1. El rol del usuario (roles[] en cada NavItem)
// 2. Los permisos de plataforma (platform_permissions)
```

**Para agregar un nuevo ítem al menú:**
```typescript
// En app-layout.component.ts, agrega a navItems[]:
{
  label: 'Mi Nuevo Módulo',         // Texto que aparece en el sidebar
  route: '/mi-ruta',                // Ruta Angular donde navega
  icon: 'fas fa-star',              // Ícono FontAwesome
  roles: [UserRole.ADMIN],          // Quién puede verlo
  moduleKey: 'menu_mi_modulo'       // Llave para permisos en platform_permissions
}
```

---

### Autenticación

#### `components/login/login.component`
```typescript
// Pantalla de login con email y contraseña.
// Llama AuthService.login() y redirige según el rol:
//   - ADMIN/TEACHER/TUTOR → /dashboard
//   - STUDENT → /courses
//
// También tiene enlace a /password-reset para recuperar contraseña.
```

#### `components/password-reset/password-reset.component`
```typescript
// Flujo de recuperación de contraseña en dos pasos:
// 1. El usuario ingresa su email → AuthService.requestPasswordReset()
// 2. Supabase envía email con link → usuario hace click
// 3. La app detecta el token en la URL → AuthService.resetPassword()
```

---

### Dashboard

#### `components/dashboard/dashboard.component`
```typescript
// Panel de control para ADMIN, TEACHER y TUTOR.
// Muestra estadísticas: total de cursos, usuarios, quizzes, etc.
// Accesos rápidos a las secciones principales.
```

#### `components/student-dashboard/student-dashboard.component`
```typescript
// Panel de control específico para estudiantes.
// Muestra sus cursos asignados, progreso en lecciones, quizzes pendientes.
```

---

### Gestión de Cursos

#### `components/course-management/course-management.component`
```typescript
// Para ADMIN y TEACHER.
// Permite crear, editar y eliminar cursos.
// Formulario con: título, descripción, imagen, color, estado (activo/inactivo).
//
// Cómo agregar un campo nuevo a cursos:
// 1. Agrega la columna en Supabase (SQL: ALTER TABLE courses ADD COLUMN nombre_campo tipo)
// 2. Agrega el campo al modelo en src/app/models/course.model.ts
// 3. Agrega el input en course-management.component.html
// 4. Actualiza createCourse/updateCourse en course.service.ts para incluir el campo
```

#### `components/courses/courses.component`
```typescript
// Vista de cursos para TODOS los usuarios.
// ESTUDIANTE ve sus cursos y puede abrir el chat de mensajes.
// ADMIN/TEACHER ve todos los cursos.
//
// PROPIEDADES DE MENSAJERÍA:
conversationId: string | null  // ID de la conversación activa
currentAuthId: string          // auth.users.id del estudiante (capturado en ngOnInit)
chatMessages: any[]            // Mensajes de la conversación activa
//
// Los estudiantes pueden abrir el chat desde aquí.
// El chat se abre cuando el sidebar dispara el evento 'escuelamak:open-mensajes'
// o cuando hay 'open_modal'='mensajes' en localStorage.
```

---

### Gestión de Clases y Lecciones

#### `components/class-management/class-management.component`
```typescript
// Para ADMIN y TEACHER.
// Maneja las clases dentro de un curso.
// Una clase es un agrupador de lecciones dentro de un curso.
// Permite: crear, editar, reordenar y eliminar clases.
```

#### `components/lesson-management/lesson-management.component`
```typescript
// Para ADMIN y TEACHER.
// Maneja las lecciones dentro de una clase.
// Ruta: /lesson-management/:courseId
// Una lección puede tener: título, contenido HTML, video URL.
// Permite reordenar lecciones con drag & drop o flechas.
```

#### `components/student-lessons/student-lessons.component`
```typescript
// Vista de lecciones para ESTUDIANTES.
// Muestra las lecciones de sus cursos asignados.
// El estudiante puede marcar una lección como completada.
```

---

### Gestión de Quizzes

#### `components/quiz-management/quiz-management.component`
```typescript
// Para ADMIN, TEACHER y TUTOR.
// Permite crear y gestionar quizzes con preguntas de opción múltiple.
//
// Estructura de un quiz:
// Quiz → Preguntas (quiz_questions) → Opciones (quiz_options)
//
// Cada pregunta tiene varias opciones; una marcada como is_correct = true.
```

#### `components/quiz-taking/quiz-taking.component`
```typescript
// Para todos los roles.
// Ruta: /quiz/:id
// El estudiante responde el quiz. Al finalizar llama QuizService.submitQuiz()
// que calcula el puntaje y guarda el intento en quiz_attempts.
```

#### `components/student-quizzes/student-quizzes.component`
```typescript
// Para ESTUDIANTES.
// Lista de quizzes disponibles con su estado (pendiente/completado/aprobado).
```

---

### Revisión y Mensajería (Solo Staff)

#### `components/review/review.component`
```typescript
// Para ADMIN, TEACHER y TUTOR.
// Tiene tres secciones como modales/paneles:
//
// 1. QUIZZES — lista de quizzes activos con sus preguntas
// 2. LOGROS — intentos de quiz de todos los estudiantes (con filtros)
// 3. MENSAJES — sistema de mensajería con estudiantes ← SECCIÓN PRINCIPAL
//
// PROPIEDADES DE MENSAJERÍA:
currentAuthId: string      // auth.users.id del admin/teacher (capturado en ngOnInit)
conversations: any[]       // Lista de conversaciones
activeConversation: any    // Conversación seleccionada actualmente
activeMessages: any[]      // Mensajes de la conversación activa
replyInput: string         // Texto del campo de respuesta
allStudents: any[]         // Lista de estudiantes para nuevo mensaje
//
// FLUJO DE MENSAJES:
// ngOnInit → getUser() una vez → guarda en currentAuthId
// loadConversations() → busca en conversations tabla → para cada una busca el otro usuario
// openConversation() → carga mensajes, marca como leídos
// sendReply() → inserta mensaje con conversation_id + sender_id=currentAuthId
// sendNewMessage() → busca/crea conversación → inserta primer mensaje
```

---

### Administración

#### `components/user-management/user-management.component`
```typescript
// Para ADMIN únicamente.
// CRUD completo de usuarios de app_users.
// Permite crear usuarios con roles específicos.
// ⚠️ Crear un usuario aquí NO lo crea en Supabase Auth.
// Para crear un usuario con login, usar la Edge Function 'admin-users'.
```

#### `components/module-permissions/module-permissions.component`
```typescript
// Para ADMIN únicamente.
// Controla qué módulos del menú están habilitados para cada rol.
// Los cambios se guardan en platform_permissions.
// El menú del sidebar se actualiza automáticamente al cambiar permisos.
//
// moduleKey disponibles:
//   menu_dashboard, menu_courses, menu_review, menu_user_management,
//   menu_course_management, menu_quiz_management,
//   menu_gradient_generator, menu_parameters, menu_permissions
```

#### `components/parameters/parameters.component`
```typescript
// Para ADMIN únicamente.
// Configuraciones globales de la plataforma.
// Ejemplo: nombre de la institución, logo, colores principales.
```

#### `components/gradient-generator/gradient-generator.component`
```typescript
// Herramienta para generar gradientes CSS.
// Útil para los colores de fondo de cursos y clases.
// Solo para ADMIN y TEACHER.
```

---

## 7. App Web Angular — Rutas y Guards

### Tabla de Rutas (`src/app/app.routes.ts`)

| Ruta | Componente | Roles permitidos | Requiere login |
|------|-----------|-----------------|----------------|
| `/` | — | Todos | No (redirige a /login) |
| `/login` | LoginComponent | Todos | No |
| `/password-reset` | PasswordResetComponent | Todos | No |
| `/student-dashboard` | StudentDashboardComponent | Todos | No |
| `/lesson-management/:courseId` | LessonManagementComponent | Todos | No |
| `/my-lessons` | StudentLessonsComponent | Todos | No |
| `/my-quizzes` | StudentQuizzesComponent | Todos | No |
| `/dashboard` | DashboardComponent | Todos | Sí |
| `/courses` | CoursesComponent | Todos | Sí |
| `/review` | ReviewComponent | ADMIN, TEACHER, TUTOR | Sí |
| `/user-management` | UserManagementComponent | ADMIN | Sí |
| `/course-management` | CourseManagementComponent | ADMIN, TEACHER | Sí |
| `/class-management` | ClassManagementComponent | ADMIN, TEACHER | Sí |
| `/quiz-management` | QuizManagementComponent | ADMIN, TEACHER, TUTOR | Sí |
| `/quiz/:id` | QuizTakingComponent | Todos | Sí |
| `/module-permissions` | ModulePermissionsComponent | ADMIN | Sí |
| `/parameters` | ParametersComponent | ADMIN | Sí |
| `/gradient-generator` | GradientGeneratorComponent | ADMIN, TEACHER | Sí |
| `/**` | — | Todos | No (redirige a /login) |

### Guards

#### `guards/auth.guard.ts`
```typescript
// Verifica que hay una sesión activa.
// Si no hay usuario en AuthService.getCurrentUser() → redirige a /login
// Se aplica a todas las rutas dentro de AppLayoutComponent (el group path '')
```

#### `guards/role.guard.ts`
```typescript
// Verifica que el usuario tiene el rol correcto para la ruta.
// Uso: canActivate: [roleGuard([UserRole.ADMIN, UserRole.TEACHER])]
// Si el rol no está en la lista → redirige al dashboard correspondiente
```

**Para agregar una nueva ruta protegida:**
```typescript
// En app.routes.ts, dentro del bloque { path: '', component: AppLayoutComponent, children: [...] }
{
  path: 'mi-nueva-ruta',
  component: MiNuevoComponent,
  canActivate: [roleGuard([UserRole.ADMIN])]  // Ajusta los roles
}
```

---

## 8. App Móvil Flutter

### Punto de Entrada (`escuelamak/lib/main.dart`)
```dart
// Inicializa Supabase con las credenciales de SupabaseKeys
// Envuelve toda la app en ProviderScope (necesario para Riverpod)
// Aplica el tema y el router

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ← Siempre primero en Flutter
  await Supabase.initialize(
    url: SupabaseKeys.url,          // Tu URL de Supabase
    anonKey: SupabaseKeys.anonKey,  // Tu clave anónima
  );
  runApp(const ProviderScope(child: EscuelaMakApp())); // Inicia la app
}

// Para acceder a Supabase desde cualquier parte:
final supabase = Supabase.instance.client;
```

### Configuración (`escuelamak/lib/core/`)

#### `core/constants/supabase_keys.dart`
```dart
// ⚠️ ARCHIVO SENSIBLE — No subir al repositorio con credenciales reales
// Contiene las claves de conexión a Supabase

class SupabaseKeys {
  static const String url = 'https://TU_PROYECTO.supabase.co';
  static const String anonKey = 'TU_CLAVE_ANONIMA';
}

// Para cambiar las credenciales: edita este archivo
// Las credenciales se encuentran en: Supabase Dashboard → Settings → API
```

#### `core/router/app_router.dart`
```dart
// Define las rutas de la app móvil

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',  // Empieza en SplashScreen
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),    // Splash/carga
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()), // Login
      GoRoute(
        path: '/home',
        builder: (context, state) {
          // Recibe datos del usuario desde el router (pasados por extra)
          final extra = state.extra as Map<String, String>? ?? {};
          return HomeScreen(
            rol: extra['rol'] ?? 'student',
            nombre: extra['nombre'] ?? 'Usuario',
          );
        },
      ),
    ],
  );
});

// Para agregar una nueva pantalla:
// 1. Crea el archivo en features/nueva_feature/presentation/nueva_screen.dart
// 2. Agrega la ruta aquí: GoRoute(path: '/nueva', builder: (_, __) => NuevaScreen())
// 3. Navega con: context.go('/nueva') o context.push('/nueva')
```

#### `core/theme/app_theme.dart`
```dart
// Define los colores y estilos visuales de la app

class AppTheme {
  static ThemeData light = ThemeData(
    // Colores principales, fuentes, estilos de botones, etc.
  );
  static ThemeData dark = ThemeData(
    // Versión oscura del tema
  );
}

// Para cambiar colores: edita los valores en AppTheme.light y AppTheme.dark
// La app usa: ThemeMode.system → cambia según la preferencia del teléfono
```

### Pantallas (`escuelamak/lib/features/`)

#### `features/auth/presentation/login_screen.dart`
```dart
// Pantalla de login del estudiante en la app móvil.
// Flujo:
// 1. Usuario ingresa email + contraseña
// 2. Llama supabase.auth.signInWithPassword()
// 3. Busca el usuario en app_users por email
// 4. Navega a /home pasando rol y nombre como extra
//    context.go('/home', extra: {'rol': user.role, 'nombre': user.name})
```

#### `features/home/presentation/splash_screen.dart`
```dart
// Primera pantalla que aparece al abrir la app.
// Verifica si hay sesión activa en Supabase:
//   - Si hay sesión → navega a /home
//   - Si no hay sesión → navega a /login
// Muestra el logo de la app mientras verifica.
```

#### `features/home/presentation/home_screen.dart`
```dart
// Pantalla principal después del login.
// Recibe: rol (string) y nombre (string) del usuario.
// Muestra un menú según el rol del estudiante.
// CONTIENE EL SISTEMA DE MENSAJERÍA INTEGRADO.
//
// MENSAJERÍA EN HOME SCREEN:
// - Muestra lista de conversaciones con admins/profesores
// - Los mensajes propios aparecen a la DERECHA (burbuja gris/azul)
// - Los mensajes del profesor aparecen a la IZQUIERDA con fondo VERDE (#DCF8C6)
//   → Este color verde imita WhatsApp para distinguir quién habla
//
// Para cambiar el color de las burbujas:
// Busca en home_screen.dart la sección "received message bubble color"
// Cambia: const Color(0xFFDCF8C6) al color que desees
```

#### `features/classes/presentation/classes_screen.dart`
```dart
// Pantalla de clases del estudiante.
// Lista las clases de los cursos asignados al estudiante.
// Al tocar una clase → muestra sus lecciones.
```

---

## 9. Sistema de Mensajería

Este es el sistema más complejo del proyecto. Lee esto con cuidado.

### Arquitectura de la Mensajería

```
IDENTIFICADORES (3 tipos de ID — no confundirlos):
┌─────────────────────────────────────────────────────┐
│  auth.users.id        → ID de autenticación          │
│  app_users.id         → ID interno de la app         │
│  app_users.auth_user_id → Puente entre los dos       │
│                                                       │
│  MENSAJES usan: auth.users.id (sender_id, receiver_id)│
│  CURSOS usan:   app_users.id (student_id, etc.)       │
└─────────────────────────────────────────────────────┘

TABLAS INVOLUCRADAS:
┌──────────────────┐     ┌──────────────────────┐
│  conversations   │     │      messages        │
├──────────────────┤     ├──────────────────────┤
│ id               │◄────│ conversation_id      │
│ participant_ids  │     │ sender_id            │
│ (array de        │     │ receiver_id          │
│  auth.users.id)  │     │ contenido            │
│ last_message_at  │     │ is_read              │
└──────────────────┘     └──────────────────────┘
```

### Flujo Completo de un Mensaje

**Desde la App Web (Admin/Profesor → Estudiante):**
```
1. Admin abre /review y va al modal "Mensajes"
2. review.component.ts llama loadConversations()
   → SELECT * FROM conversations WHERE participant_ids @> [admin_auth_id]
   → Para cada conv: busca el otro participante en app_users por auth_user_id
   → Cuenta mensajes no leídos

3. Admin toca una conversación → openConversation(conv)
   → SELECT * FROM messages WHERE conversation_id = conv.id ORDER BY created_at
   → UPDATE messages SET is_read = true WHERE sender_id = estudiante_auth_id

4. Admin escribe y envía → sendReply()
   → INSERT INTO messages {
       conversation_id: conv.id,
       sender_id: admin.currentAuthId,    ← auth.users.id del admin
       receiver_id: conv.student.auth_user_id, ← auth.users.id del estudiante
       contenido: 'Hola estudiante',
       is_read: false
     }
```

**Desde la App Móvil (Estudiante → Admin/Profesor):**
```
1. Estudiante abre la sección de mensajes en home_screen.dart
2. App busca conversaciones del estudiante
   → SELECT * FROM conversations WHERE participant_ids @> [student_auth_id]
3. Estudiante envía mensaje
   → INSERT INTO messages {
       conversation_id: conv.id,
       sender_id: student_auth_id,
       receiver_id: admin_auth_id,
       contenido: 'Hola profesor',
       is_read: false
     }
4. La campana del admin en la web aumenta su contador (polling cada 30s)
```

### Por Qué `currentAuthId` Es Crítico

```typescript
// ⚠️ PROBLEMA DEL NAVEGADOR COMPARTIDO:
// En el mismo navegador, si hay dos pestañas:
//   - Pestaña 1: Admin logueado
//   - Pestaña 2: Estudiante logueado
// Ambas pestañas comparten localStorage de Supabase.
// Si llamas supabase.auth.getUser() desde la pestaña 1 DESPUÉS de que
// el estudiante hizo login en la pestaña 2, te devuelve el ID del ESTUDIANTE.
//
// SOLUCIÓN: Capturar currentAuthId UNA SOLA VEZ en ngOnInit y no volver a pedirlo.
//
// ✅ CORRECTO:
ngOnInit() {
  const { data: { user } } = await supabase.auth.getUser();
  this.currentAuthId = user?.id ?? '';  // Guardado una vez, nunca más getUser()
}

// ❌ INCORRECTO (no hacer esto):
async sendMessage() {
  const { data: { user } } = await supabase.auth.getUser();  // ← NUNCA acá
  // user.id puede ser el ID del estudiante si hay otra pestaña abierta
}
```

### Notificaciones (Campana en el Sidebar)

```typescript
// En app-layout.component.ts:

// 1. syncAuthUserId() → captura currentAuthId al iniciar
// 2. loadUnreadCount() → llama cada 30 segundos:
//    a. SELECT COUNT FROM messages WHERE receiver_id = authId AND is_read = false
//    b. SELECT FROM conversations WHERE participant_ids @> [authId]
//       → Para cada conv: COUNT mensajes de otros sin leer
//    c. unreadCount = Math.max(a, b)
// 3. La campana en el HTML muestra: <span>{{ unreadCount }}</span>

// Para que las notificaciones lleguen al admin (no al estudiante):
// - El admin debe haber hecho login en la web (para que auth_user_id se sincronice)
// - syncAuthUserId() actualiza app_users.auth_user_id en la BD al cargar el layout
// - Si las notificaciones llegan al lugar equivocado → verificar app_users.auth_user_id
```

---

## 10. Roles y Permisos

### Roles Disponibles

| Rol | Clave | Descripción |
|-----|-------|-------------|
| Administrador | `admin` | Acceso completo a todo |
| Profesor | `teacher` | Gestiona cursos, quizzes y mensajes |
| Tutor | `tutor` | Revisa quizzes y mensajes |
| Estudiante | `student` | Ve cursos, toma quizzes, envía mensajes |

### Permisos por Rol (hardcodeados en `auth.service.ts`)

```typescript
ADMIN:   manage_users, manage_permissions, view_courses, review_exercises,
         create_courses, edit_courses, create_quizzes, edit_quizzes, submit_exercises

TEACHER: view_courses, create_courses, edit_courses,
         create_quizzes, edit_quizzes, review_exercises

TUTOR:   view_courses, review_exercises, create_quizzes

STUDENT: view_courses, submit_exercises, take_quizzes
```

### Permisos Dinámicos (Platform Permissions)

Además de los permisos hardcodeados, hay permisos dinámicos que el admin puede cambiar:
- Se guardan en la tabla `platform_permissions`
- El admin los cambia desde `/module-permissions`
- Controlan qué ítems del sidebar están visibles

```
Ejemplo: Ocultar "Cursos" para estudiantes
→ En /module-permissions, deshabilitar 'menu_courses' para rol 'student'
→ El sidebar de los estudiantes ya no mostrará "Cursos"
→ Pero la ruta /courses sigue existiendo (no hay guards de permisos dinámicos en rutas)
```

---

## 11. Cómo Hacer Cambios — Guía Práctica

### Cambiar el Color Principal de la App Web

```css
/* En src/global_styles.css */
:root {
  --color-primary: #TU_COLOR;      /* Color principal */
  --color-secondary: #TU_COLOR;    /* Color secundario */
}
```

### Agregar un Nuevo Campo a un Formulario

**Ejemplo: Agregar "Duración" a los cursos**

```sql
-- 1. Agregar la columna en Supabase SQL Editor:
ALTER TABLE courses ADD COLUMN duration_minutes INTEGER DEFAULT 0;
```

```typescript
// 2. Agregar al modelo (src/app/models/course.model.ts):
export interface Course {
  id: string;
  title: string;
  // ... campos existentes ...
  durationMinutes?: number;  // ← Nuevo campo
}
```

```typescript
// 3. Agregar al formulario (course-management.component.html):
<input type="number" [(ngModel)]="newCourse.durationMinutes"
       placeholder="Duración en minutos">
```

```typescript
// 4. Incluir en la petición (course.service.ts):
createCourse(data: Partial<Course>) {
  return this.supabase.from('courses').insert({
    title: data.title,
    // ... campos existentes ...
    duration_minutes: data.durationMinutes  // ← Incluir nuevo campo
  });
}
```

### Agregar una Nueva Pantalla en Flutter

```dart
// 1. Crear el archivo: escuelamak/lib/features/nueva/presentation/nueva_screen.dart

class NuevaScreen extends StatelessWidget {
  const NuevaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Pantalla')),
      body: const Center(child: Text('Contenido aquí')),
    );
  }
}

// 2. Agregar la ruta en core/router/app_router.dart:
GoRoute(
  path: '/nueva',
  builder: (_, __) => const NuevaScreen(),
),

// 3. Navegar desde otra pantalla:
context.push('/nueva');          // Agrega al historial (botón atrás funciona)
context.go('/nueva');            // Reemplaza el historial
```

### Hacer una Consulta a Supabase en Flutter

```dart
// Ejemplo: Cargar lecciones de una clase
Future<List<Map<String, dynamic>>> loadLessons(String classId) async {
  final supabase = Supabase.instance.client;  // Obtener el cliente

  final response = await supabase
    .from('lessons')                           // Tabla a consultar
    .select('id, title, content, video_url')  // Columnas (o '*' para todas)
    .eq('class_id', classId)                  // Filtro WHERE
    .eq('is_active', true)                    // Otro filtro
    .order('order_index');                    // Ordenar por

  return response as List<Map<String, dynamic>>;
}
```

### Hacer una Consulta a Supabase en Angular

```typescript
// Ejemplo en un componente Angular
async loadLessons(classId: string): Promise<void> {
  const supabase = this.supabaseService.getClient();

  const { data, error } = await supabase
    .from('lessons')
    .select('id, title, content, video_url')
    .eq('class_id', classId)
    .eq('is_active', true)
    .order('order_index');

  if (error) {
    console.error('Error cargando lecciones:', error);
    return;
  }

  this.lessons = data ?? [];
}
```

### Ejecutar una Migración SQL Nueva

```
1. Crea el archivo: supabase/migrations/YYYYMMDDHHMMSS_descripcion.sql
2. Escribe el SQL (ALTER TABLE, CREATE TABLE, etc.)
3. Ve al Supabase Dashboard → SQL Editor
4. Pega y ejecuta el contenido del archivo
```

### Deshabilitar RLS para Pruebas

```sql
-- ⚠️ Solo usar en desarrollo/pruebas, no en producción
ALTER TABLE nombre_tabla DISABLE ROW LEVEL SECURITY;

-- Para volver a habilitarlo:
ALTER TABLE nombre_tabla ENABLE ROW LEVEL SECURITY;
```

### Crear un Usuario Nuevo con Acceso a Login

```
Opción A — Desde Supabase Dashboard:
1. Authentication → Users → Invite user
2. Ingresa el email → se envía un email de invitación
3. Luego crear el registro en app_users con el mismo email y rol deseado

Opción B — Desde la Edge Function admin-users:
1. Hacer POST a /functions/v1/admin-users con { email, role, name }
2. La función crea el usuario en auth.users Y en app_users
```

---

## 12. Errores Conocidos y Soluciones

### Error: Mensajes no aparecen / "violates not-null constraint"
```
Causa: La columna conversation_id tiene NOT NULL constraint
Solución: Ejecutar en Supabase SQL Editor:
  ALTER TABLE messages ALTER COLUMN conversation_id DROP NOT NULL;
  ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
  ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;
```

### Error: La notificación de mensaje llega al estudiante, no al admin
```
Causa: app_users.auth_user_id del admin es NULL o tiene un valor viejo
Solución:
  1. El admin debe hacer logout y login de nuevo en la web
  2. Esto ejecuta AuthService.login() que sincroniza auth_user_id
  3. También syncAuthUserId() en app-layout lo actualiza al cargar

Verificar en Supabase:
  SELECT id, name, role, auth_user_id FROM app_users WHERE role = 'admin';
  → auth_user_id NO debe ser NULL
```

### Error: El admin ve sus propios mensajes como si fueran del estudiante
```
Causa: sender_id se compara con app_users.id en lugar de auth.users.id
Solución: En el HTML, usar currentAuthId (no currentUserId):
  [class.msg-mine]="msg.sender_id === currentAuthId"   // ✅ Correcto
  [class.msg-mine]="msg.sender_id === currentUserId"   // ❌ Incorrecto
```

### Error: Las dos pestañas (admin + estudiante) se confunden
```
Causa: Supabase comparte la sesión por localStorage en el mismo navegador
Solución:
  - Usar un navegador diferente o modo incógnito para cada usuario
  - El código ya usa currentAuthId capturado en ngOnInit para evitar esto
  - NUNCA llamar supabase.auth.getUser() en métodos de envío/carga
```

### Error: quiz_assignments 400 Bad Request
```
Causa: La tabla quiz_assignments tiene FK faltante o política RLS bloqueando
Solución: Usar getVisibleQuizzes() en lugar de getQuizzes()
  En quiz.service.ts:
  getVisibleQuizzes() {
    return this.supabase.from('quizzes')
      .select('*')           // Sin join a quiz_assignments
      .eq('is_enabled', true);
  }
```

### Error en Flutter: Tipo nulo en mapa de navegación
```dart
// Error: Null check operator used on a null value en app_router.dart
// Causa: state.extra es null cuando navegas sin pasar datos
// Solución: Siempre usar ?? {} como fallback:
final extra = state.extra as Map<String, String>? ?? {};
```

### Error: Módulo del menú no aparece aunque el permiso esté habilitado
```
Causa: moduleKey en navItems no coincide con module_key en platform_permissions
Verificar en app-layout.component.ts que el moduleKey del ítem de menú
coincide exactamente con el valor en la tabla platform_permissions
Ejemplo:
  navItems: moduleKey = 'menu_courses'
  platform_permissions: module_key = 'menu_courses'  ← deben ser idénticos
```

---

## RESUMEN RÁPIDO — Dónde Está Cada Cosa

| Si quieres cambiar... | Ve a... |
|----------------------|---------|
| Colores globales web | `src/global_styles.css` → variables CSS |
| Menú del sidebar | `src/app/components/layout/app-layout.component.ts` → `navItems[]` |
| Rutas de la web | `src/app/app.routes.ts` |
| Login web | `src/app/components/login/login.component.ts` |
| Lógica de autenticación | `src/app/services/auth.service.ts` |
| Gestión de cursos | `src/app/components/course-management/` |
| Sistema de mensajería web | `src/app/components/review/review.component.ts` (admin) |
| Chat del estudiante web | `src/app/components/courses/courses.component.ts` |
| Notificaciones (campana) | `src/app/components/layout/app-layout.component.ts` → `loadUnreadCount()` |
| Colores app móvil | `escuelamak/lib/core/theme/app_theme.dart` |
| Rutas app móvil | `escuelamak/lib/core/router/app_router.dart` |
| Credenciales Supabase | `escuelamak/lib/core/constants/supabase_keys.dart` |
| Pantalla home móvil | `escuelamak/lib/features/home/presentation/home_screen.dart` |
| Color de burbujas de chat móvil | `home_screen.dart` → buscar `Color(0xFFDCF8C6)` |
| Tablas de la base de datos | Supabase Dashboard → Table Editor |
| Políticas de seguridad (RLS) | Supabase Dashboard → Authentication → Policies |
| Edge Functions (API serverless) | `supabase/functions/` |
