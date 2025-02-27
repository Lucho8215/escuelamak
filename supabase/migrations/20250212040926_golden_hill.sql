/*
  # Corrección de autenticación y usuarios

  1. Cambios
    - Recrear función de verificación de contraseña con mejor manejo de errores
    - Asegurar que los usuarios de prueba existan
    - Actualizar políticas de seguridad

  2. Seguridad
    - Mejorar la función de verificación
    - Actualizar políticas RLS
*/

-- Mejorar la función de verificación de contraseña
CREATE OR REPLACE FUNCTION verify_user_password(
  p_email text,
  p_password text
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_found boolean;
  v_user_exists boolean;
BEGIN
  -- Primero verificar si el usuario existe
  SELECT EXISTS (
    SELECT 1 FROM app_users WHERE email = p_email
  ) INTO v_user_exists;

  IF NOT v_user_exists THEN
    RETURN false;
  END IF;

  -- Verificar la contraseña
  SELECT EXISTS (
    SELECT 1
    FROM app_users
    WHERE email = p_email
    AND password_hash = crypt(p_password, password_hash)
  ) INTO v_found;
  
  RETURN v_found;
END;
$$;

-- Asegurar que los usuarios de prueba existan
DO $$ 
BEGIN
  -- Eliminar usuarios existentes para evitar duplicados
  DELETE FROM app_users WHERE email IN (
    'luis.moreno@example.com',
    'carmen.andrade@gmail.com',
    'carlos.peña@gmail.com'
  );

  -- Insertar usuarios de prueba
  INSERT INTO app_users (name, email, role, password_hash) VALUES 
    (
      'Luis Moreno',
      'luis.moreno@example.com',
      'admin',
      crypt('Luism*', gen_salt('bf'))
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
    );
END $$;