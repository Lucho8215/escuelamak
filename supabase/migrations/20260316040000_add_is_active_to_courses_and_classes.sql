-- ═══════════════════════════════════════════════════════════════
-- Agrega columna is_active a courses y classes
-- ═══════════════════════════════════════════════════════════════
-- Por qué: La edge function mobile-api filtra por is_active = true
-- en ambas tablas, pero la columna no existía, por lo que
-- ningún curso ni clase aparecía en la app móvil.
--
-- is_active en courses: indica si el curso está publicado/disponible.
--   Se inicializa desde is_visible para mantener el estado actual.
-- is_active en classes: indica si la clase está habilitada.
--   Todas las clases existentes se marcan como activas.
-- ═══════════════════════════════════════════════════════════════

-- 1. Agregar is_active a la tabla courses
ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;

-- Sincronizar con el valor actual de is_visible
UPDATE courses
  SET is_active = is_visible
  WHERE true;

-- 2. Agregar is_active a la tabla classes
ALTER TABLE classes
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;

-- Todas las clases existentes quedan activas
UPDATE classes
  SET is_active = true
  WHERE true;

-- 3. Índices para mejorar rendimiento en los filtros más comunes
CREATE INDEX IF NOT EXISTS idx_courses_is_active
  ON courses(is_active);

CREATE INDEX IF NOT EXISTS idx_classes_is_active
  ON classes(is_active);

-- Índice compuesto para la consulta más frecuente: clases activas de un curso
CREATE INDEX IF NOT EXISTS idx_classes_course_is_active
  ON classes(course_id, is_active);
