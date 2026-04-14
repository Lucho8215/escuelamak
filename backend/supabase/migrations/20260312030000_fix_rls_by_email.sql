/*
  # Fix RLS para quiz_assignments - Usar email para verificación
  
  Esta migración modifica las políticas RLS para verificar contra el email
  del usuario autenticado, ya que es el campo que se mantiene consistente
  entre Supabase Auth y app_users.
*/

-- 1. Eliminar políticas existentes de quiz_assignments
DROP POLICY IF EXISTS "allow_teachers_create_assignments" ON quiz_assignments;
DROP POLICY IF EXISTS "allow_teachers_delete_assignments" ON quiz_assignments;
DROP POLICY IF EXISTS "allow_teachers_view_all_assignments" ON quiz_assignments;

-- 2. Recrear políticas usando auth.email() para verificar
CREATE POLICY "allow_teachers_view_all_assignments"
  ON quiz_assignments
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE email = auth.jwt()->>'email'
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
      WHERE email = auth.jwt()->>'email'
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
      WHERE email = auth.jwt()->>'email'
      AND role IN ('admin', 'teacher', 'tutor')
    )
  );

-- 3. Actualizar políticas de quizzes
DROP POLICY IF EXISTS "allow_teacher_admin_manage_quizzes" ON quizzes;

CREATE POLICY "allow_teacher_admin_manage_quizzes"
  ON quizzes
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE email = auth.jwt()->>'email'
      AND role IN ('admin', 'teacher')
    )
  );

-- 4. Actualizar políticas de questions
DROP POLICY IF EXISTS "allow_teacher_admin_manage_questions" ON questions;

CREATE POLICY "allow_teacher_admin_manage_questions"
  ON questions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE email = auth.jwt()->>'email'
      AND role IN ('admin', 'teacher')
    )
  );

-- 5. Actualizar políticas de quiz_attempts
DROP POLICY IF EXISTS "allow_teachers_view_all_attempts" ON quiz_attempts;

CREATE POLICY "allow_teachers_view_all_attempts"
  ON quiz_attempts
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE email = auth.jwt()->>'email'
      AND role IN ('admin', 'teacher', 'tutor')
    )
  );

-- 6. Actualizar política de app_users
DROP POLICY IF EXISTS "Usuarios pueden ver su propia información" ON app_users;

CREATE POLICY "Usuarios pueden ver su propia información"
  ON app_users
  FOR SELECT
  TO authenticated
  USING (email = auth.jwt()->>'email');
