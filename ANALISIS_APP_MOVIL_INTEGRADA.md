# Análisis Completo: App Móvil Integrada Escuela Mak

## 1. Resumen Ejecutivo

Este documento presenta el análisis y diseño completo para crear una aplicación móvil (Flutter) que se integre perfectamente con la plataforma web existente de Escuela Mak. La app móvil funcionará como un cliente ligero que consume los mismos datos de Supabase, permitiendo a los usuarios acceder y gestionar su contenido educativo desde cualquier dispositivo.

---

## 2. Arquitectura del Sistema

### 2.1 Diagrama de Arquitectura General

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ESCUELA MAK - ARQUITECTURA                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐           ┌─────────────────┐                         │
│  │   WEB APP       │           │   APP MÓVIL     │                         │
│  │   (Angular)     │           │   (Flutter)     │                         │
│  └────────┬────────┘           └────────┬────────┘                         │
│           │                              │                                   │
│           └──────────┬───────────────────┘                                   │
│                      │                                                       │
│                      ▼                                                       │
│           ┌─────────────────────┐                                           │
│           │    SUPABASE         │                                           │
│           │  ┌───────────────┐  │                                           │
│           │  │ Authentication │  │                                           │
│           │  │ (Auth)         │  │                                           │
│           │  └───────────────┘  │                                           │
│           │  ┌───────────────┐  │                                           │
│           │  │   Database     │  │                                           │
│           │  │ (PostgreSQL)   │  │                                           │
│           │  └───────────────┘  │                                           │
│           │  ┌───────────────┐  │                                           │
│           │  │   Storage      │  │                                           │
│           │  │ (Archivos)     │  │                                           │
│           │  └───────────────┘  │                                           │
│           │  ┌───────────────┐  │                                           │
│           │  │ Edge Functions │  │                                           │
│           │  │   (APIs)       │  │                                           │
│           │  └───────────────┘  │                                           │
│           └─────────────────────┘                                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Flujo de Datos

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FLUJO DE DATOS                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ACCIÓN EN WEB                         ACCIÓN EN APP MÓVIL               │
│   ────────────────                      ───────────────────               │
│        │                                        │                           │
│        ▼                                        ▼                           │
│   ┌──────────┐                             ┌──────────┐                   │
│   │ Angular  │                             │ Flutter  │                   │
│   │   App    │                             │   App    │                   │
│   └────┬─────┘                             └────┬─────┘                   │
│        │                                          │                         │
│        └────────────────┬─────────────────────────┘                         │
│                         │                                                   │
│                         ▼                                                   │
│              ┌─────────────────────┐                                        │
│              │  Supabase Client    │                                        │
│              │  (REST / Realtime)  │                                        │
│              └──────────┬──────────┘                                        │
│                         │                                                   │
│          ┌──────────────┼──────────────┐                                    │
│          │              │              │                                    │
│          ▼              ▼              ▼                                    │
│    ┌──────────┐  ┌──────────┐  ┌──────────┐                              │
│    │  Auth     │  │ Database │  │ Storage  │                              │
│    │  (JWT)    │  │  (RLS)   │  │          │                              │
│    └──────────┘  └──────────┘  └──────────┘                              │
│                                                                             │
│    LOS CAMBIOS SE SINCRONIZAN EN TIEMPO REAL VIA SUPABASE REALTIME         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Análisis de Requisitos

### 3.1 Requisitos Funcionales

| # | Módulo | Descripción | Web | App Móvil |
|---|--------|-------------|-----|-----------|
| 1 | **Autenticación** | Iniciar sesión, registro, recuperación de contraseña | ✅ | ✅ |
| 2 | **Dashboard** | Vista principal según rol de usuario | ✅ | ✅ |
| 3 | **Módulos/Permisos** | Mostrar módulos según permisos del usuario | ✅ | ✅ |
| 4 | **Gestión de Cursos** | Crear, editar, eliminar, publicar cursos | ✅ | 👨‍🏫 |
| 5 | **Lecciones/Clases** | Crear, editar, eliminar lecciones | ✅ | 👨‍🏫 |
| 6 | **Contenido de Lecciones** | Texto, videos, archivos adjuntos | ✅ | ✅ |
| 7 | **Tareas** | Crear tareas, entregar tareas, calificar | ✅ | ✅ |
| 8 | **Quizzes/Evaluaciones** | Crear quizzes, responder, ver resultados | ✅ | ✅ |
| 9 | **Mensajería** | Chat entre estudiantes y profesores | ✅ | ✅ |
| 10 | **Progreso** | Seguimiento de progreso en cursos | ✅ | ✅ |
| 11 | **Matrículas** | Inscribir/desinscribir en cursos | ✅ | ✅ |
| 12 | **Administración** | Gestión de usuarios y permisos | ✅ | 🔒 |

### 3.2 Comparativa: Web vs App Móvil

| Funcionalidad | Web (Angular) | App Móvil (Flutter) | Notas |
|---------------|---------------|---------------------|-------|
| **Crear Cursos** | ✅ Completo | 👨‍🏫 Solo profesor | Mismos datos |
| **Editar Lecciones** | ✅ Completo | 👨‍🏫 Solo profesor | Mismos datos |
| **Ver Contenido** | ✅ Completo | ✅ Completo | Mismos datos |
| **Entregar Tareas** | ✅ Completo | ✅ Completo | Mismos datos |
| **Ver Videos** | ✅ En navegador | ✅ Video player nativo | Mejor experiencia |
| **Realizar Quizzes** | ✅ Completo | ✅ Completo | Mismos datos |
| **Chat/Mensajes** | ✅ Completo | ✅ Notificaciones push | Sincronizado |
| **Admin Panel** | ✅ Completo | ❌ No necesario | Solo web |

### 3.3 Permisos por Rol

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PERMISOS POR ROL                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                        │
│  │  ESTUDIANTE │  │  PROFESOR   │  │   ADMIN     │                        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                        │
│         │                 │                 │                               │
│  ┌──────┴──────┐  ┌───────┴───────┐  ┌──────┴──────┐                       │
│  │ • Ver cursos │  │ • Todo lo del │  │ • Acceso    │                       │
│  │ • Ver clases │  │   estudiante  │  │   total     │                       │
│  │ • Ver tareas │  │ • Crear curso │  │ • Crear     │                       │
│  │ • Entregar   │  │ • Editar clases│  │   usuarios  │                      │
│  │ • Hacer quiz │  │ • Calificar   │  │ • Permisos  │                       │
│  │ • Chat       │  │ • Ver stats   │  │ • Stats     │                       │
│  │ • Mi progreso│  │ • Chat        │  │ • Settings  │                       │
│  └─────────────┘  └───────────────┘  └─────────────┘                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Diseño de APIs para App Móvil

### 4.1 Endpoints Existentes (Ya Creados)

| Endpoint | Acción | Descripción | Parámetros |
|----------|--------|-------------|-------------|
| [`mobile-api`](supabase/functions/mobile-api/index.ts) | `get-modules` | Obtiene módulos según permisos | `user_id` |
| [`mobile-api`](supabase/functions/mobile-api/index.ts) | `get-courses` | Lista cursos disponibles | `user_id`, `status` |
| [`mobile-api`](supabase/functions/mobile-api/index.ts) | `get-course-content` | Obtiene contenido del curso | `course_id`, `user_id` |
| [`mobile-api`](supabase/functions/mobile-api/index.ts) | `get-lesson` | Obtiene detalle de lección | `lesson_id`, `user_id` |
| [`mobile-api`](supabase/functions/mobile-api/index.ts) | `update-lesson` | Edita una lección | `lesson_id`, `user_id`, `titulo`, `contenido`, etc. |
| [`mobile-api`](supabase/functions/mobile-api/index.ts) | `complete-lesson` | Marca clase completada | `lesson_id`, `user_id`, `progress_pct` |
| [`mobile-api`](supabase/functions/mobile-api/index.ts) | `report-lesson-status` | Reporta estado desde app | `lesson_id`, `user_id`, `status` |
| [`mobile-api`](supabase/functions/mobile-api/index.ts) | `get-user-progress` | Obtiene progreso del usuario | `user_id` |
| [`mobile-api`](supabase/functions/mobile-api/index.ts) | `enroll-course` | Matricular en curso | `course_id`, `user_id` |

### 4.2 Endpoints Adicionales Requeridos

#### A. Gestión de Cursos (Profesor/Admin)

```typescript
// action: "create-course"
// Crear un nuevo curso
{
  "action": "create-course",
  "user_id": "uuid",
  "titulo": "Título del curso",
  "descripcion": "Descripción",
  "categoria_id": "uuid",
  "imagen_url": "https://...",
  "is_published": false
}

// action: "update-course"
// Actualizar un curso
{
  "action": "update-course",
  "course_id": "uuid",
  "user_id": "uuid",
  "titulo": "Nuevo título",        // opcional
  "descripcion": "Nueva desc",    // opcional
  "is_published": true            // opcional
}

// action: "delete-course"
// Eliminar un curso
{
  "action": "delete-course",
  "course_id": "uuid",
  "user_id": "uuid"
}
```

#### B. Gestión de Lecciones (Profesor/Admin)

```typescript
// action: "create-lesson"
// Crear una lección
{
  "action": "create-lesson",
  "user_id": "uuid",
  "course_id": "uuid",
  "titulo": "Título de la lección",
  "contenido": "Contenido en markdown/HTML",
  "video_url": "https://youtube.com/...",
  "orden": 1
}

// action: "delete-lesson"
// Eliminar una lección
{
  "action": "delete-lesson",
  "lesson_id": "uuid",
  "user_id": "uuid"
}
```

#### C. Gestión de Tareas

```typescript
// action: "get-tasks"
// Obtener tareas del usuario
{
  "action": "get-tasks",
  "user_id": "uuid"
}

// action: "create-task" (Profesor)
// Crear tarea
{
  "action": "create-task",
  "user_id": "uuid",
  "lesson_id": "uuid",
  "titulo": "Título de la tarea",
  "descripcion": "Instrucciones",
  "fecha_entrega": "2024-12-31T23:59:00Z",
  "archivo_url": "https://..."  // archivo del profesor
}

// action: "submit-task" (Estudiante)
// Entregar tarea
{
  "action": "submit-task",
  "user_id": "uuid",
  "task_id": "uuid",
  "archivo_url": "https://...",
  "comentarios": "Mi respuesta..."
}

// action: "grade-task" (Profesor)
// Calificar tarea
{
  "action": "grade-task",
  "user_id": "uuid",
  "submission_id": "uuid",
  "calificacion": 85,
  "retroalimentación": "Muy bien!"
}
```

#### D. Gestión de Quizzes

```typescript
// action: "get-quiz"
// Obtener quiz para realizar
{
  "action": "get-quiz",
  "quiz_id": "uuid",
  "user_id": "uuid"
}

// action: "submit-quiz"
// Enviar respuestas del quiz
{
  "action": "submit-quiz",
  "user_id": "uuid",
  "quiz_id": "uuid",
  "respuestas": {
    "question_id_1": "respuesta",
    "question_id_2": "respuesta"
  },
  "tiempo_usado": 1800  // segundos
}

// action: "create-quiz" (Profesor)
// Crear quiz
{
  "action": "create-quiz",
  "user_id": "uuid",
  "lesson_id": "uuid",
  "titulo": "Quiz de la lección 1",
  "descripcion": "Evaluación de conocimientos",
  "tiempo_limite": 30,
  "intentos_permitidos": 2,
  "mostrar_resultados": true,
  "questions": [
    {
      "tipo_pregunta": "opcion_multiple",
      "pregunta": "¿Cuál es la respuesta?",
      "opciones": ["A", "B", "C", "D"],
      "respuestas_correctas": ["A"],
      "puntos": 1
    }
  ]
}
```

#### E. Mensajería

```typescript
// action: "get-conversations"
// Obtener conversaciones
{
  "action": "get-conversations",
  "user_id": "uuid"
}

// action: "get-messages"
// Obtener mensajes de una conversación
{
  "action": "get-messages",
  "user_id": "uuid",
  "conversation_id": "uuid"
}

// action: "send-message"
// Enviar mensaje
{
  "action": "send-message",
  "user_id": "uuid",
  "receiver_id": "uuid",
  "contenido": "Hola!",
  "archivo_adjunto": "https://..."  // opcional
}
```

#### F. Usuario y Perfil

```typescript
// action: "get-profile"
// Obtener perfil del usuario
{
  "action": "get-profile",
  "user_id": "uuid"
}

// action: "update-profile"
// Actualizar perfil
{
  "action": "update-profile",
  "user_id": "uuid",
  "nombres": "Juan",
  "apellidos": "Pérez",
  "foto_url": "https://..."
}

// action: "update-password"
// Cambiar contraseña
{
  "action": "update-password",
  "user_id": "uuid",
  "password": "nueva_contraseña"
}
```

#### G. Estadísticas

```typescript
// action: "get-stats"
// Obtener estadísticas (Profesor/Admin)
{
  "action": "get-stats",
  "user_id": "uuid",
  "type": "courses" | "users" | "progress" | "general"
}
```

---

## 5. Estructura del Proyecto Flutter

### 5.1 Estructura de Carpetas Propuesta

```
escuelamak/                          # Proyecto Flutter principal
├── lib/
│   ├── main.dart                    # Entry point
│   ├── app.dart                     # Configuración de la app
│   ├── config/
│   │   ├── app_config.dart          # Configuración general
│   │   ├── supabase_config.dart     # Configuración de Supabase
│   │   └── api_config.dart          # URLs de la API
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart      # Colores de la marca
│   │   │   ├── app_strings.dart     # Strings globales
│   │   │   └── app_sizes.dart       # Tamaños y spacing
│   │   ├── theme/
│   │   │   ├── app_theme.dart       # Tema claro
│   │   │   └── app_dark_theme.dart  # Tema oscuro
│   │   ├── utils/
│   │   │   ├── date_utils.dart      # Utilidades de fecha
│   │   │   ├── validators.dart      # Validadores
│   │   │   └── extensions.dart     # Extensiones útiles
│   │   └── errors/
│   │       ├── exceptions.dart      # Excepciones personalizadas
│   │       └── failures.dart        # Fallos para manejo de errores
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   ├── local_storage.dart    # SharedPreferences
│   │   │   │   └── hive_storage.dart     # Base de datos local
│   │   │   └── remote/
│   │   │   │   ├── supabase_client.dart  # Cliente de Supabase
│   │   │   │   ├── api_client.dart        # Cliente HTTP
│   │   │   │   └── mobile_api.dart        # API específica móvil
│   │   │   └── realtime/
│   │   │       └── realtime_listener.dart # Supabase Realtime
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── course_model.dart
│   │   │   ├── lesson_model.dart
│   │   │   ├── task_model.dart
│   │   │   ├── quiz_model.dart
│   │   │   ├── message_model.dart
│   │   │   ├── category_model.dart
│   │   │   └── permission_model.dart
│   │   └── repositories/
│   │       ├── auth_repository.dart
│   │       ├── user_repository.dart
│   │       ├── course_repository.dart
│   │       ├── lesson_repository.dart
│   │       ├── task_repository.dart
│   │       ├── quiz_repository.dart
│   │       ├── message_repository.dart
│   │       └── progress_repository.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── user.dart
│   │   │   ├── course.dart
│   │   │   └── ...
│   │   └── repositories/
│   │       ├── i_auth_repository.dart
│   │       └── i_course_repository.dart
│   ├── presentation/
│   │   ├── blocs/
│   │   │   ├── auth/
│   │   │   │   ├── auth_bloc.dart
│   │   │   │   ├── auth_event.dart
│   │   │   │   └── auth_state.dart
│   │   │   ├── splash/
│   │   │   ├── home/
│   │   │   ├── courses/
│   │   │   ├── lessons/
│   │   │   ├── tasks/
│   │   │   ├── quizzes/
│   │   │   ├── messages/
│   │   │   └── profile/
│   │   ├── screens/
│   │   │   ├── splash/
│   │   │   │   └── splash_screen.dart
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   └── reset_password_screen.dart
│   │   │   ├── main/
│   │   │   │   └── main_screen.dart    # Contenedor con bottom navigation
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart
│   │   │   ├── courses/
│   │   │   │   ├── courses_list_screen.dart
│   │   │   │   ├── course_detail_screen.dart
│   │   │   │   ├── course_create_screen.dart
│   │   │   │   └── course_edit_screen.dart
│   │   │   ├── lessons/
│   │   │   │   ├── lesson_list_screen.dart
│   │   │   │   ├── lesson_detail_screen.dart
│   │   │   │   ├── lesson_video_screen.dart
│   │   │   │   └── lesson_edit_screen.dart
│   │   │   ├── tasks/
│   │   │   │   ├── tasks_list_screen.dart
│   │   │   │   ├── task_detail_screen.dart
│   │   │   │   ├── task_submit_screen.dart
│   │   │   │   └── task_grade_screen.dart
│   │   │   ├── quizzes/
│   │   │   │   ├── quiz_list_screen.dart
│   │   │   │   ├── quiz_screen.dart
│   │   │   │   └── quiz_result_screen.dart
│   │   │   ├── messages/
│   │   │   │   ├── conversations_screen.dart
│   │   │   │   └── chat_screen.dart
│   │   │   └── profile/
│   │   │       ├── profile_screen.dart
│   │   │       └── profile_edit_screen.dart
│   │   └── widgets/
│   │       ├── common/
│   │       │   ├── app_button.dart
│   │       │   ├── app_text_field.dart
│   │       │   ├── app_card.dart
│   │       │   ├── loading_widget.dart
│   │       │   ├── error_widget.dart
│   │       │   └── empty_widget.dart
│   │       ├── course/
│   │       │   ├── course_card.dart
│   │       │   ├── course_tile.dart
│   │       │   └── progress_indicator.dart
│   │       ├── lesson/
│   │       │   ├── lesson_card.dart
│   │       │   ├── video_player_widget.dart
│   │       │   └── lesson_progress.dart
│   │       ├── task/
│   │       │   ├── task_card.dart
│   │       │   ├── task_submission_card.dart
│   │       │   └── file_upload_widget.dart
│   │       ├── quiz/
│   │       │   ├── quiz_question.dart
│   │       │   ├── quiz_option.dart
│   │       │   └── quiz_timer.dart
│   │       └── messages/
│   │           ├── message_bubble.dart
│   │           └── conversation_tile.dart
│   ├── routes/
│   │   ├── app_router.dart
│   │   ├── app_routes.dart
│   │   └── route_guard.dart
│   ├── services/
│   │   ├── notification_service.dart
│   │   ├── download_service.dart
│   │   └── sync_service.dart
│   └── injection_container.dart
├── assets/
│   ├── images/
│   ├── icons/
│   └── l10n/
├── test/
├── android/
├── ios/
└── pubspec.yaml
```

### 5.2 pubspec.yaml - Depencias Recomendadas

```yaml
name: escuelamak
description: Aplicación móvil de la Escuela Mak
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # Supabase
  supabase_flutter: ^2.0.0
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Navigation
  go_router: ^13.0.0
  
  # Network
  dio: ^5.3.0
  
  # Local Storage
  shared_preferences: ^2.2.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # UI
  cached_network_image: ^3.3.0
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0
  pull_to_refresh: ^2.0.0
  
  # Media
  video_player: ^2.7.0
  chewie: ^1.7.0
  image_picker: ^1.0.4
  file_picker: ^6.1.1
  
  # Utils
  intl: ^0.18.1
  uuid: ^4.2.1
  url_launcher: ^6.2.1
  path_provider: ^2.1.1
  connectivity_plus: ^5.0.1
  
  # Notifications
  flutter_local_notifications: ^16.3.0
  
  # Forms
  reactive_forms: ^16.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.7
  hive_generator: ^2.0.1
  mocktail: ^1.0.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
```

---

## 6. Plan de Implementación

### 6.1 Fases de Desarrollo

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      PLAN DE IMPLEMENTACIÓN                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  FASE 1: CONFIGURACIÓN Y AUTENTICACIÓN (Semana 1)                          │
│  ────────────────────────────────────────                                   │
│  □ Configurar proyecto Flutter                                              │
│  □ Configurar Supabase en Flutter                                          │
│  □ Implementar autenticación (login, registro, recuperación)               │
│  □ Pantalla de splash y redirección según rol                              │
│  □ Navegación principal con bottom navigation                               │
│                                                                             │
│  FASE 2: MÓDULOS Y CURSOS (Semana 2)                                       │
│  ────────────────────────────────                                           │
│  □ Implementar API get-modules                                             │
│  □ Dashboard según rol                                                     │
│  □ Lista de cursos disponibles                                             │
│  □ Detalle del curso                                                       │
│  □ Lista de lecciones                                                      │
│                                                                             │
│  FASE 3: LECCIONES Y CONTENIDO (Semana 3)                                  │
│  ───────────────────────────────────                                        │
│  □ Reproducción de videos                                                  │
│  □ Contenido de lecciones (texto)                                          │
│  □ Progreso de lecciones                                                   │
│  □ Marcar clase como completada                                            │
│  □ Editor de lecciones (profesor)                                           │
│                                                                             │
│  FASE 4: TAREAS Y QUIZZES (Semana 4)                                       │
│  ────────────────────────────────                                           │
│  □ Lista de tareas                                                         │
│  □ Entrega de tareas                                                       │
│  □ Calificación de tareas (profesor)                                       │
│  □ Realizar quizzes                                                        │
│  □ Resultados de quizzes                                                  │
│                                                                             │
│  FASE 5: MENSAJERÍA Y EXTRAS (Semana 5)                                   │
│  ───────────────────────────────────                                        │
│  □ Lista de conversaciones                                                 │
│  □ Chat en tiempo real                                                     │
│  □ Perfil de usuario                                                       │
│  □ Notificaciones push                                                     │
│  □ Modo offline básico                                                     │
│                                                                             │
│  FASE 6: PRUEBAS Y PUBLICACIÓN (Semana 6)                                  │
│  ─────────────────────────────────────                                      │
│  □ Pruebas en Android e iOS                                                │
│  □ Corrección de bugs                                                      │
│  □ Optimización de rendimiento                                             │
│  □ Generar APK/AAB para publicación                                        │
│  □ Publicar en Play Store y App Store                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Tareas por Fase

#### Fase 1: Configuración y Autenticación
- [ ] 1.1 Crear proyecto Flutter con estructura limpia
- [ ] 1.2 Configurar pubspec.yaml con todas las dependencias
- [ ] 1.3 Configurar Supabase (inicializar en main.dart)
- [ ] 1.4 Implementar tema y configuración global
- [ ] 1.5 Crear modelos de datos (User, Course, Lesson, etc.)
- [ ] 1.6 Implementar AuthRepository
- [ ] 1.7 Crear AuthBloc con eventos y estados
- [ ] 1.8 Pantalla de Login
- [ ] 1.9 Pantalla de Registro
- [ ] 1.10 Recuperación de contraseña
- [ ] 1.11 Pantalla Splash
- [ ] 1.12 Configurar GoRouter con Guards

#### Fase 2: Módulos y Cursos
- [ ] 2.1 Implementar CourseRepository
- [ ] 2.2 CourseBloc para gestión de cursos
- [ ] 2.3 Pantalla de Dashboard (según rol)
- [ ] 2.4 Pantalla de Lista de Cursos
- [ ] 2.5 Pantalla de Detalle de Curso
- [ ] 2.6 Funcionalidad de matrícula
- [ ] 2.7 Mostrar progreso por curso

#### Fase 3: Lecciones y Contenido
- [ ] 3.1 Implementar LessonRepository
- [ ] 3.2 LessonBloc para lecciones
- [ ] 3.3 Pantalla de Lista de Lecciones
- [ ] 3.4 Video Player con Chewie
- [ ] 3.5 Visor de contenido HTML/Markdown
- [ ] 3.6 Seguimiento de progreso
- [ ] 3.7 API endpoints para editar lecciones
- [ ] 3.8 Pantalla de edición de lección (profesor)

#### Fase 4: Tareas y Quizzes
- [ ] 4.1 Implementar TaskRepository
- [ ] 4.2 Pantalla de lista de tareas
- [ ] 4.3 Entrega de tareas con archivos
- [ ] 4.4 Calificación de tareas (profesor)
- [ ] 4.5 Implementar QuizRepository
- [ ] 4.6 Pantalla de quiz
- [ ] 4.7 Temporizador de quiz
- [ ] 4.8 Resultados de quiz

#### Fase 5: Mensajería y Extras
- [ ] 5.1 Implementar MessageRepository
- [ ] 5.2 Lista de conversaciones
- [ ] 5.3 Chat en tiempo real (Supabase Realtime)
- [ ] 5.4 Perfil de usuario
- [ ] 5.5 Configuración de notificaciones
- [ ] 5.6 Tema oscuro

#### Fase 6: Pruebas y Publicación
- [ ] 6.1 Pruebas unitarias
- [ ] 6.2 Pruebas de integración
- [ ] 6.3 Testing en dispositivos reales
- [ ] 6.4 Optimización
- [ ] 6.5 Generar build de producción
- [ ] 6.6 Documentación

---

## 7. Sincronización en Tiempo Real

### 7.1 Implementación con Supabase Realtime

```dart
// Ejemplo de escucha de cambios en tiempo real
class RealtimeService {
  final SupabaseClient _client;
  
  RealtimeService(this._client);
  
  // Escuchar cambios en lecciones
  Stream<Map<String, dynamic>> watchLessons(String courseId) {
    return _client
        .channel('lessons:$courseId')
        .onPostgresChanges(
          schema: 'public',
          table: 'lessons',
          filter: PostgresFilter('course_id', 'eq', courseId),
          event: PostgresChangeEvent.update,
        )
        .map((change) => change.newRecord.toJson());
  }
  
  // Escuchar nuevos mensajes
  Stream<Map<String, dynamic>> watchMessages(String conversationId) {
    return _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          schema: 'public',
          table: 'messages',
          filter: PostgresFilter('conversation_id', 'eq', conversationId),
          event: PostgresChangeEvent.insert,
        )
        .map((change) => change.newRecord.toJson());
  }
  
  // Escuchar progreso de lecciones
  Stream<Map<String, dynamic>> watchProgress(String userId) {
    return _client
        .channel('progress:$userId')
        .onPostgresChanges(
          schema: 'public',
          table: 'lesson_progress',
          filter: PostgresFilter('user_id', 'eq', userId),
        )
        .map((change) => change.newRecord.toJson());
  }
}
```

### 7.2 Manejo Offline

```dart
// Estrategia de sincronización offline
class SyncService {
  // Guardar cambios locales cuando no hay conexión
  Future<void> queueOfflineAction(OfflineAction action) async {
    final box = Hive.box('offline_queue');
    await box.add(action.toJson());
  }
  
  // Sincronizar cuando vuelva la conexión
  Future<void> syncOfflineActions() async {
    if (!await Connectivity().isConnected()) return;
    
    final box = Hive.box('offline_queue');
    final actions = box.values.toList();
    
    for (final action in actions) {
      try {
        await _executeAction(OfflineAction.fromJson(action));
        await box.delete(action['id']);
      } catch (e) {
        // Reintentar más tarde
      }
    }
  }
}
```

---

## 8. Recomendación: Proyecto Integrado vs Separate

### 8.1 Análisis de Opciones

| Aspecto | Proyecto Integrado | Proyecto Separate |
|---------|-------------------|-------------------|
| **Ventajas** | ✅ Un solo repositorio | ✅ Equipo dedicado |
| | ✅ Compartir código | ✅ Despliegue independiente |
| | ✅ Una DB Supabase | ✅ Escalabilidad |
| | ✅ Sincronización simple | ✅ App store separado |
| **Desventajas** | ❌ Tamaño del proyecto | ❌ Mantener 2 proyectos |
| | ❌ Complejidad | ❌ Sincronización manual |
| | ❌ Actualizaciones vinculadas | ❌ Duplicar configuración |

### 8.2 Recomendación Final

**SE RECOMIENDA: Proyecto Integrado (mismo repositorio)**

**Razones:**
1. **Base de datos única:** Ya tienes todo configurado en Supabase
2. **Sincronización automática:** Los cambios en la web se ven inmediatamente en la app
3. **Mantenimiento simplificado:** Un solo proyecto para actualizar
4. **Consistencia:** Mismos modelos, misma lógica de negocio
5. **Costos:** Un solo proyecto en Supabase/hosting

La app móvil usará las mismas tablas de Supabase que la web, con Edge Functions compartidas. Solo tendrá interfaces diferentes (Flutter vs Angular).

---

## 9. Próximos Pasos Inmediatos

1. **Confirmar alcance:** ¿Estás de acuerdo con este plan?
2. **Iniciar Fase 1:** ¿Comenzamos con la configuración del proyecto Flutter?
3. **APIs adicionales:** ¿Necesitas que cree los endpoints adicionales mencionados en la sección 4.2?

La estructura del proyecto Flutter está lista para ser creada en la carpeta `escuelamak/` que ya existe en el repositorio.

---

*Documento creado el 16 de Marzo de 2026*
*Versión 1.0*
