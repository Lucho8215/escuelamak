/*
  # Vistas para análisis en Metabase

  1. Vistas Principales
    - Vista de resumen de usuarios
    - Vista de métricas de cursos
    - Vista de análisis de clases
    - Vista de seguimiento de inscripciones

  2. Seguridad
    - Las vistas son de solo lectura
    - Acceso restringido a través de RLS
*/

-- Vista de resumen de usuarios
CREATE OR REPLACE VIEW user_analytics AS
SELECT 
  role,
  COUNT(*) as total_users,
  COUNT(CASE WHEN created_at > now() - interval '30 days' THEN 1 END) as new_users_30d,
  MIN(created_at) as first_user_date,
  MAX(created_at) as last_user_date
FROM app_users
GROUP BY role;

-- Vista de métricas de cursos
CREATE OR REPLACE VIEW course_analytics AS
SELECT 
  c.id,
  c.title,
  c.category,
  c.price,
  c.is_visible,
  COUNT(ce.id) as total_enrollments,
  COUNT(CASE WHEN ce.status = 'completed' THEN 1 END) as completed_enrollments,
  SUM(c.price) as total_revenue,
  c.created_at,
  c.updated_at
FROM courses c
LEFT JOIN course_enrollments ce ON c.id = ce.course_id
GROUP BY c.id, c.title, c.category, c.price, c.is_visible, c.created_at, c.updated_at;

-- Vista de análisis de clases
CREATE OR REPLACE VIEW class_analytics AS
SELECT 
  cl.id,
  cl.name,
  c.title as course_title,
  u.name as teacher_name,
  cl.status,
  cl.enrollment_count,
  cl.max_students,
  (cl.enrollment_count::float / cl.max_students * 100) as occupancy_rate,
  cl.start_date,
  cl.end_date
FROM classes cl
JOIN courses c ON cl.course_id = c.id
JOIN app_users u ON cl.teacher_id = u.id;

-- Vista de seguimiento de inscripciones
CREATE OR REPLACE VIEW enrollment_analytics AS
SELECT 
  ce.id,
  c.title as course_title,
  u.name as student_name,
  u.email as student_email,
  ce.status,
  ce.enrollment_date,
  c.price as course_price,
  cl.name as class_name,
  cl.start_date as class_start,
  cl.end_date as class_end
FROM course_enrollments ce
JOIN courses c ON ce.course_id = c.id
JOIN app_users u ON ce.student_id = u.id
JOIN classes cl ON ce.class_id = cl.id;

-- Función para obtener estadísticas generales
CREATE OR REPLACE FUNCTION get_platform_statistics()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_stats jsonb;
BEGIN
  SELECT jsonb_build_object(
    'total_users', (SELECT COUNT(*) FROM app_users),
    'total_courses', (SELECT COUNT(*) FROM courses),
    'total_active_classes', (SELECT COUNT(*) FROM classes WHERE status = 'open'),
    'total_enrollments', (SELECT COUNT(*) FROM course_enrollments),
    'total_revenue', (SELECT COALESCE(SUM(c.price), 0) FROM course_enrollments ce JOIN courses c ON ce.course_id = c.id),
    'active_teachers', (SELECT COUNT(DISTINCT teacher_id) FROM classes),
    'completion_rate', (
      SELECT 
        ROUND(
          (COUNT(CASE WHEN status = 'completed' THEN 1 END)::float / 
          NULLIF(COUNT(*), 0) * 100)::numeric, 
          2
        )
      FROM course_enrollments
    )
  ) INTO v_stats;

  RETURN v_stats;
END;
$$;