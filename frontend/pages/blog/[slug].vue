<template>
  <div>
    <div v-if="post">
      <!-- Hero -->
      <section
        class="py-16 px-4 text-center text-white"
        :style="{ background: `linear-gradient(135deg, ${post.color}, ${post.colorEnd})` }"
      >
        <div class="max-w-3xl mx-auto">
          <div class="text-6xl mb-4">{{ post.emoji }}</div>
          <div class="flex items-center gap-2 justify-center mb-4">
            <span class="bg-white/20 text-white text-xs font-semibold px-3 py-1 rounded-full">
              {{ post.category }}
            </span>
            <span class="text-white/70 text-sm">{{ post.readTime }} min čitanja</span>
            <span class="text-white/70 text-sm">•</span>
            <span class="text-white/70 text-sm">{{ post.date }}</span>
          </div>
          <h1 class="font-display text-3xl md:text-4xl font-bold mb-4">{{ post.title }}</h1>
          <p class="text-white/90 text-lg max-w-2xl mx-auto">{{ post.excerpt }}</p>
          <div class="flex items-center gap-2 justify-center mt-6">
            <div class="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center text-sm font-bold">
              {{ post.author[0] }}
            </div>
            <span class="text-white/90 font-semibold">{{ post.author }}</span>
          </div>
        </div>
      </section>

      <!-- Article Content -->
      <section class="py-12 px-4">
        <div class="max-w-3xl mx-auto">
          <!-- Tags -->
          <div class="flex flex-wrap gap-2 mb-8">
            <span
              v-for="tag in post.tags"
              :key="tag"
              class="text-xs bg-gray-100 text-gray-600 rounded-full px-3 py-1 font-semibold"
            >
              #{{ tag }}
            </span>
          </div>

          <!-- Content (in production from Supabase) -->
          <div class="prose prose-lg max-w-none">
            <div class="card mb-6 bg-primary-50 border-l-4 border-primary-500">
              <p class="text-primary-800 font-semibold">
                💡 Ovaj članak je dio edukativnog sadržaja Šarene Sfere. Za personalizovane savjete prema razvoju vašeg djeteta,
                <NuxtLink to="/quiz" class="text-primary-600 underline">uradite besplatni razvojni kviz</NuxtLink>.
              </p>
            </div>

            <p class="text-gray-700 leading-relaxed mb-4">
              {{ post.content }}
            </p>

            <!-- CTA section -->
            <div class="card-featured mt-8 text-center">
              <h3 class="font-display font-bold text-xl mb-3">Više savjeta u vašem inboxu</h3>
              <p class="text-white/90 mb-4 text-sm">Jednom sedmično — bez spama. Samo korisni sadržaj za roditelje.</p>
              <div class="flex gap-2 max-w-sm mx-auto">
                <input
                  v-model="newsletterEmail"
                  type="email"
                  class="flex-1 rounded-xl px-4 py-2 text-gray-900 text-sm focus:outline-none"
                  placeholder="vas@email.com"
                />
                <button class="btn bg-white text-primary-600 hover:bg-gray-50 font-bold text-sm px-4">
                  Prijavi se
                </button>
              </div>
            </div>
          </div>

          <!-- Navigation -->
          <div class="border-t border-gray-100 mt-10 pt-8 flex justify-between">
            <NuxtLink to="/blog" class="flex items-center gap-2 text-primary-600 hover:text-primary-700 font-semibold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
              Natrag na Blog
            </NuxtLink>
            <NuxtLink to="/resources" class="flex items-center gap-2 text-primary-600 hover:text-primary-700 font-semibold">
              Besplatni resursi
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </NuxtLink>
          </div>
        </div>
      </section>
    </div>

    <!-- 404 -->
    <div v-else class="py-24 text-center">
      <p class="text-6xl mb-4">📄</p>
      <h2 class="font-display font-bold text-2xl text-gray-900 mb-3">Članak nije pronađen</h2>
      <NuxtLink to="/blog" class="btn-primary">Nazad na blog</NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
const route = useRoute()
const slug = route.params.slug as string

// In production, fetch from Supabase; static data for now
const allPosts = [
  {
    slug: 'kako-razgovarati-s-djetetom-o-emocijama',
    title: 'Kako razgovarati s djetetom o emocijama',
    excerpt: 'Emocionalna pismenost počinje već od 2. godine. Otkrijte jednostavne tehnike kojima možete pomoći djetetu da razumije i imenuje svoja osjećanja.',
    category: 'Emocionalni razvoj',
    color: '#cf2e2e',
    colorEnd: '#9b51e0',
    emoji: '❤️',
    author: 'Amina Hodžić',
    date: '1. mart 2026.',
    readTime: 5,
    tags: ['emocije', 'komunikacija', 'roditelji'],
    content: 'Djeca ne znaju automatski kako da imenuju i upravljaju emocijama. To je vještina koja se uči — baš kao čitanje ili vožnja bicikla. A mi, kao roditelji, smo prvi i najvažniji učitelji u toj školi. Istraživanja pokazuju da djeca čiji roditelji redovno razgovaraju o emocijama razvijaju bolju emocionalnu regulaciju, više empatije prema drugima i bolji akademski uspjeh u kasnijim godinama. Kako početi? Imenujte emocije koje vidite: "Vidim da si ljut jer je zauzeta tvoja igračka." Normalizujte sve emocije: "Normalno je biti tužan." Pokažite vlastite emocije: "Ja se osjećam umorno, ali sretno što smo zajedno." Knjige su odličan alat — priče o likovima koji osećaju strah, radost, ljubomoru otvaraju razgovor na bezopasan način.',
  },
  {
    slug: '10-aktivnosti-za-razvoj-fine-motorike',
    title: '10 aktivnosti za razvoj fine motorike kod kuće',
    excerpt: 'Rezanje, lijepljenje, crtanje, sortiranje — sve to gradi fine motoričke vještine. Evo 10 aktivnosti s materijalima iz svake kuhinje.',
    category: 'Motorički razvoj',
    color: '#00d084',
    colorEnd: '#0693e3',
    emoji: '✂️',
    author: 'Selma Begović',
    date: '15. feb. 2026.',
    readTime: 4,
    tags: ['motorika', 'aktivnosti', 'kuhinja'],
    content: 'Fina motorika — koordinacija malih mišića ruku i prstiju — ključna je za pisanje, crtanje i mnoge svakodnevne aktivnosti. Dobra vijest: razvija se kroz svakodnevne aktivnosti koje se djeci čine kao igra. Evo 10 aktivnosti koje možete odmah početi: 1) Sipanje riže između posuda 2) Sortiranje gumba po boji 3) Trganje papira i pravljenje kolaža 4) Modeliranje tijestom ili plastelinom 5) Rezanje plastelina tupim nožem 6) Nizanje tjestenine na žicu 7) Crtanje prstima u pijesku ili brašnu 8) Lijepljenje naljepnica 9) Otvaranje i zatvaranje patentnih zatvarača i dugmadi 10) Igra "pincetom" — hvatanje graha pincetom. Svaka od ovih aktivnosti, rađena 10-15 minuta dnevno, daje vidljive rezultate za 4-6 sedmica.',
  },
]

const post = computed(() => allPosts.find(p => p.slug === slug))

if (post.value) {
  useSeoMeta({
    title: `${post.value.title} — Šarena Sfera Blog`,
    description: post.value.excerpt,
    ogTitle: post.value.title,
    ogDescription: post.value.excerpt,
  })

  useHead({
    script: [
      {
        type: 'application/ld+json',
        innerHTML: JSON.stringify({
          '@context': 'https://schema.org',
          '@type': 'BlogPosting',
          headline: post.value.title,
          description: post.value.excerpt,
          author: { '@type': 'Person', name: post.value.author },
          datePublished: post.value.date,
          publisher: { '@type': 'Organization', name: 'Šarena Sfera' },
        }),
      },
    ],
  })
}

const newsletterEmail = ref('')
</script>
