<template>
  <div>
    <!-- Header -->
    <section class="bg-gradient-to-br from-brand-blue to-primary-500 py-16 px-4 text-white text-center">
      <div class="max-w-3xl mx-auto">
        <h1 class="font-display text-4xl font-bold mb-3">Blog</h1>
        <p class="text-white/90 text-lg">
          Savjeti za roditelje, vijesti iz dječije psihologije i ideje za aktivnosti kod kuće.
        </p>
      </div>
    </section>

    <section class="py-12 px-4">
      <div class="max-w-6xl mx-auto">

        <!-- Categories -->
        <div class="flex flex-wrap gap-2 mb-8 justify-center">
          <button
            v-for="cat in allCategories"
            :key="cat"
            class="px-4 py-2 rounded-xl text-sm font-semibold transition-all"
            :class="activeCategory === cat
              ? 'bg-primary-500 text-white shadow-colorful'
              : 'bg-white text-gray-600 hover:bg-primary-50 border border-gray-200'"
            @click="activeCategory = cat"
          >
            {{ cat }}
          </button>
        </div>

        <!-- Featured Post -->
        <div v-if="filteredPosts.length > 0" class="mb-10">
          <NuxtLink :to="`/blog/${filteredPosts[0].slug}`" class="card-hover block overflow-hidden">
            <div class="flex flex-col md:flex-row gap-6">
              <div
                class="h-48 md:h-auto md:w-64 flex-shrink-0 rounded-xl flex items-center justify-center text-6xl"
                :style="{ backgroundColor: filteredPosts[0].color + '20' }"
              >
                {{ filteredPosts[0].emoji }}
              </div>
              <div class="flex-1">
                <div class="flex items-center gap-2 mb-3">
                  <span
                    class="text-xs font-semibold px-3 py-1 rounded-full"
                    :style="{ backgroundColor: filteredPosts[0].color + '20', color: filteredPosts[0].color }"
                  >
                    {{ filteredPosts[0].category }}
                  </span>
                  <span class="text-xs text-gray-400">{{ filteredPosts[0].readTime }} min čitanja</span>
                  <span class="text-xs text-gray-400">•</span>
                  <span class="text-xs text-gray-400">{{ filteredPosts[0].date }}</span>
                </div>
                <h2 class="font-display font-bold text-2xl text-gray-900 mb-3 hover:text-primary-600 transition-colors">
                  {{ filteredPosts[0].title }}
                </h2>
                <p class="text-gray-600 mb-4">{{ filteredPosts[0].excerpt }}</p>
                <div class="flex items-center gap-2">
                  <div class="w-7 h-7 rounded-full bg-primary-100 flex items-center justify-center text-xs font-bold text-primary-600">
                    {{ filteredPosts[0].author[0] }}
                  </div>
                  <span class="text-sm text-gray-600">{{ filteredPosts[0].author }}</span>
                </div>
              </div>
            </div>
          </NuxtLink>
        </div>

        <!-- Posts Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <NuxtLink
            v-for="post in filteredPosts.slice(1)"
            :key="post.slug"
            :to="`/blog/${post.slug}`"
            class="card-hover block"
          >
            <div
              class="h-40 rounded-xl mb-4 flex items-center justify-center text-5xl"
              :style="{ backgroundColor: post.color + '20' }"
            >
              {{ post.emoji }}
            </div>
            <div class="flex items-center gap-2 mb-2">
              <span
                class="text-xs font-semibold px-2 py-1 rounded-full"
                :style="{ backgroundColor: post.color + '20', color: post.color }"
              >
                {{ post.category }}
              </span>
              <span class="text-xs text-gray-400">{{ post.readTime }} min</span>
            </div>
            <h3 class="font-bold text-gray-900 mb-2 hover:text-primary-600 transition-colors line-clamp-2">
              {{ post.title }}
            </h3>
            <p class="text-gray-600 text-sm line-clamp-2 mb-3">{{ post.excerpt }}</p>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <div class="w-6 h-6 rounded-full bg-primary-100 flex items-center justify-center text-xs font-bold text-primary-600">
                  {{ post.author[0] }}
                </div>
                <span class="text-xs text-gray-500">{{ post.author }}</span>
              </div>
              <span class="text-xs text-gray-400">{{ post.date }}</span>
            </div>
          </NuxtLink>
        </div>

        <!-- Pagination -->
        <div v-if="totalPages > 1" class="mt-10 flex justify-center gap-2">
          <button
            v-for="p in totalPages"
            :key="p"
            class="w-10 h-10 rounded-xl text-sm font-semibold transition-all"
            :class="currentPage === p
              ? 'bg-primary-500 text-white shadow-colorful'
              : 'bg-white text-gray-600 hover:bg-primary-50 border border-gray-200'"
            @click="currentPage = p"
          >
            {{ p }}
          </button>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
useSeoMeta({
  title: 'Blog — Šarena Sfera',
  description: 'Savjeti za roditelje, članci o dječijem razvoju i ideje za aktivnosti.',
  ogTitle: 'Blog — Šarena Sfera',
})

useHead({
  script: [
    {
      type: 'application/ld+json',
      children: JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'Blog',
        name: 'Šarena Sfera Blog',
        url: 'https://sarenasfera.com/blog',
        description: 'Savjeti za roditelje djece uzrasta 2-6 godina',
      }),
    },
  ],
})

const activeCategory = ref('Sve kategorije')
const currentPage = ref(1)
const postsPerPage = 7

// Static blog posts (in production these would come from Supabase)
const posts = [
  {
    slug: 'kako-razgovarati-s-djetetom-o-emocijama',
    title: 'Kako razgovarati s djetetom o emocijama',
    excerpt: 'Emocionalna pismenost počinje već od 2. godine. Otkrijte jednostavne tehnike kojima možete pomoći djetetu da razumije i imenuje svoja osjećanja.',
    category: 'Emocionalni razvoj',
    color: '#cf2e2e',
    emoji: '❤️',
    author: 'Amina Hodžić',
    date: '1. mart 2026.',
    readTime: 5,
    tags: ['emocije', 'komunikacija', 'roditelji'],
  },
  {
    slug: '10-aktivnosti-za-razvoj-fine-motorike',
    title: '10 aktivnosti za razvoj fine motorike kod kuće',
    excerpt: 'Rezanje, lijepljenje, crtanje, sortiranje — sve to gradi fine motoričke vještine. Evo 10 aktivnosti s materijalima iz svake kuhinje.',
    category: 'Motorički razvoj',
    color: '#00d084',
    emoji: '✂️',
    author: 'Selma Begović',
    date: '15. feb. 2026.',
    readTime: 4,
    tags: ['motorika', 'aktivnosti', 'kuhinja'],
  },
  {
    slug: 'zasto-je-slobodna-igra-vazna',
    title: 'Zašto je slobodna igra ključna za razvoj djeteta',
    excerpt: 'U eri strukturiranih aktivnosti i organizovanih sportova, slobodna igra se sve više zanemaruje. A upravo ona je temelj kreativnosti i socijalizacije.',
    category: 'Kreativni razvoj',
    color: '#9b51e0',
    emoji: '🎭',
    author: 'Amina Hodžić',
    date: '10. feb. 2026.',
    readTime: 6,
    tags: ['igra', 'kreativnost', 'slobodno vrijeme'],
  },
  {
    slug: 'knjige-za-djecu-2-4-godine',
    title: 'Preporučene knjige za djecu 2–4 godine',
    excerpt: 'Čitanje naglas jedno je od najmoćnijih alata za razvoj jezika, mašte i emocionalne inteligencije. Evo naše liste omiljenih knjiga.',
    category: 'Jezički razvoj',
    color: '#f78da7',
    emoji: '📚',
    author: 'Lejla Mehić',
    date: '5. feb. 2026.',
    readTime: 3,
    tags: ['knjige', 'čitanje', 'jezik'],
  },
  {
    slug: 'dijete-u-vrtiću-prva-sedmica',
    title: 'Prva sedmica u vrtiću — savjeti za roditelje',
    excerpt: 'Odvajanje od roditelja je veliki korak i za dijete i za nas. Kako olakšati taj prijelaz i šta je normalno ponašanje u ovom periodu.',
    category: 'Socijalni razvoj',
    color: '#fcb900',
    emoji: '🏫',
    author: 'Selma Begović',
    date: '28. jan. 2026.',
    readTime: 5,
    tags: ['vrtić', 'odvajanje', 'socijalizacija'],
  },
  {
    slug: 'matematicko-razmisljanje-kroz-igru',
    title: 'Matematičko razmišljanje kroz igru',
    excerpt: 'Djeca su urođeni matematičari. Svrstavanje čarapa, brojanje stepenica, dijeljenje biskvita — sve su to matematičke aktivnosti.',
    category: 'Kognitivni razvoj',
    color: '#0693e3',
    emoji: '🔢',
    author: 'Amina Hodžić',
    date: '20. jan. 2026.',
    readTime: 4,
    tags: ['matematika', 'kognitivni', 'igra'],
  },
  {
    slug: 'montessori-kod-kuce',
    title: 'Montessori principi koje možete primijeniti kod kuće',
    excerpt: 'Montessori nije samo skupi materijali i posebne škole. Osnovna filozofija — dijete kao aktivni učesnik — može se živjeti u svakom domu.',
    category: 'Metodologija',
    color: '#9b51e0',
    emoji: '🌱',
    author: 'Lejla Mehić',
    date: '12. jan. 2026.',
    readTime: 7,
    tags: ['montessori', 'metode', 'kuća'],
  },
]

const allCategories = computed(() => ['Sve kategorije', ...new Set(posts.map(p => p.category))])

const filteredPosts = computed(() => {
  const filtered = activeCategory.value === 'Sve kategorije'
    ? posts
    : posts.filter(p => p.category === activeCategory.value)
  const start = (currentPage.value - 1) * postsPerPage
  return filtered.slice(start, start + postsPerPage)
})

const totalPages = computed(() => {
  const filtered = activeCategory.value === 'Sve kategorije' ? posts : posts.filter(p => p.category === activeCategory.value)
  return Math.ceil(filtered.length / postsPerPage)
})

watch(activeCategory, () => { currentPage.value = 1 })
</script>
