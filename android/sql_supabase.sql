-- ============================================================
-- ESCUELAMAK — Script SQL Completo para Supabase
-- Versión 1.0 | Ejecutar en Supabase SQL Editor
-- ============================================================
-- INSTRUCCIONES: Copia todo este script y pégalo en
-- Supabase Dashboard → SQL Editor → New Query → Run
-- ============================================================


-- ============================================================
-- 0. EXTENSIONES NECESARIAS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ============================================================
-- 1. TABLA: categories (sin dependencias)
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre      TEXT NOT NULL,
  descripcion TEXT,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Datos iniciales
INSERT INTO categories (nombre, descripcion) VALUES
  ('Matemáticas',     'Álgebra, cálculo y estadística'),
  ('Ciencias',        'Física, química y biología'),
  ('Idiomas',         'Español, inglés y otros idiomas'),
  ('Tecnología',      'Programación y herramientas digitales'),
  ('Arte y Música',   'Expresión artística y musical'),
  ('Historia',        'Historia universal y local')
ON CONFLICT DO NOTHING;


-- ============================================================
-- 2. TABLA: profiles (extiende auth.users de Supabase)
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  usuario_id  VARCHAR(50) UNIQUE,
  nombres     VARCHAR(100) NOT NULL,
  apellidos   VARCHAR(100) NOT NULL,
  foto_url    TEXT,
  rol         VARCHAR(20) NOT NULL DEFAULT 'estudiante'
                CHECK (rol IN ('estudiante', 'profesor', 'admin')),
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_profiles_rol ON profiles(rol);
CREATE INDEX IF NOT EXISTS idx_profiles_usuario_id ON profiles(usuario_id);


-- ============================================================
-- 3. TABLA: courses
-- ============================================================
CREATE TABLE IF NOT EXISTS courses (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  titulo        TEXT NOT NULL,
  descripcion   TEXT,
  instructor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  categoria_id  UUID REFERENCES categories(id) ON DELETE SET NULL,
  duracion      INTEGER DEFAULT 0,          -- en minutos
  imagen_url    TEXT,
  is_published  BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_courses_instructor ON courses(instructor_id);
CREATE INDEX IF NOT EXISTS idx_courses_categoria  ON courses(categoria_id);
CREATE INDEX IF NOT EXISTS idx_courses_published  ON courses(is_published);


-- ============================================================
-- 4. TABLA: course_enrollments
-- ============================================================
CREATE TABLE IF NOT EXISTS course_enrollments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id   UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status      VARCHAR(20) DEFAULT 'activo'
                CHECK (status IN ('activo', 'completado', 'suspendido')),
  enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(course_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_enrollments_user   ON course_enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON course_enrollments(course_id);


-- ============================================================
-- 5. TABLA: lessons
-- ============================================================
CREATE TABLE IF NOT EXISTS lessons (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id  UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  titulo     TEXT NOT NULL,
  contenido  TEXT,
  video_url  TEXT,
  orden      INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lessons_course ON lessons(course_id);
CREATE INDEX IF NOT EXISTS idx_lessons_orden  ON lessons(course_id, orden);


-- ============================================================
-- 6. TABLA: tasks
-- ============================================================
CREATE TABLE IF NOT EXISTS tasks (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id      UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  titulo         TEXT NOT NULL,
  descripcion    TEXT,
  fecha_entrega  TIMESTAMP WITH TIME ZONE,
  criterios      TEXT,
  archivo_url    TEXT,     -- archivo adjunto del profesor
  is_active      BOOLEAN DEFAULT TRUE,
  created_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_lesson       ON tasks(lesson_id);
CREATE INDEX IF NOT EXISTS idx_tasks_fecha        ON tasks(fecha_entrega);


-- ============================================================
-- 7. TABLA: task_submissions
-- ============================================================
CREATE TABLE IF NOT EXISTS task_submissions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id         UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  student_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  archivo_url     TEXT,
  comentarios     TEXT,
  calificacion    INTEGER CHECK (calificacion BETWEEN 0 AND 100),
  retroalimentacion TEXT,
  status          VARCHAR(20) DEFAULT 'entregado'
                    CHECK (status IN ('entregado', 'calificado', 'revision')),
  submitted_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(task_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_submissions_task    ON task_submissions(task_id);
CREATE INDEX IF NOT EXISTS idx_submissions_student ON task_submissions(student_id);


-- ============================================================
-- 8. TABLA: quizzes
-- ============================================================
CREATE TABLE IF NOT EXISTS quizzes (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id           UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  titulo              TEXT NOT NULL,
  descripcion         TEXT,
  tiempo_limite       INTEGER DEFAULT 30,    -- en minutos
  intentos_permitidos INTEGER DEFAULT 1,
  mostrar_resultados  BOOLEAN DEFAULT TRUE,  -- inmediato o posterior
  is_active           BOOLEAN DEFAULT TRUE,
  created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quizzes_lesson ON quizzes(lesson_id);


-- ============================================================
-- 9. TABLA: questions
-- ============================================================
CREATE TABLE IF NOT EXISTS questions (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  quiz_id            UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  tipo_pregunta      VARCHAR(30) NOT NULL
                       CHECK (tipo_pregunta IN (
                         'opcion_multiple', 'respuesta_corta',
                         'verdadero_falso', 'emparejamiento'
                       )),
  pregunta           TEXT NOT NULL,
  opciones           JSONB,              -- array de opciones para opción múltiple
  respuestas_correctas JSONB NOT NULL,  -- respuestas correctas
  puntos             INTEGER DEFAULT 1,
  orden              INTEGER DEFAULT 1,
  created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_questions_quiz ON questions(quiz_id);

-- Ejemplo de estructura JSON para opciones:
-- opciones: ["Opción A", "Opción B", "Opción C", "Opción D"]
-- respuestas_correctas: ["Opción A"] o [0] (índice)


-- ============================================================
-- 10. TABLA: quiz_results
-- ============================================================
CREATE TABLE IF NOT EXISTS quiz_results (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  quiz_id      UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  student_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  respuestas   JSONB,           -- respuestas dadas por el estudiante
  calificacion INTEGER CHECK (calificacion BETWEEN 0 AND 100),
  tiempo_usado INTEGER,         -- segundos usados
  intento_num  INTEGER DEFAULT 1,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_results_quiz    ON quiz_results(quiz_id);
CREATE INDEX IF NOT EXISTS idx_results_student ON quiz_results(student_id);


-- ============================================================
-- 11. TABLA: conversations
-- ============================================================
CREATE TABLE IF NOT EXISTS conversations (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  participant_ids  UUID[] NOT NULL,        -- array de 2 UUIDs
  last_message     TEXT,
  last_message_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_conversations_participants
  ON conversations USING gin(participant_ids);


-- ============================================================
-- 12. TABLA: messages
-- ============================================================
CREATE TABLE IF NOT EXISTS messages (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  contenido       TEXT,
  archivo_adjunto TEXT,
  tipo            VARCHAR(20) DEFAULT 'texto'
                    CHECK (tipo IN ('texto', 'imagen', 'archivo')),
  is_read         BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender       ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created      ON messages(created_at DESC);


-- ============================================================
-- 13. TABLA: platform_permissions
-- (Ya existe — incluida por completitud, usar IF NOT EXISTS)
-- ============================================================
CREATE TABLE IF NOT EXISTS platform_permissions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key         VARCHAR(100) UNIQUE NOT NULL,
  name        VARCHAR(100) NOT NULL,
  description TEXT,
  icon        VARCHAR(100),
  route       VARCHAR(200),
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Datos iniciales de módulos (solo si no existen)
INSERT INTO platform_permissions (key, name, description, icon, route) VALUES
  ('courses',     'Cursos',        'Acceso al módulo de cursos',        'book',         '/courses'),
  ('tasks',       'Tareas',        'Gestión de tareas',                 'assignment',   '/tasks'),
  ('quizzes',     'Evaluaciones',  'Quizzes y evaluaciones',            'quiz',         '/quizzes'),
  ('messages',    'Mensajes',      'Chat con profesores/estudiantes',   'chat',         '/messages'),
  ('calendar',    'Calendario',    'Calendario de actividades',         'calendar',     '/calendar'),
  ('stats',       'Estadísticas',  'Reportes y estadísticas',           'bar_chart',    '/stats'),
  ('admin',       'Administración','Panel de administración',           'admin_panel',  '/admin'),
  ('profile',     'Perfil',        'Perfil de usuario',                 'person',       '/profile')
ON CONFLICT (key) DO NOTHING;


-- ============================================================
-- 14. TABLA: role_permissions
-- ============================================================
CREATE TABLE IF NOT EXISTS role_permissions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role        VARCHAR(20) NOT NULL CHECK (role IN ('estudiante', 'profesor', 'admin')),
  permission_key VARCHAR(100) NOT NULL REFERENCES platform_permissions(key),
  is_granted  BOOLEAN DEFAULT TRUE,
  UNIQUE(role, permission_key)
);

-- Permisos por defecto para cada rol
INSERT INTO role_permissions (role, permission_key, is_granted) VALUES
  -- Estudiante: acceso básico
  ('estudiante', 'courses',   TRUE),
  ('estudiante', 'tasks',     TRUE),
  ('estudiante', 'quizzes',   TRUE),
  ('estudiante', 'messages',  TRUE),
  ('estudiante', 'calendar',  TRUE),
  ('estudiante', 'stats',     FALSE),
  ('estudiante', 'admin',     FALSE),
  ('estudiante', 'profile',   TRUE),
  -- Profesor: acceso extendido
  ('profesor',   'courses',   TRUE),
  ('profesor',   'tasks',     TRUE),
  ('profesor',   'quizzes',   TRUE),
  ('profesor',   'messages',  TRUE),
  ('profesor',   'calendar',  TRUE),
  ('profesor',   'stats',     TRUE),
  ('profesor',   'admin',     FALSE),
  ('profesor',   'profile',   TRUE),
  -- Admin: acceso total
  ('admin',      'courses',   TRUE),
  ('admin',      'tasks',     TRUE),
  ('admin',      'quizzes',   TRUE),
  ('admin',      'messages',  TRUE),
  ('admin',      'calendar',  TRUE),
  ('admin',      'stats',     TRUE),
  ('admin',      'admin',     TRUE),
  ('admin',      'profile',   TRUE)
ON CONFLICT (role, permission_key) DO NOTHING;


-- ============================================================
-- 15. TABLA: user_permissions (sobrescribe permisos de rol)
-- ============================================================
CREATE TABLE IF NOT EXISTS user_permissions (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  permission_key VARCHAR(100) NOT NULL REFERENCES platform_permissions(key),
  is_granted     BOOLEAN DEFAULT TRUE,
  granted_by     UUID REFERENCES profiles(id),
  granted_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, permission_key)
);

CREATE INDEX IF NOT EXISTS idx_user_permissions_user ON user_permissions(user_id);


-- ============================================================
-- 16. TABLA: lesson_progress (seguimiento de progreso)
-- ============================================================
CREATE TABLE IF NOT EXISTS lesson_progress (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id     UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  completed     BOOLEAN DEFAULT FALSE,
  progress_pct  INTEGER DEFAULT 0 CHECK (progress_pct BETWEEN 0 AND 100),
  last_position INTEGER DEFAULT 0,  -- segundos en el video
  updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(lesson_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_progress_user   ON lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_lesson ON lesson_progress(lesson_id);


-- ============================================================
-- 17. TRIGGERS — Actualizar updated_at automáticamente
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger a tablas con updated_at
CREATE OR REPLACE TRIGGER trg_profiles_updated
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER trg_courses_updated
  BEFORE UPDATE ON courses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER trg_submissions_updated
  BEFORE UPDATE ON task_submissions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER trg_conversations_updated
  BEFORE UPDATE ON conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger: cuando llega un mensaje, actualizar last_message en conversations
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET last_message    = NEW.contenido,
      last_message_at = NEW.created_at,
      updated_at      = NOW()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE TRIGGER trg_message_update_conversation
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION update_conversation_last_message();

-- Trigger: crear perfil automáticamente al registrar usuario en auth.users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, nombres, apellidos, rol)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nombres', 'Usuario'),
    COALESCE(NEW.raw_user_meta_data->>'apellidos', ''),
    COALESCE(NEW.raw_user_meta_data->>'rol', 'estudiante')
  );
  RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trg_auth_new_user
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();


-- ============================================================
-- 18. ROW LEVEL SECURITY (RLS) — Políticas de Seguridad
-- ============================================================

-- Activar RLS en todas las tablas sensibles
ALTER TABLE profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses           ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons           ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks             ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_submissions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes           ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_results      ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages          ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations     ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_permissions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress   ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_enrollments ENABLE ROW LEVEL SECURITY;

-- ── PROFILES ──
CREATE POLICY "Ver perfil propio" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Actualizar perfil propio" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admin ve todos los perfiles" ON profiles
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND rol = 'admin')
  );

-- ── COURSES ──
CREATE POLICY "Cursos publicados visibles para todos" ON courses
  FOR SELECT USING (is_published = TRUE OR instructor_id = auth.uid());

CREATE POLICY "Instructor gestiona sus cursos" ON courses
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "Admin gestiona todos los cursos" ON courses
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND rol = 'admin')
  );

-- ── LESSONS ──
CREATE POLICY "Ver lecciones de cursos matriculados" ON lessons
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM course_enrollments ce
      JOIN courses c ON c.id = ce.course_id
      WHERE ce.user_id = auth.uid()
        AND c.id = lessons.course_id
        AND ce.status = 'activo'
    )
    OR EXISTS (
      SELECT 1 FROM courses WHERE id = course_id AND instructor_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND rol = 'admin'
    )
  );

-- ── TASK_SUBMISSIONS ──
CREATE POLICY "Ver entregas propias" ON task_submissions
  FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "Crear entrega propia" ON task_submissions
  FOR INSERT WITH CHECK (student_id = auth.uid());

CREATE POLICY "Profesor ve entregas de sus tareas" ON task_submissions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tasks t
      JOIN lessons l ON l.id = t.lesson_id
      JOIN courses c ON c.id = l.course_id
      WHERE t.id = task_id AND c.instructor_id = auth.uid()
    )
  );

-- ── MESSAGES ──
CREATE POLICY "Ver mensajes propios" ON messages
  FOR SELECT USING (sender_id = auth.uid() OR receiver_id = auth.uid());

CREATE POLICY "Enviar mensajes propios" ON messages
  FOR INSERT WITH CHECK (sender_id = auth.uid());

-- ── QUIZ_RESULTS ──
CREATE POLICY "Ver resultados propios" ON quiz_results
  FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "Crear resultado propio" ON quiz_results
  FOR INSERT WITH CHECK (student_id = auth.uid());

-- ── USER_PERMISSIONS ──
CREATE POLICY "Admin gestiona permisos" ON user_permissions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND rol = 'admin')
  );

CREATE POLICY "Usuario ve sus permisos" ON user_permissions
  FOR SELECT USING (user_id = auth.uid());

-- ── LESSON_PROGRESS ──
CREATE POLICY "Ver progreso propio" ON lesson_progress
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Actualizar progreso propio" ON lesson_progress
  FOR ALL USING (user_id = auth.uid());


-- ============================================================
-- 19. FUNCIÓN ÚTIL: obtener permisos efectivos de un usuario
-- ============================================================
CREATE OR REPLACE FUNCTION get_user_permissions(p_user_id UUID)
RETURNS TABLE(permission_key VARCHAR, is_granted BOOLEAN) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pp.key,
    COALESCE(up.is_granted, rp.is_granted, FALSE) AS is_granted
  FROM platform_permissions pp
  LEFT JOIN (
    SELECT permission_key, is_granted FROM user_permissions
    WHERE user_id = p_user_id
  ) up ON up.permission_key = pp.key
  LEFT JOIN (
    SELECT rp2.permission_key, rp2.is_granted
    FROM role_permissions rp2
    JOIN profiles pr ON pr.rol = rp2.role
    WHERE pr.id = p_user_id
  ) rp ON rp.permission_key = pp.key
  WHERE pp.is_active = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Uso: SELECT * FROM get_user_permissions('uuid-del-usuario');


-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
-- Tablas creadas:
--  1. categories
--  2. profiles
--  3. courses
--  4. course_enrollments
--  5. lessons
--  6. tasks
--  7. task_submissions
--  8. quizzes
--  9. questions
-- 10. quiz_results
-- 11. conversations
-- 12. messages
-- 13. platform_permissions (ya existía)
-- 14. role_permissions
-- 15. user_permissions
-- 16. lesson_progress
-- ============================================================
