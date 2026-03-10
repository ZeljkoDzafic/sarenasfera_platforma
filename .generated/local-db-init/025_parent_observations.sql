-- T-1004: Parent observations (moderated)

CREATE TABLE IF NOT EXISTS public.parent_observations (
  id                     UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id               UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  parent_id              UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  domain                 TEXT NOT NULL CHECK (domain IN (
                           'emotional', 'social', 'creative', 'cognitive', 'motor', 'language'
                         )),
  content                TEXT NOT NULL,
  photo_url              TEXT,
  status                 TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  review_note            TEXT,
  reviewed_by            UUID REFERENCES public.profiles(id),
  reviewed_at            TIMESTAMPTZ,
  approved_observation_id UUID REFERENCES public.observations(id),
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_parent_observations_child ON public.parent_observations(child_id);
CREATE INDEX IF NOT EXISTS idx_parent_observations_parent ON public.parent_observations(parent_id);
CREATE INDEX IF NOT EXISTS idx_parent_observations_status ON public.parent_observations(status);
CREATE INDEX IF NOT EXISTS idx_parent_observations_domain ON public.parent_observations(domain);

DROP TRIGGER IF EXISTS parent_observations_updated_at ON public.parent_observations;
CREATE TRIGGER parent_observations_updated_at
  BEFORE UPDATE ON public.parent_observations
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE public.parent_observations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "parent_observations_parent_read" ON public.parent_observations;
CREATE POLICY "parent_observations_parent_read" ON public.parent_observations FOR SELECT
  USING (parent_id = auth.uid());

DROP POLICY IF EXISTS "parent_observations_parent_insert" ON public.parent_observations;
CREATE POLICY "parent_observations_parent_insert" ON public.parent_observations FOR INSERT
  WITH CHECK (
    parent_id = auth.uid()
    AND child_id IN (
      SELECT pc.child_id
      FROM public.parent_children pc
      WHERE pc.parent_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "parent_observations_parent_update" ON public.parent_observations;
CREATE POLICY "parent_observations_parent_update" ON public.parent_observations FOR UPDATE
  USING (parent_id = auth.uid() AND status = 'pending')
  WITH CHECK (parent_id = auth.uid() AND status = 'pending');

DROP POLICY IF EXISTS "parent_observations_staff_all" ON public.parent_observations;
CREATE POLICY "parent_observations_staff_all" ON public.parent_observations FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin'))
  WITH CHECK (auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin'));

DROP POLICY IF EXISTS "notifications_staff_insert" ON public.notifications;
CREATE POLICY "notifications_staff_insert" ON public.notifications FOR INSERT
  WITH CHECK (auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin'));

-- In local docker-compose boot, Storage API creates its schema after Postgres init scripts.
DO $$
BEGIN
  IF to_regclass('storage.buckets') IS NULL
     OR to_regclass('storage.objects') IS NULL
     OR to_regprocedure('storage.foldername(text)') IS NULL THEN
    RAISE NOTICE 'Skipping parent observation storage policies until storage schema is available';
    RETURN;
  END IF;

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
END
$$;
