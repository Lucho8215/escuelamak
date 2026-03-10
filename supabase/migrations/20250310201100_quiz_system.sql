/*
  # Quiz System - Tablas para gestión de cuestionarios
  
  1. Tablas creadas:
    - quizzes: Almacena los cuestionarios
    - questions: Preguntas de cada cuestionario
    - quiz_attempts: Intentos de estudiantes
    - quiz_assignments: Asignaciones de quizzes a estudiantes
  
  2. Seguridad:
    - Habilitar RLS en todas las tablas
    - Políticas para admin, profesores, tutores y estudiantes
*/

-- Tabla de cuestionarios
CREATE TABLE IF NOT EXISTS quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'general',
  difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  time_limit INTEGER DEFAULT 10,
  passing_score INTEGER DEFAULT 60,
  is_enabled BOOLEAN DEFAULT true,
  is_visible BOOLEAN DEFAULT true,
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de preguntas
CREATE TABLE IF NOT EXISTS questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  options JSONB NOT NULL DEFAULT '[]',
  correct_answer INTEGER NOT NULL,
  explanation TEXT,
  points INTEGER DEFAULT 10,
  order_number INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de intentos de estudiantes
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  score INTEGER DEFAULT 0,
  passed BOOLEAN DEFAULT false,
  answers JSONB DEFAULT '[]',
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  time_spent_seconds INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de asignaciones de quizzes a estudiantes
CREATE TABLE IF NOT EXISTS quiz_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  assigned_by TEXT,
  due_date TIMESTAMPTZ,
  is_completed BOOLEAN DEFAULT false,
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  UNIQUE(quiz_id, student_id)
);

-- Habilitar RLS
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_assignments ENABLE ROW LEVEL SECURITY;

-- Políticas para quizzes
CREATE POLICY "allow_public_view_enabled_quizzes"
  ON quizzes
  FOR SELECT
  TO PUBLIC
  USING (is_enabled = true AND is_visible = true);

CREATE POLICY "allow_teacher_admin_manage_quizzes"
  ON quizzes
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher')
    )
  );

-- Políticas para preguntas
CREATE POLICY "allow_public_view_questions"
  ON questions
  FOR SELECT
  TO PUBLIC
  USING (
    EXISTS (
      SELECT 1 FROM quizzes
      WHERE id = quiz_id
      AND is_enabled = true
    )
  );

CREATE POLICY "allow_teacher_admin_manage_questions"
  ON questions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher')
    )
  );

-- Políticas para intentos de quiz
CREATE POLICY "allow_students_view_own_attempts"
  ON quiz_attempts
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

CREATE POLICY "allow_teachers_view_all_attempts"
  ON quiz_attempts
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher', 'tutor')
    )
  );

CREATE POLICY "allow_students_create_attempts"
  ON quiz_attempts
  FOR INSERT
  TO authenticated
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "allow_students_update_own_attempts"
  ON quiz_attempts
  FOR UPDATE
  TO authenticated
  USING (student_id = auth.uid());

-- Políticas para asignaciones de quizzes
CREATE POLICY "allow_students_view_own_assignments"
  ON quiz_assignments
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

CREATE POLICY "allow_teachers_view_all_assignments"
  ON quiz_assignments
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher', 'tutor')
    )
  );

CREATE POLICY "allow_teachers_create_assignments"
  ON quiz_assignments
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher', 'tutor')
    )
  );

CREATE POLICY "allow_teachers_delete_assignments"
  ON quiz_assignments
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher', 'tutor')
    )
  );

-- Índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_questions_quiz_id ON questions(quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_quiz_id ON quiz_attempts(quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_student_id ON quiz_attempts(student_id);
CREATE INDEX IF NOT EXISTS idx_quiz_assignments_quiz_id ON quiz_assignments(quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_assignments_student_id ON quiz_assignments(student_id);
