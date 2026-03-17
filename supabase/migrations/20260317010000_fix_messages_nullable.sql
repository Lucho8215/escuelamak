-- ═══════════════════════════════════════════════════════════════
-- Hace que conversation_id sea nullable en messages
-- para permitir mensajes sin conversación previa (desde la web)
-- ═══════════════════════════════════════════════════════════════

-- Hacer conversation_id nullable
ALTER TABLE messages
  ALTER COLUMN conversation_id DROP NOT NULL;

-- Desactivar RLS para que la web pueda insertar sin auth.uid()
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
