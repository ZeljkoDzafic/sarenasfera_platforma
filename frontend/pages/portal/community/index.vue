<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Zajednica</h1>
        <p class="text-sm text-gray-500 mt-1">Forum za roditelje - razmijenite iskustva i savjete</p>
      </div>
      <NuxtLink to="/portal/community/new" class="btn-primary text-sm">
        + Nova diskusija
      </NuxtLink>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-primary-600 mb-1">{{ stats.topics }}</div>
        <div class="text-xs text-gray-600">Diskusija</div>
      </div>
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-brand-green mb-1">{{ stats.posts }}</div>
        <div class="text-xs text-gray-600">Objava</div>
      </div>
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-brand-amber mb-1">{{ stats.members }}</div>
        <div class="text-xs text-gray-600">Članova</div>
      </div>
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-brand-pink mb-1">{{ stats.online }}</div>
        <div class="text-xs text-gray-600">Online</div>
      </div>
    </div>

    <!-- Search & Filters -->
    <div class="card">
      <div class="flex flex-col md:flex-row gap-3 md:items-center md:justify-between">
        <div class="relative flex-1 max-w-md">
          <svg class="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            v-model="search"
            type="search"
            class="input pl-10"
            placeholder="Pretraži diskusije..."
          />
        </div>
        <div class="flex gap-2">
          <select v-model="sortBy" class="input w-auto text-sm">
            <option value="latest">Najnovije</option>
            <option value="active">Najaktivnije</option>
            <option value="popular">Najpopularnije</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Categories -->
    <div class="grid gap-4">
      <div
        v-for="category in categories"
        :key="category.id"
        class="card hover:shadow-md transition-shadow cursor-pointer"
        @click="selectCategory(category.slug)"
      >
        <div class="flex items-center gap-4">
          <!-- Icon -->
          <div
            class="w-14 h-14 rounded-xl flex items-center justify-center text-2xl flex-shrink-0"
            :style="{ backgroundColor: category.color + '20' }"
          >
            {{ category.icon }}
          </div>

          <!-- Content -->
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-1">
              <h3 class="font-bold text-gray-900">{{ category.name }}</h3>
              <span v-if="category.is_locked" class="text-xs text-brand-red">🔒 Zaključano</span>
            </div>
            <p class="text-sm text-gray-600 line-clamp-1">{{ category.description }}</p>
            <div class="flex items-center gap-4 mt-2 text-xs text-gray-500">
              <span>{{ category.topic_count }} tema</span>
              <span>{{ category.post_count }} objava</span>
            </div>
          </div>

          <!-- Last activity -->
          <div class="hidden md:block text-right text-xs text-gray-500">
            <p v-if="category.last_activity_at">
              Posljednja aktivnost
            </p>
            <p v-if="category.last_activity_at">
              {{ formatTimeAgo(category.last_activity_at) }}
            </p>
          </div>

          <!-- Arrow -->
          <svg class="w-5 h-5 text-gray-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </div>
      </div>
    </div>

    <!-- Recent Topics -->
    <section>
      <div class="flex items-center justify-between mb-4">
        <h2 class="font-display font-bold text-lg text-gray-900">Najnovije Diskusije</h2>
        <NuxtLink to="/portal/community/all" class="text-sm text-primary-600 hover:text-primary-700 font-semibold">
          Pogledaj sve →
        </NuxtLink>
      </div>

      <div v-if="recentTopics && recentTopics.length > 0" class="space-y-2">
        <div
          v-for="topic in recentTopics"
          :key="topic.id"
          class="card hover:shadow-md transition-shadow cursor-pointer"
          @click="navigateTo(`/portal/community/topic/${topic.slug}`)"
        >
          <div class="flex items-start gap-3">
            <!-- Author avatar -->
            <div class="w-10 h-10 rounded-full bg-primary-100 flex items-center justify-center text-primary-600 font-bold text-sm flex-shrink-0">
              {{ topic.profiles?.full_name?.[0] || 'U' }}
            </div>

            <!-- Content -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-1">
                <h3 class="font-semibold text-gray-900 line-clamp-1">{{ topic.title }}</h3>
                <span v-if="topic.is_pinned" class="text-xs bg-primary-100 text-primary-700 px-2 py-0.5 rounded-full font-semibold">📌 Pinned</span>
                <span v-if="topic.is_featured" class="text-xs bg-brand-amber/20 text-brand-amber px-2 py-0.5 rounded-full font-semibold">⭐ Featured</span>
              </div>
              <p class="text-sm text-gray-600 line-clamp-2">{{ topic.content }}</p>
              <div class="flex items-center gap-4 mt-2 text-xs text-gray-500">
                <span class="font-semibold">{{ topic.profiles?.full_name }}</span>
                <span>•</span>
                <span>{{ formatTimeAgo(topic.created_at) }}</span>
                <span>•</span>
                <span>{{ topic.reply_count }} odgovora</span>
                <span>•</span>
                <span>{{ topic.view_count }} pregleda</span>
              </div>
            </div>

            <!-- Category badge -->
            <div
              class="hidden md:flex px-3 py-1 rounded-full text-xs font-semibold flex-shrink-0"
              :style="{ backgroundColor: topic.forum_categories?.color + '20', color: topic.forum_categories?.color }"
            >
              {{ topic.forum_categories?.name }}
            </div>
          </div>
        </div>
      </div>

      <div v-else class="card text-center py-8">
        <div class="text-4xl mb-3">💬</div>
        <p class="text-gray-600 text-sm">Još nema diskusija. Budi prvi/a!</p>
      </div>
    </section>

    <!-- Top Contributors -->
    <section class="card">
      <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Top Kontributori</h2>
      <div v-if="topContributors && topContributors.length > 0" class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div
          v-for="(contributor, index) in topContributors"
          :key="contributor.user_id"
          class="flex items-center gap-3 p-3 rounded-xl bg-gray-50"
        >
          <!-- Rank -->
          <div class="w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm"
            :class="index === 0 ? 'bg-yellow-100 text-yellow-700' : index === 1 ? 'bg-gray-200 text-gray-700' : index === 2 ? 'bg-amber-100 text-amber-700' : 'bg-gray-100 text-gray-600'">
            {{ index + 1 }}
          </div>

          <!-- Avatar -->
          <div class="w-10 h-10 rounded-full bg-primary-100 flex items-center justify-center text-primary-600 font-bold text-sm">
            {{ contributor.profiles?.full_name?.[0] || 'U' }}
          </div>

          <!-- Info -->
          <div class="flex-1 min-w-0">
            <p class="font-semibold text-gray-900 text-sm truncate">{{ contributor.profiles?.full_name }}</p>
            <p class="text-xs text-gray-500">{{ contributor.points }} poena • {{ contributor.level }}</p>
          </div>
        </div>
      </div>
      <div v-else class="text-center py-8 text-gray-400 text-sm">
        <p>Nema kontributora još.</p>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })
useSeoMeta({ title: 'Zajednica — Forum' })

const supabase = useSupabase()
const { user } = useAuth()

const search = ref('')
const sortBy = ref('latest')
const selectedCategory = ref('')

// Load categories
const { data: categories } = await useAsyncData('forum-categories', async () => {
  const { data } = await supabase
    .from('forum_categories')
    .select('*')
    .eq('is_active', true)
    .order('sort_order')

  return data ?? []
})

// Load recent topics
const { data: recentTopics } = await useAsyncData('forum-recent-topics', async () => {
  const { data } = await supabase
    .from('forum_topics')
    .select(`
      *,
      profiles(full_name, avatar_url),
      forum_categories(name, color)
    `)
    .eq('status', 'published')
    .order('created_at', { ascending: false })
    .limit(10)

  return data ?? []
})

// Load top contributors
const { data: topContributors } = await useAsyncData('forum-top-contributors', async () => {
  const { data } = await supabase
    .from('forum_reputation')
    .select(`
      *,
      profiles(full_name)
    `)
    .order('points', { ascending: false })
    .limit(3)

  return data ?? []
})

// Stats (mock for now)
const stats = ref({
  topics: recentTopics.value?.length ?? 0,
  posts: 0,
  members: 0,
  online: 0,
})

function selectCategory(slug: string) {
  navigateTo(`/portal/community/category/${slug}`)
}

function formatTimeAgo(dateStr: string): string {
  const date = new Date(dateStr)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMs / 3600000)
  const diffDays = Math.floor(diffMs / 86400000)

  if (diffMins < 1) return 'Upravo sada'
  if (diffMins < 60) return `prije ${diffMins} min`
  if (diffHours < 24) return `prije ${diffHours}h`
  if (diffDays < 7) return `prije ${diffDays}d`
  return date.toLocaleDateString('bs-BA', { day: 'numeric', month: 'short' })
}
</script>
