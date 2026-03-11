<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Blog</h1>
        <p class="text-sm text-gray-500 mt-1">Kreiranje, objava i uređivanje blog sadržaja.</p>
      </div>
      <NuxtLink to="/admin/blog/new" class="btn-primary">+ Novi post</NuxtLink>
    </div>

    <div class="card">
      <div class="flex flex-col md:flex-row gap-3">
        <input v-model="search" class="input" placeholder="Pretraži po naslovu ili kategoriji" />
        <select v-model="statusFilter" class="input md:w-56">
          <option value="all">Svi statusi</option>
          <option value="published">Objavljeno</option>
          <option value="draft">Draft</option>
          <option value="featured">Istaknuto</option>
        </select>
      </div>
    </div>

    <div v-if="filteredPosts.length > 0" class="space-y-4">
      <div v-for="post in filteredPosts" :key="post.id" class="card">
        <div class="flex flex-col lg:flex-row gap-4 lg:items-center">
          <div class="w-full lg:w-48 h-28 rounded-2xl overflow-hidden bg-primary-50 flex items-center justify-center text-3xl">
            <img v-if="post.cover_image_url" :src="post.cover_image_url" :alt="post.title" class="w-full h-full object-cover" />
            <span v-else>📝</span>
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex flex-wrap items-center gap-2 mb-2">
              <span class="badge badge-paid">{{ post.is_published ? 'Objavljeno' : 'Draft' }}</span>
              <span v-if="post.is_featured" class="badge badge-premium">Istaknuto</span>
              <span v-if="post.category" class="badge badge-free">{{ post.category }}</span>
            </div>
            <h2 class="font-display text-xl font-bold text-gray-900">{{ post.title }}</h2>
            <p class="mt-2 text-sm text-gray-600 line-clamp-2">{{ post.excerpt || excerptFromContent(post.content) }}</p>
            <div class="mt-3 flex flex-wrap gap-4 text-xs text-gray-500">
              <span>{{ post.author_name || 'Šarena Sfera tim' }}</span>
              <span>{{ formatDate(post.published_at ?? post.updated_at) }}</span>
              <span>/blog/{{ post.slug }}</span>
            </div>
          </div>
          <div class="flex gap-2 flex-wrap">
            <NuxtLink :to="`/blog/${post.slug}`" target="_blank" class="btn-secondary text-sm">Pregled</NuxtLink>
            <NuxtLink :to="`/admin/blog/${post.id}`" class="btn-secondary text-sm">Uredi</NuxtLink>
          </div>
        </div>
      </div>
    </div>

    <div v-else class="card text-center py-12">
      <div class="text-5xl mb-4">🗂️</div>
      <p class="text-gray-600">Nema blog postova za prikaz.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Blog — Admin — Šarena Sfera' })

const search = ref('')
const statusFilter = ref<'all' | 'published' | 'draft' | 'featured'>('all')
const { listPosts } = useBlogAdmin()
const { data: posts } = await useAsyncData('admin-blog-posts', () => listPosts(true))

const filteredPosts = computed(() => {
  const term = search.value.trim().toLowerCase()
  return (posts.value ?? []).filter((post) => {
    const matchesTerm = !term || [post.title, post.category, post.excerpt, post.slug].some((value) => (value ?? '').toLowerCase().includes(term))
    const matchesStatus =
      statusFilter.value === 'all'
      || (statusFilter.value === 'published' && post.is_published)
      || (statusFilter.value === 'draft' && !post.is_published)
      || (statusFilter.value === 'featured' && post.is_featured)
    return matchesTerm && matchesStatus
  })
})

function excerptFromContent(content: string | null | undefined): string {
  return (content ?? '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 140)
}

function formatDate(value: string): string {
  return new Date(value).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short', year: 'numeric' })
}
</script>
