/*
  # Crear tablas para gestión de cursos

  1. Nuevas Tablas
    - `courses`
      - `id` (uuid, primary key)
      - `title` (text)
      - `description` (text)
      - `category` (text)
      - `is_visible` (boolean)
      - `video_url` (text)
      - `price` (numeric)
      - `duration` (integer)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

    - `classes`
      - `id` (uuid, primary key)
      - `course_id` (uuid, foreign key)
      - `name` (text)
      - `teacher_id` (uuid, foreign key)
      - `status` (text)
      - `class_number` (integer)
      - `enrollment_count` (integer)
      - `max_students` (integer)
      - `start_date` (timestamptz)
      - `end_date` (timestamptz)

    - `course_enrollments`
      - `id` (uuid, primary key)
      - `course_id` (uuid, foreign key)
      - `student_id` (uuid, foreign key)
      - `enrollment_date` (timestamptz)
      - `status` (text)

  2. Seguridad
    - Habilitar RLS en todas las tablas
    - Políticas para lectura y escritura basadas en roles
*/

-- Crear tabla de cursos
CREATE TABLE IF NOT EXISTS courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  category text NOT NULL CHECK (category IN ('education', 'mathematics')),
  is_visible boolean DEFAULT true,
  video_url text,
  price numeric NOT NULL DEFAULT 0 CHECK (price >= 0),
  duration integer NOT NULL DEFAULT 1 CHECK (duration > 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Crear tabla de clases
CREATE TABLE IF NOT EXISTS classes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  name text NOT NULL,
  teacher_id uuid REFERENCES app_users(id),
  status text NOT NULL CHECK (status IN ('open', 'closed')) DEFAULT 'open',
  class_number integer NOT NULL,
  enrollment_count integer DEFAULT 0,
  max_students integer NOT NULL CHECK (max_students > 0),
  start_date timestamptz NOT NULL,
  end_date timestamptz NOT NULL,
  CONSTRAINT valid_dates CHECK (end_date > start_date),
  CONSTRAINT valid_enrollment CHECK (enrollment_count <= max_students)
);

-- Crear tabla de inscripciones
CREATE TABLE IF NOT EXISTS course_enrollments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  student_id uuid REFERENCES app_users(id),
  enrollment_date timestamptz DEFAULT now(),
  status text NOT NULL CHECK (status IN ('active', 'completed', 'cancelled')) DEFAULT 'active',
  UNIQUE(course_id, student_id)
);

-- Habilitar RLS
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_enrollments ENABLE ROW LEVEL SECURITY;

-- Políticas para cursos
CREATE POLICY "Cursos visibles para todos"
  ON courses
  FOR SELECT
  USING (is_visible = true OR EXISTS (
    SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

CREATE POLICY "Administradores y profesores pueden gestionar cursos"
  ON courses
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

-- Políticas para clases
CREATE POLICY "Clases visibles para usuarios autenticados"
  ON classes
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Administradores y profesores pueden gestionar clases"
  ON classes
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

-- Políticas para inscripciones
CREATE POLICY "Estudiantes pueden ver sus inscripciones"
  ON course_enrollments
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid() OR EXISTS (
    SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

CREATE POLICY "Estudiantes pueden inscribirse"
  ON course_enrollments
  FOR INSERT
  TO authenticated
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Administradores pueden gestionar inscripciones"
  ON course_enrollments
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM app_users WHERE id = auth.uid() AND role = 'admin'
  ));

-- Índices
CREATE INDEX idx_courses_category ON courses(category);
CREATE INDEX idx_classes_course_id ON classes(course_id);
CREATE INDEX idx_classes_teacher_id ON classes(teacher_id);
CREATE INDEX idx_course_enrollments_course_id ON course_enrollments(course_id);
CREATE INDEX idx_course_enrollments_student_id ON course_enrollments(student_id);