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
