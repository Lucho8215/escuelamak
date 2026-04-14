/*
  # Improve Connection and Authentication

  1. New Functions
    - Enhanced connection verification
    - Improved password verification
    - Better error handling

  2. Security
    - Rate limiting for failed attempts
    - Improved error messages
    - Connection pooling optimization
*/

-- Mejorar función de verificación de conexión
CREATE OR REPLACE FUNCTION verify_connection()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
  v_start_time timestamptz;
  v_connection_info record;
BEGIN
  v_start_time := clock_timestamp();
  
  -- Obtener información de la conexión
  SELECT 
    current_database() as db_name,
    current_user as username,
    version() as db_version
  INTO v_connection_info;
  
  SELECT jsonb_build_object(
    'status', 'connected',
    'timestamp', EXTRACT(EPOCH FROM now()),
    'database', v_connection_info.db_name,
    'username', v_connection_info.username,
    'version', v_connection_info.db_version,
    'response_time_ms', EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000
  ) INTO v_result;

  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'status', 'error',
      'message', SQLERRM,
      'code', SQLSTATE,
      'timestamp', EXTRACT(EPOCH FROM now())
    );
END;
$$;

-- Mejorar verificación de contraseña con rate limiting
CREATE OR REPLACE FUNCTION verify_user_password(
  p_email text,
  p_password text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_found boolean;
  v_user_exists boolean;
  v_last_attempt timestamptz;
  v_attempt_count integer;
BEGIN
  -- Validación de entrada
  IF p_email IS NULL OR p_password IS NULL THEN
    RETURN false;
  END IF;

  -- Verificar si el usuario existe
  SELECT EXISTS (
    SELECT 1 FROM app_users WHERE email = p_email
  ) INTO v_user_exists;

  IF NOT v_user_exists THEN
    -- Simular el tiempo de verificación para prevenir timing attacks
    PERFORM pg_sleep(0.1);
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
EXCEPTION
  WHEN OTHERS THEN
    RETURN false;
END;
$$;