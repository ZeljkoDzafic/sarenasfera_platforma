<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Događaji i Webinari</h1>
      <p class="text-sm text-gray-500 mt-1">Prijavi se na predstojeće događaje i pristupi snimcima</p>
    </div>

    <!-- Tabs -->
    <div class="flex gap-1 bg-gray-100 rounded-xl p-1">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        class="flex-1 py-2 px-3 rounded-lg text-sm font-semibold transition-all"
        :class="activeTab === tab.key ? 'bg-white shadow-sm text-gray-900' : 'text-gray-500 hover:text-gray-700'"
        @click="activeTab = tab.key"
      >
        {{ tab.label }}
      </button>
    </div>

    <!-- My Registrations -->
    <section v-if="activeTab === 'my'" class="space-y-4">
      <h2 class="font-display font-bold text-lg text-gray-900">Moje Prijave</h2>

      <div v-if="myRegistrations && myRegistrations.length > 0" class="space-y-3">
        <div
          v-for="reg in myRegistrations"
          :key="reg.id"
          class="card"
        >
          <div class="flex items-start justify-between gap-4">
            <div class="flex items-start gap-4 flex-1">
              <!-- Event icon -->
              <div
                class="w-16 h-16 rounded-xl flex items-center justify-center text-2xl flex-shrink-0"
                :class="getEventIconClass(reg.educational_content?.content_type)"
              >
                {{ getEventIcon(reg.educational_content?.content_type) }}
              </div>

              <!-- Info -->
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 mb-1">
                  <h3 class="font-bold text-gray-900">{{ reg.educational_content?.title }}</h3>
                  <TierBadge :tier="reg.educational_content?.required_tier" size="sm" />
                </div>
                <p class="text-sm text-gray-600 line-clamp-2 mb-2">
                  {{ reg.educational_content?.description }}
                </p>
                <div class="flex flex-wrap items-center gap-3 text-xs text-gray-500">
                  <span class="flex items-center gap-1">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    {{ formatDate(reg.educational_content?.metadata?.start_date) }}
                  </span>
                  <span class="flex items-center gap-1">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    {{ formatTime(reg.educational_content?.metadata?.start_time) }}
                  </span>
                  <span
                    class="px-2 py-0.5 rounded-full text-xs font-semibold"
                    :class="reg.educational_content?.metadata?.is_online ? 'bg-primary-100 text-primary-700' : 'bg-brand-green/10 text-brand-green'"
                  >
                    {{ reg.educational_content?.metadata?.is_online ? '🔴 Online' : '📍 Uživo' }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Status & Actions -->
            <div class="text-right">
              <span
                class="text-xs font-semibold px-2 py-0.5 rounded-full"
                :class="getStatusClass(reg.status)"
              >
                {{ getStatusLabel(reg.status) }}
              </span>

              <div class="flex gap-2 mt-3">
                <button
                  v-if="reg.status === 'confirmed' && reg.meeting_link"
                  class="btn-primary text-xs"
                  @click="joinMeeting(reg.meeting_link)"
                >
                  📹 Uđi u meeting
                </button>
                <button
                  class="btn-secondary text-xs"
                  @click="downloadCalendar(reg)"
                >
                  📅 Dodaj u kalendar
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="card text-center py-12">
        <div class="text-4xl mb-3">📅</div>
        <p class="text-gray-600 text-sm">Nisi prijavljen/a na nijedan događaj.</p>
        <NuxtLink to="/events" class="btn-primary text-sm mt-4 inline-block">
          Pogledaj događaje
        </NuxtLink>
      </div>
    </section>

    <!-- Upcoming Events -->
    <section v-if="activeTab === 'upcoming'" class="space-y-4">
      <h2 class="font-display font-bold text-lg text-gray-900">Predstojeći Događaji</h2>

      <div v-if="upcomingEvents && upcomingEvents.length > 0" class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div
          v-for="event in upcomingEvents"
          :key="event.id"
          class="card hover:shadow-md transition-shadow"
        >
          <div
            v-if="event.cover_image_url"
            class="h-40 rounded-xl bg-cover bg-center mb-4 -mx-6 -mt-6"
            :style="{ backgroundImage: `url(${event.cover_image_url})` }"
          />

          <div class="flex items-center gap-2 mb-2">
            <span
              class="px-2 py-1 rounded-full text-xs font-semibold"
              :class="event.metadata?.is_online ? 'bg-primary-100 text-primary-700' : 'bg-brand-green/10 text-brand-green'"
            >
              {{ event.metadata?.is_online ? '🔴 Webinar' : '📍 Događaj' }}
            </span>
            <TierBadge :tier="event.required_tier" size="sm" />
          </div>

          <h3 class="font-bold text-gray-900 mb-1">{{ event.title }}</h3>
          <p class="text-sm text-gray-600 line-clamp-2 mb-3">{{ event.description }}</p>

          <div class="flex flex-wrap items-center gap-3 text-xs text-gray-500 mb-4">
            <span class="flex items-center gap-1">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              {{ formatDate(event.metadata?.start_date) }}
            </span>
            <span class="flex items-center gap-1">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              {{ formatTime(event.metadata?.start_time) }}
            </span>
            <span class="flex items-center gap-1">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              {{ event.metadata?.capacity || '∞' }} mjesta
            </span>
          </div>

          <button
            class="btn-primary w-full text-sm"
            @click="registerForEvent(event)"
            :disabled="isRegistered(event.id)"
          >
            {{ isRegistered(event.id) ? '✓ Prijavljen/a' : 'Prijavi se' }}
          </button>
        </div>
      </div>

      <div v-else class="card text-center py-12">
        <div class="text-4xl mb-3">📅</div>
        <p class="text-gray-600 text-sm">Nema predstojećih događaja.</p>
      </div>
    </section>

    <!-- Recordings (Premium) -->
    <section v-if="activeTab === 'recordings'" class="space-y-4">
      <div class="flex items-center justify-between">
        <h2 class="font-display font-bold text-lg text-gray-900">Snimci Događaja</h2>
        <TierBadge tier="premium" />
      </div>

      <FeatureGate required-tier="premium">
        <template #locked>
          <div class="text-center py-12">
            <div class="text-5xl mb-4">🔒</div>
            <h3 class="font-display font-bold text-xl text-gray-900 mb-2">
              Snimci su dostupni na Premium tieru
            </h3>
            <p class="text-gray-600 mb-6">
              Nadogradite na Premium tier za pristup snimcima prošlih događaja.
            </p>
            <NuxtLink to="/pricing" class="btn-primary">Pregledajte Planove</NuxtLink>
          </div>
        </template>

        <div v-if="recordings && recordings.length > 0" class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div
            v-for="rec in recordings"
            :key="rec.id"
            class="card"
          >
            <div class="flex items-start gap-4">
              <div class="w-20 h-20 rounded-xl bg-gradient-to-br from-primary-500 to-brand-pink flex items-center justify-center text-3xl flex-shrink-0">
                🎬
              </div>
              <div class="flex-1 min-w-0">
                <h3 class="font-bold text-gray-900 mb-1">{{ rec.title }}</h3>
                <p class="text-sm text-gray-600 line-clamp-2 mb-2">{{ rec.description }}</p>
                <p class="text-xs text-gray-500">
                  Održano: {{ formatDate(rec.metadata?.start_date) }}
                </p>
              </div>
            </div>

            <a
              v-if="rec.metadata?.recording_url"
              :href="rec.metadata.recording_url"
              target="_blank"
              class="btn-secondary w-full text-sm mt-4"
            >
              ▶️ Pogledaj snimak
            </a>
          </div>
        </div>

        <div v-else class="card text-center py-12">
          <div class="text-4xl mb-3">🎬</div>
          <p class="text-gray-600 text-sm">Još nema dostupnih snimaka.</p>
        </div>
      </FeatureGate>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })
useSeoMeta({ title: 'Moji Događaji — Šarena Sfera' })

const supabase = useSupabase()
const { user } = useAuth()

const activeTab = ref('my')
const tabs = [
  { key: 'my', label: 'Moje Prijave' },
  { key: 'upcoming', label: 'Predstojeći' },
  { key: 'recordings', label: 'Snimci' },
]

// Load my registrations
const { data: myRegistrations } = await useAsyncData('my-event-registrations', async () => {
  if (!user.value) return []

  const { data } = await supabase
    .from('content_registrations')
    .select(`
      *,
      educational_content(
        id, title, slug, description, content_type, required_tier,
        metadata, cover_image_url
      )
    `)
    .eq('user_id', user.value.id)
    .order('registered_at', { ascending: false })

  return data ?? []
})

// Load upcoming events
const { data: upcomingEvents } = await useAsyncData('upcoming-events', async () => {
  const { data } = await supabase
    .from('educational_content')
    .select('*')
    .eq('content_type', 'event')
    .eq('status', 'published')
    .gte('metadata->>start_date', new Date().toISOString().split('T')[0])
    .order('metadata->>start_date')

  return data ?? []
})

// Load recordings (premium)
const { data: recordings } = await useAsyncData('event-recordings', async () => {
  const { data } = await supabase
    .from('educational_content')
    .select('*')
    .eq('content_type', 'event')
    .eq('status', 'published')
    .lte('metadata->>start_date', new Date().toISOString().split('T')[0])
    .not('metadata->recording_url', 'is', null)
    .order('metadata->>start_date', { ascending: false })
    .limit(10)

  return data ?? []
})

const registeredEventIds = computed(() =>
  myRegistrations.value?.map(r => r.content_id) || []
)

function isRegistered(eventId: string): boolean {
  return registeredEventIds.value.includes(eventId)
}

async function registerForEvent(event: any) {
  if (!user.value) return

  try {
    await supabase.from('content_registrations').insert({
      user_id: user.value.id,
      content_id: event.id,
      status: 'registered',
    })

    await refreshNuxtData('my-event-registrations')
    await refreshNuxtData('upcoming-events')
  } catch (err) {
    console.error('Failed to register:', err)
  }
}

function joinMeeting(link: string) {
  window.open(link, '_blank')
}

function downloadCalendar(reg: any) {
  const event = reg.educational_content
  const startDate = event.metadata?.start_date
  const startTime = event.metadata?.start_time

  const icsContent = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Šarena Sfera//Event//BA',
    'BEGIN:VEVENT',
    `UID:${event.id}@sarenasfera.com`,
    `DTSTAMP:${new Date().toISOString().replace(/[-:]/g, '').split('.')[0]}Z`,
    `DTSTART:${startDate?.replace(/-/g, '')}T${startTime?.replace(':', '') || '100000'}`,
    `SUMMARY:${event.title}`,
    `DESCRIPTION:${event.description?.replace(/\n/g, '\\n')}`,
    'END:VEVENT',
    'END:VCALENDAR',
  ].join('\r\n')

  const blob = new Blob([icsContent], { type: 'text/calendar' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${event.slug || 'event'}.ics`
  a.click()
  URL.revokeObjectURL(url)
}

function getEventIcon(type: string): string {
  return type === 'webinar' ? '🔴' : '📍'
}

function getEventIconClass(type: string): string {
  return type === 'webinar' ? 'bg-primary-100 text-primary-600' : 'bg-brand-green/10 text-brand-green'
}

function getStatusClass(status: string): string {
  const map: Record<string, string> = {
    registered: 'bg-primary-100 text-primary-700',
    confirmed: 'bg-brand-green/10 text-brand-green',
    waitlist: 'bg-brand-amber/10 text-brand-amber',
    cancelled: 'bg-gray-100 text-gray-500',
    attended: 'bg-brand-pink/10 text-brand-pink',
  }
  return map[status] || 'bg-gray-100 text-gray-600'
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = {
    registered: 'Prijavljen',
    confirmed: 'Potvrđen',
    waitlist: 'Lista čekanja',
    cancelled: 'Otkazan',
    attended: 'Prisustvovao',
  }
  return map[status] || status
}

function formatDate(dateStr: string): string {
  if (!dateStr) return '—'
  return new Date(dateStr).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short', year: 'numeric' })
}

function formatTime(timeStr: string): string {
  if (!timeStr) return '—'
  return timeStr
}
</script>
