-- Agregar módulos del menú principal a platform_permissions
-- Esta tabla ya existe, solo agregamos los módulos del menú
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
