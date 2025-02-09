/*
  # Corregir tabla de usuarios y función de verificación

  1. Cambios
    - Agregar índice para búsqueda por email
    - Actualizar función de verificación de contraseña
    - Corregir políticas de RLS
*/

-- Agregar índice para búsqueda por email
CREATE INDEX IF NOT EXISTS idx_app_users_email ON app_users(email);

-- Actualizar función de verificación
CREATE OR REPLACE FUNCTION verify_user_password(
  p_email text,
  p_password text
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count integer;
BEGIN
  SELECT COUNT(*)
  INTO v_count
  FROM app_users
  WHERE email = p_email
  AND password_hash = crypt(p_password, password_hash);
  
  RETURN v_count > 0;
END;
$$;

-- Actualizar políticas de RLS
DROP POLICY IF EXISTS "Administradores pueden gestionar todos los usuarios" ON app_users;
DROP POLICY IF EXISTS "Usuarios pueden ver su propia información" ON app_users;

CREATE POLICY "Permitir lectura de usuarios"
  ON app_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Permitir creación de usuarios"
  ON app_users
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Reinsertar usuarios de prueba
DELETE FROM app_users WHERE email IN (
  'luis.moreno@example.com',
  'carmen.andrade@gmail.com',
  'carlos.peña@gmail.com',
  'luis.peña@gmail.com'
);

INSERT INTO app_users (name, email, role, password_hash)
VALUES 
  (
    'Luis Moreno',
    'luis.moreno@example.com',
    'admin',
    crypt('admin123', gen_salt('bf'))
  ),
  (
    'Carmen Andrade',
    'carmen.andrade@gmail.com',
    'student',
    crypt('student123', gen_salt('bf'))
  ),
  (
    'Carlos Peña',
    'carlos.peña@gmail.com',
    'teacher',
    crypt('teacher123', gen_salt('bf'))
  ),
  (
    'Luis Peña',
    'luis.peña@gmail.com',
    'tutor',
    crypt('tutor123', gen_salt('bf'))
  );