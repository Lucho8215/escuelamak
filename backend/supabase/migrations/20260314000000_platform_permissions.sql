-- Tabla de permisos de la plataforma
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

-- Tabla de configuración de la escuela
CREATE TABLE IF NOT EXISTS school_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_name VARCHAR(255) DEFAULT 'Escuela MAK',
  school_description TEXT,
  school_logo_url TEXT,
  school_address TEXT,
  school_phone VARCHAR(50),
  school_email VARCHAR(255),
  primary_color VARCHAR(20) DEFAULT '#667eea',
  secondary_color VARCHAR(20) DEFAULT '#764ba2',
  accent_color VARCHAR(20) DEFAULT '#f093fb',
  background_color VARCHAR(20) DEFAULT '#f0f2ff',
  active_theme VARCHAR(50) DEFAULT 'default',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de métricas configurables
CREATE TABLE IF NOT EXISTS platform_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_key VARCHAR(100) UNIQUE NOT NULL,
  metric_name VARCHAR(255) NOT NULL,
  metric_value VARCHAR(255),
  metric_type VARCHAR(50) DEFAULT 'text',
  is_visible BOOLEAN DEFAULT true,
  display_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insertar permisos iniciales
INSERT INTO platform_permissions (key, name, description, category) VALUES
('view_courses', 'Ver Cursos', 'Acceso a la lista de cursos disponibles', 'Contenido'),
('manage_classes', 'Gestión de Clases', 'Crear, editar y eliminar clases', 'Gestión'),
('manage_quizzes', 'Gestión de Quizzes', 'Crear y gestionar evaluaciones', 'Evaluación'),
('take_quizzes', 'Tomar Quiz', 'Resolver evaluaciones y quizzes', 'Evaluación'),
('view_reports', 'Ver Informes', 'Ver reportes y estadísticas de alumnos', 'Informes'),
('manage_users', 'Gestión Usuarios', 'Administrar cuentas de usuarios', 'Administración'),
('manage_settings', 'Parámetros', 'Configurar parámetros del sistema', 'Administración'),
('view_lessons', 'Ver Lecciones', 'Ver y completar lecciones asignadas', 'Contenido'),
('view_review', 'Revisión Académica', 'Área de práctica y ejercicios', 'Contenido'),
('manage_courses', 'Gestión de Cursos', 'Crear y administrar cursos', 'Contenido'),
('upload_files', 'Subir Archivos', 'Subir archivos al sistema', 'Gestión')
ON CONFLICT (key) DO NOTHING;

-- Insertar configuración inicial de la escuela
INSERT INTO school_config (school_name, school_description) VALUES 
('Escuela MAK', 'Plataforma educativa moderna para el aprendizaje interactivo')
ON CONFLICT DO NOTHING;

-- Insertar métricas iniciales
INSERT INTO platform_metrics (metric_key, metric_name, metric_value, metric_type, is_visible, display_order) VALUES
('total_students', 'Total Estudiantes', '0', 'number', true, 1),
('total_teachers', 'Total Profesores', '0', 'number', true, 2),
('total_courses', 'Total Cursos', '0', 'number', true, 3),
('total_classes', 'Total Clases', '0', 'number', true, 4),
('total_quizzes', 'Total Quizzes', '0', 'number', true, 5),
('avg_score', 'Promedio General', '0%', 'percentage', true, 6),
('pass_rate', 'Tasa de Aprobación', '0%', 'percentage', true, 7)
ON CONFLICT (metric_key) DO NOTHING;

-- Habilitar RLS
ALTER TABLE platform_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_metrics ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para platform_permissions
CREATE POLICY "platform_permissions_all" ON platform_permissions FOR ALL USING (true) WITH CHECK (true);

-- Políticas RLS para school_config
CREATE POLICY "school_config_all" ON school_config FOR ALL USING (true) WITH CHECK (true);

-- Políticas RLS para platform_metrics
CREATE POLICY "platform_metrics_all" ON platform_metrics FOR ALL USING (true) WITH CHECK (true);
