-- Enable pgcrypto extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Recreate the password verification function with proper error handling
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
BEGIN
  -- Input validation
  IF p_email IS NULL OR p_password IS NULL THEN
    RETURN false;
  END IF;

  -- First check if user exists
  SELECT EXISTS (
    SELECT 1 FROM app_users WHERE email = p_email
  ) INTO v_user_exists;

  IF NOT v_user_exists THEN
    RETURN false;
  END IF;

  -- Verify password
  SELECT EXISTS (
    SELECT 1
    FROM app_users
    WHERE email = p_email
    AND password_hash = crypt(p_password, password_hash)
  ) INTO v_found;

  RETURN v_found;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error details (in production, you'd want to use proper logging)
    RAISE NOTICE 'Error in verify_user_password: %', SQLERRM;
    RETURN false;
END;
$$;

-- Recreate the user creation function with proper error handling
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

  -- Check if email already exists
  IF EXISTS (SELECT 1 FROM app_users WHERE email = p_email) THEN
    RAISE EXCEPTION 'Email already exists';
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
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error creating user: %', SQLERRM;
END;
$$;

-- Recreate the password update function with proper error handling
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
  SET 
    password_hash = crypt(p_new_password, gen_salt('bf')),
    updated_at = now()
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error updating password: %', SQLERRM;
END;
$$;