-- Habilitar la extensión pgcrypto
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Recrear la función de verificación de contraseña
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
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM app_users
    WHERE email = p_email
    AND password_hash = crypt(p_password, password_hash)
  ) INTO v_found;
  
  RETURN v_found;
END;
$$;

-- Asegurar que los usuarios existan con contraseñas actualizadas
DELETE FROM app_users WHERE email = 'luis.moreno@example.com';

INSERT INTO app_users (name, email, role, password_hash)
VALUES (
  'Luis Moreno',
  'luis.moreno@example.com',
  'admin',
  crypt('Luism*', gen_salt('bf'))
);

-- Actualizar políticas
DROP POLICY IF EXISTS "public_select_policy" ON app_users;
DROP POLICY IF EXISTS "authenticated_insert_policy" ON app_users;

CREATE POLICY "allow_public_select"
  ON app_users
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "allow_authenticated_insert"
  ON app_users
  FOR INSERT
  TO authenticated
  WITH CHECK (true);