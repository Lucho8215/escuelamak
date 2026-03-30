-- ═══════════════════════════════════════════════════════════════
-- Tablas para el sistema de roles personalizados y permisos granulares
-- ═══════════════════════════════════════════════════════════════

-- Tabla de roles personalizados
CREATE TABLE IF NOT EXISTS custom_roles (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  code text UNIQUE NOT NULL,
  description text DEFAULT '',
  color text DEFAULT '#667eea',
  icon text DEFAULT 'fas fa-user',
  is_default boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabla de permisos por módulo para cada rol
CREATE TABLE IF NOT EXISTS role_module_permissions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  role_code text NOT NULL REFERENCES custom_roles(code) ON DELETE CASCADE,
  module_key text NOT NULL,
  can_view boolean DEFAULT false,
  can_create boolean DEFAULT false,
  can_edit boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(role_code, module_key)
);

-- Habilitar RLS
ALTER TABLE custom_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_module_permissions ENABLE ROW LEVEL SECURITY;

-- Políticas permisivas para usuarios autenticados
CREATE POLICY "allow_all_custom_roles" ON custom_roles FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_role_permissions" ON role_module_permissions FOR ALL USING (true) WITH CHECK (true);

-- Índices para búsqueda rápida
CREATE INDEX IF NOT EXISTS idx_role_module_permissions_role_code ON role_module_permissions(role_code);
CREATE INDEX IF NOT EXISTS idx_role_module_permissions_module_key ON role_module_permissions(module_key);

-- ─── Roles por defecto del sistema ───────────────────────────────────────────
INSERT INTO custom_roles (name, code, description, color, icon, is_default) VALUES
  ('Administrador', 'admin',    'Acceso completo a todos los módulos del sistema', '#667eea', 'fas fa-crown',               true),
  ('Profesor',      'teacher',  'Puede gestionar cursos, clases y evaluaciones',   '#f7971e', 'fas fa-chalkboard-teacher',  true),
  ('Tutor',         'tutor',    'Puede ver informes y progreso de estudiantes',    '#11998e', 'fas fa-user-friends',        true),
  ('Estudiante',    'student',  'Puede ver contenido y realizar evaluaciones',     '#56ab2f', 'fas fa-user-graduate',       true)
ON CONFLICT (code) DO NOTHING;

-- ─── Permisos por defecto del rol Administrador ───────────────────────────────
INSERT INTO role_module_permissions (role_code, module_key, can_view, can_create, can_edit) VALUES
  ('admin', 'courses',  true, true, true),
  ('admin', 'lessons',  true, true, true),
  ('admin', 'classes',  true, true, true),
  ('admin', 'quizzes',  true, true, true),
  ('admin', 'take_quiz',true, false,false),
  ('admin', 'practice', true, false,false),
  ('admin', 'users',    true, true, true),
  ('admin', 'roles',    true, true, true),
  ('admin', 'settings', true, true, true),
  ('admin', 'reports',  true, false,false),
  ('admin', 'school',   true, true, true),
  ('admin', 'metrics',  true, true, true)
ON CONFLICT (role_code, module_key) DO NOTHING;

-- ─── Permisos por defecto del rol Profesor ───────────────────────────────────
INSERT INTO role_module_permissions (role_code, module_key, can_view, can_create, can_edit) VALUES
  ('teacher', 'courses',  true, true, true),
  ('teacher', 'lessons',  true, true, true),
  ('teacher', 'classes',  true, true, true),
  ('teacher', 'quizzes',  true, true, true),
  ('teacher', 'take_quiz',true, false,false),
  ('teacher', 'practice', true, false,false),
  ('teacher', 'users',    false,false,false),
  ('teacher', 'roles',    false,false,false),
  ('teacher', 'settings', false,false,false),
  ('teacher', 'reports',  false,false,false),
  ('teacher', 'school',   false,false,false),
  ('teacher', 'metrics',  false,false,false)
ON CONFLICT (role_code, module_key) DO NOTHING;

-- ─── Permisos por defecto del rol Tutor ──────────────────────────────────────
INSERT INTO role_module_permissions (role_code, module_key, can_view, can_create, can_edit) VALUES
  ('tutor', 'courses',  true, false,false),
  ('tutor', 'lessons',  true, false,false),
  ('tutor', 'classes',  true, false,false),
  ('tutor', 'quizzes',  false,false,false),
  ('tutor', 'take_quiz',true, false,false),
  ('tutor', 'practice', true, false,false),
  ('tutor', 'users',    false,false,false),
  ('tutor', 'roles',    false,false,false),
  ('tutor', 'settings', false,false,false),
  ('tutor', 'reports',  true, false,false),
  ('tutor', 'school',   false,false,false),
  ('tutor', 'metrics',  false,false,false)
ON CONFLICT (role_code, module_key) DO NOTHING;

-- ─── Permisos por defecto del rol Estudiante ─────────────────────────────────
INSERT INTO role_module_permissions (role_code, module_key, can_view, can_create, can_edit) VALUES
  ('student', 'courses',  true, false,false),
  ('student', 'lessons',  true, false,false),
  ('student', 'classes',  false,false,false),
  ('student', 'quizzes',  false,false,false),
  ('student', 'take_quiz',true, false,false),
  ('student', 'practice', true, false,false),
  ('student', 'users',    false,false,false),
  ('student', 'roles',    false,false,false),
  ('student', 'settings', false,false,false),
  ('student', 'reports',  false,false,false),
  ('student', 'school',   false,false,false),
  ('student', 'metrics',  false,false,false)
ON CONFLICT (role_code, module_key) DO NOTHING;
