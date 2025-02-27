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
  
  -- Obtener información básica de la conexión
  SELECT 
    current_database() as db_name,
    current_user as username,
    version() as db_version
  INTO v_connection_info;
  
  -- Construir respuesta
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

-- Asegurar que la función sea accesible
GRANT EXECUTE ON FUNCTION verify_connection() TO anon, authenticated, service_role;