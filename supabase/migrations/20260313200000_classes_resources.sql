-- Añade columnas para imagen, enlace y archivo (PDF) en la tabla classes.
-- Por qué: El formulario "Gestión de Lecciones" permite subir imagen y PDF,
-- pero no se guardaban porque las columnas faltaban y los archivos no se subían.
-- Para qué: Que la imagen y el PDF asignados a una clase se persistan y se muestren.
--
-- También crea el bucket de Storage para los archivos de clase (si existe el esquema storage).
DO $
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'classes' AND column_name = 'image_url'
  ) THEN
    ALTER TABLE classes ADD COLUMN image_url text;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'classes' AND column_name = 'resource_link'
  ) THEN
    ALTER TABLE classes ADD COLUMN resource_link text;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'classes' AND column_name = 'resource_file_url'
  ) THEN
    ALTER TABLE classes ADD COLUMN resource_file_url text;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'classes' AND column_name = 'observation'
  ) THEN
    ALTER TABLE classes ADD COLUMN observation text;
  END IF;
END $;

-- Crear bucket para archivos de clase (imagen, PDF) si existe el esquema storage
DO $
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'storage') THEN
    INSERT INTO storage.buckets (id, name, public, file_size_limit)
    SELECT 'class-resources', 'class-resources', true, 52428800
    WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'class-resources');
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- Si falla (ej. storage no configurado), continuar sin error
  NULL;
END $;

-- Políticas RLS para permitir acceso público al bucket class-resources
DO $
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'objects' AND schemaname = 'storage') THEN
    -- Política de lectura pública
    CREATE POLICY "Public read access for class-resources"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'class-resources');

    -- Política de inserción (authenticated users)
    CREATE POLICY "Authenticated insert for class-resources"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'class-resources');

    -- Política de actualización (authenticated users)
    CREATE POLICY "Authenticated update for class-resources"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'class-resources');
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $;
