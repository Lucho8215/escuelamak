/*
  # Agregar función para verificar contraseñas

  1. Nueva Función
    - `verify_user_password`: Función para verificar contraseñas de usuario
      - Parámetros:
        - `p_email`: email del usuario
        - `p_password`: contraseña a verificar
      - Retorna: boolean
*/

CREATE OR REPLACE FUNCTION verify_user_password(
  p_email text,
  p_password text
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM app_users
    WHERE email = p_email
    AND password_hash = crypt(p_password, password_hash)
  );
END;
$$;