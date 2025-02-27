/*
  # Add connection verification function
  
  This migration adds a simple function to verify the database connection
  is working properly. It's used for health checks and connection monitoring.
*/

CREATE OR REPLACE FUNCTION verify_connection()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN true;
END;
$$;