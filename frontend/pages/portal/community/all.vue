<template>
  <div class="space-y-6">
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Sve diskusije</h1>
      <p class="text-sm text-gray-500">Kompletan pregled tema u roditeljskoj zajednici.</p>
    </div>

    <div class="card">
      <input v-model="search" class="input" placeholder="Pretraži teme" />
    </div>

    <div v-if="filteredTopics.length > 0" class="space-y-3">
      <NuxtLink
        v-for="topic in filteredTopics"
        :key="topic.id"
        :to="`/portal/community/${topic.slug}`"
        class="card block hover:shadow-md transition-shadow"
      >
        <div class="flex flex-wrap items-center gap-2 mb-2">
          <span class="badge badge-free">{{ firstCategoryName(topic.forum_categories) }}</span>
          <span v-if="topic.is_pinned" class="badge badge-premium">Pinned</span>
        </div>
        <h2 class="font-semibold text-gray-900">{{ topic.title }}</h2>
        <p class="mt-2 text-sm text-gray-600 line-clamp-2">{{ topic.content }}</p>
        <div class="mt-3 flex gap-4 text-xs text-gray-500">
          <span>{{ firstAuthorName(topic.profiles) }}</span>
          <span>{{ topic.reply_count }} odgovora</span>
          <span>{{ formatDate(topic.created_at) }}</span>
        </div>
      </NuxtLink>
    </div>

    <div v-else class="card text-center py-12 text-gray-500">Nema tema za prikaz.</div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })

const supabase = useSupabase()
const search = ref('')

const { data: topics } = await useAsyncData('forum-topics-all', async () => {
  const { data } = await supabase
    .from('forum_topics')
    .select('id, title, slug, content, reply_count, is_pinned, created_at, forum_categories(name), profiles(full_name)')
    .eq('status', 'published')
    .order('is_pinned', { ascending: false })
    .order('created_at', { ascending: false })

  return data ?? []
})

const filteredTopics = computed(() => {
  const term = search.value.trim().toLowerCase()
  return (topics.value ?? []).filter((topic) =>
    !term || [topic.title, topic.content, firstAuthorName(topic.profiles), firstCategoryName(topic.forum_categories)].some((value) => (value ?? '').toLowerCase().includes(term)),
  )
})

function formatDate(value: string): string {
  return new Date(value).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short', year: 'numeric' })
}

function firstAuthorName(profiles: Array<{ full_name?: string | null }> | null | undefined): string {
  return profiles?.[0]?.full_name ?? 'Korisnik'
}

function firstCategoryName(categories: Array<{ name?: string | null }> | null | undefined): string {
  return categories?.[0]?.name ?? 'Zajednica'
}
</script>
