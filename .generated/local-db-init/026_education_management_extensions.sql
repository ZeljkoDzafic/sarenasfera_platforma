-- T-1014: admin management extensions for education content

ALTER TABLE public.educational_content
  ADD COLUMN IF NOT EXISTS short_description TEXT,
  ADD COLUMN IF NOT EXISTS starts_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS ends_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS location_type TEXT,
  ADD COLUMN IF NOT EXISTS location_name TEXT,
  ADD COLUMN IF NOT EXISTS location_url TEXT,
  ADD COLUMN IF NOT EXISTS capacity INTEGER,
  ADD COLUMN IF NOT EXISTS event_subtype TEXT,
  ADD COLUMN IF NOT EXISTS external_registration_url TEXT;

ALTER TABLE public.resource_materials
  ADD COLUMN IF NOT EXISTS content_html TEXT,
  ADD COLUMN IF NOT EXISTS video_url TEXT;

ALTER TABLE public.resource_materials
  DROP CONSTRAINT IF EXISTS resource_materials_file_type_check;

ALTER TABLE public.resource_materials
  ADD CONSTRAINT resource_materials_file_type_check
  CHECK (file_type IN ('article', 'pdf', 'image', 'video', 'audio', 'document', 'worksheet'));

-- In local docker-compose boot, Storage API creates its schema after Postgres init scripts.
DO $$
BEGIN
  IF to_regclass('storage.buckets') IS NULL
     OR to_regclass('storage.objects') IS NULL THEN
    RAISE NOTICE 'Skipping education content storage policies until storage schema is available';
    RETURN;
  END IF;

  INSERT INTO storage.buckets (id, name, public)
  VALUES ('education-content', 'education-content', true)
  ON CONFLICT (id) DO NOTHING;

  DROP POLICY IF EXISTS "education_content_storage_public_read" ON storage.objects;
  CREATE POLICY "education_content_storage_public_read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'education-content');

  DROP POLICY IF EXISTS "education_content_storage_staff_insert" ON storage.objects;
  CREATE POLICY "education_content_storage_staff_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (
      bucket_id = 'education-content'
      AND auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin')
    );

  DROP POLICY IF EXISTS "education_content_storage_staff_manage" ON storage.objects;
  CREATE POLICY "education_content_storage_staff_manage"
    ON storage.objects FOR ALL
    USING (
      bucket_id = 'education-content'
      AND auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin')
    )
    WITH CHECK (
      bucket_id = 'education-content'
      AND auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin')
    );
END
$$;
