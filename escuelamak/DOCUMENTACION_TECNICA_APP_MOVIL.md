# Documentación Técnica Completa - App Móvil EscuelaMAK

## 1. Introducción

Este documento describe la arquitectura técnica, integración con APIs y configuración necesaria para la aplicación móvil de EscuelaMAK. La app está desarrollada en Flutter y utiliza Supabase como backend, incluyendo autenticación, base de datos y Edge Functions para una API RESTful completa.

La aplicación sigue el patrón de arquitectura limpia (Clean Architecture) con separación en capas de presentación, dominio y datos. Utiliza Riverpod para el manejo de estado y está diseñada para funcionar de manera similar a Google Classroom, permitiendo a estudiantes, profesores y administradores gestionar cursos, lecciones y progreso académico.

---

## 2. Arquitectura del Proyecto

### 2.1 Estructura de Carpetas

```
lib/
├── main.dart                          # Punto de entrada de la aplicación
├── core/
│   ├── constants/
│   │   └── supabase_keys.dart         # Configuración de Supabase
│   ├── theme/
│   │   └── app_theme.dart             # Temas y estilos visuales
│   ├── router/                        # Enrutamiento de la app
│   ├── errors/                        # Manejo de errores
│   └── utils/                         # Utilidades helper
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── login_screen.dart      # Pantalla de inicio de sesión
│   ├── courses/
│   │   ├── data/
│   │   │   └── courses_repository.dart # Repositorio de cursos
│   │   └── presentation/
│   │       ├── courses_providers.dart  # Providers de estado
│   │       ├── course_detail_screen.dart
│   │       └── module_content_screen.dart
│   ├── home/
│   │   └── presentation/
│   │       ├── home_screen.dart        # Dashboard principal
│   │       └── main_navigation.dart    # Navegación por roles
│   ├── messages/                       # Módulo de mensajería
│   ├── permissions/                    # Gestión de permisos
│   ├── quizzes/                        # Exámenes y evaluaciones
│   └── tasks/                          # Tareas y entregas
└── shared/
    ├── models/
    │   └── course_model.dart           # Modelos de datos
    └── widgets/                        # Widgets reutilizables
```

### 2.2 Capas de la Arquitectura

La aplicación está organizada en tres capas principales que separan las responsabilidades de manera clara:

La **capa de presentación** contiene todas las pantallas (screens) y widgets que el usuario ve e interactúa directamente. Aquí encontramos las pantallas de login, home, detalle de curso y contenido de módulos, junto con componentes reutilizables como tarjetas de curso, indicadores de progreso y elementos de navegación.

La **capa de datos** incluye los repositorios que gestionan la comunicación con fuentes externas, específicamente el CoursesRepository que se conecta a las Edge Functions de Supabase. Esta capa también contiene los modelos de datos que estructuran la información recibida desde la API.

La **capa de dominio** mediante Riverpod proporciona el estado de la aplicación a través de providers que manejan la lógica de negocio, como la obtención de cursos por rol, el progreso del usuario y la inscripción en cursos.

---

## 3. Configuración de Supabase

### 3.1 Credenciales

La aplicación está configurada para conectarse a un proyecto Supabase específico. Las credenciales se encuentran en el archivo `lib/core/constants/supabase_keys.dart`:

```dart
class SupabaseKeys {
  static const String url = 'https://xtbzwxwrlvtsdbppdgxe.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}
```

### 3.2 Inicialización

La inicialización de Supabase ocurre en el punto de entrada de la aplicación (`main.dart`) antes de ejecutar el widget principal:

```dart
await Supabase.initialize(
  url: SupabaseKeys.url,
  anonKey: SupabaseKeys.anonKey,
  debug: true,
);
```

El parámetro `debug: true` habilita los logs de desarrollo. Para producción se debe cambiar a `false`.

---

## 4. API de Supabase Edge Functions

### 4.1 URL Base

Todas las llamadas a la API se realizan a través de la Edge Function denominada `mobile-api`:

```
https://xtbzwxwrlvtsdbppdgxe.supabase.co/functions/v1/mobile-api
```

### 4.2 Autenticación

La API utiliza autenticación JWT a través de Supabase Auth. Las solicitudes incluyen el token de sesión en el encabezado de autorización. El flujo de autenticación funciona de la siguiente manera:

Primero, el usuario inicia sesión en la app móvil usando su correo y contraseña. Supabase Auth verifica las credenciales y genera un token JWT de sesión. Este token se incluye automáticamente en todas las llamadas a la Edge Function. La Edge Function puede verificar el token y extraer el ID del usuario para realizar operaciones personalizadas.

### 4.3 Endpoints Disponibles

La API expone los siguientes endpoints a través de la acción `action` en el cuerpo de la solicitud:

#### 4.3.1 Obtener Módulos por Usuario

**Acción:** `get-modules`

Este endpoint retorna los módulos y permisos disponibles para el usuario según su rol en el sistema. Un módulo representa una sección o funcionalidad de la app a la cual el usuario puede tener acceso.

```json
// Solicitud
{
  "action": "get-modules",
  "user_id": "uuid-del-usuario"
}

// Respuesta exitosa
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

#### 4.3.2 Obtener Cursos por Rol

**Acción:** `get-courses`

Retorna los cursos disponibles según el rol del usuario. Los estudiantes ven los cursos en los que están matriculados, los profesores los cursos que imparten y los administradores ven todos los cursos publicados.

```json
// Solicitud
{
  "action": "get-courses",
  "user_id": "uuid-del-usuario",
  "status": "activo"
}

// Respuesta exitosa
{
  "success": true,
  "data": {
    "courses": [
      {
        "id": "uuid",
        "titulo": "Curso de Matemáticas Avanzadas",
        "descripcion": "Aprende cálculo diferencial e integral",
        "image_url": "https://...",
        "teacher_id": "uuid",
        "teacher_name": "Prof. García",
        "categoria": "Matemáticas",
        "total_estudiantes": 25,
        "publico": true,
        "created_at": "2024-01-15T10:00:00Z"
      }
    ]
  }
}
```

#### 4.3.3 Obtener Contenido de un Curso

**Acción:** `get-course-content`

Este endpoint devuelve el contenido completo de un curso específico, incluyendo todas las lecciones, tareas y quizzes asociados. También incluye el progreso del usuario en cada lección.

```json
// Solicitud
{
  "action": "get-course-content",
  "course_id": "uuid-del-curso",
  "user_id": "uuid-del-usuario"
}

// Respuesta exitosa
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
        "tasks": [],
        "quizzes": [],
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

#### 4.3.4 Obtener Detalle de una Lección

**Acción:** `get-lesson`

Retorna el contenido detallado de una lección específica, incluyendo el video, contenido de texto, tareas y quizzes asociados.

```json
// Solicitud
{
  "action": "get-lesson",
  "lesson_id": "uuid-de-la-leccion",
  "user_id": "uuid-del-usuario"
}

// Respuesta exitosa
{
  "success": true,
  "data": {
    "id": "uuid",
    "titulo": "Lección 1: Introducción",
    "contenido": "Contenido completo de la lección...",
    "video_url": "https://...",
    "progress": {
      "completed": false,
      "progress_pct": 50,
      "last_position": 300
    },
    "tasks": [],
    "quizzes": []
  }
}
```

#### 4.3.5 Completar una Lección

**Acción:** `complete-lesson`

Marca una lección como completada por parte del usuario. Este endpoint actualiza el progreso del estudiante y registra la fecha de finalización.

```json
// Solicitud
{
  "action": "complete-lesson",
  "lesson_id": "uuid-de-la-leccion",
  "user_id": "uuid-del-usuario",
  "progress_pct": 100,
  "last_position": 0
}

// Respuesta exitosa
{
  "success": true,
  "data": {
    "message": "Lección completada exitosamente"
  }
}
```

#### 4.3.6 Reportar Estado de Lección

**Acción:** `report-lesson-status`

Permite a la app reportar el estado de una lección en tiempo real. Es útil para rastrear el progreso de videos o actualizar el estado cuando el usuario pausa o reanuda una lección.

```json
// Solicitud
{
  "action": "report-lesson-status",
  "lesson_id": "uuid-de-la-leccion",
  "user_id": "uuid-del-usuario",
  "status": "in_progress",
  "progress_pct": 75,
  "last_position": 450,
  "duration_watched": 450
}

// Valores de status:
// - "in_progress": La clase está en progreso
// - "completed": La clase fue completada
// - "paused": La clase fue pausada
```

#### 4.3.7 Obtener Progreso del Usuario

**Acción:** `get-user-progress`

Retorna el progreso general del usuario en todos sus cursos matriculados, incluyendo el porcentaje de finalización y el número de lecciones completadas.

```json
// Solicitud
{
  "action": "get-user-progress",
  "user_id": "uuid-del-usuario"
}

// Respuesta exitosa
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

#### 4.3.8 Matricularse en un Curso

**Acción:** `enroll-course`

Permite a un estudiante matricularse en un curso disponible. Verifica que el estudiante no esté ya matriculado antes de crear la inscripción.

```json
// Solicitud
{
  "action": "enroll-course",
  "course_id": "uuid-del-curso",
  "user_id": "uuid-del-estudiante"
}

// Respuesta exitosa
{
  "success": true,
  "data": {
    "message": "Inscripción exitosa"
  }
}
```

---

## 5. Integración en Flutter

### 5.1 Repositorio de Cursos

La clase `CoursesRepository` en `lib/features/courses/data/courses_repository.dart` encapsula todas las llamadas a la API de Supabase. Utiliza el cliente de Supabase para invocar la Edge Function `mobile-api` con los parámetros requeridos:

```dart
class CoursesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> _callApi(
      String action, Map<String, dynamic> body) async {
    final response = await supabase.functions.invoke('mobile-api', body: {
      'action': action,
      ...body,
    });

    if (response.data != null && response.data['success'] == true) {
      return response.data;
    } else {
      throw Exception(response.data?['error'] ?? 'Error en la API');
    }
  }

  Future<List<CourseModel>> getCoursesByRole(String userId, String role) async {
    final response = await _callApi('get-courses', {'user_id': userId});
    final courses = response['data']['courses'] as List<dynamic>? ?? [];
    return courses.map((c) => CourseModel.fromApiJson(c)).toList();
  }

  // Más métodos...
}
```

### 5.2 Modelos de Datos

Los modelos de datos proporcionan una estructura tipada para la información recibida de la API. El modelo principal es `CourseModel` que se encuentra en `lib/shared/models/course_model.dart`:

```dart
class CourseModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String teacherId;
  final String teacherName;
  final String category;
  final int enrollmentCount;
  final bool isPublished;
  final DateTime createdAt;

  factory CourseModel.fromApiJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String? ?? '',
      title: json['titulo'] as String? ?? 'Sin título',
      description: json['descripcion'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      teacherId: json['teacher_id'] as String? ?? '',
      teacherName: json['teacher_name'] as String? ?? 'Profesor',
      category: json['categoria'] as String? ?? 'General',
      enrollmentCount: json['total_estudiantes'] as int? ?? 0,
      isPublished: json['publico'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
```

### 5.3 Providers de Estado

Riverpod gestiona el estado de la aplicación a través de providers definidos en `lib/features/courses/presentation/courses_providers.dart`. El provider principal para obtener cursos según el rol es:

```dart
final coursesProvider =
    FutureProvider.family<List<CourseModel>, String>((ref, role) async {
  final repository = ref.watch(coursesRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (userData) => repository.getCoursesByRole(
      userData['userId'] as String,
      role,
    ),
    loading: () => [],
    error: (_, __) => [],
  );
});
```

---

## 6. Roles de Usuario

### 6.1 Definición de Roles

La aplicación soporta cuatro roles diferentes, cada uno con acceso a funcionalidades específicas:

**Administrador (admin)**: Acceso completo a todas las funcionalidades del sistema. Puede gestionar usuarios, cursos, ver reportes y configuraciones. El color distintivo en la interfaz es rojo oscuro (#B71C1C).

**Profesor (teacher)**: Puede gestionar los cursos que imparte, crear y editar lecciones, asignar tareas, crear quizzes y calificar trabajos de estudiantes. El color distintivo es azul oscuro (#1565C0).

**Estudiante (student)**: Puede ver los cursos en los que está matriculado, acceder al contenido de las lecciones, completar tareas y quizzes, ytrackear su progreso. El color distintivo es verde oscuro (#2E7D32).

**Tutor (tutor)**: Similar al estudiante pero con funcionalidades adicionales de seguimiento para supervisar el progreso de los estudiantes a su cargo.

### 6.2 Navegación por Roles

La navegación principal de la aplicación se adapta dinámicamente según el rol del usuario. En `lib/features/home/presentation/home_screen.dart` se define la navegación para cada rol:

- **Admin**: Inicio, Cursos, Usuarios, Reportes, Ajustes
- **Teacher**: Inicio, Mis Clases, Tareas, Quizzes, Mensajes
- **Student**: Inicio, Cursos, Tareas, Exámenes, Calendario

---

## 7. Funcionalidades de la Interfaz

### 7.1 Pantalla de Splash

La pantalla de inicioanimated presenta el logo de la aplicación con una animación de escala y fundido de entrada. La animación incluye tres fases secuenciales: aparición del logo con efecto elástico, aparición del texto con deslizamiento hacia arriba, y una barra de progreso animada. El tiempo total de la animación es de aproximadamente 1.5 segundos antes de verificar la sesión del usuario.

### 7.2 Pantalla de Login

El formulario de inicio de sesión incluye validación de campos, manejo de errores de autenticación traducidos al español, y animaciones de entrada para los elementos del formulario. Utiliza Supabase Auth para la autenticación segura con correo electrónico y contraseña.

### 7.3 Dashboard Principal

El dashboard muestra información personalizada según el rol del usuario. Incluye una tarjeta de bienvenida con el nombre del usuario, una lista de cursos disponibles, y accesos directos a las funcionalidades principales. La interfaz sigue el estilo de Google Classroom con tarjetas limpias, colores por rol y animaciones suaves.

### 7.4 Detalle de Curso

Al seleccionar un curso, se muestra una vista detallada que incluye la imagen o颜色 de portada del curso, información del profesor, descripción, número de estudiantes matriculados, y una lista de todas las lecciones disponibles. Cada lección muestra su tipo (video, texto, quiz, tarea), duración estimada, y estado de completado.

### 7.5 Contenido de Lección

La pantalla de contenido de lección varía según el tipo de contenido. Para videos, muestra el reproductor o miniatura del video. Para texto, presenta el contenido formateado. Para quizzes, muestra las preguntas y opciones de respuesta. Incluye un botón para marcar la lección como completada.

---

## 8. Animaciones y Transiciones

### 8.1 Widget FadeSlideIn

El widget personalizado `FadeSlideIn` proporciona una animación combinada de fundido (fade) y deslizamiento (slide) para elementos que aparecen en pantalla:

```dart
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
  });
}
```

### 8.2 Skeleton Loader

El widget `SkeletonBox` crea un efecto de carga placeholder similar al de Facebook o LinkedIn, mostrando rectángulos animados en gris mientras los datos se cargan:

```dart
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
}
```

### 8.3 Transiciones entre Pantallas

Todas las navegaciones utilizan transiciones de fundido (FadeTransition) con una duración de 400 milisegundos para proporcionar una experiencia de usuario fluida y profesional.

---

## 9. Códigos de Respuesta

| Código | Descripción |
|--------|-------------|
| 200 | Solicitud exitosa |
| 400 | Error en la solicitud (parámetros inválidos o faltantes) |
| 403 | Acceso denegado (sin permisos suficientes) |
| 500 | Error del servidor de Supabase |

### 9.1 Estructura de Errores

```json
{
  "success": false,
  "error": "Mensaje de error descriptivo"
}
```

---

## 10. Consideraciones de Seguridad

### 10.1 Autenticación

La aplicación utiliza Supabase Auth para gestionar la autenticación de usuarios. Los tokens JWT se almacenan de forma segura en el dispositivo y se incluyen automáticamente en todas las solicitudes a la API.

### 10.2 Verificación de Permisos

Cada endpoint de la Edge Function verifica que el usuario tenga los permisos necesarios para realizar la operación solicitada. Por ejemplo, solo los profesores pueden crear o editar lecciones, y solo los estudiantes pueden completar lecciones.

### 10.3 Validación de Entrada

Todos los parámetros de entrada se validan en la Edge Function antes de ejecutar cualquier operación en la base de datos, previniendo inyecciones SQL y otros ataques.

---

## 11. Configuración para Producción

### 11.1 Construir APK de Liberación

Para generar una APK lista para producción, ejecuta los siguientes comandos en la terminal:

```bash
flutter build apk --release
```

El archivo APK generado se ubicará en `build/app/outputs/flutter-apk/app-release.apk`.

### 11.2 Configuración de Variables de Entorno

En producción, considera cambiar las siguientes configuraciones:

- Establecer `debug: false` en la inicialización de Supabase
- Verificar que las políticas de Row Level Security (RLS) estén activas en Supabase
- Configurar dominios autorizados en la configuración de Supabase para seguridad adicional

---

## 12. Troubleshooting

### 12.1 Problemas Comunes

**Error de conexión**: Verifica que el dispositivo tenga acceso a internet y que las credenciales de Supabase sean correctas.

**Usuario no encontrado**: Asegúrate de que el usuario exista en la tabla `app_users` con el `auth_user_id` correcto vinculado a su cuenta de Supabase Auth.

**Cursos vacíos**: Verifica que el usuario tenga cursos asociados según su rol (matriculado como estudiante, impartiendo como profesor, o publicados como administrador).

### 12.2 Logs de Debug

Para habilitar logs detallados durante el desarrollo, la inicialización de Supabase está configurada con `debug: true`. Esto muestra todas las solicitudes HTTP y respuestas en la consola.

---

## 13. Próximas Mejoras

Algunas funcionalidades planificadas para futuras versiones incluyen:

- Notificaciones push para nuevos contenidos y recordatorios de tareas
- Soporte offline con sincronización de datos
- Integración con Google Drive para almacenamiento de archivos
- Chat en tiempo real entre estudiantes y profesores
- Estadísticas detalladas de progreso académico
- Modo oscuro optimizado
- Widgets de pantalla de inicio para Android

---

## 14. Referencias

- Documentación oficial de Flutter: https://flutter.dev/docs
- Documentación de Supabase: https://supabase.com/docs
- Paquete supabase_flutter: https://pub.dev/packages/supabase_flutter
- Riverpod para gestión de estado: https://riverpod.dev/
- Material Design 3: https://m3.material.io/

---

*Documento generado para la versión 1.0 de la App Móvil EscuelaMAK*
*Última actualización: 2024*
