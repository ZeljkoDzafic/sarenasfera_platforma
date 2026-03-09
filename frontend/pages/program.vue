<template>
  <div>
    <!-- Hero -->
    <section class="bg-gradient-to-br from-primary-500 via-primary-600 to-brand-pink py-20 px-4">
      <div class="max-w-4xl mx-auto text-center text-white">
        <h1 class="font-display text-4xl md:text-5xl font-bold mb-4">
          Naš Program
        </h1>
        <p class="text-lg md:text-xl text-white/90 max-w-2xl mx-auto">
          12 mjeseci, 96 radionica — sveobuhvatni program razvoja djece uzrasta 2–6 godina
          kroz igru, kreativnost i naučno potvrđene metode.
        </p>
      </div>
    </section>

    <!-- 6 Domains -->
    <section class="py-16 px-4 bg-white">
      <div class="max-w-6xl mx-auto">
        <div class="text-center mb-12">
          <h2 class="font-display text-3xl font-bold text-gray-900 mb-3">
            6 Razvojnih Domena
          </h2>
          <p class="text-gray-600 max-w-2xl mx-auto">
            Svako dijete prati napredak u šest ključnih oblasti razvoja.
            Zajedno tvore cjelovitu sliku o djetetu — <em>Dječiji pasoš</em>.
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div
            v-for="domain in domains"
            :key="domain.key"
            class="bg-white rounded-2xl shadow-card overflow-hidden hover:shadow-lg transition-shadow"
          >
            <div class="h-2" :style="{ backgroundColor: domain.color }" />
            <div class="p-6">
              <div
                class="w-12 h-12 rounded-xl flex items-center justify-center mb-4"
                :style="{ backgroundColor: domain.color + '20' }"
              >
                <span class="text-2xl">{{ domain.icon }}</span>
              </div>
              <h3 class="font-display font-bold text-lg text-gray-900 mb-2">
                {{ domain.name }}
              </h3>
              <p class="text-gray-600 text-sm mb-4">{{ domain.description }}</p>
              <div class="space-y-1">
                <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">Šta pratimo:</p>
                <ul class="space-y-1">
                  <li
                    v-for="indicator in domain.indicators"
                    :key="indicator"
                    class="flex items-start gap-2 text-sm text-gray-600"
                  >
                    <span class="mt-1 w-1.5 h-1.5 rounded-full flex-shrink-0" :style="{ backgroundColor: domain.color }" />
                    {{ indicator }}
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Workshop Structure -->
    <section class="py-16 px-4 bg-gray-50">
      <div class="max-w-6xl mx-auto">
        <div class="text-center mb-12">
          <h2 class="font-display text-3xl font-bold text-gray-900 mb-3">
            Struktura Programa
          </h2>
          <p class="text-gray-600 max-w-2xl mx-auto">
            Program traje 12 mjeseci i uključuje 96 radionica — 8 po mjesecu.
            Svaka radionica je pažljivo osmišljena da potiče razvoj u svim domenima.
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
          <div class="card text-center">
            <div class="text-5xl font-display font-bold text-primary-500 mb-2">12</div>
            <div class="text-lg font-semibold text-gray-900">Mjeseci</div>
            <div class="text-sm text-gray-500">trajanje programa</div>
          </div>
          <div class="card text-center">
            <div class="text-5xl font-display font-bold text-brand-red mb-2">96</div>
            <div class="text-lg font-semibold text-gray-900">Radionica</div>
            <div class="text-sm text-gray-500">8 po mjesecu</div>
          </div>
          <div class="card text-center">
            <div class="text-5xl font-display font-bold text-brand-green mb-2">6</div>
            <div class="text-lg font-semibold text-gray-900">Razvojnih domena</div>
            <div class="text-sm text-gray-500">integrisano praćenje</div>
          </div>
        </div>

        <!-- Monthly progression -->
        <div class="card">
          <h3 class="font-display font-bold text-xl text-gray-900 mb-6">Godišnji plan</h3>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div
              v-for="quarter in quarters"
              :key="quarter.label"
              class="rounded-xl p-4 text-center"
              :style="{ backgroundColor: quarter.color + '15', borderLeft: '4px solid ' + quarter.color }"
            >
              <div class="font-bold text-gray-900 mb-1">{{ quarter.label }}</div>
              <div class="text-sm text-gray-600">{{ quarter.months }}</div>
              <div class="text-xs text-gray-500 mt-1">{{ quarter.workshops }} radionica</div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Methodology -->
    <section class="py-16 px-4 bg-white">
      <div class="max-w-6xl mx-auto">
        <div class="text-center mb-12">
          <h2 class="font-display text-3xl font-bold text-gray-900 mb-3">
            Naša Metodologija
          </h2>
          <p class="text-gray-600 max-w-2xl mx-auto">
            Program kombinuje tri naučno utemeljene metodologije u jedinstven pristup
            koji poštuje djetetovu individualnost i prirodni tempo razvoja.
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div
            v-for="method in methodologies"
            :key="method.name"
            class="card-hover text-center"
          >
            <div class="text-5xl mb-4">{{ method.icon }}</div>
            <h3 class="font-display font-bold text-xl text-gray-900 mb-3">{{ method.name }}</h3>
            <p class="text-gray-600 text-sm leading-relaxed">{{ method.description }}</p>
            <div class="mt-4 flex flex-wrap gap-2 justify-center">
              <span
                v-for="tag in method.tags"
                :key="tag"
                class="text-xs bg-primary-50 text-primary-600 rounded-full px-3 py-1 font-semibold"
              >
                {{ tag }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Pricing Tiers -->
    <section class="py-16 px-4 bg-gray-50">
      <div class="max-w-5xl mx-auto">
        <div class="text-center mb-12">
          <h2 class="font-display text-3xl font-bold text-gray-900 mb-3">
            Planovi Pretplate
          </h2>
          <p class="text-gray-600 max-w-xl mx-auto">
            Odaberite plan koji odgovara vašim potrebama. Uvijek možete promijeniti plan.
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div
            v-for="tier in tiers"
            :key="tier.name"
            class="bg-white rounded-2xl shadow-card overflow-hidden"
            :class="{ 'ring-2 ring-primary-500 shadow-colorful': tier.highlighted }"
          >
            <div v-if="tier.highlighted" class="bg-primary-500 text-white text-center py-2 text-sm font-bold">
              Najpopularnije
            </div>
            <div class="p-6">
              <div class="mb-1">
                <span class="badge-{{ tier.badge }}">{{ tier.badge.toUpperCase() }}</span>
              </div>
              <h3 class="font-display font-bold text-xl text-gray-900 mt-3 mb-1">{{ tier.name }}</h3>
              <div class="flex items-baseline gap-1 mb-4">
                <span class="text-4xl font-bold text-gray-900">{{ tier.price }}</span>
                <span class="text-gray-500 text-sm">KM/mj</span>
              </div>
              <ul class="space-y-2 mb-6">
                <li
                  v-for="feature in tier.features"
                  :key="feature.text"
                  class="flex items-start gap-2 text-sm"
                  :class="feature.included ? 'text-gray-700' : 'text-gray-400'"
                >
                  <svg
                    class="w-4 h-4 flex-shrink-0 mt-0.5"
                    :class="feature.included ? 'text-brand-green' : 'text-gray-300'"
                    fill="none" stroke="currentColor" viewBox="0 0 24 24"
                  >
                    <path v-if="feature.included" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    <path v-else stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                  {{ feature.text }}
                </li>
              </ul>
              <NuxtLink
                :to="tier.price === '0' ? '/auth/register' : '/auth/register?tier=' + tier.badge"
                :class="tier.highlighted ? 'btn-primary w-full text-center' : 'btn-secondary w-full text-center'"
              >
                {{ tier.price === '0' ? 'Registrujte se besplatno' : 'Počni s ' + tier.name }}
              </NuxtLink>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA -->
    <section class="py-16 px-4 bg-gradient-to-r from-primary-500 to-brand-pink text-white text-center">
      <div class="max-w-2xl mx-auto">
        <h2 class="font-display text-3xl font-bold mb-4">
          Prijavite dijete na prvu radionicu
        </h2>
        <p class="text-white/90 mb-8">
          Prva radionica je besplatna. Uvjerite se sami kako izgleda program Šarene Sfere.
        </p>
        <div class="flex flex-col sm:flex-row gap-4 justify-center">
          <NuxtLink to="/events" class="btn bg-white text-primary-600 hover:bg-gray-50 font-bold px-8 py-3">
            Pogledaj radionice
          </NuxtLink>
          <NuxtLink to="/quiz" class="btn bg-white/10 text-white border-2 border-white/50 hover:bg-white/20 font-bold px-8 py-3">
            Uradi razvojni kviz
          </NuxtLink>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
useSeoMeta({
  title: 'Program — Šarena Sfera',
  description: '12-mjesečni program razvoja djece uzrasta 2-6 godina. 96 radionica, 6 razvojnih domena, Montessori i NTC metodologija.',
  ogTitle: 'Program — Šarena Sfera',
  ogDescription: 'Sveobuhvatni program praćenja i poticanja dječijeg razvoja kroz igru i kreativnost.',
})

const domains = [
  {
    key: 'emotional',
    name: 'Emocionalni razvoj',
    icon: '❤️',
    color: '#cf2e2e',
    description: 'Prepoznavanje, razumijevanje i regulacija emocija. Temelj zdravog mentalnog razvoja.',
    indicators: ['Imenuje i prepoznaje emocije', 'Prihvata frustraciju bez agresije', 'Pokazuje empatiju prema drugima', 'Traži utjehu na primjeren način'],
  },
  {
    key: 'social',
    name: 'Socijalni razvoj',
    icon: '🤝',
    color: '#fcb900',
    description: 'Izgradnja odnosa sa vršnjacima i odraslima. Suradnja, dijeljenje i komunikacija.',
    indicators: ['Sarađuje u grupnim aktivnostima', 'Dijeli igračke i materijale', 'Čeka red bez sukoba', 'Komunicira potrebe riječima'],
  },
  {
    key: 'creative',
    name: 'Kreativni razvoj',
    icon: '🎨',
    color: '#9b51e0',
    description: 'Izražavanje kroz likovne, muzičke i dramske aktivnosti. Mašta i slobodna igra.',
    indicators: ['Koristi materijale na originalan način', 'Eksperimentira bez straha od grešaka', 'Izražava ideje kroz crtež/pokret', 'Uživa u slobodnoj kreativnoj igri'],
  },
  {
    key: 'cognitive',
    name: 'Kognitivni razvoj',
    icon: '🧠',
    color: '#0693e3',
    description: 'Razmišljanje, rješavanje problema, pamćenje i koncentracija. Priprema za školu.',
    indicators: ['Kategorizuje i sortira predmete', 'Rješava jednostavne probleme', 'Postavlja pitanja iz radoznalosti', 'Koncentracija na zadatak 10+ min'],
  },
  {
    key: 'motor',
    name: 'Motorički razvoj',
    icon: '🏃',
    color: '#00d084',
    description: 'Gruba i fina motorika. Koordinacija, ravnoteža, preciznost pokreta.',
    indicators: ['Kontroliše hvatanje i puštanje', 'Crta i piše s pritiskom', 'Ravnoteža na jednoj nozi', 'Koordinacija oko-ruka'],
  },
  {
    key: 'language',
    name: 'Jezički razvoj',
    icon: '💬',
    color: '#f78da7',
    description: 'Razumijevanje i izražavanje jezikom. Rječnik, naracija, slušanje.',
    indicators: ['Aktivni vokabular 1000+ riječi', 'Priča priče s početkom/krajem', 'Razumije složene upute', 'Komunikacija u grupi'],
  },
]

const quarters = [
  { label: 'Q1', months: 'Jan – Mar', workshops: 24, color: '#cf2e2e' },
  { label: 'Q2', months: 'Apr – Jun', workshops: 24, color: '#fcb900' },
  { label: 'Q3', months: 'Jul – Sep', workshops: 24, color: '#9b51e0' },
  { label: 'Q4', months: 'Okt – Dec', workshops: 24, color: '#0693e3' },
]

const methodologies = [
  {
    name: 'Montessori',
    icon: '🌱',
    description: 'Dijete kao aktivni učesnik vlastitog razvoja. Pripremljeno okruženje koje poziva na istraživanje i samostalnost. Voditelj prati, a ne nalaže.',
    tags: ['Samostalnost', 'Slobodan izbor', 'Prirodni tempo'],
  },
  {
    name: 'NTC metoda',
    icon: '🔬',
    description: 'Neurološki potvrđena metoda koja stimuliše razvoj mozga kroz kretanje, ritam, i asocijativno razmišljanje. Poseban fokus na kreativno mišljenje.',
    tags: ['Neuroplastičnost', 'Kretanje', 'Asocijacije'],
  },
  {
    name: 'Projektna nastava',
    icon: '🏗️',
    description: 'Djeca istražuju teme koje ih interesuju kroz projekte koji traju više radionica. Integrišu se sve razvojne oblasti u jednoj temi.',
    tags: ['Istraživanje', 'Integracija', 'Duboko učenje'],
  },
]

const tiers = [
  {
    badge: 'free',
    name: 'Besplatni',
    price: '0',
    highlighted: false,
    features: [
      { text: 'Pristup blogu i edukativnim člancima', included: true },
      { text: '3 besplatna PDF vodiča', included: true },
      { text: 'Prisustvo jednoj probnoj radionici', included: true },
      { text: 'Dječiji pasoš (praćenje razvoja)', included: false },
      { text: 'Materijali za sve radionice', included: false },
      { text: 'Kvartalni izvještaji (PDF)', included: false },
      { text: 'Kućne aktivnosti i video tutorijali', included: false },
    ],
  },
  {
    badge: 'paid',
    name: 'Osnovni',
    price: '15',
    highlighted: true,
    features: [
      { text: 'Sve iz besplatnog plana', included: true },
      { text: 'Dječiji pasoš (praćenje razvoja)', included: true },
      { text: 'Materijali za sve radionice', included: true },
      { text: 'Kvartalni izvještaji (PDF)', included: true },
      { text: 'Kućne aktivnosti', included: true },
      { text: 'Video tutorijali', included: false },
      { text: 'Zajednica roditelja + stručnjak', included: false },
    ],
  },
  {
    badge: 'premium',
    name: 'Premium',
    price: '30',
    highlighted: false,
    features: [
      { text: 'Sve iz osnovnog plana', included: true },
      { text: 'Video tutorijali za kućne aktivnosti', included: true },
      { text: 'Zajednica roditelja (forum)', included: true },
      { text: 'Pitanje stručnjaku (psiholog/pedagog)', included: true },
      { text: 'Prioritetna podrška', included: true },
      { text: 'Personalizovana razvojna putanja', included: true },
      { text: 'Certifikati i nagrade', included: true },
    ],
  },
]
</script>
