-- Eliminar la función existente
DROP FUNCTION IF EXISTS verify_connection();

-- Crear la función con el nuevo tipo de retorno
CREATE OR REPLACE FUNCTION verify_connection()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'status', 'connected',
    'timestamp', EXTRACT(EPOCH FROM now()),
    'database', current_database(),
    'version', version()
  ) INTO v_result;

  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'status', 'error',
      'message', SQLERRM,
      'timestamp', EXTRACT(EPOCH FROM now())
    );
END;
$$;