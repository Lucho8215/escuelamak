/*
  # Sistema de recuperación de contraseña

  1. Nuevas Tablas
    - `password_reset_tokens`
      - `id` (uuid, primary key)
      - `user_id` (uuid, referencia a app_users)
      - `token` (text, token único)
      - `expires_at` (timestamptz)
      - `used` (boolean)
  
  2. Nuevas Funciones
    - create_password_reset_token: Genera token de recuperación
    - verify_reset_token: Verifica validez del token
    - update_password_with_token: Actualiza contraseña usando token
*/

-- Crear tabla para tokens de recuperación
CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES app_users(id) ON DELETE CASCADE,
  token text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  used boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE password_reset_tokens ENABLE ROW LEVEL SECURITY;

-- Crear política de seguridad
CREATE POLICY "Tokens solo visibles para administradores"
  ON password_reset_tokens
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Función para generar token de recuperación
CREATE OR REPLACE FUNCTION create_password_reset_token(
  p_email text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_token text;
BEGIN
  -- Obtener ID del usuario
  SELECT id INTO v_user_id
  FROM app_users
  WHERE email = p_email;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuario no encontrado';
  END IF;

  -- Generar token único
  v_token := encode(gen_random_bytes(32), 'hex');

  -- Invalidar tokens anteriores
  UPDATE password_reset_tokens
  SET used = true
  WHERE user_id = v_user_id AND used = false;

  -- Crear nuevo token (válido por 1 hora)
  INSERT INTO password_reset_tokens (user_id, token, expires_at)
  VALUES (v_user_id, v_token, now() + interval '1 hour');

  RETURN v_token;
END;
$$;