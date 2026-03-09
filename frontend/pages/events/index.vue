<template>
  <div>
    <!-- Hero -->
    <section class="bg-gradient-to-br from-brand-red to-brand-amber py-16 px-4 text-white text-center">
      <div class="max-w-3xl mx-auto">
        <h1 class="font-display text-4xl font-bold mb-3">Radionice i Događaji</h1>
        <p class="text-white/90 text-lg">
          Prijavite dijete na radionicu. Prva je besplatna!
        </p>
      </div>
    </section>

    <section class="py-12 px-4">
      <div class="max-w-6xl mx-auto">

        <div class="mb-6 flex flex-wrap gap-2">
          <button
            v-for="tab in tabs"
            :key="tab.value"
            class="rounded-xl px-4 py-2 text-sm font-semibold transition-all"
            :class="activeTab === tab.value ? 'bg-primary-500 text-white shadow-colorful' : 'bg-white text-gray-600 hover:bg-primary-50 border border-gray-200'"
            @click="activeTab = tab.value"
          >
            {{ tab.label }}
          </button>
        </div>

        <!-- Filters -->
        <div class="flex flex-wrap gap-3 mb-8">
          <!-- Age filter -->
          <div class="flex items-center gap-2">
            <label class="text-sm font-semibold text-gray-600">Uzrast:</label>
            <select v-model="filterAge" class="input text-sm py-1.5 pr-8 w-auto">
              <option value="">Svi uzrasti</option>
              <option value="2-3">2–3 godine</option>
              <option value="3-4">3–4 godine</option>
              <option value="4-5">4–5 godina</option>
              <option value="5-6">5–6 godina</option>
            </select>
          </div>

          <!-- Domain filter -->
          <div class="flex items-center gap-2">
            <label class="text-sm font-semibold text-gray-600">Oblast:</label>
            <select v-model="filterDomain" class="input text-sm py-1.5 pr-8 w-auto">
              <option value="">Sve oblasti</option>
              <option v-for="d in domains" :key="d.key" :value="d.key">{{ d.name }}</option>
            </select>
          </div>

          <button
            v-if="filterAge || filterDomain"
            class="btn-ghost text-sm"
            @click="filterAge = ''; filterDomain = ''"
          >
            ✕ Obriši filtere
          </button>
        </div>

        <!-- Loading state -->
        <div v-if="pending" class="text-center py-16">
          <div class="animate-spin w-8 h-8 border-2 border-primary-500 border-t-transparent rounded-full mx-auto mb-4" />
          <p class="text-gray-500">Učitavam događaje...</p>
        </div>

        <!-- No results -->
        <div v-else-if="filteredEvents.length === 0" class="text-center py-16">
          <p class="text-5xl mb-4">📅</p>
          <h3 class="font-bold text-xl text-gray-900 mb-2">Nema predstojećih događaja</h3>
          <p class="text-gray-600 mb-4">Pratite nas za najave novih termina.</p>
          <NuxtLink to="/contact" class="btn-primary">Obavijestite me o novim terminima</NuxtLink>
        </div>

        <!-- Events Grid -->
        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <NuxtLink
            v-for="event in filteredEvents"
            :key="event.id"
            :to="`/events/${event.slug}`"
            class="card-hover block group"
          >
            <!-- Domain color bar -->
            <div class="h-2 rounded-t-2xl -mx-6 -mt-6 mb-4" :style="{ backgroundColor: getDomainColor(event.domain) }" />

            <div class="flex items-start justify-between mb-3 gap-3">
              <div class="flex flex-wrap gap-2">
                <span
                  class="text-xs font-semibold px-2 py-1 rounded-full"
                  :style="{ backgroundColor: getDomainColor(event.domain) + '20', color: getDomainColor(event.domain) }"
                >
                  {{ getDomainName(event.domain) }}
                </span>
                <span
                  class="text-xs font-semibold px-2 py-1 rounded-full"
                  :class="event.contentType === 'webinar' ? 'bg-brand-blue/10 text-brand-blue' : event.contentType === 'event' ? 'bg-brand-amber/10 text-brand-amber' : 'bg-gray-100 text-gray-600'"
                >
                  {{ event.typeLabel }}
                </span>
              </div>
              <span v-if="event.is_free" class="badge-free text-xs">Besplatno</span>
              <span v-else class="badge-paid text-xs">{{ event.price_km }} KM</span>
            </div>

            <h3 class="font-display font-bold text-lg text-gray-900 mb-2 group-hover:text-primary-600 transition-colors">
              {{ event.title }}
            </h3>
            <p class="text-gray-600 text-sm mb-4 line-clamp-2">{{ event.short_desc }}</p>

            <div class="space-y-2 text-sm text-gray-500">
              <div class="flex items-center gap-2">
                <svg class="w-4 h-4 flex-shrink-0 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                {{ formatDate(event.starts_at) }}
              </div>
              <div class="flex items-center gap-2">
                <svg class="w-4 h-4 flex-shrink-0 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {{ formatTime(event.starts_at) }} – {{ formatTime(event.ends_at) }}
              </div>
              <div class="flex items-center gap-2">
                <svg class="w-4 h-4 flex-shrink-0 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                </svg>
                {{ event.location }}
              </div>
              <div class="flex items-center gap-2">
                <svg class="w-4 h-4 flex-shrink-0 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
                Uzrast {{ event.age_min }}–{{ event.age_max }} god. • {{ event.capacity }} mjesta
              </div>
            </div>

            <div class="mt-4 pt-4 border-t border-gray-100">
              <span class="text-primary-600 font-semibold text-sm group-hover:text-primary-700">
                Pogledaj i prijavi se →
              </span>
            </div>
          </NuxtLink>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
useSeoMeta({
  title: 'Radionice — Šarena Sfera',
  description: 'Prijavite dijete na radionice Šarene Sfere. Prva radionica je besplatna! Uzrast 2–6 godina.',
  ogTitle: 'Radionice i Događaji — Šarena Sfera',
})

const filterAge = ref('')
const filterDomain = ref('')
const activeTab = ref<'all' | 'workshop' | 'webinar' | 'event'>('all')

interface EventCard {
  id: string
  slug: string
  title: string
  short_desc: string
  description?: string
  domain: string
  age_min: number
  age_max: number
  contentType: 'workshop' | 'webinar' | 'event'
  typeLabel: string
  is_free: boolean
  price_km: number
  location: string
  location_url?: string | null
  starts_at?: string
  ends_at?: string
  capacity: number
}

const tabs = [
  { value: 'all', label: 'Sve' },
  { value: 'workshop', label: 'Radionice' },
  { value: 'webinar', label: 'Webinari' },
  { value: 'event', label: 'Događaji' },
] as const

const domains = [
  { key: 'emotional', name: 'Emocionalni', color: '#cf2e2e' },
  { key: 'social', name: 'Socijalni', color: '#fcb900' },
  { key: 'creative', name: 'Kreativni', color: '#9b51e0' },
  { key: 'cognitive', name: 'Kognitivni', color: '#0693e3' },
  { key: 'motor', name: 'Motorički', color: '#00d084' },
  { key: 'language', name: 'Jezički', color: '#f78da7' },
]

function getDomainColor(domain: string): string {
  return domains.find(d => d.key === domain)?.color ?? '#9b51e0'
}

function getDomainName(domain: string): string {
  return domains.find(d => d.key === domain)?.name ?? domain
}

// Fetch events from Supabase
const supabase = useSupabase()
const { data: events, pending } = await useAsyncData<EventCard[]>('events', async () => {
  const { data: workshopRows } = await supabase
    .from('events')
    .select('*')
    .eq('is_published', true)
    .eq('is_active', true)
    .gte('starts_at', new Date().toISOString())
    .order('starts_at', { ascending: true })

  const { data: educationRows } = await supabase
    .from('educational_content')
    .select('id, title, slug, description, short_description, domain, age_min, age_max, required_tier, starts_at, ends_at, location_name, location_url, capacity, content_type, event_subtype, external_registration_url')
    .in('content_type', ['event', 'webinar'])
    .eq('status', 'published')
    .order('starts_at', { ascending: true, nullsFirst: false })

  const workshops: EventCard[] = (workshopRows ?? []).map((event: Record<string, any>) => ({
    ...event,
    id: String(event.id),
    slug: String(event.slug ?? event.id),
    title: String(event.title ?? 'Radionica'),
    short_desc: String(event.short_desc ?? event.description ?? ''),
    domain: String(event.domain ?? 'creative'),
    age_min: Number(event.age_min ?? 2),
    age_max: Number(event.age_max ?? 6),
    contentType: 'workshop',
    typeLabel: 'Radionica',
    price_km: Number(event.price_km ?? 0),
    is_free: Boolean(event.is_free),
    location: String(event.location ?? 'Šarena Sfera'),
    starts_at: event.starts_at,
    ends_at: event.ends_at ?? event.starts_at,
    capacity: Number(event.capacity ?? 0),
  }))

  const education: EventCard[] = (educationRows ?? []).map((content: Record<string, any>) => ({
    id: String(content.id),
    slug: String(content.slug ?? content.id),
    title: String(content.title ?? 'Događaj'),
    short_desc: String(content.short_description ?? content.description ?? 'Edukativni sadržaj za roditelje i djecu.'),
    description: String(content.description ?? ''),
    domain: String(content.domain ?? 'creative'),
    age_min: Number(content.age_min ?? 2),
    age_max: Number(content.age_max ?? 6),
    contentType: content.content_type === 'webinar' ? 'webinar' : 'event',
    typeLabel: content.content_type === 'webinar'
      ? 'Webinar'
      : content.event_subtype === 'workshop'
        ? 'Radionica'
        : content.event_subtype === 'open_day'
          ? 'Open day'
          : 'Događaj',
    is_free: content.required_tier === 'free',
    price_km: Number(content.required_tier === 'paid' ? 15 : content.required_tier === 'premium' ? 30 : 0),
    location: String(content.content_type === 'webinar'
      ? (content.location_name || content.location_url || 'Online pristup')
      : (content.location_name || 'Detalji lokacije po prijavi')),
    location_url: content.location_url ?? content.external_registration_url ?? null,
    starts_at: content.starts_at,
    ends_at: content.ends_at ?? content.starts_at,
    capacity: Number(content.capacity ?? 0),
  }))

  return [...workshops, ...education]
})

const filteredEvents = computed<EventCard[]>(() => {
  let list = events.value ?? []

  if (activeTab.value !== 'all') {
    list = list.filter((e) => e.contentType === activeTab.value)
  }

  if (filterDomain.value) {
    list = list.filter((e) => e.domain === filterDomain.value)
  }

  if (filterAge.value) {
    const ageParts = filterAge.value.split('-').map(Number)
    const minAge = ageParts[0]
    const maxAge = ageParts[1]
    if (Number.isNaN(minAge) || Number.isNaN(maxAge)) return list
    list = list.filter((e) => {
      const ageMin = e.age_min
      const ageMax = e.age_max
      return ageMin <= (maxAge ?? ageMin) && ageMax >= (minAge ?? ageMax)
    })
  }

  return list
})

function formatDate(iso?: string): string {
  if (!iso) return 'Termin uskoro'
  return new Date(iso).toLocaleDateString('bs-BA', { weekday: 'long', day: 'numeric', month: 'long' })
}

function formatTime(iso?: string): string {
  if (!iso) return 'TBD'
  return new Date(iso).toLocaleTimeString('bs-BA', { hour: '2-digit', minute: '2-digit' })
}
</script>
