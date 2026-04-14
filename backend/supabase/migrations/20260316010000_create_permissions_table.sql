-- Crear tabla de permisos de plataforma
CREATE TABLE IF NOT EXISTS platform_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100) NOT NULL,
  admin_enabled BOOLEAN DEFAULT true,
  teacher_enabled BOOLEAN DEFAULT true,
  tutor_enabled BOOLEAN DEFAULT true,
  student_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE platform_permissions ENABLE ROW LEVEL SECURITY;

-- Política RLS para platform_permissions (permite todo para todos)
DROP POLICY IF EXISTS "platform_permissions_all" ON platform_permissions;
CREATE POLICY "platform_permissions_all" ON platform_permissions FOR ALL USING (true) WITH CHECK (true);

-- Insertar módulos del menú principal
INSERT INTO platform_permissions (key, name, description, category, admin_enabled, teacher_enabled, tutor_enabled, student_enabled) VALUES
('menu_dashboard', 'Dashboard', 'Panel principal de control', 'Navegación', true, true, true, true),
('menu_courses', 'Cursos', 'Ver y acceder a cursos', 'Navegación', true, true, true, true),
('menu_review', 'Revisión', 'Revisión académica y ejercicios', 'Navegación', true, true, true, false),
('menu_user_management', 'Gestión de Usuarios', 'Administrar usuarios del sistema', 'Navegación', true, false, false, false),
('menu_course_management', 'Gestión de Cursos', 'Crear y administrar cursos', 'Navegación', true, true, false, false),
('menu_quiz_management', 'Gestión de Quizzes', 'Crear y gestionar evaluaciones', 'Navegación', true, true, true, false),
('menu_gradient_generator', 'Generador de Gradientes', 'Herramienta de generación de gradientes', 'Navegación', true, true, false, false),
('menu_parameters', 'Parámetros', 'Configuración del sistema', 'Navegación', true, false, false, false),
('menu_permissions', 'Permisos de Módulos', 'Gestionar permisos de acceso', 'Navegación', true, false, false, false)
ON CONFLICT (key) DO NOTHING;

-- Verificar que se insertaron
SELECT key, name, admin_enabled, teacher_enabled, tutor_enabled, student_enabled 
FROM platform_permissions 
WHERE key LIKE 'menu_%'
ORDER BY key;
