-- ═══════════════════════════════════════════════════════════════
-- Tabla de mensajes entre estudiantes y profesores/admin
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS messages (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id    UUID        NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  recipient_id UUID        REFERENCES app_users(id) ON DELETE SET NULL,
  content      TEXT        NOT NULL,
  course_id    UUID        REFERENCES courses(id) ON DELETE SET NULL,
  class_id     UUID        REFERENCES classes(id) ON DELETE SET NULL,
  is_read      BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Estudiantes: pueden ver sus propios mensajes (enviados o recibidos)
CREATE POLICY "messages_student_select"
  ON messages FOR SELECT
  TO authenticated
  USING (
    sender_id = auth.uid()
    OR recipient_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'tutor')
    )
  );

-- Cualquier usuario autenticado puede insertar (enviar) mensajes
CREATE POLICY "messages_insert"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (sender_id = auth.uid());

-- Admin/teacher/tutor pueden actualizar (marcar como leído) cualquier mensaje
-- Estudiantes solo pueden actualizar mensajes dirigidos a ellos
CREATE POLICY "messages_update"
  ON messages FOR UPDATE
  TO authenticated
  USING (
    recipient_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid() AND role IN ('admin', 'teacher', 'tutor')
    )
  );

CREATE INDEX IF NOT EXISTS idx_messages_sender    ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_messages_course    ON messages(course_id);
CREATE INDEX IF NOT EXISTS idx_messages_created   ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_unread    ON messages(is_read) WHERE is_read = FALSE;
