<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Radionice i Događaji</h1>
        <p class="text-sm text-gray-500 mt-1">Upravljajte javnim radionicama i događajima</p>
      </div>
      <NuxtLink to="/admin/events/new" class="btn-primary">
        ➕ Novi događaj
      </NuxtLink>
    </div>

    <!-- Filter Tabs -->
    <div class="flex gap-2 border-b border-gray-200 overflow-x-auto">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        @click="currentTab = tab.key"
        :class="[
          'px-4 py-2 font-semibold text-sm whitespace-nowrap border-b-2 transition-colors',
          currentTab === tab.key
            ? 'border-primary-500 text-primary-600'
            : 'border-transparent text-gray-500 hover:text-gray-700'
        ]"
      >
        {{ tab.label }} <span v-if="tab.count !== null" class="text-xs opacity-60">({{ tab.count }})</span>
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="space-y-4">
      <div v-for="i in 3" :key="i" class="card h-32 animate-pulse bg-gray-100" />
    </div>

    <!-- Events List -->
    <div v-else-if="filteredEvents.length > 0" class="space-y-4">
      <div
        v-for="event in filteredEvents"
        :key="event.id"
        class="card hover:shadow-lg transition-shadow"
      >
        <div class="flex flex-col md:flex-row gap-4">
          <!-- Image -->
          <div
            v-if="event.image_url"
            class="w-full md:w-40 h-32 rounded-xl bg-gray-100 overflow-hidden flex-shrink-0"
          >
            <img :src="event.image_url" :alt="event.title" class="w-full h-full object-cover" />
          </div>
          <div
            v-else
            class="w-full md:w-40 h-32 rounded-xl bg-gradient-to-br flex-shrink-0"
            :style="{ background: `linear-gradient(135deg, ${getDomainColor(event.domain ?? null)}, ${getDomainColor(event.domain ?? null)}aa)` }"
          >
            <div class="w-full h-full flex items-center justify-center text-white text-4xl">
              {{ getDomainIcon(event.domain ?? null) }}
            </div>
          </div>

          <!-- Content -->
          <div class="flex-1 min-w-0">
            <div class="flex items-start justify-between gap-4 mb-2">
              <div class="flex-1 min-w-0">
                <h3 class="font-display font-bold text-lg text-gray-900 truncate">
                  {{ event.title }}
                </h3>
                <p v-if="event.short_desc" class="text-sm text-gray-600 line-clamp-2 mt-1">
                  {{ event.short_desc }}
                </p>
              </div>
              <div class="flex gap-2 flex-shrink-0">
                <span
                  :class="[
                    'badge text-xs px-2 py-1 rounded-full font-semibold',
                    event.is_published ? 'badge-paid' : 'badge-free'
                  ]"
                >
                  {{ event.is_published ? 'Objavljeno' : 'Draft' }}
                </span>
              </div>
            </div>

            <!-- Meta -->
            <div class="flex flex-wrap items-center gap-x-4 gap-y-2 text-sm text-gray-500 mb-3">
              <div class="flex items-center gap-1.5">
                <span>📅</span>
                <span>{{ formatDate(event.starts_at) }}</span>
              </div>
              <div class="flex items-center gap-1.5">
                <span>⏰</span>
                <span>{{ formatTime(event.starts_at) }}</span>
              </div>
              <div v-if="event.location" class="flex items-center gap-1.5">
                <span>📍</span>
                <span>{{ event.location }}</span>
              </div>
              <div class="flex items-center gap-1.5">
                <span>👶</span>
                <span>{{ event.age_min }}-{{ event.age_max }} god</span>
              </div>
              <div class="flex items-center gap-1.5">
                <span>👥</span>
                <span>{{ event.registrations_count || 0 }}/{{ event.capacity }}</span>
              </div>
            </div>

            <!-- Actions -->
            <div class="flex flex-wrap gap-2">
              <NuxtLink
                :to="`/admin/events/${event.id}/registrations`"
                class="btn-secondary text-xs px-3 py-1.5"
              >
                📋 Prijave ({{ event.registrations_count || 0 }})
              </NuxtLink>
              <NuxtLink
                :to="`/admin/events/${event.id}`"
                class="btn-secondary text-xs px-3 py-1.5"
              >
                ✏️ Uredi
              </NuxtLink>
              <button
                v-if="event.is_published"
                @click="togglePublish(event.id, false)"
                class="btn-secondary text-xs px-3 py-1.5"
              >
                👁️ Sakrij
              </button>
              <button
                v-else
                @click="togglePublish(event.id, true)"
                class="btn-primary text-xs px-3 py-1.5"
              >
                🚀 Objavi
              </button>
              <button
                @click="duplicateEvent(event.id)"
                class="btn-secondary text-xs px-3 py-1.5"
              >
                📄 Kopiraj
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="card text-center py-12">
      <div class="text-5xl mb-4">🎨</div>
      <p class="text-gray-500">Nema događaja u ovoj kategoriji.</p>
      <NuxtLink to="/admin/events/new" class="btn-primary mt-4 inline-block">
        Dodaj prvi događaj
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
// T-832: Admin Events Management — Index Page
// Lists all events (upcoming, past, drafts) with filtering and quick actions

definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Događaji — Admin — Šarena Sfera' })

const supabase = useSupabase()

const loading = ref(true)
type AdminEventRecord = {
  id: string
  title: string
  slug: string
  starts_at: string
  is_published: boolean
  image_url?: string | null
  short_desc?: string | null
  location?: string | null
  age_min?: number | null
  age_max?: number | null
  capacity?: number | null
  domain?: string | null
  registrations_count?: number
  registrations?: Array<{ count?: number | null }>
}

const events = ref<AdminEventRecord[]>([])
const currentTab = ref<'upcoming' | 'past' | 'drafts' | 'all'>('upcoming')

const tabs: Array<{ key: 'upcoming' | 'past' | 'drafts' | 'all'; label: string; count: number | null }> = [
  { key: 'upcoming', label: 'Nadolazeći', count: null },
  { key: 'past', label: 'Prošli', count: null },
  { key: 'drafts', label: 'Drafts', count: null },
  { key: 'all', label: 'Svi', count: null },
]

const filteredEvents = computed(() => {
  const now = new Date()
  switch (currentTab.value) {
    case 'upcoming':
      return events.value.filter((e) => new Date(e.starts_at) >= now && e.is_published)
    case 'past':
      return events.value.filter((e) => new Date(e.starts_at) < now)
    case 'drafts':
      return events.value.filter((e) => !e.is_published)
    case 'all':
    default:
      return events.value
  }
})

const domainColors: Record<string, string> = {
  emotional: '#cf2e2e',
  social: '#fcb900',
  creative: '#9b51e0',
  cognitive: '#0693e3',
  motor: '#00d084',
  language: '#f78da7',
  all: '#9b51e0',
}

const domainIcons: Record<string, string> = {
  emotional: '❤️',
  social: '🤝',
  creative: '🎨',
  cognitive: '🧠',
  motor: '🏃',
  language: '💬',
  all: '🌟',
}

function getDomainColor(domain: string | null): string {
  return domainColors[domain || 'all'] || domainColors.all
}

function getDomainIcon(domain: string | null): string {
  return domainIcons[domain || 'all'] || domainIcons.all
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
}

function formatTime(iso: string): string {
  return new Date(iso).toLocaleTimeString('bs-BA', {
    hour: '2-digit',
    minute: '2-digit',
  })
}

async function loadEvents() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('events')
      .select(`
        *,
        registrations:event_registrations(count)
      `)
      .order('starts_at', { ascending: false })

    if (error) throw error

    // Count registrations
    events.value = ((data || []) as AdminEventRecord[]).map((event) => ({
      ...event,
      registrations_count: event.registrations?.[0]?.count || 0,
    }))

    // Update tab counts
    const now = new Date()
    tabs[0]!.count = events.value.filter((e) => new Date(e.starts_at) >= now && e.is_published).length
    tabs[1]!.count = events.value.filter((e) => new Date(e.starts_at) < now).length
    tabs[2]!.count = events.value.filter((e) => !e.is_published).length
    tabs[3]!.count = events.value.length
  } catch (err) {
    console.error('Failed to load events:', err)
  } finally {
    loading.value = false
  }
}

async function togglePublish(id: string, publish: boolean) {
  try {
    const { error } = await supabase
      .from('events')
      .update({ is_published: publish })
      .eq('id', id)

    if (error) throw error

    // Update local state
    const event = events.value.find((entry) => entry.id === id)
    if (event) event.is_published = publish
  } catch (err) {
    console.error('Failed to toggle publish:', err)
    alert('Greška pri ažuriranju statusa')
  }
}

async function duplicateEvent(id: string) {
  if (!confirm('Da li želite kopirati ovaj događaj?')) return

  try {
    const original = events.value.find((entry) => entry.id === id)
    if (!original) return

    const { error } = await supabase
      .from('events')
      .insert({
        ...original,
        id: undefined,
        slug: `${original.slug || original.id}-copy-${Date.now()}`,
        title: `${original.title} (Kopija)`,
        is_published: false,
        created_at: undefined,
        updated_at: undefined,
      })
      .select()
      .single()

    if (error) throw error

    alert('Događaj kopiran uspješno!')
    await loadEvents()
  } catch (err) {
    console.error('Failed to duplicate event:', err)
    alert('Greška pri kopiranju događaja')
  }
}

onMounted(() => {
  loadEvents()
})
</script>
