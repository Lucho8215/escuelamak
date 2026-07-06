/*
  # Fix RLS app_users - Permitir que admin/teacher vean todos los usuarios

  PROBLEMA: La política anterior solo permite a cada usuario ver su propio registro.
  Esto impide que admin y teacher carguen la lista de estudiantes para inscribirlos.

  SOLUCIÓN: Crear política que permita a admin/teacher ver todos los usuarios,
  mientras que el resto solo ve el suyo propio.
*/

-- Eliminar política restrictiva anterior
DROP POLICY IF EXISTS "Usuarios pueden ver su propia información" ON app_users;

-- Nueva política: admin/teacher ven todos; los demás solo el suyo
CREATE POLICY "app_users_select"
  ON app_users
  FOR SELECT
  TO authenticated
  USING (
    -- El usuario ve su propio registro siempre
    email = auth.jwt()->>'email'
    OR
    -- Admin y teacher ven todos los registros
    EXISTS (
      SELECT 1 FROM app_users au
      WHERE au.email = auth.jwt()->>'email'
        AND au.role IN ('admin', 'teacher')
    )
  );
