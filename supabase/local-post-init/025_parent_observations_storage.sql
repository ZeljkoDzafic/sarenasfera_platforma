INSERT INTO storage.buckets (id, name, public)
VALUES ('parent-observations', 'parent-observations', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "parent_observation_storage_public_read" ON storage.objects;
CREATE POLICY "parent_observation_storage_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'parent-observations');

DROP POLICY IF EXISTS "parent_observation_storage_parent_insert" ON storage.objects;
CREATE POLICY "parent_observation_storage_parent_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'parent-observations'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "parent_observation_storage_staff_manage" ON storage.objects;
CREATE POLICY "parent_observation_storage_staff_manage"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'parent-observations'
    AND auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin')
  )
  WITH CHECK (
    bucket_id = 'parent-observations'
    AND auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin')
  );
