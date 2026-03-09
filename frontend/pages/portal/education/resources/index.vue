<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Biblioteka Resursa</h1>
      <p class="text-sm text-gray-500 mt-1">Članci, PDF vodiči, video snimci i radni listovi</p>
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
            placeholder="Pretraži resurse..."
          />
        </div>
        <div class="flex flex-wrap gap-2">
          <select v-model="filterType" class="input w-auto text-sm">
            <option value="">Svi tipovi</option>
            <option value="article">Članak</option>
            <option value="pdf">PDF</option>
            <option value="video">Video</option>
            <option value="worksheet">Radni list</option>
          </select>
          <select v-model="filterDomain" class="input w-auto text-sm">
            <option value="">Sve domene</option>
            <option value="emotional">Emocionalni</option>
            <option value="social">Socijalni</option>
            <option value="creative">Kreativni</option>
            <option value="cognitive">Kognitivni</option>
            <option value="motor">Motorički</option>
            <option value="language">Jezički</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Tier Info -->
    <div class="card bg-gradient-to-r from-primary-50 to-brand-pink/10 border-2 border-primary-200">
      <div class="flex items-center gap-4">
        <div class="text-3xl">📊</div>
        <div class="flex-1">
          <p class="text-sm text-gray-700">
            <span class="font-semibold">Free:</span> 5 preuzimanja mjesečno •
            <span class="font-semibold">Paid:</span> 20 preuzimanja mjesečno •
            <span class="font-semibold">Premium:</span> Neograničeno
          </p>
        </div>
        <div class="text-right">
          <p class="text-sm text-gray-600">Ostalo ti je:</p>
          <p class="text-lg font-bold text-primary-600">{{ downloadsRemaining }} preuzimanja</p>
        </div>
      </div>
    </div>

    <!-- Resources Grid -->
    <div v-if="filteredResources && filteredResources.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <NuxtLink
        v-for="resource in filteredResources"
        :key="resource.id"
        :to="`/portal/education/resources/${resource.slug}`"
        class="card-hover block"
      >
        <!-- Type icon header -->
        <div
          class="h-24 rounded-t-xl flex items-center justify-center text-4xl"
          :class="getTypeBgClass(resource.resource_type)"
        >
          {{ getTypeIcon(resource.resource_type) }}
        </div>

        <div class="p-4">
          <div class="flex items-center gap-2 mb-2">
            <TierBadge :tier="resource.required_tier" size="sm" />
            <span
              v-if="resource.domain"
              class="px-2 py-0.5 rounded-full text-xs font-semibold"
              :style="{ backgroundColor: getDomainColor(resource.domain) + '20', color: getDomainColor(resource.domain) }"
            >
              {{ getDomainName(resource.domain) }}
            </span>
          </div>

          <h3 class="font-bold text-gray-900 mb-1 line-clamp-2">{{ resource.title }}</h3>
          <p class="text-sm text-gray-600 line-clamp-2 mb-3">{{ resource.description }}</p>

          <div class="flex items-center justify-between text-xs text-gray-500">
            <span class="flex items-center gap-1">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
              </svg>
              {{ resource.view_count || 0 }}
            </span>
            <span class="flex items-center gap-1">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
              </svg>
              {{ resource.download_count || 0 }}
            </span>
          </div>
        </div>
      </NuxtLink>
    </div>

    <!-- Empty State -->
    <div v-else class="card text-center py-12">
      <div class="text-4xl mb-3">📚</div>
      <p class="text-gray-600 text-sm">Nema pronađenih resursa prema odabranim filterima.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })
useSeoMeta({ title: 'Biblioteka Resursa — Šarena Sfera' })

const supabase = useSupabase()
const { user } = useAuth()
const { tierName } = useTier()

const search = ref('')
const filterType = ref('')
const filterDomain = ref('')

// Load resources
const { data: resources } = await useAsyncData('portal-resources', async () => {
  const { data } = await supabase
    .from('educational_content')
    .select(`
      *,
      resource_materials(file_type, file_url)
    `)
    .eq('content_type', 'resource')
    .eq('status', 'published')
    .order('created_at', { ascending: false })

  return (data ?? []).map(r => ({
    ...r,
    resource_type: r.resource_materials?.[0]?.file_type || 'article',
  }))
})

// Load user's download count for this month
const { data: downloadStats } = await useAsyncData('user-downloads', async () => {
  if (!user.value) return { count: 0, limit: 5 }

  const startOfMonth = new Date()
  startOfMonth.setDate(1)
  startOfMonth.setHours(0, 0, 0, 0)

  const { count } = await supabase
    .from('content_registrations')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user.value.id)
    .gte('created_at', startOfMonth.toISOString())

  const limits: Record<string, number> = {
    free: 5,
    paid: 20,
    premium: 9999,
  }

  return {
    count: count || 0,
    limit: limits[tierName.value] || 5,
  }
})

const downloadsRemaining = computed(() => {
  if (!downloadStats.value) return 5
  return Math.max(0, downloadStats.value.limit - downloadStats.value.count)
})

const filteredResources = computed(() => {
  let list = resources.value ?? []

  // Search filter
  if (search.value) {
    const s = search.value.toLowerCase()
    list = list.filter(r =>
      r.title.toLowerCase().includes(s) ||
      r.description?.toLowerCase().includes(s)
    )
  }

  // Type filter
  if (filterType.value) {
    list = list.filter(r => r.resource_type === filterType.value)
  }

  // Domain filter
  if (filterDomain.value) {
    list = list.filter(r => r.domain === filterDomain.value)
  }

  return list
})

function getTypeIcon(type: string): string {
  const map: Record<string, string> = {
    article: '📄',
    pdf: '📕',
    video: '🎬',
    worksheet: '📝',
  }
  return map[type] || '📄'
}

function getTypeBgClass(type: string): string {
  const map: Record<string, string> = {
    article: 'bg-gray-100',
    pdf: 'bg-brand-red/10',
    video: 'bg-brand-pink/10',
    worksheet: 'bg-primary-100',
  }
  return map[type] || 'bg-gray-100'
}

function getDomainColor(domain: string): string {
  const colors: Record<string, string> = {
    emotional: '#cf2e2e',
    social: '#fcb900',
    creative: '#9b51e0',
    cognitive: '#0693e3',
    motor: '#00d084',
    language: '#f78da7',
  }
  return colors[domain] || '#9b51e0'
}

function getDomainName(domain: string): string {
  const names: Record<string, string> = {
    emotional: 'Emocionalni',
    social: 'Socijalni',
    creative: 'Kreativni',
    cognitive: 'Kognitivni',
    motor: 'Motorički',
    language: 'Jezički',
  }
  return names[domain] || domain
}
</script>
