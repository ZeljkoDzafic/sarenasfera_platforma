-- ─── Seed Data for Development ───────────────────────────────────────────────
-- T-103: Seed Data
-- Migration: 018_seed.sql
-- NOTE: This is development seed data. Do NOT run in production.

-- ─── Seed: Blog Posts ────────────────────────────────────────────────────────
INSERT INTO public.blog_posts (slug, title, excerpt, content, category, tags, is_published, is_featured, author_name, read_time_minutes, published_at)
VALUES
  (
    'kako-razgovarati-s-djetetom-o-emocijama',
    'Kako razgovarati s djetetom o emocijama',
    'Emocionalna pismenost počinje već od 2. godine. Otkrijte jednostavne tehnike kojima možete pomoći djetetu da razumije i imenuje svoja osjećanja.',
    'Djeca ne znaju automatski kako da imenuju i upravljaju emocijama. To je vještina koja se uči — baš kao čitanje ili vožnja bicikla. Istraživanja pokazuju da djeca čiji roditelji redovno razgovaraju o emocijama razvijaju bolju emocionalnu regulaciju, više empatije prema drugima i bolji akademski uspjeh. Kako početi? Imenujte emocije koje vidite: "Vidim da si ljut jer je zauzeta tvoja igračka." Normalizujte sve emocije: "Normalno je biti tužan." Pokažite vlastite emocije.',
    'Emocionalni razvoj',
    ARRAY['emocije', 'komunikacija', 'roditelji', 'emocionalni-razvoj'],
    true, true, 'Amina Hodžić', 5, now() - interval '7 days'
  ),
  (
    '10-aktivnosti-za-razvoj-fine-motorike',
    '10 aktivnosti za razvoj fine motorike kod kuće',
    'Rezanje, lijepljenje, crtanje, sortiranje — sve to gradi fine motoričke vještine. Evo 10 aktivnosti s materijalima iz svake kuhinje.',
    'Fina motorika — koordinacija malih mišića ruku i prstiju — ključna je za pisanje, crtanje i mnoge svakodnevne aktivnosti. Dobra vijest: razvija se kroz svakodnevne aktivnosti koje se djeci čine kao igra. 1) Sipanje riže između posuda 2) Sortiranje gumba po boji 3) Trganje papira i pravljenje kolaža 4) Modeliranje plastelinom 5) Rezanje tupim nožem 6) Nizanje tjestenine na žicu 7) Crtanje prstima u pijesku 8) Lijepljenje naljepnica 9) Otvaranje i zatvaranje patentnih zatvarača 10) Hvatanje graha pincetom.',
    'Motorički razvoj',
    ARRAY['motorika', 'aktivnosti', 'kuhinja', 'fina-motorika'],
    true, false, 'Selma Begović', 4, now() - interval '14 days'
  ),
  (
    'zasto-je-slobodna-igra-vazna',
    'Zašto je slobodna igra najvažnija "aktivnost" za dijete',
    'U doba prekrcanih rasporeda i edukativnih igračaka — nauka kaže da djeca uče najviše kroz slobodnu, nestrukturiranu igru.',
    'Slobodna igra nije "nedjelovanje" — to je kako djeca uče donositi odluke, rješavati probleme, biti kreativni i regulirati emocije. Studija Harvarda pokazuje da djeca koja imaju više slobodne igre razvijaju bolje izvršne funkcije mozga. Savjeti: rezervirajte svaki dan barem 1 sat potpuno slobodne igre bez ekrana. Neka dijete samo bira šta će raditi. Vaša uloga je posmatrač, ne vodič.',
    'Kreativni razvoj',
    ARRAY['igra', 'slobodna-igra', 'kreativnost', 'razvoj'],
    true, false, 'Dina Husić', 3, now() - interval '21 days'
  )
ON CONFLICT (slug) DO NOTHING;

-- ─── Seed: Resources ─────────────────────────────────────────────────────────
INSERT INTO public.resources (title, description, resource_type, category, requires_email, min_tier, is_published)
VALUES
  ('Vodič za emocionalni razvoj 2–4 god.', 'Praktični vodič za roditelje: kako podržati emocionalni razvoj djeteta od 2 do 4 godine kroz svakodnevne aktivnosti.', 'pdf', 'Emocionalni razvoj', true, 'free', true),
  ('50 aktivnosti za motorički razvoj', 'Kolekcija 50 aktivnosti za razvoj grube i fine motorike kod djece 2–6 godina. S materijalima koje imate doma.', 'pdf', 'Motorički razvoj', true, 'free', true),
  ('Kako čitati djetetu (i zašto)', 'Vodič za zajedničko čitanje: tehnika "dialogic reading" koja ubrzava jezički razvoj kod djece do 5 godina.', 'guide', 'Jezički razvoj', true, 'free', true),
  ('Plan kućnih aktivnosti — 4 sedmice', 'Gotov plan kućnih aktivnosti za 4 sedmice, temeljen na Montessori principima. Po jednoj aktivnosti dnevno.', 'pdf', 'Program', true, 'paid', true)
ON CONFLICT DO NOTHING;

-- ─── Seed: Weekly challenge ───────────────────────────────────────────────────
INSERT INTO public.weekly_challenges (title, description, instructions, week_number, year, is_active)
VALUES (
  'Kutija emocija',
  'Napravite sa djetetom "kutiju emocija" — kutiju u kojoj imate kartice s lica koja pokazuju različite emocije.',
  '1. Uzmite praznu kutiju ili zdjelu. 2. Izrežite lica iz starih časopisa ili nacrtajte s djetetom. 3. Svaki dan vadite jednu karticu i razgovarajte: "Kada se ti tako osjećaš?" 4. Pohvalite dijete za svaki odgovor.',
  EXTRACT(WEEK FROM now())::INTEGER,
  EXTRACT(YEAR FROM now())::INTEGER,
  true
) ON CONFLICT DO NOTHING;

-- ─── Seed: Observation Templates ─────────────────────────────────────────────
INSERT INTO public.observation_templates (skill_area_id, content, has_placeholder, is_system)
SELECT id, 'Dijete je spontano imenovalo emociju {emocija} bez poticaja odrasle osobe.', true, true FROM public.skill_areas WHERE key = 'emotional'
ON CONFLICT DO NOTHING;

INSERT INTO public.observation_templates (skill_area_id, content, has_placeholder, is_system)
SELECT id, 'Dijete je sarađivalo sa vršnjacima tokom grupne aktivnosti bez sukoba.', false, true FROM public.skill_areas WHERE key = 'social'
ON CONFLICT DO NOTHING;

INSERT INTO public.observation_templates (skill_area_id, content, has_placeholder, is_system)
SELECT id, 'Dijete je koristilo materijale na originalan, neočekivan način.', false, true FROM public.skill_areas WHERE key = 'creative'
ON CONFLICT DO NOTHING;

INSERT INTO public.observation_templates (skill_area_id, content, has_placeholder, is_system)
SELECT id, 'Dijete je samostalno riješilo problem {opis} bez traženja pomoći.', true, true FROM public.skill_areas WHERE key = 'cognitive'
ON CONFLICT DO NOTHING;

INSERT INTO public.observation_templates (skill_area_id, content, has_placeholder, is_system)
SELECT id, 'Dijete je pokazalo dobru koordinaciju i preciznost pri {aktivnost}.', true, true FROM public.skill_areas WHERE key = 'motor'
ON CONFLICT DO NOTHING;

INSERT INTO public.observation_templates (skill_area_id, content, has_placeholder, is_system)
SELECT id, 'Dijete je jasno i razumljivo ispričalo kratku priču sa početkom i krajem.', false, true FROM public.skill_areas WHERE key = 'language'
ON CONFLICT DO NOTHING;
