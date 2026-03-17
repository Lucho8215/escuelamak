# Documentación API - App Móvil Escuela Mak

## Descripción General

Este documento describe los endpoints disponibles en la API de Supabase Edge Functions para la aplicación móvil de la Escuela Mak. Todos los endpoints se encuentran en la función `mobile-api`.

**URL Base:**
```
https://escuelamak-nuevo.supabase.co/functions/v1/mobile-api
```

**Encabezados requeridos:**
```
Content-Type: application/json
```

---

## Endpoints Disponibles

### 1. Obtener Módulos por Usuario
**Acción:** `get-modules`

Obtiene los módulos/permisos disponibles para el usuario según su rol y permisos personalizados.

```http
POST /mobile-api
Content-Type: application/json

{
  "action": "get-modules",
  "user_id": "uuid-del-usuario"
}
```

**Respuesta exitosa:**
```json
{
  "success": true,
  "data": {
    "modules": [
      {
        "key": "courses",
        "name": "Cursos",
        "description": "Acceso al módulo de cursos",
        "icon": "book",
        "route": "/courses",
        "is_granted": true
      }
    ],
    "user": {
      "id": "uuid",
      "nombres": "Juan",
      "apellidos": "Pérez",
      "rol": "estudiante",
      "foto_url": "https://..."
    }
  }
}
```

---

### 2. Obtener Cursos Disponibles
**Acción:** `get-courses`

Devuelve los cursos disponibles para el usuario según su rol.

```http
POST /mobile-api
Content-Type: application/json

{
  "action": "get-courses",
  "user_id": "uuid-del-usuario",
  "status": "activo"  // opcional: filtrar por estado
}
```

**Notas:**
- **Estudiante:** Ve cursos donde está matriculado
- **Profesor:** Ve cursos que imparte
- **Admin:** Ve todos los cursos publicados

---

### 3. Obtener Contenido de un Curso
**Acción:** `get-course-content`

Devuelve el contenido completo de un curso, incluyendo todas sus lecciones, tareas y quizzes.

```http
POST /mobile-api
Content-Type: application/json

{
  "action": "get-course-content",
  "course_id": "uuid-del-curso",
  "user_id": "uuid-del-usuario"
}
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "course": {
      "id": "uuid",
      "titulo": "Curso de Matemáticas",
      "descripcion": "Aprende matemáticas básicas"
    },
    "lessons": [
      {
        "id": "uuid",
        "titulo": "Lección 1: Introducción",
        "contenido": "Contenido de la lección...",
        "video_url": "https://...",
        "orden": 1,
        "tasks": [...],
        "quizzes": [...],
        "progress": {
          "completed": true,
          "progress_pct": 100,
          "last_position": 0
        }
      }
    ]
  }
}
```

---

### 4. Obtener Detalle de una Lección
**Acción:** `get-lesson`

Devuelve el contenido detallado de una lección específica.

```http
POST /mobile-api
Content-Type: application/json

{
  "action": "get-lesson",
  "lesson_id": "uuid-de-la-leccion",
  "user_id": "uuid-del-usuario"
}
```

---

### 5. Editar una Clase (Leción)
**Acción:** `update-lesson`

Permite editar el contenido de una clase/lección. Solo disponible para profesores y administradores.

```http
POST /mobile-api
Content-Type: application/json

{
  "action": "update-lesson",
  "lesson_id": "uuid-de-la-leccion",
  "user_id": "uuid-del-usuario",
  "titulo": "Nuevo título",           // opcional
  "contenido": "Nuevo contenido",      // opcional
  "video_url": "https://...",        // opcional
  "orden": 1                          // opcional
}
```

**Permisos requeridos:** Profesor (del curso) o Administrador

---

### 6. Marcar Clase como Completada
**Acción:** `complete-lesson`

Marca una clase/lección como completada por el usuario.

```http
POST /mobile-api
Content-Type: application/json

{
  "action": "complete-lesson",
  "lesson_id": "uuid-de-la-leccion",
  "user_id": "uuid-del-usuario",
  "progress_pct": 100,    // opcional: porcentaje de progreso
  "last_position": 0       // opcional: posición en el video
}
```

---

### 7. Reportar Estado de Clase (desde App Móvil)
**Acción:** `report-lesson-status`

Permite a la app móvil reportar el estado de una clase en tiempo real. Usado cuando:
- El usuario termina de ver un video
- El usuario completa una actividad
- La app envía actualizaciones de progreso

```http
POST /mobile-api
Content-Type: application/json

{
  "action": "report-lesson-status",
  "lesson_id": "uuid-de-la-leccion",
  "user_id": "uuid-del-usuario",
  "status": "completed",  // valores: "in_progress", "completed", "paused"
  "progress_pct": 75,     // opcional: porcentaje de progreso
  "last_position": 450,   // opcional: posición actual en el video (segundos)
  "duration_watched": 450 // opcional: duración total vista
}
```

**Valores de status:**
- `in_progress`: La clase está en progreso
- `completed`: La clase fue completada
- `paused`: La clase fue pausada

---

### 8. Obtener Progreso del Usuario
**Acción:** `get-user-progress`

Devuelve el progreso general del usuario en todos sus cursos.

```http
POST /mobile-api
Content-Type: application/json

{
  "action": "get-user-progress",
  "user_id": "uuid-del-usuario"
}
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "courses": [
      {
        "course_id": "uuid",
        "course_title": "Matemáticas",
        "total_lessons": 10,
        "completed_lessons": 5,
        "progress_pct": 50,
        "status": "activo"
      }
    ],
    "total_lessons_completed": 5,
    "total_courses": 1
  }
}
```

---

### 9. Matricularse en un Curso
**Acción:** `enroll-course`

Permite a un estudiante matricularse en un curso.

```http
POST /mobile-api
Content-Type: application/json

{
  "action": "enroll-course",
  "course_id": "uuid-del-curso",
  "user_id": "uuid-del-estudiante"
}
```

---

## Códigos de Respuesta

| Código | Descripción |
|--------|-------------|
| 200 | Solicitud exitosa |
| 400 | Error en la solicitud (parámetros inválidos) |
| 403 | Acceso denegado (sin permisos) |
| 500 | Error del servidor |

---

## Estructura de Errores

```json
{
  "success": false,
  "error": "Mensaje de error descriptivo"
}
```

---

## Ejemplo de Uso en Flutter/Dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<List<dynamic>> getModules(String userId) async {
  final response = await supabase.functions.invoke('mobile-api', body: {
    'action': 'get-modules',
    'user_id': userId,
  });
  
  if (response.data['success'] == true) {
    return response.data['data']['modules'];
  } else {
    throw Exception(response.data['error']);
  }
}

Future<void> reportLessonStatus({
  required String lessonId,
  required String userId,
  required String status,
  int? progressPct,
  int? lastPosition,
}) async {
  await supabase.functions.invoke('mobile-api', body: {
    'action': 'report-lesson-status',
    'lesson_id': lessonId,
    'user_id': userId,
    'status': status,
    'progress_pct': progressPct,
    'last_position': lastPosition,
  });
}
```

---

## Notas de Seguridad

1. La función `mobile-api` tiene `verify_jwt = false` para permitir acceso desde la app móvil
2. Se recomienda implementar autenticación en la app móvil usando Supabase Auth
3. Para operaciones sensibles (como editar clases), se verifica el rol del usuario en cada solicitud

---

## Archivos Creados

- [`supabase/functions/mobile-api/index.ts`](supabase/functions/mobile-api/index.ts) - Código de la API
- [`supabase/functions/mobile-api/deno.json`](supabase/functions/mobile-api/deno.json) - Configuración de dependencias
- [`supabase/config.toml`](supabase/config.toml) - Configuración de la función en Supabase
