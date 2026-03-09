<template>
  <div>
    <!-- Hero -->
    <section class="bg-gradient-to-br from-primary-500 via-primary-600 to-brand-pink py-20 px-4">
      <div class="max-w-4xl mx-auto text-center text-white">
        <h1 class="font-display text-4xl md:text-5xl font-bold mb-4">
          Cjenovnik i Planovi
        </h1>
        <p class="text-lg md:text-xl text-white/90 max-w-2xl mx-auto">
          Odaberite plan koji najbolje odgovara vašoj porodici. Bez skrivenih troškova,
          možete otkazati ili promijeniti plan bilo kada.
        </p>
      </div>
    </section>

    <!-- Pricing Tiers -->
    <section class="py-16 px-4 bg-white">
      <div class="max-w-6xl mx-auto">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 lg:gap-8">
          <div
            v-for="tier in tiers"
            :key="tier.key"
            class="bg-white rounded-2xl shadow-card overflow-hidden hover:shadow-lg transition-shadow"
            :class="{ 'ring-2 ring-primary-500 shadow-colorful scale-105': tier.highlighted }"
          >
            <div
              v-if="tier.highlighted"
              class="bg-gradient-to-r from-primary-500 to-brand-pink text-white text-center py-2 text-sm font-bold"
            >
              ⭐ Najpopularnije
            </div>

            <div class="p-8">
              <!-- Badge -->
              <div class="mb-4">
                <span :class="`badge-${tier.key}`" class="uppercase text-xs font-bold px-3 py-1 rounded-full">
                  {{ tier.key }}
                </span>
              </div>

              <!-- Title & Price -->
              <h3 class="font-display font-bold text-2xl text-gray-900 mb-2">{{ tier.name }}</h3>
              <p class="text-sm text-gray-500 mb-6">{{ tier.description }}</p>

              <div class="flex items-baseline gap-2 mb-6">
                <span class="text-5xl font-display font-bold text-gray-900">{{ tier.price }}</span>
                <div class="flex flex-col">
                  <span class="text-gray-500 text-base">KM</span>
                  <span class="text-gray-400 text-xs">/ mjesečno</span>
                </div>
              </div>

              <!-- CTA Button -->
              <NuxtLink
                :to="tier.cta_link"
                :class="tier.highlighted ? 'btn-primary w-full text-center mb-8' : 'btn-secondary w-full text-center mb-8'"
              >
                {{ tier.cta_text }}
              </NuxtLink>

              <!-- Features List -->
              <div class="space-y-3">
                <p class="text-xs font-bold text-gray-500 uppercase tracking-wide">Šta je uključeno:</p>
                <ul class="space-y-2.5">
                  <li
                    v-for="(feature, idx) in tier.features"
                    :key="idx"
                    class="flex items-start gap-3 text-sm"
                  >
                    <svg
                      v-if="feature.included"
                      class="w-5 h-5 flex-shrink-0 mt-0.5 text-brand-green"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                    <svg
                      v-else
                      class="w-5 h-5 flex-shrink-0 mt-0.5 text-gray-300"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                    <span :class="feature.included ? 'text-gray-700' : 'text-gray-400'">
                      {{ feature.text }}
                    </span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <!-- Annual Discount Note -->
        <div class="mt-8 text-center">
          <p class="text-gray-500 text-sm">
            💰 Uštedite 15% plaćanjem unaprijed za cijelu godinu.
            <NuxtLink to="/contact" class="text-primary-600 font-semibold hover:underline">Kontaktirajte nas</NuxtLink>
            za godišnje pakete.
          </p>
        </div>
      </div>
    </section>

    <!-- Detailed Feature Comparison -->
    <section class="py-16 px-4 bg-gray-50">
      <div class="max-w-6xl mx-auto">
        <div class="text-center mb-12">
          <h2 class="font-display text-3xl font-bold text-gray-900 mb-3">
            Detaljna Poređenja Planova
          </h2>
          <p class="text-gray-600 max-w-2xl mx-auto">
            Pogledajte sve funkcionalnosti i benefite koje svaki plan nudi.
          </p>
        </div>

        <div class="card overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b-2 border-gray-200">
                <th class="text-left py-4 px-4 font-bold text-gray-900">Funkcionalnost</th>
                <th class="text-center py-4 px-4 font-bold text-gray-900">Besplatni</th>
                <th class="text-center py-4 px-4 font-bold text-primary-600 bg-primary-50">Osnovni</th>
                <th class="text-center py-4 px-4 font-bold text-gray-900">Premium</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(row, idx) in comparisonTable"
                :key="idx"
                class="border-b border-gray-100 hover:bg-gray-50"
              >
                <td class="py-3 px-4 font-semibold text-gray-700">
                  {{ row.feature }}
                  <span v-if="row.description" class="block text-xs text-gray-500 font-normal mt-1">
                    {{ row.description }}
                  </span>
                </td>
                <td class="text-center py-3 px-4">
                  <span v-if="row.free === true" class="text-brand-green text-xl">✓</span>
                  <span v-else-if="row.free === false" class="text-gray-300 text-xl">✕</span>
                  <span v-else class="text-gray-600 text-sm">{{ row.free }}</span>
                </td>
                <td class="text-center py-3 px-4 bg-primary-50/30">
                  <span v-if="row.paid === true" class="text-brand-green text-xl">✓</span>
                  <span v-else-if="row.paid === false" class="text-gray-300 text-xl">✕</span>
                  <span v-else class="text-gray-600 text-sm font-semibold">{{ row.paid }}</span>
                </td>
                <td class="text-center py-3 px-4">
                  <span v-if="row.premium === true" class="text-brand-green text-xl">✓</span>
                  <span v-else-if="row.premium === false" class="text-gray-300 text-xl">✕</span>
                  <span v-else class="text-gray-600 text-sm">{{ row.premium }}</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <!-- FAQ Section -->
    <section class="py-16 px-4 bg-white">
      <div class="max-w-4xl mx-auto">
        <div class="text-center mb-12">
          <h2 class="font-display text-3xl font-bold text-gray-900 mb-3">
            Često Postavljana Pitanja
          </h2>
        </div>

        <div class="space-y-4">
          <div v-for="(faq, idx) in faqs" :key="idx" class="card-hover">
            <h3 class="font-bold text-gray-900 mb-2">{{ faq.question }}</h3>
            <p class="text-gray-600 text-sm leading-relaxed">{{ faq.answer }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA Section -->
    <section class="py-16 px-4 bg-gradient-to-r from-primary-500 to-brand-pink text-white text-center">
      <div class="max-w-2xl mx-auto">
        <h2 class="font-display text-3xl font-bold mb-4">
          Spremni da počnete?
        </h2>
        <p class="text-white/90 mb-8">
          Prijavite se besplatno i pogledajte kako naša platforma može pomoći razvoju vašeg djeteta.
        </p>
        <div class="flex flex-col sm:flex-row gap-4 justify-center">
          <NuxtLink to="/auth/register" class="btn bg-white text-primary-600 hover:bg-gray-50 font-bold px-8 py-3 rounded-xl">
            Registrujte se besplatno
          </NuxtLink>
          <NuxtLink to="/events" class="btn bg-white/10 text-white border-2 border-white/50 hover:bg-white/20 font-bold px-8 py-3 rounded-xl">
            Pogledaj radionice
          </NuxtLink>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
// T-840: Pricing Page
// Public page showing subscription tiers and feature comparison

useSeoMeta({
  title: 'Cjenovnik i Planovi — Šarena Sfera',
  description: 'Odaberite plan koji odgovara vašoj porodici. Besplatni, Osnovni (15 KM/mj) i Premium (30 KM/mj) planovi.',
  ogTitle: 'Cjenovnik i Planovi — Šarena Sfera',
  ogDescription: 'Pregledni cjenovnik i poređenje planova za praćenje razvoja djeteta.',
})

const tiers = [
  {
    key: 'free',
    name: 'Besplatni',
    description: 'Savršeno za testiranje platforme i probnu radionicu',
    price: '0',
    highlighted: false,
    cta_text: 'Registrujte se besplatno',
    cta_link: '/auth/register',
    features: [
      { text: 'Pristup blogu i edukativnim člancima', included: true },
      { text: 'Preuzimanje 3 besplatna PDF vodiča', included: true },
      { text: 'Prisustvo jednoj probnoj radionici', included: true },
      { text: 'Prijavite se na javne događaje', included: true },
      { text: 'Email obavještenja', included: true },
      { text: 'Dječiji pasoš (radar grafikon)', included: false },
      { text: 'Materijali za radionice', included: false },
      { text: 'Opservacije voditelja', included: false },
      { text: 'Kućne aktivnosti', included: false },
      { text: 'Kvartalni PDF izvještaji', included: false },
    ],
  },
  {
    key: 'paid',
    name: 'Osnovni',
    description: 'Za roditelje koji žele pratiti razvoj svog djeteta',
    price: '15',
    highlighted: true,
    cta_text: 'Započnite Osnovni plan',
    cta_link: '/auth/register?tier=paid',
    features: [
      { text: 'Sve iz besplatnog plana', included: true },
      { text: 'Dječiji pasoš (6-domena radar)', included: true },
      { text: 'Poslednje 3 opservacije voditelja', included: true },
      { text: 'Materijali za sve radionice', included: true },
      { text: 'Kvartalni izvještaji (PDF)', included: true },
      { text: 'Kućne aktivnosti (2 mjesečno)', included: true },
      { text: 'Praćenje do 3 djece', included: true },
      { text: 'Poruke sa voditeljima', included: true },
      { text: 'Video tutorijali', included: false },
      { text: 'Forum zajednice', included: false },
    ],
  },
  {
    key: 'premium',
    name: 'Premium',
    description: 'Potpuna podrška i personalizovan pristup',
    price: '30',
    highlighted: false,
    cta_text: 'Sve uključeno',
    cta_link: '/auth/register?tier=premium',
    features: [
      { text: 'Sve iz osnovnog plana', included: true },
      { text: 'Sve opservacije i izvještaji', included: true },
      { text: 'Video tutorijali za aktivnosti', included: true },
      { text: 'Pristup zajednici roditelja (forum)', included: true },
      { text: 'Pitanje stručnjaku (1× mjesečno)', included: true },
      { text: 'Personalizovana razvojna putanja', included: true },
      { text: 'Neograničen broj djece', included: true },
      { text: 'Prioritetna podrška', included: true },
      { text: 'Certifikati i nagrade', included: true },
      { text: 'Fotografska galerija', included: true },
    ],
  },
]

const comparisonTable = [
  { feature: 'Broj djece', free: '1', paid: '3', premium: 'Neograničeno' },
  { feature: 'Dječiji pasoš (radar)', free: false, paid: true, premium: true },
  { feature: 'Opservacije', description: 'Bilješke voditelja o razvoju djeteta', free: false, paid: 'Zadnje 3', premium: 'Sve' },
  { feature: 'Kvartalni izvještaji (PDF)', free: false, paid: true, premium: true },
  { feature: 'Kućne aktivnosti', free: false, paid: '2/mj', premium: 'Sve' },
  { feature: 'Materijali za radionice', free: false, paid: true, premium: true },
  { feature: 'Video tutorijali', free: false, paid: false, premium: true },
  { feature: 'Poruke sa voditeljima', free: false, paid: true, premium: true },
  { feature: 'Forum zajednice', free: false, paid: false, premium: true },
  { feature: 'Pitanje stručnjaku', free: false, paid: false, premium: '1× mjesečno' },
  { feature: 'Personalizovana razvojna putanja', free: false, paid: false, premium: true },
  { feature: 'Foto galerija', free: false, paid: false, premium: true },
  { feature: 'Certifikati i nagrade', free: false, paid: false, premium: true },
  { feature: 'Prioritetna podrška', free: false, paid: false, premium: true },
]

const faqs = [
  {
    question: 'Mogu li promijeniti plan tokom korištenja?',
    answer: 'Naravno! Možete nadograditi ili smanjiti svoj plan bilo kada. Promjena stupa na snagu odmah, a razlika u cijeni se proporcionalnosno obračunava.',
  },
  {
    question: 'Šta se dešava ako otkažem pretplatu?',
    answer: 'Možete otkazati pretplatu bilo kada. Vaš pristup plaćenim funkcijama nastavlja do kraja plaćenog perioda. Svi vaši podaci ostaju sačuvani i možete se ponovno pretplatiti kasnije.',
  },
  {
    question: 'Kako se vrši plaćanje?',
    answer: 'Trenutno prihvatamo bankovnu transakciju ili gotovinu pri dolasku. Uskoro ćemo omogućiti online plaćanje karticom. Kontaktirajte nas za detalje.',
  },
  {
    question: 'Postoji li popust za godišnju pretplatu?',
    answer: 'Da! Dobijate 15% popusta ako platite godišnju pretplatu unaprijed. To znači da umjesto 180 KM (15 KM × 12), plaćate samo 153 KM godišnje.',
  },
  {
    question: 'Je li prva radionica zaista besplatna?',
    answer: 'Apsolutno! Svako dijete može doći na jednu probnu radionicu bez ikakve naknade. To vam omogućava da vidite kako funkcioniše program prije nego što se odlučite za pretplatu.',
  },
  {
    question: 'Šta je "Roditelji Pioniri" program?',
    answer: 'Roditelji Pioniri su prvih 50 porodica koje se pridruže platformi. Oni dobijaju trajno zaključanu cijenu (10 KM za Osnovni, 20 KM za Premium), pionirski bedž i prioritetnu podršku.',
  },
  {
    question: 'Mogu li dodati više djece tokom pretplate?',
    answer: 'Možete dodati djecu u okviru limita vašeg plana (Free: 1, Osnovni: 3, Premium: neograničeno). Ako trebate više, jednostavno nadogradite plan.',
  },
]
</script>
