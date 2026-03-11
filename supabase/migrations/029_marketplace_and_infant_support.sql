-- Marketplace support + infant groups and milestone extensions

CREATE TABLE IF NOT EXISTS public.marketplace_items (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title             TEXT NOT NULL,
  description       TEXT,
  item_type         TEXT NOT NULL CHECK (item_type IN ('sale', 'exchange', 'gift')),
  category          TEXT NOT NULL,
  age_group_label   TEXT,
  location_label    TEXT,
  price             NUMERIC(10,2),
  currency          TEXT NOT NULL DEFAULT 'BAM',
  image_urls        TEXT[] DEFAULT '{}',
  contact_email     TEXT,
  contact_phone     TEXT,
  status            TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'reserved', 'sold', 'archived')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_marketplace_items_owner ON public.marketplace_items(owner_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_items_status ON public.marketplace_items(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_marketplace_items_category ON public.marketplace_items(category);
CREATE INDEX IF NOT EXISTS idx_marketplace_items_type ON public.marketplace_items(item_type);

DROP TRIGGER IF EXISTS marketplace_items_updated_at ON public.marketplace_items;
CREATE TRIGGER marketplace_items_updated_at
  BEFORE UPDATE ON public.marketplace_items
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE public.marketplace_items ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'marketplace_items' AND policyname = 'marketplace_authenticated_read'
  ) THEN
    CREATE POLICY "marketplace_authenticated_read"
      ON public.marketplace_items FOR SELECT
      USING (auth.uid() IS NOT NULL AND status IN ('active', 'reserved', 'sold'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'marketplace_items' AND policyname = 'marketplace_owner_insert'
  ) THEN
    CREATE POLICY "marketplace_owner_insert"
      ON public.marketplace_items FOR INSERT
      WITH CHECK (owner_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'marketplace_items' AND policyname = 'marketplace_owner_update'
  ) THEN
    CREATE POLICY "marketplace_owner_update"
      ON public.marketplace_items FOR UPDATE
      USING (owner_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'))
      WITH CHECK (owner_id = auth.uid() OR auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'marketplace_items' AND policyname = 'marketplace_admin_delete'
  ) THEN
    CREATE POLICY "marketplace_admin_delete"
      ON public.marketplace_items FOR DELETE
      USING (auth.jwt()->'app_metadata'->>'role' IN ('admin', 'staff'));
  END IF;
END
$$;

INSERT INTO public.groups (name, description, age_range_min, age_range_max, max_capacity, is_active)
SELECT 'Zvjezdice (0-1 god)', 'Rani razvoj, senzorne aktivnosti i podrška roditeljima za bebe do 12 mjeseci.', 0, 12, 8, true
WHERE NOT EXISTS (
  SELECT 1 FROM public.groups WHERE name = 'Zvjezdice (0-1 god)'
);

INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order)
SELECT *
FROM (
  VALUES
    ('emotional', 0, 12, 'Prepoznaje glas i bliskost roditelja', 'Smiruje se na poznat glas i traži kontakt pogledom.', 1),
    ('social', 0, 12, 'Odgovara osmijehom', 'Uzvraća osmijeh i pokazuje interes za lice odrasle osobe.', 2),
    ('creative', 0, 12, 'Istražuje zvuk i teksturu', 'Dodiruje, trese i ispituje predmete različitih materijala.', 3),
    ('cognitive', 0, 12, 'Prati predmet pogledom', 'Vizuelno prati igračku ili lice kroz prostor.', 4),
    ('motor', 0, 12, 'Kontroliše pokrete glave i trupa', 'Postepeno razvija stabilnost pri ležanju, okretanju i sjedenju.', 5),
    ('language', 0, 12, 'Reaguje na govor i gugutanje', 'Okreće se prema zvuku i uzvraća glasovima.', 6)
) AS seed(domain, age_range_min, age_range_max, title, description, sort_order)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.developmental_milestones existing
  WHERE existing.domain = seed.domain
    AND existing.age_range_min = seed.age_range_min
    AND existing.age_range_max = seed.age_range_max
    AND existing.title = seed.title
);
