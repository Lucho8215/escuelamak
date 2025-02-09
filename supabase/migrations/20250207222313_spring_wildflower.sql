/*
  # Crear tabla de usuarios y roles

  1. Nueva Tabla
    - `app_users`
      - `id` (uuid, primary key)
      - `name` (text)
      - `email` (text, unique)
      - `role` (text)
      - `password_hash` (text)
      - `created_at` (timestamp)

  2. Seguridad
    - Habilitar RLS en la tabla `app_users`
    - Políticas para:
      - Administradores pueden ver y gestionar todos los usuarios
      - Usuarios pueden ver su propia información
*/

-- Crear tabla de usuarios
CREATE TABLE IF NOT EXISTS app_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text UNIQUE NOT NULL,
  role text NOT NULL,
  password_hash text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad
CREATE POLICY "Administradores pueden gestionar todos los usuarios"
  ON app_users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_users au
      WHERE au.id = auth.uid() AND au.role = 'admin'
    )
  );

CREATE POLICY "Usuarios pueden ver su propia información"
  ON app_users
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Insertar usuarios iniciales
DO $$ 
BEGIN
  -- Admin: Luis Moreno
  INSERT INTO app_users (name, email, role, password_hash)
  VALUES (
    'Luis Moreno',
    'luis.moreno@example.com',
    'admin',
    crypt('Luism*', gen_salt('bf'))
  );

  -- Estudiante: Carmen Andrade
  INSERT INTO app_users (name, email, role, password_hash)
  VALUES (
    'Carmen Andrade',
    'carmen.andrade@gmail.com',
    'student',
    crypt('carmen12', gen_salt('bf'))
  );

  -- Profesor: Carlos Peña
  INSERT INTO app_users (name, email, role, password_hash)
  VALUES (
    'Carlos Peña',
    'carlos.peña@gmail.com',
    'teacher',
    crypt('carmen12', gen_salt('bf'))
  );

  -- Tutor: Luis Peña
  INSERT INTO app_users (name, email, role, password_hash)
  VALUES (
    'Luis Peña',
    'luis.peña@gmail.com',
    'tutor',
    crypt('carmen12', gen_salt('bf'))
  );
END $$;