# Documento Técnico - Aplicación Móvil Educativa EscuelaMak

## 1. Recomendación: Flutter vs React Native

### 🏆 Recomendación: **Flutter**

**Razones técnicas y estratégicas:**

| Aspecto | Flutter | React Native |
|---------|---------|--------------|
| **Curva de aprendizaje** | Más fácil para principiantes | Requiere conocimientos sólidos de JavaScript/React |
| **Documentación** | Excelente, en español disponible | Buena pero fragmentada |
| **Rendimiento** | ✅ Superior (compilado a nativo) | Bueno pero con bridge JS |
| **Comunidad** | En rápido crecimiento | Más grande pero más fragmentada |
| **Paquetes** | Rich set de widgets Material/Cupertino | Más paquetes pero calidad variable |
| **Mantenimiento a largo plazo** | ✅Google respalda activamente | Meta puede cambiar prioridades |
| **Debugging** | ✅Excelente tooling | Más complejo |

### ¿Por qué Flutter para este proyecto?

1. **Experiencia del usuario uniforme** en iOS y Android
2. **Widgets integrados** de Material Design 3 y Cupertino
3. **Hot reload** rápido para desarrollo ágil
4. **Dart** es más fácil de aprender que TypeScript para principiantes
5. **Supabase** tiene SDK oficial para Flutter bien mantenido

### Tecnologías del stack recomendado:

```
Flutter 3.x → Supabase (Auth, Database, Storage) → PostgreSQL
```

---

## 2. Arquitectura de la Aplicación

### 2.1 Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                        APLICACIÓN FLUTTER                        │
├─────────────────────────────────────────────────────────────────┤
│  UI Layer (Screens, Widgets)                                   │
│  ├── Auth Screens (Login, Register, Reset Password)            │
│  ├── Student Screens (Dashboard, Courses, Lessons, Quizzes)    │
│  ├── Teacher Screens (Course Management, Grading)               │
│  └── Admin Screens (User Management, Permissions)               │
├─────────────────────────────────────────────────────────────────┤
│  Business Logic Layer (BLoC/Cubit)                              │
│  ├── AuthBloc - Manejo de sesiones                             │
│  ├── CourseBloc - Gestión de cursos                            │
│  ├── QuizBloc - Quizzes y evaluaciones                          │
│  ├── TaskBloc - Tareas y entregas                              │
│  └── PermissionBloc - Permisos de módulos                      │
├─────────────────────────────────────────────────────────────────┤
│  Data Layer (Repositories)                                      │
│  ├── AuthRepository → Supabase Auth                            │
│  ├── CourseRepository → Supabase Database                      │
│  ├── StorageRepository → Supabase Storage                      │
│  └── NotificationRepository → Firebase/Supabase                │
├─────────────────────────────────────────────────────────────────┤
│  External Services                                             │
│  ├── Supabase (Auth, Database, Storage, Realtime)              │
│  └── Push Notifications                                         │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Estructura de Carpetas Recomendada

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # Configuración global
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_typography.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── dark_theme.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   └── validators.dart
│   └── errors/
│       ├── exceptions.dart
│       └── failures.dart
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   └── local_storage.dart
│   │   └── remote/
│   │       ├── supabase_auth.dart
│   │       ├── supabase_courses.dart
│   │       ├── supabase_quizzes.dart
│   │       └── supabase_storage.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── course_model.dart
│   │   ├── lesson_model.dart
│   │   ├── task_model.dart
│   │   ├── quiz_model.dart
│   │   └── message_model.dart
│   └── repositories/
│       ├── auth_repository.dart
│       ├── course_repository.dart
│       ├── task_repository.dart
│       └── quiz_repository.dart
├── domain/
│   ├── entities/
│   │   ├── user.dart
│   │   ├── course.dart
│   │   └── task.dart
│   └── repositories/
│       ├── i_auth_repository.dart
│       └── i_course_repository.dart
├── presentation/
│   ├── blocs/
│   │   ├── auth/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   ├── courses/
│   │   ├── tasks/
│   │   ├── quizzes/
│   │   └── permissions/
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── reset_password_screen.dart
│   │   ├── student/
│   │   │   ├── student_home_screen.dart
│   │   │   ├── student_courses_screen.dart
│   │   │   ├── student_lessons_screen.dart
│   │   │   ├── student_tasks_screen.dart
│   │   │   ├── student_quizzes_screen.dart
│   │   │   └── student_messages_screen.dart
│   │   ├── teacher/
│   │   │   ├── teacher_dashboard_screen.dart
│   │   │   ├── teacher_courses_screen.dart
│   │   │   ├── teacher_tasks_screen.dart
│   │   │   ├── teacher_quizzes_screen.dart
│   │   │   └── teacher_grading_screen.dart
│   │   └── admin/
│   │       ├── admin_dashboard_screen.dart
│   │       ├── admin_users_screen.dart
│   │       ├── admin_permissions_screen.dart
│   │       └── admin_settings_screen.dart
│   └── widgets/
│       ├── common/
│       │   ├── app_button.dart
│       │   ├── app_text_field.dart
│       │   ├── app_card.dart
│       │   └── loading_widget.dart
│       ├── course/
│       │   ├── course_card.dart
│       │   └── lesson_item.dart
│       └── task/
│           ├── task_card.dart
│           └── task_submission.dart
├── injection_container.dart     # Dependency injection
└── routes.dart                 # Navigation routes
```

---

## 3. Diseño de Base de Datos (Supabase/PostgreSQL)

### 3.1 Diagrama de Entidades

```
┌─────────────────┐       ┌─────────────────┐
│    app_users    │       │  user_profiles  │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──────│ user_id (FK)    │
│ auth_user_id    │       │ id (PK)         │
│ email           │       │ name            │
│ role            │       │ photo_url       │
│ is_active       │       │ phone           │
│ created_at      │       │ bio             │
│ updated_at      │       │ created_at      │
└─────────────────┘       └─────────────────┘
         │
         │
         ▼
┌─────────────────┐       ┌─────────────────┐
│     courses     │       │   course_user   │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──────│ course_id (FK)  │
│ title           │       │ user_id (FK)    │
│ description     │       │ enrolled_at     │
│ image_url       │       │ progress        │
│ category_id     │       │ is_active      │
│ teacher_id (FK) │       └─────────────────┘
│ is_published    │
│ created_at      │
└─────────────────┘
         │
         ▼
┌─────────────────┐       ┌─────────────────┐
│    lessons      │       │ lesson_progress │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──────│ lesson_id (FK)  │
│ course_id (FK)  │       │ user_id (FK)    │
│ title           │       │ is_completed    │
│ description     │       │ progress_percent│
│ video_url       │       │ last_accessed   │
│ duration        │       └─────────────────┘
│ order_index     │
└─────────────────┘

┌─────────────────┐       ┌─────────────────┐
│     tasks       │       │  task_delivery  │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──────│ task_id (FK)    │
│ course_id (FK)  │       │ user_id (FK)    │
│ lesson_id (FK)  │       │ file_url        │
│ title           │       │ content         │
│ description     │       │ delivered_at    │
│ due_date        │       │ grade           │
│ max_grade       │       │ feedback        │
│ created_by      │       │ graded_by       │
└─────────────────┘       │ graded_at       │
                          └─────────────────┘

┌─────────────────┐       ┌─────────────────┐
│     quizzes     │       │ quiz_attempts   │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──────│ quiz_id (FK)    │
│ course_id (FK)  │       │ user_id (FK)    │
│ title           │       │ started_at      │
│ description     │       │ completed_at    │
│ time_limit      │       │ score          │
│ passing_score   │       │ is_completed    │
│ attempts_limit  │       └─────────────────┘
│ is_published    │
└─────────────────┘
         │
         ▼
┌─────────────────┐       ┌─────────────────┐
│ quiz_questions  │       │ question_answer │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──────│ question_id (FK)│
│ quiz_id (FK)    │       │ attempt_id (FK) │
│ question_text   │       │ selected_answer │
│ question_type   │       │ is_correct      │
│ options (JSON)  │       │ points_earned   │
│ correct_answer  │       └─────────────────┘
│ points          │
│ order_index     │
└─────────────────┘

┌─────────────────┐       ┌─────────────────┐
│    messages     │       │  conversations  │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──────│ id (PK)         │
│ conversation_id │       │ type (direct/   │
│ sender_id (FK)  │       │   group)        │
│ content         │       │ title           │
│ file_url        │       │ created_at      │
│ created_at      │       └─────────────────┘
└─────────────────┘

┌─────────────────┐       ┌─────────────────┐
│ platform_perm  │       │  system_modules │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──────│ id (PK)         │
│ user_id (FK)    │       │ key             │
│ module_key (FK) │       │ name            │
│ is_enabled      │       │ icon            │
│ created_at      │       │ route           │
│ updated_at      │       │ category        │
└─────────────────┘       │ is_active       │
                          └─────────────────┘
```

### 3.2 Script SQL Completo de Base de Datos

```sql
-- =====================================================
-- ESCUELAMAK - APLICACIÓN MÓVIL EDUCATIVA
-- Base de Datos Completa para Supabase
-- =====================================================

-- -----------------------------------------------------
-- 1. USUARIOS Y AUTENTICACIÓN
-- -----------------------------------------------------

-- Tabla principal de usuarios
CREATE TABLE app_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'teacher', 'tutor', 'student')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Perfiles de usuario
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    photo_url TEXT,
    phone VARCHAR(50),
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------
-- 2. CURSOS Y CONTENIDO
-- -----------------------------------------------------

-- Categorías de cursos
CREATE TABLE course_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    color VARCHAR(20),
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cursos
CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_url TEXT,
    category_id UUID REFERENCES course_categories(id),
    teacher_id UUID NOT NULL REFERENCES app_users(id),
    difficulty VARCHAR(50) DEFAULT 'beginner' CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
    duration_hours DECIMAL(5,2) DEFAULT 0,
    is_published BOOLEAN DEFAULT false,
    is_free BOOLEAN DEFAULT false,
    price DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Relación usuarios-cursos (matrículas)
CREATE TABLE course_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    progress_percent DECIMAL(5,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(course_id, user_id)
);

-- Lecciones
CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content TEXT,
    video_url TEXT,
    video_duration INT, -- en segundos
    order_index INT NOT NULL,
    is_published BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Materiales de lección
CREATE TABLE lesson_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50), -- pdf, doc, image, video
    file_size INT, -- en bytes
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Progreso del estudiante en lecciones
CREATE TABLE lesson_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    is_completed BOOLEAN DEFAULT false,
    progress_percent DECIMAL(5,2) DEFAULT 0,
    time_spent_seconds INT DEFAULT 0,
    last_accessed TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    UNIQUE(lesson_id, user_id)
);

-- -----------------------------------------------------
-- 3. TAREAS Y EVALUACIONES
-- -----------------------------------------------------

-- Tareas
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    instructions TEXT,
    due_date TIMESTAMPTZ,
    max_grade DECIMAL(5,2) DEFAULT 100,
    allow_late BOOLEAN DEFAULT false,
    late_penalty_percent DECIMAL(5,2) DEFAULT 10,
    attachments JSONB DEFAULT '[]',
    created_by UUID NOT NULL REFERENCES app_users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Entregas de tareas
CREATE TABLE task_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    content TEXT,
    file_urls JSONB DEFAULT '[]',
    delivered_at TIMESTAMPTZ DEFAULT NOW(),
    is_late BOOLEAN DEFAULT false,
    grade DECIMAL(5,2),
    feedback TEXT,
    graded_by UUID REFERENCES app_users(id),
    graded_at TIMESTAMPTZ,
    UNIQUE(task_id, user_id)
);

-- -----------------------------------------------------
-- 4. QUIZZES Y PREGUNTAS
-- -----------------------------------------------------

-- Quizzes
CREATE TABLE quizzes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    time_limit INT, -- en minutos, NULL = sin límite
    passing_score DECIMAL(5,2) DEFAULT 70,
    attempts_limit INT DEFAULT 1,
    shuffle_questions BOOLEAN DEFAULT false,
    show_results IMMEDIATE VARCHAR(50) DEFAULT 'after_submit' CHECK (show_results IN ('after_submit', 'after_deadline', 'never')),
    is_published BOOLEAN DEFAULT false,
    created_by UUID NOT NULL REFERENCES app_users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Preguntas de quiz
CREATE TABLE quiz_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL CHECK (question_type IN ('multiple_choice', 'true_false', 'short_answer', 'matching')),
    options JSONB NOT NULL DEFAULT '[]',
    correct_answer JSONB NOT NULL,
    points DECIMAL(5,2) DEFAULT 1,
    order_index INT NOT NULL,
    explanation TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Intentos de quiz
CREATE TABLE quiz_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    score DECIMAL(5,2),
    max_score DECIMAL(5,2),
    is_completed BOOLEAN DEFAULT false,
    UNIQUE(quiz_id, user_id, started_at)
);

-- Respuestas de preguntas
CREATE TABLE question_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES quiz_attempts(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES quiz_questions(id) ON DELETE CASCADE,
    selected_answer JSONB,
    is_correct BOOLEAN DEFAULT false,
    points_earned DECIMAL(5,2) DEFAULT 0,
    answered_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------
-- 5. MENSAJERÍA
-- -----------------------------------------------------

-- Conversaciones
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) DEFAULT 'direct' CHECK (type IN ('direct', 'group', 'course')),
    title VARCHAR(255),
    course_id UUID REFERENCES courses(id),
    created_by UUID NOT NULL REFERENCES app_users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Participantes de conversación
CREATE TABLE conversation_participants (
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    last_read_at TIMESTAMPTZ,
    UNIQUE(conversation_id, user_id)
);

-- Mensajes
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES app_users(id),
    content TEXT NOT NULL,
    file_url TEXT,
    file_type VARCHAR(50),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------
-- 6. PERMISOS DE MÓDULOS
-- -----------------------------------------------------

-- Módulos del sistema
CREATE TABLE system_modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    route VARCHAR(255),
    category VARCHAR(100),
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Permisos por usuario
CREATE TABLE user_module_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    module_key VARCHAR(100) NOT NULL,
    is_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, module_key)
);

-- Permisos por rol
CREATE TABLE role_module_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role VARCHAR(50) NOT NULL,
    module_key VARCHAR(100) NOT NULL,
    is_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(role, module_key)
);

-- -----------------------------------------------------
-- 7. CALENDARIO Y EVENTOS
-- -----------------------------------------------------

-- Eventos del calendario
CREATE TABLE calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('class', 'task_due', 'quiz', 'exam', 'announcement')),
    course_id UUID REFERENCES courses(id),
    start_datetime TIMESTAMPTZ NOT NULL,
    end_datetime TIMESTAMPTZ,
    all_day BOOLEAN DEFAULT false,
    color VARCHAR(20),
    created_by UUID REFERENCES app_users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------
-- 8. ACTIVIDAD Y AUDITORÍA
-- -----------------------------------------------------

-- Log de actividad de usuarios
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES app_users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    metadata JSONB DEFAULT '{}',
    ip_address VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------
-- ÍNDICES PARA MEJORAR RENDIMIENTO
-- -----------------------------------------------------

CREATE INDEX idx_users_email ON app_users(email);
CREATE INDEX idx_users_role ON app_users(role);
CREATE INDEX idx_courses_teacher ON courses(teacher_id);
CREATE INDEX idx_courses_category ON courses(category_id);
CREATE INDEX idx_lessons_course ON lessons(course_id);
CREATE INDEX idx_lessons_order ON lessons(order_index);
CREATE INDEX idx_tasks_course ON tasks(course_id);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_deliveries_task ON task_deliveries(task_id);
CREATE INDEX idx_deliveries_user ON task_deliveries(user_id);
CREATE INDEX idx_quizzes_course ON quizzes(course_id);
CREATE INDEX idx_questions_quiz ON quiz_questions(quiz_id);
CREATE INDEX idx_attempts_quiz ON quiz_attempts(quiz_id);
CREATE INDEX idx_attempts_user ON quiz_attempts(user_id);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_created ON messages(created_at);
CREATE INDEX idx_activity_logs_user ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_created ON activity_logs(created_at);

-- -----------------------------------------------------
-- 9. POLÍTICAS DE SEGURIDAD RLS
-- -----------------------------------------------------

-- Habilitar RLS en todas las tablas
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_module_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_module_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- Políticas para usuarios (lectura pública del perfil)
CREATE POLICY "Usuarios pueden ver sus propios datos" ON app_users
    FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "Usuarios ven sus propios perfiles" ON user_profiles
    FOR SELECT USING (
        user_id IN (SELECT id FROM app_users WHERE auth.uid() = auth_user_id)
    );

-- Políticas para cursos
CREATE POLICY "Cursos publicados visibles para todos" ON courses
    FOR SELECT USING (is_published = true);

CREATE POLICY "Profesores ven sus cursos" ON courses
    FOR ALL USING (
        teacher_id IN (SELECT id FROM app_users WHERE auth.uid() = auth_user_id)
    );

-- -----------------------------------------------------
-- 10. DATOS INICIALES
-- -----------------------------------------------------

-- Insertar categorías de cursos
INSERT INTO course_categories (name, description, icon, color, display_order) VALUES
('Matemáticas', 'Cursos de matemáticas y cálculo', 'fas fa-calculator', '#3b82f6', 1),
('Ciencias', 'Ciencias naturales y física', 'fas fa-flask', '#10b981', 2),
('Programación', 'Desarrollo de software', 'fas fa-code', '#8b5cf6', 3),
('Idiomas', 'Aprendizaje de idiomas', 'fas fa-language', '#f59e0b', 4),
('Historia', 'Historia y geografía', 'fas fa-landmark', '#ef4444', 5)
ON CONFLICT DO NOTHING;

-- Insertar módulos del sistema
INSERT INTO system_modules (key, name, description, icon, route, category, display_order) VALUES
('menu_dashboard', 'Dashboard', 'Panel principal', 'fas fa-home', '/dashboard', 'Navegación', 1),
('menu_courses', 'Mis Cursos', 'Ver cursos disponibles', 'fas fa-book', '/courses', 'Navegación', 2),
('menu_lessons', 'Lecciones', 'Contenido de clases', 'fas fa-play-circle', '/lessons', 'Navegación', 3),
('menu_tasks', 'Tareas', 'Tareas y entregas', 'fas fa-tasks', '/tasks', 'Navegación', 4),
('menu_quizzes', 'Evaluaciones', 'Quizzes y exámenes', 'fas fa-question-circle', '/quizzes', 'Navegación', 5),
('menu_messages', 'Mensajes', 'Comunicación', 'fas fa-comments', '/messages', 'Navegación', 6),
('menu_calendar', 'Calendario', 'Agenda de actividades', 'fas fa-calendar', '/calendar', 'Navegación', 7),
('menu_profile', 'Perfil', 'Mi perfil', 'fas fa-user', '/profile', 'Navegación', 8),
('menu_teacher_courses', 'Gestión de Cursos', 'Administrar cursos', 'fas fa-chalkboard-teacher', '/teacher/courses', 'Docente', 9),
('menu_teacher_tasks', 'Revisar Tareas', 'Calificar entregas', 'fas fa-check-double', '/teacher/tasks', 'Docente', 10),
('menu_teacher_quizzes', 'Crear Quizzes', 'Gestionar evaluaciones', 'fas fa-plus-circle', '/teacher/quizzes', 'Docente', 11),
('menu_admin_users', 'Gestión de Usuarios', 'Administrar usuarios', 'fas fa-users-cog', '/admin/users', 'Administración', 12),
('menu_admin_permissions', 'Permisos de Módulos', 'Configurar accesos', 'fas fa-shield-alt', '/admin/permissions', 'Administración', 13),
('menu_admin_settings', 'Configuración', 'Ajustes del sistema', 'fas fa-cogs', '/admin/settings', 'Administración', 14)
ON CONFLICT DO NOTHING;

-- Insertar permisos por rol (default)
INSERT INTO role_module_permissions (role, module_key, is_enabled) VALUES
-- Admin tiene todo
('admin', 'menu_dashboard', true),
('admin', 'menu_courses', true),
('admin', 'menu_lessons', true),
('admin', 'menu_tasks', true),
('admin', 'menu_quizzes', true),
('admin', 'menu_messages', true),
('admin', 'menu_calendar', true),
('admin', 'menu_profile', true),
('admin', 'menu_teacher_courses', true),
('admin', 'menu_teacher_tasks', true),
('admin', 'menu_teacher_quizzes', true),
('admin', 'menu_admin_users', true),
('admin', 'menu_admin_permissions', true),
('admin', 'menu_admin_settings', true),
-- Teacher tiene acceso a funcionalidades de profesor
('teacher', 'menu_dashboard', true),
('teacher', 'menu_courses', true),
('teacher', 'menu_lessons', true),
('teacher', 'menu_tasks', true),
('teacher', 'menu_quizzes', true),
('teacher', 'menu_messages', true),
('teacher', 'menu_calendar', true),
('teacher', 'menu_profile', true),
('teacher', 'menu_teacher_courses', true),
('teacher', 'menu_teacher_tasks', true),
('teacher', 'menu_teacher_quizzes', true),
('teacher', 'menu_admin_users', false),
('teacher', 'menu_admin_permissions', false),
('teacher', 'menu_admin_settings', false),
-- Tutor
('tutor', 'menu_dashboard', true),
('tutor', 'menu_courses', true),
('tutor', 'menu_lessons', true),
('tutor', 'menu_tasks', true),
('tutor', 'menu_quizzes', true),
('tutor', 'menu_messages', true),
('tutor', 'menu_calendar', true),
('tutor', 'menu_profile', true),
('tutor', 'menu_teacher_courses', false),
('tutor', 'menu_teacher_tasks', true),
('tutor', 'menu_teacher_quizzes', true),
('tutor', 'menu_admin_users', false),
('tutor', 'menu_admin_permissions', false),
('tutor', 'menu_admin_settings', false),
-- Student
('student', 'menu_dashboard', true),
('student', 'menu_courses', true),
('student', 'menu_lessons', true),
('student', 'menu_tasks', true),
('student', 'menu_quizzes', true),
('student', 'menu_messages', true),
('student', 'menu_calendar', true),
('student', 'menu_profile', true),
('student', 'menu_teacher_courses', false),
('student', 'menu_teacher_tasks', false),
('student', 'menu_teacher_quizzes', false),
('student', 'menu_admin_users', false),
('student', 'menu_admin_permissions', false),
('student', 'menu_admin_settings', false)
ON CONFLICT DO NOTHING;
```

---

## 4. Dependencias y Paquetes Flutter

### 4.1 pubspec.yaml

```yaml
name: escuelamak_mobile
description: Aplicación educativa móvil EscuelaMak
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Supabase
  supabase_flutter: ^2.0.0
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Dependency Injection
  get_it: ^7.6.4
  
  # Navigation
  go_router: ^12.1.1
  
  # UI Components
  flutter_slidable: ^3.0.1
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # Forms
  flutter_form_builder: ^9.1.1
  form_builder_validators: ^9.1.0
  
  # Date/Time
  intl: ^0.18.1
  
  # Storage
  shared_preferences: ^2.2.2
  
  # Notifications
  flutter_local_notifications: ^15.1.0+1
  
  # Charts
  fl_chart: ^0.65.0
  
  # File Picker
  file_picker: ^6.1.1
  
  # Image Picker
  image_picker: ^1.0.4
  
  # URL Launcher
  url_launcher: ^6.2.1
  
  # Timezone
  timezone: ^0.9.2
  
  # JSON Serialization
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.6
  json_serializable: ^6.7.1
  bloc_test: ^9.1.5
  mocktail: ^1.0.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
```

---

## 5. Especificación de API

### 5.1 Autenticación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/auth/signup` | Registro de usuario |
| POST | `/auth/login` | Inicio de sesión |
| POST | `/auth/logout` | Cerrar sesión |
| POST | `/auth/reset-password` | Recuperar contraseña |
| GET | `/auth/user` | Obtener usuario actual |

### 5.2 Cursos

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/courses` | Listar cursos |
| GET | `/courses/:id` | Ver curso |
| POST | `/courses` | Crear curso |
| PUT | `/courses/:id` | Actualizar curso |
| DELETE | `/courses/:id` | Eliminar curso |
| POST | `/courses/:id/enroll` | Matricularse |
| GET | `/my-courses` | Mis cursos |

### 5.3 Lecciones

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/courses/:id/lessons` | Lecciones del curso |
| GET | `/lessons/:id` | Ver lección |
| POST | `/lessons/:id/progress` | Actualizar progreso |

### 5.4 Tareas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/tasks` | Listar tareas |
| GET | `/tasks/:id` | Ver tarea |
| POST | `/tasks` | Crear tarea |
| POST | `/tasks/:id/deliver` | Entregar tarea |
| PUT | `/tasks/:id/grade` | Calificar tarea |

### 5.5 Quizzes

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/quizzes` | Listar quizzes |
| GET | `/quizzes/:id` | Ver quiz |
| GET | `/quizzes/:id/questions` | Preguntas del quiz |
| POST | `/quizzes/:id/start` | Iniciar intento |
| POST | `/quizzes/:id/answer` | Responder pregunta |
| POST | `/quizzes/:id/submit` | Enviar quiz |

### 5.6 Mensajes

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/conversations` | Mis conversaciones |
| GET | `/conversations/:id/messages` | Mensajes |
| POST | `/conversations/:id/messages` | Enviar mensaje |

---

## 6. Pantallas Principales (Wireframes Descripción)

### 6.1 Pantallas de Autenticación

#### Login Screen
- Logo de la app en centro superior
- Campo de email con icono
- Campo de contraseña (oculta caracteres)
- Botón "Iniciar Sesión" principal
- Link "Olvidé mi contraseña"
- Link "Registrarse"

#### Register Screen
- Campo nombre completo
- Campo email
- Campo contraseña
- Campo confirmar contraseña
- Selector de rol (estudiante por defecto)
- Términos y condiciones (checkbox)
- Botón "Registrarse"

### 6.2 Pantallas de Estudiante

#### Student Home
- Saludo personalizado "Hola, [nombre]"
- Cards de cursos activos con progreso
- Tareas pendientes (máximo 3)
- Próximos quizzes
- Acceso rápido a mensajes

#### Student Courses
- Grid de cards de cursos
- Cada card: imagen, título, progreso, instructor
- Filtro por categoría
- Buscador

#### Student Lessons
- Video player en parte superior
- Título y descripción
- Lista de materiales descargables
- Botón "Marcar como completada"
- Lecciones anteriores/siguiente

#### Student Tasks
- Tabs: Pendientes | Entregadas | Calificadas
- Card de tarea: título, curso, fecha límite, estado
- Indicador de días restantes
- Botón de entregar

#### Student Quizzes
- Lista de quizzes disponibles
- Card: título, preguntas, tiempo, intentos
- Estado: no iniciado, en progreso, completado

### 6.3 Pantallas de Profesor

#### Teacher Dashboard
- Estadísticas: cursos, estudiantes, tareas pendientes
- Cursos con más actividad
- Tareas por calificar
- Mensajes sin leer

#### Teacher Course Management
- Lista de cursos del profesor
- Crear nuevo curso
- Editar/eliminar curso
- Ver estudiantes matriculados

#### Teacher Quiz Builder
- Editor visual de quiz
- Tipos de preguntas en toolbar
- Arrastrar y soltar preguntas
- Vista previa
- Configuración de tiempo y intentos

### 6.4 Pantallas de Administrador

#### Admin Dashboard
- Métricas globales
- Usuarios activos por rol
- Cursos publicados
- Actividad reciente

#### Admin User Management
- Tabla de usuarios
- Buscador y filtros
- Acciones: editar rol, activar/desactivar, eliminar

#### Admin Permissions Panel
- Lista de módulos del sistema
- Switches para cada rol
- Activar/desactivar módulos
- Vista previa en tiempo real

---

## 7. Código Base - Ejemplos

### 7.1 Configuración de Supabase

```dart
// lib/core/supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'TU_SUPABASE_URL';
  static const String anonKey = 'TU_SUPABASE_ANON_KEY';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}
```

### 7.2 Modelo de Usuario

```dart
// lib/data/models/user_model.dart
import 'package:equatable/equatable.dart';

enum UserRole { admin, teacher, tutor, student }

class UserModel extends Equatable {
  final String id;
  final String authUserId;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final UserProfileModel? profile;

  const UserModel({
    required this.id,
    required this.authUserId,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.profile,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      authUserId: map['auth_user_id'] as String,
      email: map['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.student,
      ),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'email': email,
      'role': role.name,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, email, role, isActive];
}

class UserProfileModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? photoUrl;
  final String? phone;
  final String? bio;

  const UserProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    this.photoUrl,
    this.phone,
    this.bio,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      photoUrl: map['photo_url'] as String?,
      phone: map['phone'] as String?,
      bio: map['bio'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, userId, name];
}
```

### 7.3 Repositorio de Autenticación

```dart
// lib/data/repositories/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRepository {
  final SupabaseClient _client;
  
  AuthRepository(this._client);
  
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user == null) return null;
    
    // Obtener datos del usuario de app_users
    final userData = await _client
        .from('app_users')
        .select()
        .eq('auth_user_id', response.user!.id)
        .maybeSingle();
    
    if (userData == null) {
      await _client.auth.signOut();
      return null;
    }
    
    return UserModel.fromMap(userData);
  }
  
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  UserModel? getCurrentUser() {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    
    // Implementar obtener usuario actual
    return null;
  }
  
  Stream<UserModel?> get authStateChanges() {
    return _client.auth.userChanges().asyncMap((authUser) async {
      if (authUser == null) return null;
      
      final userData = await _client
          .from('app_users')
          .select()
          .eq('auth_user_id', authUser.id)
          .maybeSingle();
      
      if (userData == null) return null;
      
      return UserModel.fromMap(userData);
    });
  }
}
```

### 7.4 BLoC de Permisos

```dart
// lib/presentation/blocs/permissions/permission_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/permissions_repository.dart';

// Events
abstract class PermissionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPermissionsEvent extends PermissionEvent {
  final String userId;
  LoadPermissionsEvent(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

class ToggleModulePermissionEvent extends PermissionEvent {
  final String moduleKey;
  final bool isEnabled;
  
  ToggleModulePermissionEvent(this.moduleKey, this.isEnabled);
  
  @override
  List<Object?> get props => [moduleKey, isEnabled];
}

// States
abstract class PermissionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PermissionInitial extends PermissionState {}

class PermissionLoading extends PermissionState {}

class PermissionLoaded extends PermissionState {
  final Map<String, bool> modulePermissions;
  
  PermissionLoaded(this.modulePermissions);
  
  bool isModuleEnabled(String moduleKey) {
    return modulePermissions[moduleKey] ?? false;
  }
  
  @override
  List<Object?> get props => [modulePermissions];
}

class PermissionError extends PermissionState {
  final String message;
  PermissionError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class PermissionBloc extends Bloc<PermissionEvent, PermissionState> {
  final PermissionsRepository _repository;
  
  PermissionBloc(this._repository) : super(PermissionInitial()) {
    on<LoadPermissionsEvent>(_onLoadPermissions);
    on<ToggleModulePermissionEvent>(_onTogglePermission);
  }
  
  Future<void> _onLoadPermissions(
    LoadPermissionsEvent event,
    Emitter<PermissionState> emit,
  ) async {
    emit(PermissionLoading());
    
    try {
      final permissions = await _repository.getUserPermissions(event.userId);
      emit(PermissionLoaded(permissions));
    } catch (e) {
      emit(PermissionError(e.toString()));
    }
  }
  
  Future<void> _onTogglePermission(
    ToggleModulePermissionEvent event,
    Emitter<PermissionState> emit,
  ) async {
    try {
      await _repository.toggleModulePermission(
        event.moduleKey,
        event.isEnabled,
      );
      
      if (state is PermissionLoaded) {
        final currentPermissions = (state as PermissionLoaded).modulePermissions;
        final updatedPermissions = Map<String, bool>.from(currentPermissions);
        updatedPermissions[event.moduleKey] = event.isEnabled;
        emit(PermissionLoaded(updatedPermissions));
      }
    } catch (e) {
      emit(PermissionError(e.toString()));
    }
  }
}
```

### 7.5 Pantalla de Permisos (Admin)

```dart
// lib/presentation/screens/admin/permissions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/permissions/permission_bloc.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permisos de Módulos'),
      ),
      body: BlocBuilder<PermissionBloc, PermissionState>(
        builder: (context, state) {
          if (state is PermissionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is PermissionError) {
            return Center(child: Text(state.message));
          }
          
          if (state is PermissionLoaded) {
            return _buildPermissionList(context, state);
          }
          
          return const Center(child: Text('Cargando...'));
        },
      ),
    );
  }

  Widget _buildPermissionList(BuildContext context, PermissionLoaded state) {
    final modules = [
      {'key': 'menu_courses', 'name': 'Cursos', 'icon': Icons.school},
      {'key': 'menu_lessons', 'name': 'Lecciones', 'icon': Icons.play_circle},
      {'key': 'menu_tasks', 'name': 'Tareas', 'icon': Icons.assignment},
      {'key': 'menu_quizzes', 'name': 'Quizzes', 'icon': Icons.quiz},
      {'key': 'menu_messages', 'name': 'Mensajes', 'icon': Icons.message},
      {'key': 'menu_calendar', 'name': 'Calendario', 'icon': Icons.calendar_today},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        final isEnabled = state.isModuleEnabled(module['key']!);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(module['icon'] as IconData),
            title: Text(module['name'] as String),
            trailing: Switch(
              value: isEnabled,
              onChanged: (value) {
                context.read<PermissionBloc>().add(
                  ToggleModulePermissionEvent(module['key']!, value),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
```

---

## 8. Estrategia de Testing

### 8.1 Tipos de Testing

| Tipo | Herramienta | Cobertura Objetivo |
|------|-------------|-------------------|
| Unit Tests | flutter_test, mocktail | 70% |
| Widget Tests | flutter_test | 50% |
| Integration Tests | flutter_test | 30% |
| E2E Tests | Patrol, Codemagic | Críticos |

### 8.2 Estructura de Tests

```
test/
├── unit/
│   ├── models/
│   │   ├── user_model_test.dart
│   │   └── course_model_test.dart
│   ├── repositories/
│   │   ├── auth_repository_test.dart
│   │   └── course_repository_test.dart
│   └── blocs/
│       ├── auth_bloc_test.dart
│       └── permission_bloc_test.dart
├── widget/
│   ├── login_screen_test.dart
│   └── course_card_test.dart
└── integration/
    ├── login_flow_test.dart
    └── course_enrollment_test.dart
```

### 8.3 Ejemplo de Test Unitario

```dart
// test/unit/models/user_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:escuelamak/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create UserModel from map', () {
      final map = {
        'id': '123',
        'auth_user_id': 'abc',
        'email': 'test@test.com',
        'role': 'student',
        'is_active': true,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final user = UserModel.fromMap(map);

      expect(user.id, '123');
      expect(user.email, 'test@test.com');
      expect(user.role, UserRole.student);
      expect(user.isActive, true);
    });

    test('should convert UserModel to map', () {
      const user = UserModel(
        id: '123',
        authUserId: 'abc',
        email: 'test@test.com',
        role: UserRole.teacher,
        isActive: true,
        createdAt: null,
      );

      final map = user.toMap();

      expect(map['id'], '123');
      expect(map['email'], 'test@test.com');
      expect(map['role'], 'teacher');
    });
  });
}
```

---

## 9. Despliegue en Tiendas

### 9.1 Google Play Store

1. **Configurar signing**
   - Generar keystore: `keytool -genkeypair -v -storetype PKCS12 -keystore escuelamak.jks -keyalg RSA -keysize 2048 -validity 10000 -alias escuelamak`
   - Guardar credenciales en lugar seguro

2. **Actualizar android/app/build.gradle**
   ```gradle
   android {
       signingConfigs {
           release {
               storeFile file("escuelamak.jks")
               storePassword "password"
               keyAlias "escuelamak"
               keyPassword "password"
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
               minifyEnabled true
               shrinkResources true
           }
       }
   }
   ```

3. **Build de release**
   ```bash
   flutter build appbundle --release
   ```

4. **Publicar en Play Console**
   - Crear app en Google Play Console
   - Subir archivo .aab
   - Completar información de la app
   - Enviar a revisión

### 9.2 App Store

1. **Requisitos**
   - Cuenta de Apple Developer ($99/año)
   - Mac con Xcode
   - Certificado de distribución
   - App Store Connect

2. **Configurar iOS**
   - Actualizar Bundle Identifier
   - Configurar en Xcode: Signing & Capabilities
   - Crear App Store record

3. **Build de release**
   ```bash
   flutter build ipa --release
   ```

4. **Publicar**
   - Subir archivo .ipa via Xcode o Transporter
   - Completar información en App Store Connect
   - Enviar a revisión

---

## 10. Mejores Prácticas de Desarrollo

### 10.1 Código Limpio

1. **Nombrado**: Usar nombres descriptivos en inglés
2. **Funciones**: Máximo 20-30 líneas por función
3. **Comentarios**: Documentar funciones públicas y decisiones complejas
4. **DRY**: Evitar duplicación de código
5. **SOLID**: Aplicar principios de diseño

### 10.2 Seguridad

1. **Datos sensibles**: Nunca hardcodear credenciales
2. **Validación**: Validar input del usuario siempre
3. **RLS**: Usar políticas de Supabase
4. **HTTPS**: Solo conexiones seguras
5. **Tokens**: Refresh tokens automáticamente

### 10.3 Rendimiento

1. **Imágenes**: Usar cached_network_image
2. **Listas**: Implementar ListView.builder
3. **Lazy Loading**: Cargar datos bajo demanda
4. **Debug**: Usar DevTools para profiling

### 10.4 Control de Versiones

1. **Commits atómicos**: Un cambio por commit
2. **Mensajes claros**: Formato conventional commits
3. **Ramas**: Git Flow para features, hotfixes
4. **Code Review**: Revisiones antes de merge

---

## 11. Resumen de Módulos Esenciales

| Módulo | Prioridad | Descripción |
|--------|----------|-------------|
| Auth | 🔴 Alta | Login, registro, recuperación de contraseña |
| Dashboard | 🔴 Alta | Vista principal según rol |
| Cursos | 🔴 Alta | Listado, detalle, lecciones |
| Tareas | 🔴 Alta | Entregas, calificaciones |
| Quizzes | 🔴 Alta | Evaluaciones, intentos |
| Permisos | 🔴 Alta | Control de acceso por rol |
| Mensajes | 🟡 Media | Comunicación |
| Calendario | 🟡 Media | Agenda de actividades |
| Perfil | 🟢 Baja | Configuración de usuario |

---

Este documento proporciona una guía completa para desarrollar la aplicación móvil educativa. La estructura de base de datos está optimizada para Supabase y las políticas RLS proporcionan seguridad desde el backend.
