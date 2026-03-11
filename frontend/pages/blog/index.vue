<template>
  <div>
    <section class="bg-gradient-to-br from-brand-blue to-primary-500 py-16 px-4 text-white text-center">
      <div class="max-w-3xl mx-auto">
        <h1 class="font-display text-4xl font-bold mb-3">Blog</h1>
        <p class="text-white/90 text-lg">
          Savjeti za roditelje, vijesti iz dječijeg razvoja i ideje koje možete odmah primijeniti kod kuće.
        </p>
      </div>
    </section>

    <section class="py-12 px-4">
      <div class="max-w-6xl mx-auto">
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

        <div v-if="featuredPost" class="mb-10">
          <NuxtLink :to="`/blog/${featuredPost.slug}`" class="card-hover block overflow-hidden">
            <div class="flex flex-col md:flex-row gap-6">
              <div class="h-48 md:h-auto md:w-64 flex-shrink-0 rounded-xl overflow-hidden bg-primary-50">
                <img v-if="featuredPost.cover_image_url" :src="featuredPost.cover_image_url" :alt="featuredPost.title" class="h-full w-full object-cover" />
                <div v-else class="h-full w-full flex items-center justify-center text-5xl">📝</div>
              </div>
              <div class="flex-1">
                <div class="flex items-center gap-2 mb-3 flex-wrap">
                  <span class="text-xs font-semibold px-3 py-1 rounded-full bg-primary-50 text-primary-700">
                    {{ featuredPost.category || 'Blog' }}
                  </span>
                  <span class="text-xs text-gray-400">{{ featuredPost.read_time_minutes ?? 4 }} min čitanja</span>
                  <span class="text-xs text-gray-400">•</span>
                  <span class="text-xs text-gray-400">{{ formatDate(featuredPost.published_at ?? featuredPost.created_at) }}</span>
                </div>
                <h2 class="font-display font-bold text-2xl text-gray-900 mb-3 hover:text-primary-600 transition-colors">
                  {{ featuredPost.title }}
                </h2>
                <p class="text-gray-600 mb-4">{{ featuredPost.excerpt || excerptFromContent(featuredPost.content) }}</p>
                <div class="flex items-center gap-2">
                  <div class="w-7 h-7 rounded-full bg-primary-100 flex items-center justify-center text-xs font-bold text-primary-600">
                    {{ (featuredPost.author_name || 'Š')[0] }}
                  </div>
                  <span class="text-sm text-gray-600">{{ featuredPost.author_name || 'Šarena Sfera tim' }}</span>
                </div>
              </div>
            </div>
          </NuxtLink>
        </div>

        <div v-if="visiblePosts.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <NuxtLink
            v-for="post in visiblePosts"
            :key="post.id"
            :to="`/blog/${post.slug}`"
            class="card-hover block"
          >
            <div class="h-40 rounded-xl mb-4 overflow-hidden bg-primary-50">
              <img v-if="post.cover_image_url" :src="post.cover_image_url" :alt="post.title" class="w-full h-full object-cover" />
              <div v-else class="w-full h-full flex items-center justify-center text-5xl">📚</div>
            </div>
            <div class="flex items-center gap-2 mb-2">
              <span class="text-xs font-semibold px-2 py-1 rounded-full bg-primary-50 text-primary-700">
                {{ post.category || 'Blog' }}
              </span>
              <span class="text-xs text-gray-400">{{ post.read_time_minutes ?? 4 }} min</span>
            </div>
            <h3 class="font-bold text-gray-900 mb-2 hover:text-primary-600 transition-colors line-clamp-2">
              {{ post.title }}
            </h3>
            <p class="text-sm text-gray-600 line-clamp-3 mb-4">{{ post.excerpt || excerptFromContent(post.content) }}</p>
            <div class="flex items-center justify-between text-xs text-gray-400">
              <span>{{ post.author_name || 'Šarena Sfera tim' }}</span>
              <span>{{ formatDate(post.published_at ?? post.created_at) }}</span>
            </div>
          </NuxtLink>
        </div>

        <div v-else class="card text-center py-12">
          <div class="text-5xl mb-4">📝</div>
          <p class="text-gray-600">Blog postovi će se pojaviti čim ih objavite iz admin panela.</p>
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

const activeCategory = ref('Sve kategorije')
const { listPosts } = useBlogAdmin()
const { data: posts } = await useAsyncData('blog-posts-public', () => listPosts(false))

const filteredPosts = computed(() => {
  const items = posts.value ?? []
  if (activeCategory.value === 'Sve kategorije') return items
  return items.filter((post) => post.category === activeCategory.value)
})

const featuredPost = computed(() => filteredPosts.value.find((post) => post.is_featured) ?? filteredPosts.value[0] ?? null)
const visiblePosts = computed(() => filteredPosts.value.filter((post) => post.id !== featuredPost.value?.id))
const allCategories = computed(() => ['Sve kategorije', ...new Set((posts.value ?? []).map((post) => post.category).filter(Boolean) as string[])])

function excerptFromContent(content: string | null | undefined): string {
  return (content ?? '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 160) || 'Blog sadržaj Šarene Sfere.'
}

function formatDate(value: string): string {
  return new Date(value).toLocaleDateString('bs-BA', { day: 'numeric', month: 'long', year: 'numeric' })
}
</script>
