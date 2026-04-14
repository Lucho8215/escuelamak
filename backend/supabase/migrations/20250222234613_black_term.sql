/*
  # Update RLS policies for courses and related tables

  1. Changes
    - Drop existing policies
    - Create new policies for courses table
    - Create new policies for classes table
    - Create new policies for course_enrollments table
    
  2. Security
    - Enable RLS on all tables
    - Add policies for public and authenticated access
    - Add specific policies for teachers and admins
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Cursos visibles para todos" ON courses;
DROP POLICY IF EXISTS "Administradores y profesores pueden gestionar cursos" ON courses;
DROP POLICY IF EXISTS "Ver clases" ON classes;
DROP POLICY IF EXISTS "Gestionar clases" ON classes;
DROP POLICY IF EXISTS "Ver inscripciones" ON course_enrollments;
DROP POLICY IF EXISTS "Crear inscripciones" ON course_enrollments;
DROP POLICY IF EXISTS "Gestionar inscripciones" ON course_enrollments;

-- Policies for courses
CREATE POLICY "allow_public_view_visible_courses"
  ON courses
  FOR SELECT
  TO PUBLIC
  USING (is_visible = true);

CREATE POLICY "allow_teacher_admin_select"
  ON courses
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher')
    )
  );

CREATE POLICY "allow_teacher_admin_insert"
  ON courses
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher')
    )
  );

CREATE POLICY "allow_teacher_admin_update"
  ON courses
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher')
    )
  );

CREATE POLICY "allow_teacher_admin_delete"
  ON courses
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher')
    )
  );

-- Policies for classes
CREATE POLICY "allow_public_view_classes"
  ON classes
  FOR SELECT
  TO PUBLIC
  USING (
    EXISTS (
      SELECT 1 FROM courses
      WHERE courses.id = course_id
      AND courses.is_visible = true
    )
  );

CREATE POLICY "allow_teacher_admin_manage_classes"
  ON classes
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher')
    )
  );

-- Policies for course_enrollments
CREATE POLICY "allow_view_own_enrollments"
  ON course_enrollments
  FOR SELECT
  TO authenticated
  USING (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher')
    )
  );

CREATE POLICY "allow_create_own_enrollment"
  ON course_enrollments
  FOR INSERT
  TO authenticated
  WITH CHECK (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher')
    )
  );

CREATE POLICY "allow_teacher_admin_manage_enrollments"
  ON course_enrollments
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher')
    )
  );

-- Ensure RLS is enabled
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_enrollments ENABLE ROW LEVEL SECURITY;