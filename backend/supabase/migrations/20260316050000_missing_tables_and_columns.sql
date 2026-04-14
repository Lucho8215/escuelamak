-- ═══════════════════════════════════════════════════════════════
-- Tablas y columnas faltantes para la app móvil (mobile-api)
-- ═══════════════════════════════════════════════════════════════
-- Discrepancias detectadas entre la edge function mobile-api y
-- el esquema real de la base de datos:
--
--  TABLAS FALTANTES:
--    · lessons                    (contenidos de un curso)
--    · class_enrollments          (inscripciones en clases)
--    · student_lesson_assignments (progreso de estudiantes en lecciones)
--
--  COLUMNAS FALTANTES:
--    · app_users.cedula
--    · classes.enrolled_students  (alias generado de enrollment_count)
--    · quiz_attempts.status
-- ═══════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────
-- 1. TABLA: lessons
--    Contenidos/lecciones dentro de un curso.
--    La edge function las consulta con: course_id, is_published,
--    order_index, title, summary, estimated_minutes.
-- ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lessons (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id         uuid        NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title             text        NOT NULL,
  summary           text,
  content           text,
  video_url         text,
  resource_url      text,
  estimated_minutes integer     NOT NULL DEFAULT 0,
  order_index       integer     NOT NULL DEFAULT 0,
  is_published      boolean     NOT NULL DEFAULT true,
  created_by        uuid        REFERENCES app_users(id),
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now()
);

ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lessons_public_read"
  ON lessons FOR SELECT
  USING (
    is_published = true
    AND EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_id AND courses.is_active = true
    )
  );

CREATE POLICY "lessons_admin_teacher_all"
  ON lessons FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid() AND role IN ('admin', 'teacher')
    )
  );

CREATE INDEX IF NOT EXISTS idx_lessons_course_id      ON lessons(course_id);
CREATE INDEX IF NOT EXISTS idx_lessons_published_order ON lessons(course_id, is_published, order_index);


-- ───────────────────────────────────────────────────────────────
-- 2. TABLA: class_enrollments
--    Inscripciones de estudiantes en clases específicas.
--    La edge function necesita: student_id, class_id, course_id,
--    status, enrollment_date.
-- ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS class_enrollments (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      uuid        NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  class_id        uuid        NOT NULL REFERENCES classes(id)   ON DELETE CASCADE,
  course_id       uuid        REFERENCES courses(id)            ON DELETE SET NULL,
  status          text        NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active', 'completed', 'cancelled')),
  enrollment_date timestamptz DEFAULT now(),
  UNIQUE (student_id, class_id)
);

ALTER TABLE class_enrollments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "class_enrollments_own_select"
  ON class_enrollments FOR SELECT
  TO authenticated
  USING (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid() AND role IN ('admin', 'teacher')
    )
  );

CREATE POLICY "class_enrollments_insert"
  ON class_enrollments FOR INSERT
  TO authenticated
  WITH CHECK (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid() AND role IN ('admin', 'teacher')
    )
  );

CREATE POLICY "class_enrollments_admin_teacher_all"
  ON class_enrollments FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid() AND role IN ('admin', 'teacher')
    )
  );

CREATE INDEX IF NOT EXISTS idx_class_enrollments_student ON class_enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_class_enrollments_class   ON class_enrollments(class_id);
CREATE INDEX IF NOT EXISTS idx_class_enrollments_course  ON class_enrollments(course_id);


-- ───────────────────────────────────────────────────────────────
-- 3. TABLA: student_lesson_assignments
--    Seguimiento de progreso por estudiante en cada lección.
--    La edge function hace upsert con conflict en (student_id, lesson_id).
-- ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS student_lesson_assignments (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id    uuid        NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  -- lesson_id almacena tanto IDs de lessons como de classes (uso polimórfico).
  -- No se define FK estricta para permitir ambos casos.
  lesson_id     uuid        NOT NULL,
  status        text        NOT NULL DEFAULT 'assigned'
                  CHECK (status IN ('assigned', 'in_progress', 'completed', 'paused')),
  progress_pct  integer     NOT NULL DEFAULT 0 CHECK (progress_pct BETWEEN 0 AND 100),
  completed     boolean     NOT NULL DEFAULT false,
  last_position integer     NOT NULL DEFAULT 0,
  assigned_at   timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now(),
  completed_at  timestamptz,
  UNIQUE (student_id, lesson_id)
);

ALTER TABLE student_lesson_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sla_own_select"
  ON student_lesson_assignments FOR SELECT
  TO authenticated
  USING (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid() AND role IN ('admin', 'teacher')
    )
  );

CREATE POLICY "sla_own_insert_update"
  ON student_lesson_assignments FOR ALL
  TO authenticated
  USING (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid() AND role IN ('admin', 'teacher')
    )
  );

CREATE INDEX IF NOT EXISTS idx_sla_student ON student_lesson_assignments(student_id);
CREATE INDEX IF NOT EXISTS idx_sla_lesson  ON student_lesson_assignments(lesson_id);
CREATE INDEX IF NOT EXISTS idx_sla_completed ON student_lesson_assignments(student_id, completed);


-- ───────────────────────────────────────────────────────────────
-- 4. COLUMNA: app_users.cedula
--    Número de documento del usuario (cédula de identidad).
-- ───────────────────────────────────────────────────────────────
ALTER TABLE app_users
  ADD COLUMN IF NOT EXISTS cedula text;


-- ───────────────────────────────────────────────────────────────
-- 5. COLUMNA: classes.enrolled_students
--    La edge function selecciona "enrolled_students" al verificar
--    capacidad de una clase. Se implementa como columna generada
--    (siempre sincronizada con enrollment_count) para no duplicar
--    datos.
-- ───────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'classes' AND column_name = 'enrolled_students'
  ) THEN
    ALTER TABLE classes
      ADD COLUMN enrolled_students integer GENERATED ALWAYS AS (enrollment_count) STORED;
  END IF;
END $$;


-- ───────────────────────────────────────────────────────────────
-- 6. COLUMNA: quiz_attempts.status
--    La edge function filtra intentos por status = 'completed'.
-- ───────────────────────────────────────────────────────────────
ALTER TABLE quiz_attempts
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'completed'
    CHECK (status IN ('in_progress', 'completed', 'abandoned'));

-- Marcar todos los intentos existentes como completados
UPDATE quiz_attempts
  SET status = 'completed'
  WHERE status IS NULL OR status = 'completed';
