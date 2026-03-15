--确保 platform_permissions 表中的菜单模块数据存在且正确
-- Primero verificamos si existen los módulos del menú
-- Si no existen, los insertamos

INSERT INTO platform_permissions (key, name, description, category, admin_enabled, teacher_enabled, tutor_enabled, student_enabled) 
VALUES 
('menu_dashboard', 'Dashboard', 'Panel principal de control', 'Navegación', true, true, true, true),
('menu_courses', 'Cursos', 'Ver y acceder a cursos', 'Navegación', true, true, true, true),
('menu_review', 'Revisión', 'Revisión académica y ejercicios', 'Navegación', true, true, true, false),
('menu_user_management', 'Gestión de Usuarios', 'Administrar usuarios del sistema', 'Navegación', true, false, false, false),
('menu_course_management', 'Gestión de Cursos', 'Crear y administrar cursos', 'Navegación', true, true, false, false),
('menu_quiz_management', 'Gestión de Quizzes', 'Crear y gestionar evaluaciones', 'Navegación', true, true, true, false),
('menu_gradient_generator', 'Generador de Gradientes', 'Herramienta de generación de gradientes', 'Navegación', true, true, false, false),
('menu_parameters', 'Parámetros', 'Configuración del sistema', 'Navegación', true, false, false, false),
('menu_permissions', 'Permisos de Módulos', 'Gestionar permisos de acceso', 'Navegación', true, false, false, false)
ON CONFLICT (key) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  category = EXCLUDED.category,
  admin_enabled = EXCLUDED.admin_enabled,
  teacher_enabled = EXCLUDED.teacher_enabled,
  tutor_enabled = EXCLUDED.tutor_enabled,
  student_enabled = EXCLUDED.student_enabled,
  updated_at = NOW();

-- Verificar que los datos se insertaron correctamente
SELECT key, name, admin_enabled, teacher_enabled, tutor_enabled, student_enabled 
FROM platform_permissions 
WHERE key LIKE 'menu_%'
ORDER BY key;
