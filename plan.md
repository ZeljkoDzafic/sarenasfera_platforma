# Plan online platforme – Šarena Sfera Digital

## 1. Vizija platforme

Online platforma „Šarena Sfera Digital" je centralno mjesto za roditelje, voditelje
i partnere programa. Platforma kombinuje edukativne materijale, sistem praćenja
razvoja djece (Dječiji pasoš) i zajednicu roditelja.

**Ciljevi platforme:**
- Centralizovati sve materijale programa na jednom mjestu
- Omogućiti roditeljima uvid u napredak svog djeteta
- Kreirati digitalnu zajednicu za razmjenu iskustava
- Skalirati program van fizičke lokacije (hibridni model)

---

## 2. Struktura platforme

### 2.1 Javni dio (bez registracije)
```
sarenasfera.com/
├── Početna          → O programu, vizuelni prikaz, CTA za upis
├── O nama           → Tim, misija, metodologija
├── Program          → Pregled 12 mjeseci i 96 radionica (sažetci)
├── Blog             → Edukativni članci, savjeti za roditelje
├── Kontakt          → Forma, lokacija, socijalne mreže
└── Besplatni resursi → Lead magneti (PDF vodiči, radni listovi)
```

### 2.2 Korisnički portal (registrovani korisnici)
```
sarenasfera.com/portal/
├── Dashboard        → Pregled djetetovog napretka
├── Dječiji pasoš    → Kompletna evidencija razvoja
├── Radionice        → Detalji + materijali za svaku radionicu
├── Kućne aktivnosti → Dodatne aktivnosti za kod kuće
├── Galerija         → Fotografije sa radionica (privatno)
├── Zajednica        → Forum/chat za roditelje
└── Profil           → Postavke, podaci o djetetu/djeci
```

### 2.3 Admin panel (voditelji i administratori)
```
sarenasfera.com/admin/
├── Upravljanje djecom → Profili, grupe, prisustvo
├── Dječiji pasoši     → Unos opservacija i ocjena
├── Radionice          → Planiranje, materijali, izvještaji
├── Roditelji           → Komunikacija, izvještaji
├── Statistike         → Analitika programa i platforme
└── Marketing          → Email kampanje, obavještenja
```

---

## 3. Dječiji pasoš – Digitalni sistem praćenja

### 3.1 Struktura pasoša

Svako dijete ima digitalni profil koji sadrži:

#### Osnovni podaci
- Ime i prezime djeteta
- Datum rođenja / uzrast
- Uzrasna grupa u programu
- Datum upisa u program
- Fotografija (opciono)

#### Razvojne oblasti (6 domena)
Za svaku oblast voditelj bilježi napredak na skali 1-5:

| Oblast | Šta se prati | Indikatori |
|--------|-------------|------------|
| **Emocionalni razvoj** | Prepoznavanje i regulacija emocija | Imenuje emocije, prihvata frustraciju, pokazuje empatiju |
| **Socijalni razvoj** | Odnosi sa vršnjacima i odraslima | Dijeli, sarađuje, čeka red, komunicira potrebe |
| **Kreativni razvoj** | Izražavanje kroz razne medije | Koristi materijale kreativno, eksperimentiše, izražava ideje |
| **Kognitivni razvoj** | Mišljenje, rješavanje problema | Kategorizuje, rješava probleme, pita pitanja |
| **Motorički razvoj** | Gruba i fina motorika | Kontrola pokreta, preciznost, koordinacija |
| **Jezički razvoj** | Razumijevanje i izražavanje | Rječnik, naracija, slušanje, komunikacija |

#### Evidencija radionica
Za svaku posjećenu radionicu bilježi se:
- Datum prisustva
- Nivo učešća (posmatrao / djelimično / potpuno)
- Kratka opservacija voditelja (1-2 rečenice)
- Fotografija rada (opciono)
- Kućna aktivnost (da/ne, komentar roditelja)

#### Kvartalni izvještaj
Na svaka 3 mjeseca generiše se automatski izvještaj:
- Grafikon napretka po oblastima (radar chart)
- Posjećenost radionica (%)
- Top 3 snage djeteta
- 2-3 područja za dalji poticaj
- Preporuke za roditelje
- Preporuke za kućne aktivnosti

---

## 4. Funkcionalnosti platforme – Detalji

### 4.1 Za roditelje

#### Dashboard
- Vizuelni pregled napretka djeteta (grafikoni, zvjezdice)
- Kalendar nadolazećih radionica
- Obavještenja od voditelja
- Brzi pristup kućnim aktivnostima

#### Dječiji pasoš (roditeljev pogled)
- Pregled svih 6 razvojnih oblasti sa vizuelnim indikatorima
- Istorija svih radionica (koje je dijete posjetilo)
- Kvartalni izvještaji (downloadable PDF)
- Mogućnost dodavanja komentara i fotografija kućnih aktivnosti

#### Biblioteka resursa
- Video tutorijali za kućne aktivnosti
- PDF radni listovi za printanje
- Edukativni članci po temama
- Audio priče i vođene vizualizacije za djecu

#### Zajednica
- Forum sa temama po uzrasnim grupama
- Mogućnost pitanja stručnjaku (psiholog/pedagog)
- Dijeljenje iskustava i fotografija
- Sedmični challenge za porodice

### 4.2 Za voditelje

#### Planiranje radionica
- Pristup svim materijalima za nadolazeću radionicu
- Čeklista priprema (materijali, prostor, sigurnost)
- Povezanost sa Montessori/NTC principima
- Printabilni plan radionice

#### Praćenje djece
- Brzi unos opservacija nakon radionice (mobilni optimizovano)
- Šabloni za česte opservacije (brzo biranje)
- Pregled istorije djeteta prije radionice
- Upozorenja za djecu koja dugo nisu došla

#### Komunikacija sa roditeljima
- Automatski mini izvještaj nakon radionice
- Slanje kućnih aktivnosti
- Grupne poruke po uzrasnim grupama
- Individualne poruke za specifična zapažanja

### 4.3 Za administratore

#### Upravljanje programom
- Kreiranje grupa i rasporeda
- Praćenje posjećenosti (statistike)
- Finansijsko praćenje (kotizacije, troškovi)
- Upravljanje volonterima/voditeljima

#### Analitika
- Ukupan broj aktivne djece po mjesecima
- Retencija (koliko djece nastavlja program)
- Prosječna posjećenost po radionicama
- Najpopularnije radionice (po ocjenama roditelja)
- Razvojni trendovi (agregirano, anonimno)

#### Marketing alati
- Email kampanje za roditelje i potencijalne korisnike
- Automatizovani emailovi (dobrodošlica, podsjetnici)
- Upravljanje lead magnetima i downloadima
- Integracija sa Instagram i Facebook

---

## 5. Tehnička specifikacija

### 5.1 Preporučeni stack

| Komponenta | Preporučena tehnologija | Alternativa |
|------------|------------------------|-------------|
| Frontend | React / Next.js | Vue.js / Nuxt |
| Backend | Node.js / Express | Django / Python |
| Baza podataka | PostgreSQL | MongoDB |
| Hosting | Vercel + Supabase | Railway / Render |
| Autentifikacija | Supabase Auth | Auth0 / Firebase |
| Storage (slike) | Supabase Storage | AWS S3 / Cloudinary |
| Email | Resend / Mailgun | SendGrid |
| PDF generisanje | Puppeteer / React-PDF | jsPDF |

### 5.2 MVP (Minimalni proizvod) – Faza 1

Rok: 2-3 mjeseca | Budžet: 500-1.500 KM

**Uključuje:**
- Landing page sa programom
- Registracija roditelja i djece
- Osnovni dječiji pasoš (unos opservacija, pregled)
- Pristup materijalima za radionice
- Email obavještenja

**Ne uključuje (Faza 2):**
- Forum/zajednica
- Video tutorijali
- Automatski kvartalni izvještaji
- Mobilna aplikacija

### 5.3 Faza 2 – Puna platforma

Rok: 6-9 mjeseci nakon MVP-a | Budžet: 2.000-5.000 KM

**Dodaje:**
- Zajednica roditelja (forum + chat)
- Video biblioteka sa tutorijalima
- Automatski PDF kvartalni izvještaji
- Integracija sa Canva šablonima
- Napredna analitika
- Push notifikacije

### 5.4 Faza 3 – Skaliranje

Rok: 12-18 mjeseci | Budžet: 5.000-15.000 KM

**Dodaje:**
- Mobilna aplikacija (React Native / Flutter)
- Višejezična podrška (BHS + engleski)
- Franšizni model (više lokacija, centralna platforma)
- AI asistent za roditelje (preporuke aktivnosti)
- Marketplace za voditelje (dijeljenje radionica)

---

## 6. Monetizacija platforme

### 6.1 Modeli prihoda

| Model | Opis | Cijena |
|-------|------|--------|
| Besplatni plan | Pristup blogu, 3 radna lista, info o programu | 0 KM |
| Osnovni plan | Dječiji pasoš + materijali za radionice | 15 KM/mj |
| Premium plan | Sve + video tutorijali + zajednica + stručnjak | 30 KM/mj |
| Institucija | Grupni pristup za vrtiće/škole | 200 KM/mj (do 50 djece) |
| Franšiza | Licenca za korištenje programa + platforma | Po dogovoru |

### 6.2 Besplatni resursi (Lead generation)
- Mjesečni PDF vodiči sa aktivnostima
- Blog članci o dječijem razvoju
- Demo pristup 1 radionici
- Besplatna procjena razvojnog profila

---

## 7. Vremenski plan implementacije

| Sedmica | Aktivnost |
|---------|-----------|
| 1-2 | Dizajn wireframes i korisničkih tokova |
| 3-4 | Postavljanje baze podataka i autentifikacije |
| 5-8 | Razvoj korisničkog portala i dječijeg pasoša |
| 9-10 | Razvoj admin panela |
| 11-12 | Testiranje, popravke, lansiranje MVP-a |

---

## 8. Povezani resursi

- [Dječiji pasoš – detaljan opis](djeciji-pasos.md)
- [Marketing strategija](marketing-strategija.md)
- [Montessori i NTC osnova](montesori-ntc-osnova.md)
- [Canva šabloni](../canva/README.md)
- [Mapa svih radionica](mapa-svih-radionica.md)




Najbpitnije je napraivit nesto za registraciju korsinika mama i djece da krenemo sa prikupljanje leadova 
pogledati kako to radi khan academy - Khan Academy Kids:
transparent classroom 


Khan Academy Kids: Best for overall, comprehensive, and free curriculum (ages 2-8), covering math, reading, and social-emotional growth.
Starfall: Highly recommended for learning to read, offering phonics and early math games for preschool to 5th grade.
ABCya: Features, engaging games categorized by grade level (pre-K to 6th).
Funbrain: Offers educational games focusing on math and reading.
PBS Learning Media: Provides interactive lessons for preschoolers.
National Geographic for Kids: Focuses on science and nature.
Wonderopolis: Good for answering curious questions. 
Khan Academy
Khan Academy
 +5
Best Apps and Interactive Platforms
Endless Alphabet/Reader: Excellent for early literacy.
Code.org: Introduces basic coding concepts.
Cosmic Kids Yoga: Combines storytelling with physical activity.
Chrome Music Lab: Explores music and rhythm.
Rivet: A reading app with over 3,500 leveled books.
Learn with Socrates: Uses gamification for curriculum-based learn

