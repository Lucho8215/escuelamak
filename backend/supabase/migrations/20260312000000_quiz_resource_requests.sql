/*
  # Sistema de Solicitudes de Recursos para Quiz
  
  Esta tabla permite a los estudiantes solicitar recursos o materiales
  relacionados con los cuestionarios que están realizando.
  
  Tabla creada:
    - quiz_resource_requests: Solicitudes de recursos de estudiantes
    
  Estados de solicitud:
    - pending: Pendiente de revisión
    - approved: Aprobada (recurso enviado)
    - rejected: Rechazada
    - completed: Completada (estudiante recibió el recurso)
*/

-- Tabla de solicitudes de recursos
CREATE TABLE IF NOT EXISTS quiz_resource_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  question_id UUID REFERENCES questions(id) ON DELETE SET NULL,
  request_type TEXT NOT NULL CHECK (request_type IN (
    'explanation',      -- Solicita explicación adicional
    'material',         -- Solicita material de estudio
    'clarification',    -- Solicita aclarar pregunta
    'technical',        -- Problema técnico con el quiz
    'other'             -- Otro tipo de solicitud
  )),
  description TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
  response TEXT,
  responded_by TEXT,
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE quiz_resource_requests ENABLE ROW LEVEL SECURITY;

-- Políticas para solicitudes de recursos
-- Estudiantes pueden ver sus propias solicitudes
CREATE POLICY "allow_students_view_own_requests"
  ON quiz_resource_requests
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Estudiantes pueden crear solicitudes
CREATE POLICY "allow_students_create_requests"
  ON quiz_resource_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (student_id = auth.uid());

-- Estudiantes pueden actualizar sus propias solicitudes (solo estado)
CREATE POLICY "allow_students_update_own_requests"
  ON quiz_resource_requests
  FOR UPDATE
  TO authenticated
  USING (student_id = auth.uid());

-- Profesores/Admin pueden ver todas las solicitudes
CREATE POLICY "allow_teachers_view_all_requests"
  ON quiz_resource_requests
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher', 'tutor')
    )
  );

-- Profesores/Admin pueden responder solicitudes
CREATE POLICY "allow_teachers_respond_requests"
  ON quiz_resource_requests
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid()
      AND role IN ('admin', 'teacher', 'tutor')
    )
  );

-- Índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_resource_requests_quiz_id ON quiz_resource_requests(quiz_id);
CREATE INDEX IF NOT EXISTS idx_resource_requests_student_id ON quiz_resource_requests(student_id);
CREATE INDEX IF NOT EXISTS idx_resource_requests_status ON quiz_resource_requests(status);
