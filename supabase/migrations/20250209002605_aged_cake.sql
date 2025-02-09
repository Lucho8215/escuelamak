/*
  # Ajustes en las tablas de cursos

  1. Cambios
    - Ajuste de tipos de datos para fechas
    - Mejora en las restricciones de las tablas
    - Actualización de políticas RLS
    
  2. Seguridad
    - Políticas RLS actualizadas para mejor control de acceso
    - Índices optimizados
*/

-- Eliminar tablas existentes si existen
DROP TABLE IF EXISTS course_enrollments;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS courses;

-- Crear tabla de cursos
CREATE TABLE courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  category text NOT NULL,
  is_visible boolean DEFAULT true,
  video_url text,
  price numeric(10,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  duration integer NOT NULL DEFAULT 1 CHECK (duration > 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT valid_category CHECK (category IN ('education', 'mathematics'))
);

-- Crear tabla de clases
CREATE TABLE classes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  name text NOT NULL,
  teacher_id uuid REFERENCES app_users(id),
  status text NOT NULL DEFAULT 'open',
  class_number integer NOT NULL,
  enrollment_count integer DEFAULT 0,
  max_students integer NOT NULL,
  start_date timestamptz NOT NULL,
  end_date timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT valid_status CHECK (status IN ('open', 'closed')),
  CONSTRAINT valid_dates CHECK (end_date > start_date),
  CONSTRAINT valid_enrollment CHECK (enrollment_count <= max_students),
  CONSTRAINT valid_students CHECK (max_students > 0)
);

-- Crear tabla de inscripciones
CREATE TABLE course_enrollments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  student_id uuid REFERENCES app_users(id),
  class_id uuid REFERENCES classes(id) ON DELETE CASCADE,
  enrollment_date timestamptz DEFAULT now(),
  status text NOT NULL DEFAULT 'active',
  CONSTRAINT valid_status CHECK (status IN ('active', 'completed', 'cancelled')),
  CONSTRAINT unique_enrollment UNIQUE(course_id, student_id, class_id)
);

-- Habilitar RLS
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_enrollments ENABLE ROW LEVEL SECURITY;

-- Políticas para cursos
CREATE POLICY "Cursos visibles para todos"
  ON courses
  FOR SELECT
  TO PUBLIC
  USING (is_visible = true OR EXISTS (
    SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

CREATE POLICY "Administradores y profesores pueden gestionar cursos"
  ON courses
  FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

-- Políticas para clases
CREATE POLICY "Ver clases"
  ON classes
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Gestionar clases"
  ON classes
  FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

-- Políticas para inscripciones
CREATE POLICY "Ver inscripciones"
  ON course_enrollments
  FOR SELECT
  TO authenticated
  USING (
    student_id = auth.uid() 
    OR EXISTS (
      SELECT 1 FROM app_users 
      WHERE id = auth.uid() AND role IN ('admin', 'teacher')
    )
  );

CREATE POLICY "Crear inscripciones"
  ON course_enrollments
  FOR INSERT
  TO authenticated
  WITH CHECK (
    student_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM app_users 
      WHERE id = auth.uid() AND role IN ('admin', 'teacher')
    )
  );

CREATE POLICY "Gestionar inscripciones"
  ON course_enrollments
  FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM app_users 
    WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  ));

-- Funciones
CREATE OR REPLACE FUNCTION update_enrollment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE classes 
    SET enrollment_count = enrollment_count + 1
    WHERE id = NEW.class_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE classes 
    SET enrollment_count = enrollment_count - 1
    WHERE id = OLD.class_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER update_class_enrollment_count
AFTER INSERT OR DELETE ON course_enrollments
FOR EACH ROW
EXECUTE FUNCTION update_enrollment_count();

-- Índices
CREATE INDEX idx_courses_category ON courses(category);
CREATE INDEX idx_courses_visibility ON courses(is_visible);
CREATE INDEX idx_classes_course_id ON classes(course_id);
CREATE INDEX idx_classes_teacher_id ON classes(teacher_id);
CREATE INDEX idx_classes_dates ON classes(start_date, end_date);
CREATE INDEX idx_enrollments_course ON course_enrollments(course_id);
CREATE INDEX idx_enrollments_student ON course_enrollments(student_id);
CREATE INDEX idx_enrollments_class ON course_enrollments(class_id);