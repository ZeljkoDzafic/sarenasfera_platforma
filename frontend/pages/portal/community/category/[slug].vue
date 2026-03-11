<template>
  <div class="space-y-6">
    <div>
      <NuxtLink to="/portal/community" class="text-sm text-gray-500 hover:text-gray-700">← Nazad</NuxtLink>
      <h1 class="mt-2 font-display text-2xl font-bold text-gray-900">{{ category?.name || 'Kategorija' }}</h1>
      <p class="text-sm text-gray-500">{{ category?.description }}</p>
    </div>

    <div v-if="topics.length > 0" class="space-y-3">
      <NuxtLink
        v-for="topic in topics"
        :key="topic.id"
        :to="`/portal/community/${topic.slug}`"
        class="card block hover:shadow-md transition-shadow"
      >
        <h2 class="font-semibold text-gray-900">{{ topic.title }}</h2>
        <p class="mt-2 text-sm text-gray-600 line-clamp-2">{{ topic.content }}</p>
      </NuxtLink>
    </div>

    <div v-else class="card text-center py-12 text-gray-500">Nema tema u ovoj kategoriji.</div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })

const route = useRoute()
const supabase = useSupabase()
const slug = route.params.slug as string

const { data: category } = await useAsyncData(`forum-category-${slug}`, async () => {
  const { data } = await supabase.from('forum_categories').select('id, name, description').eq('slug', slug).maybeSingle()
  return data
})

const { data: topicRows } = await useAsyncData(`forum-category-topics-${slug}`, async () => {
  if (!category.value?.id) return []
  const { data } = await supabase.from('forum_topics').select('id, title, slug, content').eq('category_id', category.value.id).eq('status', 'published').order('created_at', { ascending: false })
  return data ?? []
})

const topics = computed(() => topicRows.value ?? [])
</script>
