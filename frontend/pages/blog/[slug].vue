<template>
  <div>
    <div v-if="post">
      <section class="py-16 px-4 text-center text-white bg-gradient-to-br from-primary-500 to-brand-blue">
        <div class="max-w-3xl mx-auto">
          <div class="flex items-center gap-2 justify-center mb-4 flex-wrap">
            <span class="bg-white/20 text-white text-xs font-semibold px-3 py-1 rounded-full">
              {{ post.category || 'Blog' }}
            </span>
            <span class="text-white/70 text-sm">{{ post.read_time_minutes ?? 4 }} min čitanja</span>
            <span class="text-white/70 text-sm">•</span>
            <span class="text-white/70 text-sm">{{ formatDate(post.published_at ?? post.created_at) }}</span>
          </div>
          <h1 class="font-display text-3xl md:text-4xl font-bold mb-4">{{ post.title }}</h1>
          <p class="text-white/90 text-lg max-w-2xl mx-auto">{{ post.excerpt || excerptFromContent(post.content) }}</p>
          <div class="flex items-center gap-2 justify-center mt-6">
            <div class="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center text-sm font-bold">
              {{ (post.author_name || 'Š')[0] }}
            </div>
            <span class="text-white/90 font-semibold">{{ post.author_name || 'Šarena Sfera tim' }}</span>
          </div>
        </div>
      </section>

      <section class="py-12 px-4">
        <div class="max-w-3xl mx-auto">
          <img v-if="post.cover_image_url" :src="post.cover_image_url" :alt="post.title" class="w-full rounded-3xl shadow-sm mb-8" />

          <div v-if="post.tags?.length" class="flex flex-wrap gap-2 mb-8">
            <span
              v-for="tag in post.tags"
              :key="tag"
              class="text-xs bg-gray-100 text-gray-600 rounded-full px-3 py-1 font-semibold"
            >
              #{{ tag }}
            </span>
          </div>

          <div class="prose prose-lg max-w-none prose-headings:font-display prose-a:text-primary-600" v-html="post.content || fallbackContent" />

          <div class="card-featured mt-8 text-center">
            <h3 class="font-display font-bold text-xl mb-3">Više savjeta u vašem inboxu</h3>
            <p class="text-white/90 mb-4 text-sm">Jednom sedmično, praktične ideje za roditelje i razvoj djece.</p>
            <NuxtLink to="/contact" class="btn bg-white text-primary-600 hover:bg-gray-50 font-bold text-sm px-4">
              Kontaktirajte nas
            </NuxtLink>
          </div>

          <div class="border-t border-gray-100 mt-10 pt-8 flex justify-between">
            <NuxtLink to="/blog" class="flex items-center gap-2 text-primary-600 hover:text-primary-700 font-semibold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
              Natrag na Blog
            </NuxtLink>
            <NuxtLink to="/resources" class="flex items-center gap-2 text-primary-600 hover:text-primary-700 font-semibold">
              Besplatni resursi
            </NuxtLink>
          </div>
        </div>
      </section>
    </div>

    <div v-else class="py-24 text-center">
      <p class="text-6xl mb-4">📄</p>
      <h2 class="font-display font-bold text-2xl text-gray-900 mb-3">Članak nije pronađen</h2>
      <NuxtLink to="/blog" class="btn-primary">Nazad na blog</NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
const route = useRoute()
const { getPostBySlug } = useBlogAdmin()
const slug = route.params.slug as string

const { data: post } = await useAsyncData(`blog-post-${slug}`, () => getPostBySlug(slug))

useSeoMeta({
  title: computed(() => `${post.value?.seo_title || post.value?.title || 'Blog'} — Šarena Sfera Blog`),
  description: computed(() => post.value?.seo_description || post.value?.excerpt || excerptFromContent(post.value?.content)),
  ogTitle: computed(() => post.value?.seo_title || post.value?.title || 'Blog'),
  ogDescription: computed(() => post.value?.seo_description || post.value?.excerpt || excerptFromContent(post.value?.content)),
})

const fallbackContent = computed(() => {
  const excerpt = post.value?.excerpt || excerptFromContent(post.value?.content)
  return `<p>${excerpt}</p>`
})

function excerptFromContent(content: string | null | undefined): string {
  return (content ?? '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 180)
}

function formatDate(value: string): string {
  return new Date(value).toLocaleDateString('bs-BA', { day: 'numeric', month: 'long', year: 'numeric' })
}
</script>
