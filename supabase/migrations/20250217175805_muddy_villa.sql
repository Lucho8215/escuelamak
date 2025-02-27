/*
  # Fix authentication functions

  1. New Functions
    - create_user: Creates a new user with encrypted password
    - update_user_password: Updates user password with encryption
    - verify_user_password: Verifies user password (improved)

  2. Security
    - All functions are SECURITY DEFINER
    - Proper error handling
    - Input validation
*/

-- Function to create a new user
CREATE OR REPLACE FUNCTION create_user(
  p_name text,
  p_email text,
  p_password text,
  p_role text
)
RETURNS app_users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user app_users;
BEGIN
  -- Validate inputs
  IF p_name IS NULL OR p_email IS NULL OR p_password IS NULL OR p_role IS NULL THEN
    RAISE EXCEPTION 'All fields are required';
  END IF;

  -- Validate email format
  IF NOT p_email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
    RAISE EXCEPTION 'Invalid email format';
  END IF;

  -- Validate role
  IF p_role NOT IN ('admin', 'teacher', 'tutor', 'student') THEN
    RAISE EXCEPTION 'Invalid role';
  END IF;

  -- Insert new user
  INSERT INTO app_users (
    name,
    email,
    password_hash,
    role
  )
  VALUES (
    p_name,
    p_email,
    crypt(p_password, gen_salt('bf')),
    p_role
  )
  RETURNING * INTO v_user;

  RETURN v_user;
END;
$$;

-- Function to update user password
CREATE OR REPLACE FUNCTION update_user_password(
  p_user_id uuid,
  p_new_password text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Validate input
  IF p_new_password IS NULL OR length(p_new_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters long';
  END IF;

  -- Update password
  UPDATE app_users
  SET password_hash = crypt(p_new_password, gen_salt('bf'))
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;
END;
$$;

-- Improved password verification function
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
  v_attempts integer;
  v_last_attempt timestamptz;
BEGIN
  -- Basic input validation
  IF p_email IS NULL OR p_password IS NULL THEN
    RETURN false;
  END IF;

  -- Check if user exists and verify password
  SELECT EXISTS (
    SELECT 1
    FROM app_users
    WHERE email = p_email
    AND password_hash = crypt(p_password, password_hash)
  ) INTO v_found;

  RETURN v_found;
END;
$$;