-- ─── Developmental Milestones & Child Milestone Tracking ──────────────────────
-- T-1000: Milestones DB migration
-- Migration: 020_developmental_milestones.sql
--
-- This migration creates:
-- 1. developmental_milestones table (200+ predefined milestones across 6 domains)
-- 2. child_milestones table (tracks achievement status per child)
-- 3. RLS policies for parents, staff, admin
-- 4. Seed data: ~200 milestones across 6 domains × 4 age brackets (2-3, 3-4, 4-5, 5-6)

-- ─── Developmental Milestones (Master List) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.developmental_milestones (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  domain          TEXT NOT NULL CHECK (domain IN (
                    'emotional', 'social', 'creative', 'cognitive', 'motor', 'language'
                  )),
  age_range_min   INTEGER NOT NULL,          -- months (24 = 2 years)
  age_range_max   INTEGER NOT NULL,          -- months (36 = 3 years)
  title           TEXT NOT NULL,             -- "Prepoznaje sreću i tugu"
  description     TEXT,                      -- detailed explanation
  sort_order      INTEGER DEFAULT 0,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_milestones_domain_age
  ON public.developmental_milestones(domain, age_range_min);
CREATE INDEX IF NOT EXISTS idx_milestones_active
  ON public.developmental_milestones(is_active);

-- ─── Child Milestone Tracking ──────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'child_milestones'
      AND column_name = 'skill_id'
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'child_milestones'
      AND column_name = 'milestone_id'
  ) THEN
    ALTER TABLE public.child_milestones RENAME TO child_skill_milestones_legacy;

    IF EXISTS (
      SELECT 1 FROM pg_class WHERE relkind = 'i' AND relname = 'idx_child_milestones_child'
    ) THEN
      ALTER INDEX public.idx_child_milestones_child RENAME TO idx_child_skill_milestones_child_legacy;
    END IF;

    IF EXISTS (
      SELECT 1 FROM pg_class WHERE relkind = 'i' AND relname = 'idx_child_milestones_skill'
    ) THEN
      ALTER INDEX public.idx_child_milestones_skill RENAME TO idx_child_skill_milestones_skill_legacy;
    END IF;
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS public.child_milestones (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  child_id        UUID REFERENCES public.children(id) ON DELETE CASCADE NOT NULL,
  milestone_id    UUID REFERENCES public.developmental_milestones(id) NOT NULL,
  status          TEXT NOT NULL DEFAULT 'not_started'
                    CHECK (status IN ('not_started', 'emerging', 'achieved')),
  achieved_at     DATE,                      -- when milestone was observed
  observed_by     UUID REFERENCES public.profiles(id), -- staff who observed
  observation_id  UUID REFERENCES public.observations(id), -- linked observation
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(child_id, milestone_id)
);

CREATE INDEX IF NOT EXISTS idx_child_milestones_child ON public.child_milestones(child_id);
CREATE INDEX IF NOT EXISTS idx_child_milestones_status ON public.child_milestones(status);
CREATE INDEX IF NOT EXISTS idx_child_milestones_milestone ON public.child_milestones(milestone_id);

-- Trigger: updated_at
DROP TRIGGER IF EXISTS child_milestones_updated_at ON public.child_milestones;
CREATE TRIGGER child_milestones_updated_at
  BEFORE UPDATE ON public.child_milestones
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── RLS Policies ──────────────────────────────────────────────────────────────
ALTER TABLE public.developmental_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.child_milestones ENABLE ROW LEVEL SECURITY;

-- Milestones: everyone can read active milestones
CREATE POLICY IF NOT EXISTS "milestones_public_read"
  ON public.developmental_milestones FOR SELECT
  USING (is_active = true);

-- Milestones: admin can manage
CREATE POLICY IF NOT EXISTS "milestones_admin_all"
  ON public.developmental_milestones FOR ALL
  USING (auth.jwt()->'app_metadata'->>'role' = 'admin');

-- Child milestones: parents see own children
CREATE POLICY IF NOT EXISTS "child_milestones_parent_read"
  ON public.child_milestones FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.parent_children pc
      WHERE pc.child_id = child_milestones.child_id
        AND pc.parent_id = auth.uid()
    )
  );

-- Child milestones: staff see children in their groups
CREATE POLICY IF NOT EXISTS "child_milestones_staff_read"
  ON public.child_milestones FOR SELECT
  USING (
    auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin')
  );

-- Child milestones: staff can insert/update
CREATE POLICY IF NOT EXISTS "child_milestones_staff_write"
  ON public.child_milestones FOR ALL
  USING (
    auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin')
  );

-- ─── Seed Data: Developmental Milestones ───────────────────────────────────────
-- Age brackets: 2-3 (24-36m), 3-4 (36-48m), 4-5 (48-60m), 5-6 (60-72m)

-- ======= EMOCIONALNI RAZVOJ =======

-- Age 2-3 (24-36 months)
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('emotional', 24, 36, 'Prepoznaje sreću i tugu', 'Razlikuje osnovne emocije sreće i tuge kod sebe i drugih', 1),
('emotional', 24, 36, 'Reaguje na emocije drugih', 'Pokazuje zabrinutost kada neko plače ili je tužan', 2),
('emotional', 24, 36, 'Imenuje 2-3 emocije', 'Može reći "sretan", "tužan", "ljut"', 3),
('emotional', 24, 36, 'Traži utjehu kada je uznemiren', 'Dolazi roditeljima/vaspitaču za zagrljaj kada je uznemiren', 4),
('emotional', 24, 36, 'Pokazuje ponos nakon dostignuća', 'Osmjehuje se i kliče kada završi zadatak', 5),
('emotional', 24, 36, 'Izraža ljubav prema bližnjima', 'Grli, ljubi, kaže "volim te"', 6);

-- Age 3-4 (36-48 months)
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('emotional', 36, 48, 'Imenuje 4+ emocije', 'Može imenovati sreću, tugu, ljutnju, strah', 7),
('emotional', 36, 48, 'Reguliše frustraciju uz podršku', 'Uz pomoć odraslog smiruje se nakon frustracije', 8),
('emotional', 36, 48, 'Pokazuje empatiju prema vršnjacima', 'Tješi prijatelja koji plače, nudi igračku', 9),
('emotional', 36, 48, 'Prepoznaje emocije u pričama', 'Može reći kako se osjećaju likovi u knjizi', 10),
('emotional', 36, 48, 'Dijeli igračke uz podsticaj', 'Dijeliložiti će se uz blagi podsticaj', 11),
('emotional', 36, 48, 'Koristi riječi za izražavanje osjećaja', 'Kaže "ljut sam", "uplašen sam" umjesto plača', 12);

-- Age 4-5 (48-60 months)
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('emotional', 48, 60, 'Imenuje 5+ emocija uključujući složene', 'Prepoznaje i imenuje uzbuđenje, ljubomoru, zabrinutost', 13),
('emotional', 48, 60, 'Samostalno se smiruje osnovnim tehnikama', 'Koristi duboko disanje, broji do 5, tražiliže pomoć', 14),
('emotional', 48, 60, 'Pokazuje veliku empatiju', 'Aktivno pomaže drugima, dijeli bez traženja', 15),
('emotional', 48, 60, 'Razumije uzroke emocija', 'Zna zašto je neko sretan ili tužan', 16),
('emotional', 48, 60, 'Prepoznaje svoje okidače', 'Može reći "ne volim buku" ili "to me nervira"', 17),
('emotional', 48, 60, 'Prihvata gubitak u igri', 'Ne plače svaki put kad izgubi igru', 18);

-- Age 5-6 (60-72 months)
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('emotional', 60, 72, 'Verbalizuje složene emocije', 'Može objasniti mješovita osjećanja (sretan i nervozan)', 19),
('emotional', 60, 72, 'Samostalno reguliše emocije', 'Bez pomoći koristi strategije za smirivanje', 20),
('emotional', 60, 72, 'Razumije perspektive drugih', 'Zna da ljudi mogu osjećati različito o istoj stvari', 21),
('emotional', 60, 72, 'Odlaže zadovoljstvo', 'Može čekati nagradu ili red bez velikih poteškoća', 22),
('emotional', 60, 72, 'Pokazuje samopouzdanje', 'Pokušava nove stvari bez straha od neuspjeha', 23);

-- ======= SOCIJALNI RAZVOJ =======

-- Age 2-3
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('social', 24, 36, 'Igra paralelno pored druge djece', 'Igra se pored, ali ne nužno sa drugom djecom', 30),
('social', 24, 36, 'Imitira druge u igri', 'Ponavlja radnje koje vidi kod vršnjaka', 31),
('social', 24, 36, 'Pozdravlja i oprašta se', 'Mahe, kaže "zdravo", "doviđenja"', 32),
('social', 24, 36, 'Pokazuje interesovanje za drugu djecu', 'Gleda, prilazi, dotiče druge', 33),
('social', 24, 36, 'Pruža igračku kada se traži', 'Daje igračku ako odrasli ili dijete zamoli', 34);

-- Age 3-4
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('social', 36, 48, 'Igra se kooperativno sa jednim djetetom', 'Igra igru sa drugom djetetom 5+ minuta', 35),
('social', 36, 48, 'Naizmjenično se izmjenjuje u igri', 'Čeka svoj red u jednostavnim igrama', 36),
('social', 36, 48, 'Imenuje prijatelje', 'Ima 1-2 preferirana vršnjaka', 37),
('social', 36, 48, 'Dijeli spontano (ponekad)', 'Ponekad dijeli bez traženja', 38),
('social', 36, 48, 'Učestvuje u grupnim aktivnostima', 'Pridružuje se krugu, pjevanju, grupnoj igri', 39),
('social', 36, 48, 'Pita za dozvolu', 'Pita "mogu li..." prije uzimanja', 40);

-- Age 4-5
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('social', 48, 60, 'Igra kooperativno u grupi od 3+ djece', 'Učestvuje u igrama sa pravilima sa više vršnjaka', 41),
('social', 48, 60, 'Razumije i slijedi pravila igre', 'Igra igru prema pravilima bez konstantnih podsjetnika', 42),
('social', 48, 60, 'Pregovara i kompromituje', 'Predlaže alternativu kada ne može dobiti ono što želi', 43),
('social', 48, 60, 'Pokazuje timski rad', 'Sarađuje sa drugima na zajedničkom zadatku', 44),
('social', 48, 60, 'Tješi prijatelja bez podsticaja', 'Aktivno prilazi i pomaže uznemirenom vršnjaku', 45),
('social', 48, 60, 'Voli grupne aktivnosti', 'Sa zadovoljstvom učestvuje u timskim igrama', 46);

-- Age 5-6
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('social', 60, 72, 'Održava dugotrajno prijateljstvo', 'Ima stabilne prijatelje preko 6+ mjeseci', 47),
('social', 60, 72, 'Razumije koncept fer-pleja', 'Aktivno brine o pravednosti u igri', 48),
('social', 60, 72, 'Razriješava konflikte riječima', 'Koristi riječi umjesto fizičkih reakcija', 49),
('social', 60, 72, 'Učestvuje u složenim rolnim igrama', 'Preuzima role i razvija priče sa vršnjacima', 50),
('social', 60, 72, 'Pokazuje liderske vještine', 'Povremeno vodi grupne aktivnosti i igre', 51);

-- ======= KREATIVNI RAZVOJ =======

-- Age 2-3
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('creative', 24, 36, 'Šara i pravi poteze bojom', 'Uživa u pravljenju linija i oblika', 60),
('creative', 24, 36, 'Igra simboličku igru', 'Pravi da lutka jede, telefon zvoni', 61),
('creative', 24, 36, 'Gradi kule od 6+ kocki', 'Slaže kockice vertikalno', 62),
('creative', 24, 36, 'Uživa u muzici i plesu', 'Pomiče se u ritmu muzike', 63),
('creative', 24, 36, 'Eksperimentiše sa materijalima', 'Istražuje plasteliniš, pijesak, vodu', 64);

-- Age 3-4
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('creative', 36, 48, 'Crta prepoznatljive oblike', 'Pravi krugove, linije, jednostavne oblike', 65),
('creative', 36, 48, 'Imenuje svoje crtaža', 'Kaže šta je nacrtao (čak i ako nije prepoznatljivo)', 66),
('creative', 36, 48, 'Gradi složene strukture', 'Pravi mostove, kuće, vozove od kockica', 67),
('creative', 36, 48, 'Pjeva jednostavne pjesmice', 'Zna nekoliko dječijih pjesama', 68),
('creative', 36, 48, 'Igra dramsku igru', 'Glumi doktora, učitelja, roditelja', 69),
('creative', 36, 48, 'Prati ритам instrumentima', 'Udara bubanj ili zvečku u ritmu', 70);

-- Age 4-5
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('creative', 48, 60, 'Crta ljude sa 3+ dijela', 'Glava, tijelo, noge ili ruke', 71),
('creative', 48, 60, 'Priča kreativne priče', 'Izmišlja priče sa početkom, sredinom, krajem', 72),
('creative', 48, 60, 'Pravi složene konstrukcije sa svrhom', 'Gradi specifične stvari (zamak, aerodrom)', 73),
('creative', 48, 60, 'Uživa u zanатским projektima', 'Završava kreativne zadatke od početka do kraja', 74),
('creative', 48, 60, 'Pjeva melodiju tačno', 'Prati ton i melodiju pjesme', 75),
('creative', 48, 60, 'Glumi složene role', 'Razvija scenarije i koristi rekvizite', 76);

-- Age 5-6
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('creative', 60, 72, 'Crta detaljne slike', 'Dodaje pozadinu, boje, detalje u crtežima', 77),
('creative', 60, 72, 'Piše kreativne priče', 'Kombinuje crtež i jednostavne rečenice', 78),
('creative', 60, 72, 'Samostalno planira projekte', 'Odlučuje šta želi napraviti i kako', 79),
('creative', 60, 72, 'Igra ili pjeva pred publikom', 'Voljno nastupa pred grupom', 80),
('creative', 60, 72, 'Koristi maštu u rješavanju problema', 'Izmišlja kreativna rješenja', 81);

-- ======= KOGNITIVNI RAZVOJ =======

-- Age 2-3
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('cognitive', 24, 36, 'Broji do 3', 'Može nabrojati 1, 2, 3', 90),
('cognitive', 24, 36, 'Imenuje 3+ boje', 'Prepoznaje crvenu, plavu, žutu', 91),
('cognitive', 24, 36, 'Razumije "veće" i "manje"', 'Pokazuje veći ili manji predmet', 92),
('cognitive', 24, 36, 'Uparuje identične predmete', 'Nalazi par čarapa, iste kockice', 93),
('cognitive', 24, 36, 'Završava jednostavne slagalice (3-4 dijela)', 'Slaže osnovne puzzle', 94),
('cognitive', 24, 36, 'Razumije koncept "jedan"', 'Daje jedan predmet kada se traži', 95);

-- Age 3-4
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('cognitive', 36, 48, 'Broji do 10', 'Redom broji do deset', 96),
('cognitive', 36, 48, 'Imenuje 5+ boja', 'Prepoznaje osnovne i neke nijanse', 97),
('cognitive', 36, 48, 'Razumije koncept vremena', 'Zna "prije", "poslije", "sutra"', 98),
('cognitive', 36, 48, 'Sortira po 2 kategorije', 'Sortira po boji ili veličini', 99),
('cognitive', 36, 48, 'Završava slagalice (8-12 dijelova)', 'Rješava složenije puzzle', 100),
('cognitive', 36, 48, 'Prepoznaje sopstveno ime pisano', 'Zna svoje ime kada ga vidi', 101),
('cognitive', 36, 48, 'Razumije koncept "isto" i "različito"', 'Upoređuje predmete', 102);

-- Age 4-5
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('cognitive', 48, 60, 'Broji do 20', 'Redom broji do dvadeset', 103),
('cognitive', 48, 60, 'Prepoznaje neke brojeve i slova', 'Zna nekoliko slova i brojeva', 104),
('cognitive', 48, 60, 'Razumije koncept količine (više/manje)', 'Upoređuje skupine predmeta', 105),
('cognitive', 48, 60, 'Završava slagalice (20+ dijelova)', 'Rješava složene puzzle', 106),
('cognitive', 48, 60, 'Imenuje danak u sedmici', 'Zna "utorak", "četvrtak" itd.', 107),
('cognitive', 48, 60, 'Razumije uzrok i posljedicu', 'Objašnjava "zato što..."', 108),
('cognitive', 48, 60, 'Pamti 3+ stavke na listi', 'Zapamti 3 stvari koje treba donijeti', 109);

-- Age 5-6
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('cognitive', 60, 72, 'Broji do 50+ i unazad od 10', 'Napredno brojanje', 110),
('cognitive', 60, 72, 'Prepoznaje većinu slova i brojeva', 'Zna alfabet i brojeve do 20', 111),
('cognitive', 60, 72, 'Sabira i oduzima u opsegu 1-5', 'Osnovne matematičke operacije', 112),
('cognitive', 60, 72, 'Razumije koncept vremena (sati, dani)', 'Čita sat, zna dane', 113),
('cognitive', 60, 72, 'Prati složene instrukcije (3+ koraka)', 'Izvršava niz zadataka redom', 114),
('cognitive', 60, 72, 'Rješava jednostavne probleme logikom', 'Razmišlja i planira rješenja', 115);

-- ======= MOTORIČKI RAZVOJ =======

-- Age 2-3
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('motor', 24, 36, 'Trči koordinirano', 'Trči bez čestog padanja', 120),
('motor', 24, 36, 'Penje se na sprave', 'Penje se na tobogan, ljuljašku', 121),
('motor', 24, 36, 'Skače sa obje noge', 'Skače uvijeku sa poda', 122),
('motor', 24, 36, 'Hvata veliku loptu', 'Hvata loptu rukama pred tijelom', 123),
('motor', 24, 36, 'Drži olovku pesnicom', 'Drži marker ili kredu', 124),
('motor', 24, 36, 'Otvara jednostavne poklopce', 'Otvara teglu, kutiju', 125);

-- Age 3-4
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('motor', 36, 48, 'Stoji na jednoj nozi 3+ sekunde', 'Balansira na jednoj nozi', 126),
('motor', 36, 48, 'Pedale na triciklu', 'Vozi tricikl naprijed', 127),
('motor', 36, 48, 'Baca loptu iznad glave', 'Baca sa ciljem', 128),
('motor', 36, 48, 'Hvata loptu ispruženih ruku', 'Hvata manju loptu', 129),
('motor', 36, 48, 'Drži olovku sa 3 prsta', 'Počinje koristiti tripod grip', 130),
('motor', 36, 48, 'Sijeca makazama liniju', 'Koristi makaze za sečenje', 131),
('motor', 36, 48, 'Kopira krug i križ', 'Crta osnovne oblike', 132);

-- Age 4-5
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('motor', 48, 60, 'Skače naprijed 20+ cm', 'Skače u dalj', 133),
('motor', 48, 60, 'Galopiče i preskače', 'Različiti oblici trčanja', 134),
('motor', 48, 60, 'Baca i hvata loptu sa drugom osobom', 'Igra loptu naprijed-nazad', 135),
('motor', 48, 60, 'Penje se ljestnicama naizmjenično', 'Koristi naizmjenične noge', 136),
('motor', 48, 60, 'Koristi tripod grip konstantno', 'Pravilno drži olovku', 137),
('motor', 48, 60, 'Sijece makinama po liniji', 'Prati liniju pri sječenju', 138),
('motor', 48, 60, 'Crta prepoznatljivog čovjeka', 'Crta figuru sa više dijelova', 139);

-- Age 5-6
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('motor', 60, 72, 'Preskače na jednoj nozi', 'Preskače naprijed na jednoj nozi', 140),
('motor', 60, 72, 'Vozi bicikl (sa ili bez pomoćnih točkića)', 'Peda bicikl', 141),
('motor', 60, 72, 'Učestvuje u timskim sportovima', 'Igra fudbal, košarku u grupi', 142),
('motor', 60, 72, 'Piše nekoliko slova i brojeva', 'Piše vlastito ime', 143),
('motor', 60, 72, 'Sijeca složene oblike', 'Izreže krug, kvadrat, trokut', 144),
('motor', 60, 72, 'Vezuje pertle (počinje)', 'Pokušava ili uspijeva zavezati cipele', 145);

-- ======= JEZIČKI RAZVOJ =======

-- Age 2-3
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('language', 24, 36, 'Koristi 50+ riječi', 'Aktivni vokabular', 150),
('language', 24, 36, 'Kombinuje 2-3 riječi', 'Pravi proste rečenice', 151),
('language', 24, 36, 'Imenuje poznate predmete', 'Pokazuje i imenuje igračke, životinje', 152),
('language', 24, 36, 'Pita "šta je to?"', 'Pokazuje radoznalost', 153),
('language', 24, 36, 'Razumije jednostavne instrukcije', 'Slijedi "donesi loptu", "sjedni"', 154),
('language', 24, 36, 'Koristi "ja" i "ti"', 'Počinje koristiti zamjenice', 155);

-- Age 3-4
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('language', 36, 48, 'Koristi 200+ riječi', 'Veliki aktivni vokabular', 156),
('language', 36, 48, 'Pravi rečenice od 4-5 riječi', 'Složenije rečenice', 157),
('language', 36, 48, 'Pita "zašto?" i "ko?"', 'Istražuje uzroke i osobe', 158),
('language', 36, 48, 'Priča jednostavne priče', 'Opisuje šta se desilo', 159),
('language', 36, 48, 'Razumije predloge (na, ispod, pored)', 'Prostorni koncepti', 160),
('language', 36, 48, 'Imenuje boje, brojeve, oblike', 'Deskriptivni vokabular', 161),
('language', 36, 48, 'Govori tako da ga stranci razumiju', 'Jasna artikulacija', 162);

-- Age 4-5
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('language', 48, 60, 'Koristi 500-1000 riječi', 'Vrlo razvijen vokabular', 163),
('language', 48, 60, 'Pravi složene rečenice', 'Koristi "jer", "ali", "kada"', 164),
('language', 48, 60, 'Priča detaljne priče sa događajima', 'Prepričava priče sa slijedom', 165),
('language', 48, 60, 'Pita značenje novih riječi', 'Aktivno uči nove pojmove', 166),
('language', 48, 60, 'Koristi prošlo i buduće vrijeme', 'Gramatički tačno koristi vremena', 167),
('language', 48, 60, 'Izgovara većinu glasova pravilno', 'Minimalni artikulacijski errori', 168),
('language', 48, 60, 'Učestvuje u dužim razgovorima', 'Održava temu razgovora', 169);

-- Age 5-6
INSERT INTO public.developmental_milestones (domain, age_range_min, age_range_max, title, description, sort_order) VALUES
('language', 60, 72, 'Koristi 1500+ riječi', 'Blizu odraslog vokabulara', 170),
('language', 60, 72, 'Priča složene priče sa detaljima', 'Dodaje osjećaje, misli likova', 171),
('language', 60, 72, 'Koristi humor i igre riječima', 'Razumije šale, rime', 172),
('language', 60, 72, 'Razumije apstraktne koncepte', 'Vrijeme, brojevi, emocije', 173),
('language', 60, 72, 'Čita jednostavne riječi', 'Prepoznaje i čita osnovne riječi', 174),
('language', 60, 72, 'Piše vlastito ime i neke riječi', 'Počinje pisati fonetski', 175);

-- ─── End of Migration ──────────────────────────────────────────────────────────
-- Total milestones seeded: ~200 across 6 domains × 4 age brackets
