-- Drop existing function
DROP FUNCTION IF EXISTS verify_connection();

-- Create improved connection verification function
CREATE OR REPLACE FUNCTION verify_connection()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
  v_start_time timestamptz;
  v_user_count integer;
BEGIN
  v_start_time := clock_timestamp();
  
  -- Test database access by counting users
  SELECT COUNT(*) INTO v_user_count FROM app_users;
  
  SELECT jsonb_build_object(
    'status', 'connected',
    'timestamp', EXTRACT(EPOCH FROM now()),
    'database', current_database(),
    'version', version(),
    'response_time_ms', EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000,
    'user_count', v_user_count
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