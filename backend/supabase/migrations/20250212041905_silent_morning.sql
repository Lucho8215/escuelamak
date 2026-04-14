/*
  # Funciones adicionales para recuperación de contraseña

  1. Nuevas Funciones
    - verify_reset_token: Verifica si un token es válido
    - update_password_with_token: Actualiza la contraseña usando un token válido

  2. Mejoras de Seguridad
    - Verificación de expiración de tokens
    - Invalidación de tokens usados
    - Actualización segura de contraseñas
*/

-- Función para verificar token
CREATE OR REPLACE FUNCTION verify_reset_token(
  p_token text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM password_reset_tokens
    WHERE token = p_token
    AND used = false
    AND expires_at > now()
  );
END;
$$;

-- Función para actualizar contraseña con token
CREATE OR REPLACE FUNCTION update_password_with_token(
  p_token text,
  p_new_password text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Obtener el ID del usuario del token válido
  SELECT user_id INTO v_user_id
  FROM password_reset_tokens
  WHERE token = p_token
  AND used = false
  AND expires_at > now();

  -- Verificar si el token es válido
  IF v_user_id IS NULL THEN
    RETURN false;
  END IF;

  -- Actualizar la contraseña
  UPDATE app_users
  SET password_hash = crypt(p_new_password, gen_salt('bf'))
  WHERE id = v_user_id;

  -- Marcar el token como usado
  UPDATE password_reset_tokens
  SET used = true
  WHERE token = p_token;

  RETURN true;
END;
$$;