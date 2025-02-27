-- Eliminar la función existente
DROP FUNCTION IF EXISTS verify_connection();

-- Crear la función con el nuevo tipo de retorno y mejor manejo de errores
CREATE OR REPLACE FUNCTION verify_connection()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
  v_start_time timestamptz;
BEGIN
  v_start_time := clock_timestamp();
  
  -- Realizar una consulta simple para verificar la conexión
  PERFORM 1;
  
  SELECT jsonb_build_object(
    'status', 'connected',
    'timestamp', EXTRACT(EPOCH FROM now()),
    'database', current_database(),
    'version', version(),
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