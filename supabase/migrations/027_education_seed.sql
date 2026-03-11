-- T-1015: Education seed data for development/demo
-- NOTE: Development seed only. Intended for local/dev environments.

DELETE FROM public.educational_content
WHERE slug IN (
  'siguran-pocetak-emocije-2-4',
  'igra-koja-gradi-govor-3-6',
  'porodicna-radionica-senzorna-igra-april',
  'webinar-kako-postaviti-rutine-bez-suza',
  'open-day-probni-dan-u-sarenoj-sferi',
  'mini-vodic-za-jutarnje-rutine',
  'kako-podrzati-samoregulaciju-kod-kuce',
  'pdf-20-igara-za-finomotoriku',
  'pdf-jezicke-igre-za-put-kuci',
  'video-5-minuta-za-smirivanje-prije-spavanja'
);

INSERT INTO public.educational_content (
  title,
  slug,
  description,
  short_description,
  content_type,
  domain,
  age_min,
  age_max,
  required_tier,
  status,
  duration_minutes,
  difficulty_level,
  meta_title,
  meta_description,
  published_at,
  starts_at,
  ends_at,
  location_type,
  location_name,
  location_url,
  capacity,
  event_subtype
)
VALUES
  (
    'Siguran početak: emocije od 2 do 4 godine',
    'siguran-pocetak-emocije-2-4',
    'Online kurs za roditelje koji žele razumjeti prve velike emocije, postaviti mirne granice i graditi osjećaj sigurnosti kroz svakodnevne rutine.',
    'Praktičan kurs o emocijama, granicama i povezanosti za roditelje djece od 2 do 4 godine.',
    'course',
    'emotional',
    2,
    4,
    'paid',
    'published',
    135,
    'beginner',
    'Siguran početak: emocije od 2 do 4 godine',
    'Kurs za roditelje o emocionalnom razvoju, granicama i sigurnoj povezanosti.',
    now() - interval '5 days',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  ),
  (
    'Igra koja gradi govor: jezik i komunikacija od 3 do 6 godina',
    'igra-koja-gradi-govor-3-6',
    'Kurs koji roditeljima pokazuje kako kroz igru, priču, svakodnevne rituale i male izazove razvijati govor, rječnik i samopouzdanje djeteta.',
    'Kurs o razvoju jezika, pričanju, slušanju i komunikaciji kroz igru.',
    'course',
    'language',
    3,
    6,
    'premium',
    'published',
    150,
    'beginner',
    'Igra koja gradi govor: jezik i komunikacija od 3 do 6 godina',
    'Online kurs za roditelje o jeziku, pričanju i komunikacijskim rutinama.',
    now() - interval '4 days',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  ),
  (
    'Porodična radionica: senzorna igra bez nereda',
    'porodicna-radionica-senzorna-igra-april',
    'Praktična offline radionica za roditelje i djecu. Pokazujemo kako postaviti senzorne stanice kod kuće uz jednostavne materijale i jasne granice.',
    'Offline radionica za porodice o senzornoj igri i kućnim stanicama.',
    'event',
    'creative',
    2,
    5,
    'free',
    'published',
    90,
    'beginner',
    'Porodična radionica: senzorna igra bez nereda',
    'Besplatna porodična radionica o senzornoj igri za djecu 2-5 godina.',
    now() - interval '2 days',
    now() + interval '14 days',
    now() + interval '14 days' + interval '90 minutes',
    'in_person',
    'Šarena Sfera Banja Luka',
    'https://maps.google.com/?q=Sarena+Sfera+Banja+Luka',
    20,
    'workshop'
  ),
  (
    'Webinar: kako postaviti rutine bez suza',
    'webinar-kako-postaviti-rutine-bez-suza',
    'Online webinar za roditelje koji žele jutarnje, večernje i prelazne rutine učiniti mirnijim, predvidljivijim i lakšim za cijelu porodicu.',
    'Webinar o mirnim rutinama, prijelazima i manje konflikta kod kuće.',
    'webinar',
    'social',
    2,
    6,
    'paid',
    'published',
    75,
    'beginner',
    'Webinar: kako postaviti rutine bez suza',
    'Online webinar za roditelje o rutinama, granicama i saradnji.',
    now() - interval '1 day',
    now() + interval '21 days',
    now() + interval '21 days' + interval '75 minutes',
    'online',
    'Zoom webinar Šarena Sfera',
    'https://zoom.us/j/1234567890',
    100,
    NULL
  ),
  (
    'Open day: probni dan u Šarenoj Sferi',
    'open-day-probni-dan-u-sarenoj-sferi',
    'Otvoren dan za roditelje koji žele upoznati prostor, tim i način rada prije upisa. Uključuje kratke aktivnosti za djecu i Q&A za roditelje.',
    'Probni dan, obilazak prostora i upoznavanje tima prije upisa.',
    'event',
    'cognitive',
    2,
    6,
    'free',
    'published',
    120,
    'beginner',
    'Open day: probni dan u Šarenoj Sferi',
    'Otvoreni dan za nove porodice uz obilazak i kratke aktivnosti.',
    now() - interval '1 day',
    now() + interval '28 days',
    now() + interval '28 days' + interval '120 minutes',
    'in_person',
    'Šarena Sfera Banja Luka',
    'https://maps.google.com/?q=Sarena+Sfera+Banja+Luka',
    40,
    'open_day'
  ),
  (
    'Mini vodič za jutarnje rutine',
    'mini-vodic-za-jutarnje-rutine',
    'Kratak članak za roditelje koji žele manje žurbe, manje pregovaranja i više saradnje tokom jutarnjih priprema.',
    'Članak s konkretnim koracima za mirnije jutro.',
    'resource',
    'social',
    2,
    6,
    'free',
    'published',
    8,
    'beginner',
    'Mini vodič za jutarnje rutine',
    'Članak s kratkim planom za mirnija i predvidljivija jutra.',
    now() - interval '6 days',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  ),
  (
    'Kako podržati samoregulaciju kod kuće',
    'kako-podrzati-samoregulaciju-kod-kuce',
    'Članak o tome kako prepoznati preopterećenje, usporiti tempo i pomoći djetetu da se vrati u ravnotežu bez kažnjavanja i posramljivanja.',
    'Članak o samoregulaciji, smirivanju i podršci kod kuće.',
    'resource',
    'emotional',
    2,
    6,
    'paid',
    'published',
    10,
    'beginner',
    'Kako podržati samoregulaciju kod kuće',
    'Praktičan tekst za roditelje o emocijama i regulaciji.',
    now() - interval '4 days',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  ),
  (
    'PDF: 20 igara za finomotoriku',
    'pdf-20-igara-za-finomotoriku',
    'PDF vodič sa 20 kratkih aktivnosti za razvoj šake, prstiju i koordinacije kroz kućne materijale i brzu pripremu.',
    'PDF vodič s igrama za razvoj fine motorike.',
    'resource',
    'motor',
    2,
    5,
    'free',
    'published',
    15,
    'beginner',
    'PDF: 20 igara za finomotoriku',
    'Praktični PDF s aktivnostima za finu motoriku.',
    now() - interval '8 days',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  ),
  (
    'PDF: jezičke igre za put kući',
    'pdf-jezicke-igre-za-put-kuci',
    'PDF materijal sa kratkim verbalnim igrama koje roditelji mogu koristiti u autu, šetnji ili čekanju bez dodatnih rekvizita.',
    'PDF sa jezičkim igrama za svakodnevne prijelaze i čekanja.',
    'resource',
    'language',
    3,
    6,
    'premium',
    'published',
    12,
    'beginner',
    'PDF: jezičke igre za put kući',
    'Praktični PDF za razvoj jezika tokom svakodnevnih prijelaza.',
    now() - interval '3 days',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  ),
  (
    'Video: 5 minuta za smirivanje prije spavanja',
    'video-5-minuta-za-smirivanje-prije-spavanja',
    'Kratka video lekcija za roditelje sa večernjom rutinom disanja, dodira i povezivanja prije spavanja.',
    'Video rutina za smirivanje i povezivanje prije spavanja.',
    'resource',
    'emotional',
    2,
    6,
    'premium',
    'published',
    5,
    'beginner',
    'Video: 5 minuta za smirivanje prije spavanja',
    'Kratak video za večernju rutinu smirivanja.',
    now() - interval '2 days',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  );

DO $$
DECLARE
  course_emotions_id UUID;
  course_language_id UUID;
  module_id UUID;
BEGIN
  SELECT id INTO course_emotions_id
  FROM public.educational_content
  WHERE slug = 'siguran-pocetak-emocije-2-4';

  INSERT INTO public.course_modules (course_id, title, description, sort_order)
  VALUES
    (course_emotions_id, 'Temelji sigurnosti i povezanosti', 'Kako dijete čita naš ton, ritam i predvidljivost u svakodnevici.', 0)
  RETURNING id INTO module_id;

  INSERT INTO public.course_lessons (module_id, title, slug, description, content_html, lesson_type, is_preview, sort_order)
  VALUES
    (module_id, 'Zašto su male rutine velika stvar', 'rutine-su-velika-stvar', 'Uvod u osjećaj sigurnosti kod malog djeteta.', '<p>Djeca se osjećaju sigurnije kada mogu predvidjeti šta dolazi dalje. Ne treba vam savršen raspored, nego nekoliko stabilnih tačaka u danu: buđenje, obrok, odlazak vani i spavanje.</p><p>Kada je odrasla osoba mirna i dosljedna, dijete lakše sarađuje i brže uči šta se od njega očekuje.</p>', 'content', true, 0),
    (module_id, 'Kako prepoznati preplavljenost', 'kako-prepoznati-preplavljenost', 'Signali da je dijete otišlo preko svoje mjere.', '<p>Preplavljenost ne izgleda uvijek kao plač. Nekad je to trčanje bez cilja, odbijanje, bacanje stvari ili nagli umor. Posmatrajte tijelo, ne samo riječi.</p><p>Kada prepoznate rane znakove, lakše je pomoći djetetu prije nego što se potpuno raspadne ritam.</p>', 'content', false, 1),
    (module_id, 'Povezivanje prije ispravljanja', 'povezivanje-prije-ispravljanja', 'Zašto odnos ide prije korekcije ponašanja.', '<p>Kad je dijete uznemireno, prvo mu treba osjećaj da ste uz njega. Spustite se u njegov nivo, govorite sporije i kratkim rečenicama. Tek kad se tijelo smiri, dijete može čuti granicu.</p>', 'content', false, 2),
    (module_id, 'Tri rečenice koje pomažu', 'tri-recenice-koje-pomazu', 'Jezik koji smanjuje otpor.', '<p>Probajte: "Vidim da ti je teško.", "Tu sam.", "Uradićemo ovo zajedno." Ove rečenice ne znače popuštanje, nego vraćanje sigurnosti prije sljedećeg koraka.</p>', 'content', false, 3),
    (module_id, 'Mini zadatak za ovu sedmicu', 'mini-zadatak-sedmica-jedan', 'Mala promjena koju uvodite odmah.', '<p>Odaberite jednu rutinu u kojoj ćete narednih sedam dana usporiti tempo i ponavljati iste dvije rečenice. Posmatrajte šta se mijenja u reakciji djeteta.</p>', 'assignment', false, 4);

  INSERT INTO public.course_modules (course_id, title, description, sort_order)
  VALUES
    (course_emotions_id, 'Velike emocije bez velikog haosa', 'Praktične strategije za ljutnju, tugu, frustraciju i prijelaze.', 1)
  RETURNING id INTO module_id;

  INSERT INTO public.course_lessons (module_id, title, slug, description, content_html, lesson_type, is_preview, sort_order)
  VALUES
    (module_id, 'Šta stoji iza tantruma', 'sta-stoji-iza-tantruma', 'Razlika između neposluha i preopterećenosti.', '<p>Tantrum nije plan protiv roditelja. Najčešće je znak da su emocije i potrebe veće od kapaciteta djeteta da ih samo obradi. To ne znači da nema granica. Znači da granice uvodimo kroz regulaciju, a ne kroz borbu moći.</p>', 'content', false, 0),
    (module_id, 'Kako ostati miran kad dijete nije', 'kako-ostati-miran', 'Brza samoregulacija za roditelja.', '<p>Prvo usporite vlastito tijelo: stopala na pod, izdah duži od udaha, tiši glas. Dijete posuđuje naš nervni sistem. Ako mi planemo, i ono se dodatno uznemiri.</p>', 'content', false, 1),
    (module_id, 'Granica koja ne posramljuje', 'granica-koja-ne-posramljuje', 'Kako zaustaviti ponašanje bez etiketa.', '<p>Umjesto "Ti si bezobrazan", recite: "Neću ti dati da udaraš. Tu sam da te zaustavim." Granica je jasna, a dijete i dalje ostaje vrijedno i sigurno u odnosu.</p>', 'content', false, 2),
    (module_id, 'Prijelazi bez borbe', 'prijelazi-bez-borbe', 'Kako najaviti promjenu aktivnosti.', '<p>Mali prijelazi su veliki izazov. Pomozite djetetu najavom, vizuelnim signalom i jednim jednostavnim izborom: "Još dvije minute, pa biraj hoćeš li prvo obući jaknu ili cipele."</p>', 'content', false, 3),
    (module_id, 'Refleksija roditelja', 'refleksija-roditelja-emocije', 'Krata dnevna refleksija.', '<p>Zapišite jednu situaciju u kojoj ste uspjeli usporiti i jednu u kojoj niste. Bez kritike. Cilj je primijetiti okidače i male pomake.</p>', 'assignment', false, 4);

  INSERT INTO public.course_modules (course_id, title, description, sort_order)
  VALUES
    (course_emotions_id, 'Jezik podrške u svakodnevici', 'Kako govoriti tako da dijete osjeti sigurnost, granicu i saradnju.', 2)
  RETURNING id INTO module_id;

  INSERT INTO public.course_lessons (module_id, title, slug, description, content_html, lesson_type, is_preview, sort_order)
  VALUES
    (module_id, 'Kratke rečenice koje rade', 'kratke-recenice-koje-rade', 'Zašto manje riječi često znači više saradnje.', '<p>Kada je dijete pod stresom, dugi govori ne pomažu. Jedna jasna rečenica i miran ton imaju veći učinak od objašnjavanja u pet koraka.</p>', 'content', false, 0),
    (module_id, 'Validacija bez popuštanja', 'validacija-bez-popustanja', 'Kako priznati emociju bez odustajanja od granice.', '<p>Možete istovremeno reći: "Znam da si ljut" i "Neću ti dati da bacaš." Djeci treba i razumijevanje i okvir.</p>', 'content', false, 1),
    (module_id, 'Pohvala procesa, ne etikete', 'pohvala-procesa-ne-etikete', 'Kako graditi unutrašnju motivaciju.', '<p>Umjesto "Bravo, ti si pametan", recite: "Vidim da si pokušavao i kad je bilo teško." Tako dijete uči da je trud vrijednost, a ne samo rezultat.</p>', 'content', false, 2),
    (module_id, 'Kako pripremiti dijete za težak trenutak', 'kako-pripremiti-dijete', 'Najava i plan prije izazova.', '<p>Prije odlaska doktoru, vrtiću ili dužeg puta, prođite kroz tri koraka: šta će se desiti, šta dijete može očekivati i kako mu vi možete pomoći ako postane teško.</p>', 'content', false, 3),
    (module_id, 'Plan za narednih 14 dana', 'plan-za-14-dana-emocije', 'Završni plan primjene.', '<p>Odaberite dvije rutine i tri rečenice podrške koje ćete koristiti naredne dvije sedmice. Ostavite ih zapisane na vidljivom mjestu.</p>', 'assignment', false, 4);

  SELECT id INTO course_language_id
  FROM public.educational_content
  WHERE slug = 'igra-koja-gradi-govor-3-6';

  INSERT INTO public.course_modules (course_id, title, description, sort_order)
  VALUES
    (course_language_id, 'Temelji jezika kroz odnos', 'Kako svakodnevni kontakt, ritam i zajednička pažnja grade govor.', 0)
  RETURNING id INTO module_id;

  INSERT INTO public.course_lessons (module_id, title, slug, description, content_html, lesson_type, is_preview, sort_order)
  VALUES
    (module_id, 'Govor raste iz povezanosti', 'govor-raste-iz-povezanosti', 'Zašto djeca uče jezik kroz odnos, ne kroz pritisak.', '<p>Najviše jezika nastaje u toplom kontaktu: kada dijete gleda vaše lice, čuje ton i osjeća da se njegove poruke računaju. Ne treba stalna korekcija, nego bogat razgovor.</p>', 'content', true, 0),
    (module_id, 'Čekanje kao alat za govor', 'cekanje-kao-alat-za-govor', 'Zašto treba ostaviti prostor djetetu.', '<p>Kada stalno završavamo rečenice za dijete, oduzimamo mu priliku da pokuša. Nakon pitanja, zastanite nekoliko sekundi. Taj prostor često donese riječ više.</p>', 'content', false, 1),
    (module_id, 'Komentarisanje umjesto ispitivanja', 'komentarisanje-umjesto-ispitivanja', 'Kako govoriti tako da dijete poželi odgovoriti.', '<p>Umjesto niza pitanja, opisujte ono što zajedno radite: "Vidi, auto ide brzo." To otvara razgovor bez pritiska i poziva dijete da se uključi.</p>', 'content', false, 2),
    (module_id, 'Ritmične igre i ponavljanje', 'ritmicne-igre-i-ponavljanje', 'Kako ritam i pjesmica pomažu jeziku.', '<p>Ponavljanje u pjesmicama i kratkim igrama pomaže djeci da lakše zadrže nove riječi i obrasce. Važno je da bude zabavno i često, a ne dugo.</p>', 'content', false, 3),
    (module_id, 'Prvi kućni izazov', 'prvi-kucni-izazov-jezik', 'Zadatak za jednu sedmicu.', '<p>Izaberite jedan dio dana, na primjer oblačenje ili večeru, i pretvorite ga u rutinu sa tri iste rečenice i jednim otvorenim komentarom.</p>', 'assignment', false, 4);

  INSERT INTO public.course_modules (course_id, title, description, sort_order)
  VALUES
    (course_language_id, 'Priča, knjiga i bogat rječnik', 'Kako od običnog čitanja napraviti snažnu jezičku aktivnost.', 1)
  RETURNING id INTO module_id;

  INSERT INTO public.course_lessons (module_id, title, slug, description, content_html, lesson_type, is_preview, sort_order)
  VALUES
    (module_id, 'Kako čitati dialogički', 'kako-citati-dialogicki', 'Tehnika čitanja koja aktivira dijete.', '<p>Tokom čitanja zastanite, komentarišite slike i povezujte priču sa stvarnim iskustvima djeteta. Cilj nije završiti knjigu, nego otvoriti razgovor.</p>', 'content', false, 0),
    (module_id, 'Riječi koje vrijedi ponavljati', 'rijeci-koje-vrijedi-ponavljati', 'Kako birati nove riječi bez preopterećenja.', '<p>Birajte dvije do tri nove riječi sedmično i vraćajte im se kroz više situacija. Kada riječ živi u rutini, dijete je lakše usvaja.</p>', 'content', false, 1),
    (module_id, 'Pitanja koja šire priču', 'pitanja-koja-sire-pricu', 'Otvorena pitanja koja podstiču pričanje.', '<p>Pitajte "Šta misliš da će se dalje desiti?" ili "Kako se on sada osjeća?" Time dijete uči povezivati događaje, emocije i uzroke.</p>', 'content', false, 2),
    (module_id, 'Kad dijete ne želi slušati priču', 'kad-dijete-ne-zeli-pricu', 'Prilagodba umjesto forsiranja.', '<p>Neka dijete bira knjigu, skrati vrijeme čitanja i uvedi pokret. Nekoj djeci više odgovara da pričaju uz crtanje ili slaganje nego da sjede mirno.</p>', 'content', false, 3),
    (module_id, 'Sedmični plan čitanja', 'sedmicni-plan-citanja', 'Mali plan sa velikim učinkom.', '<p>Planirajte tri kratka čitanja od po pet minuta sedmično. Dosljednost je važnija od dužine.</p>', 'assignment', false, 4);

  INSERT INTO public.course_modules (course_id, title, description, sort_order)
  VALUES
    (course_language_id, 'Komunikacija u pokretu i svakodnevici', 'Kako govor vježbati u autu, šetnji, kupovini i igri.', 2)
  RETURNING id INTO module_id;

  INSERT INTO public.course_lessons (module_id, title, slug, description, content_html, lesson_type, is_preview, sort_order)
  VALUES
    (module_id, 'Jezičke igre bez rekvizita', 'jezicke-igre-bez-rekvizita', 'Brze igre za hodanje, čekanje i vožnju.', '<p>Igre poput "vidim nešto crveno", "ko počinje na M" ili "završi rečenicu" šire rječnik bez dodatne pripreme.</p>', 'content', false, 0),
    (module_id, 'Šta raditi kada dijete miješa glasove', 'kad-dijete-mijesa-glasove', 'Podrška bez stalnog ispravljanja.', '<p>Umjesto direktnog ispravljanja, modelujte ispravan oblik u svom odgovoru. Dijete tako čuje dobar obrazac bez osjećaja da je pogriješilo.</p>', 'content', false, 1),
    (module_id, 'Gradimo duže rečenice', 'gradimo-duze-recenice', 'Kako proširiti djetetov govor za jedan korak.', '<p>Kada dijete kaže "auto brzo", vi možete reći "Da, crveni auto ide baš brzo niz ulicu." Dodajte malo, ne previše.</p>', 'content', false, 2),
    (module_id, 'Razgovor poslije vrtića', 'razgovor-poslije-vrtica', 'Kako dobiti više od odgovora "dobro".', '<p>Umjesto "Kako je bilo?", pitajte "Šta te danas nasmijalo?" ili "Koja igra ti je bila najzanimljivija?" Konkretno pitanje otvara konkretniji odgovor.</p>', 'content', false, 3),
    (module_id, 'Završni akcioni plan', 'zavrsni-akcioni-plan-jezik', 'Kako održati navike naredni mjesec.', '<p>Izaberite tri mikrorutine: jednu za čitanje, jednu za razgovor u pokretu i jednu za proširivanje rečenica. Držite ih mjesec dana prije procjene šta djeluje.</p>', 'assignment', false, 4);
END $$;

INSERT INTO public.resource_materials (
  content_id,
  file_url,
  file_type,
  title,
  description,
  download_count,
  is_downloadable,
  content_html,
  video_url
)
SELECT
  ec.id,
  seed.file_url,
  seed.file_type,
  seed.title,
  seed.description,
  seed.download_count,
  true,
  seed.content_html,
  seed.video_url
FROM public.educational_content ec
JOIN (
  VALUES
    (
      'mini-vodic-za-jutarnje-rutine',
      'https://example.com/resources/mini-vodic-za-jutarnje-rutine',
      'article',
      'Mini vodič za jutarnje rutine',
      'HTML članak za roditelje o jutarnjim prijelazima i saradnji.',
      12,
      '<h2>Mirnije jutro počinje večer ranije</h2><p>Pripremite dvije do tri stvari unaprijed: odjeću, ranac i jedan mali izbor za dijete. Kada ujutro ima manje odluka, ima i manje napetosti.</p><h2>Držite ritam kratkim i predvidljivim</h2><p>Koristite isti redoslijed: buđenje, toalet, odijevanje, doručak, izlazak. Dijete ne treba deset podsjetnika, nego jasan tok.</p><h2>Umjesto požurivanja, dajte sidro</h2><p>Jedna rečenica poput "Sada obuvamo cipele, pa idemo zajedno" često radi bolje od višestrukih opomena.</p>',
      NULL
    ),
    (
      'kako-podrzati-samoregulaciju-kod-kuce',
      'https://example.com/resources/kako-podrzati-samoregulaciju-kod-kuce',
      'article',
      'Kako podržati samoregulaciju kod kuće',
      'HTML članak o prepoznavanju uznemirenosti i vraćanju djeteta u ravnotežu.',
      8,
      '<h2>Prvo gledamo tijelo</h2><p>Kada dijete ubrzava, gubi fokus ili se naglo povlači, često nam tijelo pokazuje da je prag preopterećenja blizu. To je trenutak za usporavanje, a ne za dodatni zahtjev.</p><h2>Napravite kutak za oporavak, ne kaznu</h2><p>Jedna dekica, jastučić, knjiga i mirniji ton mogu pomoći da se dijete vrati sebi bez srama i borbe.</p><h2>Vratite se razgovoru tek nakon smirivanja</h2><p>Kad se tijelo vrati u ravnotežu, tada razgovaramo o onome što se desilo i šta ćemo idući put pokušati drugačije.</p>',
      NULL
    ),
    (
      'pdf-20-igara-za-finomotoriku',
      'https://example.com/resources/pdf-20-igara-za-finomotoriku.pdf',
      'pdf',
      'PDF: 20 igara za finomotoriku',
      'PDF vodič sa kućnim aktivnostima za razvoj šake i prstiju.',
      25,
      NULL,
      NULL
    ),
    (
      'pdf-jezicke-igre-za-put-kuci',
      'https://example.com/resources/pdf-jezicke-igre-za-put-kuci.pdf',
      'pdf',
      'PDF: jezičke igre za put kući',
      'PDF sa kratkim verbalnim igrama za auto, šetnju i čekanje.',
      17,
      NULL,
      NULL
    ),
    (
      'video-5-minuta-za-smirivanje-prije-spavanja',
      'https://example.com/resources/video-5-minuta-za-smirivanje-prije-spavanja',
      'video',
      'Video: 5 minuta za smirivanje prije spavanja',
      'Kratka video rutina za večernje usporavanje i povezivanje.',
      9,
      NULL,
      'https://www.youtube.com/watch?v=ysz5S6PUM-U'
    )
) AS seed(slug, file_url, file_type, title, description, download_count, content_html, video_url)
  ON seed.slug = ec.slug;
