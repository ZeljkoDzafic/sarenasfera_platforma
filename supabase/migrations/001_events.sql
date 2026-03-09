-- ─── Events & Registrations ─────────────────────────────────────────────────
-- T-830: Public Events Page
-- Migration: 001_events.sql

-- Events table (workshops/events listed on the public site)
CREATE TABLE IF NOT EXISTS public.events (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  slug            TEXT NOT NULL UNIQUE,
  title           TEXT NOT NULL,
  description     TEXT,
  short_desc      TEXT,
  image_url       TEXT,
  location        TEXT,
  location_url    TEXT,                  -- Google Maps link
  starts_at       TIMESTAMPTZ NOT NULL,
  ends_at         TIMESTAMPTZ NOT NULL,
  age_min         INTEGER NOT NULL DEFAULT 2,
  age_max         INTEGER NOT NULL DEFAULT 6,
  capacity        INTEGER NOT NULL DEFAULT 20,
  domain          TEXT CHECK (domain IN ('emotional','social','creative','cognitive','motor','language','all')),
  price_km        NUMERIC(8,2) DEFAULT 0,
  is_free         BOOLEAN DEFAULT true,
  is_published    BOOLEAN DEFAULT false,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- Event registrations (from public form — creates account or links to existing)
CREATE TABLE IF NOT EXISTS public.event_registrations (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id        UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  parent_name     TEXT NOT NULL,
  parent_email    TEXT NOT NULL,
  parent_phone    TEXT,
  child_name      TEXT NOT NULL,
  child_dob       DATE,
  notes           TEXT,
  source          TEXT DEFAULT 'website',    -- website, referral, social
  referral_code   TEXT,
  status          TEXT DEFAULT 'pending' CHECK (status IN ('pending','confirmed','cancelled','attended')),
  user_id         UUID REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- Leads table (contact form, resource downloads, newsletter)
CREATE TABLE IF NOT EXISTS public.leads (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email       TEXT NOT NULL,
  name        TEXT,
  source      TEXT,    -- contact_form, resource_download, newsletter, quiz
  metadata    JSONB DEFAULT '{}',
  user_id     UUID REFERENCES auth.users(id),
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Updated_at trigger for events
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER events_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER event_registrations_updated_at
  BEFORE UPDATE ON public.event_registrations
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Indexes
CREATE INDEX IF NOT EXISTS events_starts_at_idx ON public.events(starts_at);
CREATE INDEX IF NOT EXISTS events_domain_idx ON public.events(domain);
CREATE INDEX IF NOT EXISTS events_published_idx ON public.events(is_published, is_active);
CREATE INDEX IF NOT EXISTS event_registrations_event_idx ON public.event_registrations(event_id);
CREATE INDEX IF NOT EXISTS event_registrations_email_idx ON public.event_registrations(parent_email);
CREATE INDEX IF NOT EXISTS leads_email_idx ON public.leads(email);

-- ─── RLS Policies ────────────────────────────────────────────────────────────

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;

-- Events: public can read published events
CREATE POLICY "events_public_read" ON public.events
  FOR SELECT USING (is_published = true AND is_active = true);

-- Events: staff/admin can manage
CREATE POLICY "events_staff_manage" ON public.events
  FOR ALL USING (
    auth.uid() IS NOT NULL AND
    (auth.jwt()->'app_metadata'->>'role' = 'staff' OR
     auth.jwt()->'app_metadata'->>'role' = 'admin')
  );

-- Event registrations: anyone can insert (no auth required for public registration)
CREATE POLICY "event_registrations_public_insert" ON public.event_registrations
  FOR INSERT WITH CHECK (true);

-- Event registrations: user can see their own
CREATE POLICY "event_registrations_own_read" ON public.event_registrations
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND user_id = auth.uid()
  );

-- Event registrations: staff/admin can see all
CREATE POLICY "event_registrations_staff_read" ON public.event_registrations
  FOR SELECT USING (
    auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin')
  );

-- Event registrations: admin can update status
CREATE POLICY "event_registrations_admin_update" ON public.event_registrations
  FOR UPDATE USING (
    auth.jwt()->'app_metadata'->>'role' = 'admin'
  );

-- Leads: anyone can insert
CREATE POLICY "leads_public_insert" ON public.leads
  FOR INSERT WITH CHECK (true);

-- Leads: admin can read
CREATE POLICY "leads_admin_read" ON public.leads
  FOR SELECT USING (
    auth.jwt()->'app_metadata'->>'role' = 'admin'
  );

-- ─── Seed Data (sample events) ───────────────────────────────────────────────
INSERT INTO public.events (slug, title, short_desc, description, location, starts_at, ends_at, age_min, age_max, capacity, domain, is_free, is_published)
VALUES
  (
    'kreativna-radionica-marta-2026',
    'Kreativna radionica: Proljeće u bojama',
    'Bojanje, kolažiranje i igra s temperama.',
    'Dođite na radionicu gdje ćemo zajedno dočarati dolazak proljeća kroz boje, forme i slobodnu kreativnu igru. Djeca uzrasta 2-5 godina istraživat će teksture, miješati boje i stvarati vlastite masterpiese. Voditelji su certificirani Montessori pedagozi.',
    'Šarena Sfera Centar, Sarajevo',
    (CURRENT_DATE + INTERVAL '7 days')::DATE + TIME '10:00',
    (CURRENT_DATE + INTERVAL '7 days')::DATE + TIME '11:30',
    2, 5, 15, 'creative', true, true
  ),
  (
    'motoricka-radionica-april-2026',
    'Motoričke igre: Tijelo u pokretu',
    'Vježbe ravnoteže, koordinacije i grube motorike.',
    'Radionica posvećena motoričkom razvoju kroz igru i kretanje. Djeca uzrasta 3-6 godina razvijat će ravnotežu, koordinaciju i prostornu orijentaciju kroz zabavne aktivnosti. Prikladna obuća je obavezna.',
    'Šarena Sfera Centar, Sarajevo',
    (CURRENT_DATE + INTERVAL '14 days')::DATE + TIME '09:30',
    (CURRENT_DATE + INTERVAL '14 days')::DATE + TIME '11:00',
    3, 6, 20, 'motor', true, true
  ),
  (
    'pripovijedanje-i-jezik',
    'Jezička radionica: Pričamo priče',
    'Pripovijedanje, lutke i razvoj vokabulara.',
    'Kroz priče, lutke i dramske igre, djeca razvijaju jezičke vještine, vocabularij i sposobnost naracije. Ova radionica posebno je korisna za djecu koja trebaju poticaj u jezičkom razvoju.',
    'Šarena Sfera Centar, Sarajevo',
    (CURRENT_DATE + INTERVAL '21 days')::DATE + TIME '10:00',
    (CURRENT_DATE + INTERVAL '21 days')::DATE + TIME '11:30',
    2, 6, 12, 'language', false, true
  )
ON CONFLICT (slug) DO NOTHING;
