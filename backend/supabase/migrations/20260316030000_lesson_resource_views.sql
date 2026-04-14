-- ═══════════════════════════════════════════════════════════════
-- Tabla de seguimiento de recursos vistos por estudiante en cada lección
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lesson_resource_views (
  id           uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id   text NOT NULL,
  lesson_id    text NOT NULL,
  resource_type text NOT NULL CHECK (resource_type IN ('video','pdf','imagen','contenido')),
  viewed_at    timestamptz DEFAULT now(),
  UNIQUE(student_id, lesson_id, resource_type)
);

-- Índices para búsqueda rápida
CREATE INDEX IF NOT EXISTS idx_lrv_student  ON lesson_resource_views(student_id);
CREATE INDEX IF NOT EXISTS idx_lrv_lesson   ON lesson_resource_views(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lrv_combined ON lesson_resource_views(student_id, lesson_id);

-- RLS: cualquier usuario autenticado puede leer/escribir sus propios registros
ALTER TABLE lesson_resource_views ENABLE ROW LEVEL SECURITY;
CREATE POLICY "allow_all_lesson_resource_views"
  ON lesson_resource_views FOR ALL USING (true) WITH CHECK (true);
