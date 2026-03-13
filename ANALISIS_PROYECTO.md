# Análisis del Proyecto EscuelaMak

> **Propósito de este documento**: Resumir el estado actual del proyecto, identificar fortalezas, debilidades y recomendaciones de mejora. Sirve como guía para mantener y evolucionar la aplicación.

---

## 1. ¿Qué es EscuelaMak?

**EscuelaMak** es un **LMS (Sistema de Gestión de Aprendizaje)** web orientado a cursos de **educación** y **matemáticas**. Permite:

- Gestionar cursos, clases, lecciones y quizzes
- Gestionar usuarios (admin, profesor, tutor, estudiante)
- Inscribir estudiantes a clases
- Asignar quizzes y lecciones
- Tomar quizzes y seguir el progreso

---

## 2. Tecnologías

| Capa | Tecnología |
|------|------------|
| Frontend | Angular 17 (standalone), TypeScript 5.3 |
| Backend/DB | Supabase (PostgreSQL, Auth, Edge Functions) |
| Despliegue | Vercel (SPA con rewrites) |

---

## 3. Fortalezas del Proyecto ✅

### 3.1 Estructura general
- Separación clara en `components`, `services`, `models`, `guards`, `pipes`
- Uso de Angular standalone components (moderno)
- Modelos TypeScript bien definidos para `Course`, `Quiz`, `Lesson`, `User`

### 3.2 Documentación parcial
- `auth.guard.ts` y `role.guard.ts` tienen buenos comentarios explicativos
- `app-layout.component.ts` usa JSDoc para propiedades
- `app.routes.ts` tiene comentarios en las rutas

### 3.3 Funcionalidad
- Sistema de quizzes completo (crear, asignar, intentar, calificar)
- Gestión de cursos, clases, lecciones, inscripciones
- Generador de gradientes CSS (herramienta útil para diseño)
- Control de acceso por roles (admin, teacher, tutor, student)

---

## 4. Problemas Detectados y Recomendaciones ⚠️

### 4.1 Configuración inconsistente (CRÍTICO para despliegue)

| Problema | Dónde | Impacto |
|----------|-------|---------|
| `angular.json` usa proyecto `"demo"` y `outputPath: "dist/demo"` | angular.json | No coincide con el nombre real del proyecto |
| `versel.json` espera `outputDirectory: "dist/escuelamak"` | versel.json | **Vercel no encontrará los archivos** porque Angular genera en `dist/demo` |
| Nombre del archivo: `versel.json` | Raíz del proyecto | Debería ser `vercel.json` (typo) |

**Recomendación**: Unificar el nombre del proyecto a `escuelamak` y corregir el archivo de Vercel.

---

### 4.2 Rutas sin protección de autenticación

Las rutas siguientes están **fuera** del `authGuard`:
- `/student-dashboard`
- `/lesson-management/:courseId`
- `/my-lessons`
- `/my-quizzes`

**Riesgo**: Si son rutas que requieren sesión, un usuario no logueado podría acceder. Si están públicas por diseño, conviene documentarlo.

**Recomendación**: Revisar si el dashboard del estudiante y sus lecciones/quizzes deben exigir login. Si sí, moverlas dentro del bloque con `authGuard`.

---

### 4.3 Múltiples instancias del cliente Supabase

Varios servicios crean su propio cliente Supabase:
- `CourseService` → crea cliente con config personalizada (timeout, retry)
- `QuizService` → crea cliente
- `SupabaseService` → crea cliente central
- `SupabaseTestComponent` → crea cliente

**Problema**: `SupabaseService` no se usa en `CourseService` ni `QuizService`. Hay duplicación y configuración inconsistente.

**Recomendación**: Centralizar en `SupabaseService` y que los demás servicios lo inyecten. O documentar por qué cada uno tiene su propia instancia.

---

### 4.4 CourseService muy grande y con problemas

- **Tamaño**: ~375 líneas, mezcla cursos, clases, inscripciones, lecciones, asignaciones
- **Encoding**: Comentarios con caracteres mal codificados (`lecciÃ³n` en vez de `lección`)
- **Consistencia**: Algunos métodos usan `retryOperation`, otros no (ej. `toggleLessonAssignment`, `getClassEnrollments`)
- **Orden de propiedades**: En el modelo `Class`, `videoUrl` y `id` están desordenados

**Recomendación**: Corregir encoding, considerar dividir en servicios más pequeños (ej. `EnrollmentService`, `LessonAssignmentService`) o al menos documentar las secciones.

---

### 4.5 Falta de comentarios en varios archivos

- `quiz.model.ts` – interfaces sin documentación
- `lesson.model.ts` – interfaces sin documentación
- `gradient-generator.component.ts` – lógica sin JSDoc
- Varios métodos en `course.service.ts` sin explicación

**Recomendación**: Añadir JSDoc o comentarios breves donde falten, especialmente en modelos y métodos públicos.

---

### 4.6 Script `fix-dashboard.js`

- Es un script de Node.js que sobrescribe `class-management.component.ts`
- Parece un arreglo puntual, no un script de mantenimiento
- **Recomendación**: Añadir comentario en la cabecera explicando qué hace y cuándo se usó, o moverlo a `scripts/` si se va a mantener.

---

### 4.7 Modelo `Class` en course.model.ts

- `videoUrl?: any` y `id` están al inicio sin contexto
- Líneas en blanco innecesarias
- **Recomendación**: Reordenar y comentar para claridad.

---

## 5. Organización Sugerida

### Estructura actual (correcta)
```
src/app/
├── components/   → Vista y UI
├── guards/       → Protección de rutas
├── models/       → Interfaces TypeScript
├── pipes/        → Transformadores
└── services/     → Lógica de negocio y API
```

### Mejoras sugeridas
1. **Configuración**: Unificar `angular.json` y `vercel.json`
2. **Servicios**: Documentar o refactorizar `CourseService`; considerar dividirlo
3. **Modelos**: Añadir JSDoc a las interfaces
4. **Rutas**: Revisar protección de rutas de estudiante
5. **Scripts**: Documentar `fix-dashboard.js` o moverlo a `scripts/`

---

## 6. Resumen Ejecutivo

| Aspecto | Estado | Acción |
|---------|--------|--------|
| Estructura del código | ✅ Buena | Mantener |
| Comentarios | ⚠️ Parcial | Añadir donde falten |
| Configuración (deploy) | ❌ Inconsistente | Corregir angular.json y vercel.json |
| Rutas / seguridad | ⚠️ Revisar | Comprobar si student-* requieren auth |
| Servicios | ⚠️ Duplicación | Documentar o centralizar Supabase |
| Encoding | ❌ Errores | Corregir acentos en comentarios |

---

*Documento generado para el análisis del proyecto EscuelaMak. Última revisión: marzo 2025.*
