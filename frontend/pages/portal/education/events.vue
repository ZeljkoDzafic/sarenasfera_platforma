<template>
  <div class="space-y-6">
    <section class="card-featured">
      <div class="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <p class="text-sm font-semibold uppercase tracking-wide text-white/90">Portal edukacija</p>
          <h1 class="mt-2 text-2xl font-bold text-white">Moji događaji i webinari</h1>
          <p class="mt-2 text-sm text-white/90">
            Pregled registracija, pristupnih linkova i snimaka za nadolazeće i prošle edukativne sadržaje.
          </p>
        </div>

        <div class="grid gap-2 sm:grid-cols-3">
          <label class="text-xs font-semibold text-white/90">
            Tip
            <select v-model="activeTab" class="input mt-1 min-h-11 py-2 text-gray-900">
              <option value="all">Sve</option>
              <option value="event">Događaji</option>
              <option value="webinar">Webinari</option>
            </select>
          </label>
          <label class="text-xs font-semibold text-white/90">
            Status
            <select v-model="statusFilter" class="input mt-1 min-h-11 py-2 text-gray-900">
              <option value="all">Svi statusi</option>
              <option value="registered">Registrovan</option>
              <option value="confirmed">Potvrđen</option>
              <option value="waitlist">Lista čekanja</option>
              <option value="attended">Prisustvovao</option>
            </select>
          </label>
          <label class="text-xs font-semibold text-white/90">
            Domena
            <select v-model="domainFilter" class="input mt-1 min-h-11 py-2 text-gray-900">
              <option value="all">Sve domene</option>
              <option v-for="domain in domains" :key="domain.key" :value="domain.key">{{ domain.label }}</option>
            </select>
          </label>
        </div>
      </div>
    </section>

    <div class="grid gap-4 md:grid-cols-3">
      <article v-for="stat in stats" :key="stat.label" class="card p-4">
        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-gray-500">{{ stat.label }}</p>
        <p class="mt-2 text-2xl font-bold text-gray-900">{{ stat.value }}</p>
        <p class="mt-1 text-sm text-gray-600">{{ stat.description }}</p>
      </article>
    </div>

    <div v-if="pending" class="grid gap-4 lg:grid-cols-2">
      <div v-for="i in 4" :key="i" class="card h-40 animate-pulse" />
    </div>

    <div v-else-if="filteredItems.length === 0" class="card py-14 text-center">
      <div class="mb-4 text-5xl">📭</div>
      <h2 class="font-display text-xl font-bold text-gray-900">Još nema registracija</h2>
      <p class="mt-2 text-sm text-gray-500">Kada se prijavite na događaj ili webinar, ovdje ćete dobiti sve detalje i pristupne linkove.</p>
      <div class="mt-6 flex flex-wrap justify-center gap-3">
        <NuxtLink to="/events" class="btn-primary">Pregledaj događaje</NuxtLink>
        <NuxtLink to="/portal/education/resources" class="btn-secondary">Idi na resurse</NuxtLink>
      </div>
    </div>

    <section v-else class="grid gap-4 xl:grid-cols-[1.3fr_0.7fr]">
      <div class="space-y-4">
        <article v-for="item in filteredItems" :key="item.registrationId" class="card overflow-hidden">
          <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div class="space-y-3">
              <div class="flex flex-wrap items-center gap-2">
                <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="item.type === 'webinar' ? 'bg-brand-blue/15 text-brand-blue' : 'bg-brand-amber/15 text-brand-amber'">
                  {{ item.type === 'webinar' ? 'Webinar' : 'Događaj' }}
                </span>
                <span v-if="item.subtypeLabel" class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-semibold text-gray-600">
                  {{ item.subtypeLabel }}
                </span>
                <span v-if="item.domainLabel" class="rounded-full px-2.5 py-1 text-xs font-semibold" :style="{ backgroundColor: `${item.domainColor}20`, color: item.domainColor }">
                  {{ item.domainLabel }}
                </span>
                <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="statusClass(item.status)">
                  {{ statusLabel(item.status) }}
                </span>
                <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="item.tier === 'premium' ? 'bg-primary-100 text-primary-700' : item.tier === 'paid' ? 'bg-brand-green/15 text-brand-green' : 'bg-gray-100 text-gray-600'">
                  {{ tierLabel(item.tier) }}
                </span>
              </div>

              <div>
                <h2 class="text-xl font-bold text-gray-900">{{ item.title }}</h2>
                <p class="mt-1 text-sm text-gray-600">{{ item.description }}</p>
              </div>

              <dl class="grid gap-3 sm:grid-cols-2">
                <div class="rounded-2xl bg-gray-50 p-3">
                  <dt class="text-xs font-semibold uppercase tracking-wide text-gray-500">Termin</dt>
                  <dd class="mt-1 text-sm font-semibold text-gray-900">{{ formatDateTime(item.startsAt, item.endsAt) }}</dd>
                </div>
                <div class="rounded-2xl bg-gray-50 p-3">
                  <dt class="text-xs font-semibold uppercase tracking-wide text-gray-500">{{ item.type === 'webinar' ? 'Pristup' : 'Lokacija' }}</dt>
                  <dd class="mt-1 text-sm font-semibold text-gray-900 break-all">{{ item.locationLabel }}</dd>
                </div>
              </dl>
            </div>

            <div class="flex w-full flex-col gap-2 lg:w-56">
              <a
                v-if="item.primaryActionHref"
                :href="item.primaryActionHref"
                :target="item.primaryActionExternal ? '_blank' : undefined"
                rel="noopener noreferrer"
                class="btn-primary text-center"
              >
                {{ item.primaryActionLabel }}
              </a>
              <button type="button" class="btn-secondary" @click="downloadCalendar(item)">
                Dodaj u kalendar
              </button>
              <NuxtLink to="/events" class="btn-ghost text-center">Novi događaji</NuxtLink>
            </div>
          </div>
        </article>
      </div>

      <div class="space-y-4">
        <FeatureGate required-tier="premium">
          <template #locked>
            <div class="card">
              <p class="text-xs font-semibold uppercase tracking-[0.25em] text-primary-600">Premium</p>
              <h3 class="mt-2 text-lg font-bold text-gray-900">Snimci webinara</h3>
              <p class="mt-2 text-sm text-gray-600">Otključajte premium pristup da biste gledali snimke prethodnih webinara kada su dostupni.</p>
            </div>
          </template>

          <div class="card">
            <div class="flex items-center justify-between gap-3">
              <div>
                <p class="text-xs font-semibold uppercase tracking-[0.25em] text-primary-600">Premium</p>
                <h3 class="mt-2 text-lg font-bold text-gray-900">Snimci i materijali</h3>
              </div>
              <span class="badge bg-primary-50 text-primary-700">{{ recordings.length }}</span>
            </div>

            <div v-if="recordings.length > 0" class="mt-4 space-y-3">
              <article v-for="recording in recordings" :key="recording.id" class="rounded-2xl bg-gray-50 p-4">
                <p class="font-semibold text-gray-900">{{ recording.title }}</p>
                <p class="mt-1 text-sm text-gray-600">{{ recording.contentTitle }}</p>
                <a :href="recording.fileUrl" target="_blank" rel="noopener noreferrer" class="mt-3 inline-flex text-sm font-semibold text-primary-600 hover:text-primary-700">
                  Otvori snimak →
                </a>
              </article>
            </div>
            <p v-else class="mt-4 text-sm text-gray-500">Još nema objavljenih snimaka za vaše registracije.</p>
          </div>
        </FeatureGate>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import FeatureGate from '~/components/portal/FeatureGate.vue'

definePageMeta({ middleware: 'auth', layout: 'portal' })

useSeoMeta({
  title: 'Moji događaji i webinari — Šarena Sfera',
  description: 'Portal pregled edukativnih događaja, registracija i pristupnih linkova.',
})

type TierName = 'free' | 'paid' | 'premium'
type ContentType = 'event' | 'webinar'
type RegistrationStatus = 'registered' | 'confirmed' | 'waitlist' | 'cancelled' | 'attended'
type DomainKey = 'emotional' | 'social' | 'creative' | 'cognitive' | 'motor' | 'language'

const supabase = useSupabase()
const { user } = useAuth()

const activeTab = ref<'all' | ContentType>('all')
const statusFilter = ref<'all' | RegistrationStatus>('all')
const domainFilter = ref<'all' | DomainKey>('all')

const domains: Array<{ key: DomainKey; label: string; color: string }> = [
  { key: 'emotional', label: 'Emocionalni', color: '#cf2e2e' },
  { key: 'social', label: 'Socijalni', color: '#fcb900' },
  { key: 'creative', label: 'Kreativni', color: '#9b51e0' },
  { key: 'cognitive', label: 'Kognitivni', color: '#0693e3' },
  { key: 'motor', label: 'Motorički', color: '#00d084' },
  { key: 'language', label: 'Jezički', color: '#f78da7' },
]

const { data: registrations, pending } = await useAsyncData('portal-education-events', async () => {
  if (!user.value) return []

  const { data } = await supabase
    .from('content_registrations')
    .select(`
      id,
      status,
      meeting_link,
      registered_at,
      attended_at,
        educational_content:content_id (
          id,
          title,
          slug,
          description,
          content_type,
          domain,
          required_tier,
          starts_at,
          ends_at,
          duration_minutes,
          location_name,
          location_url,
          external_registration_url,
          event_subtype
        )
    `)
    .eq('user_id', user.value.id)
    .order('registered_at', { ascending: false })

  return data ?? []
})

const { data: recordingsData } = await useAsyncData('portal-education-recordings', async () => {
  if (!user.value) return []

  const contentIds = (registrations.value ?? [])
    .map((row: Record<string, any>) => row.educational_content?.id)
    .filter(Boolean)

  if (contentIds.length === 0) return []

  const { data } = await supabase
    .from('resource_materials')
    .select('id, title, file_url, file_type, content_id')
    .in('content_id', contentIds)

  return data ?? []
})

const normalizedItems = computed(() => {
  return (registrations.value ?? [])
    .map((row: Record<string, any>) => {
      const content = row.educational_content
      if (!content || !['event', 'webinar'].includes(content.content_type)) return null

      const domain = content.domain as DomainKey | null
      const domainInfo = domains.find((item) => item.key === domain)
      const startsAt = content.starts_at || row.registered_at
      const endsAt = content.ends_at || content.starts_at || row.registered_at
      const isWebinar = content.content_type === 'webinar'
      const meetingLink = row.meeting_link as string | null
      const locationName = content.location_name as string | null
      const locationUrl = content.location_url as string | null
      const externalRegistrationUrl = content.external_registration_url as string | null
      const subtype = content.event_subtype as string | null

      let primaryActionHref: string | null = null
      let primaryActionLabel = 'Detalji registracije'
      let primaryActionExternal = false

      if (isWebinar && meetingLink) {
        primaryActionHref = meetingLink
        primaryActionLabel = 'Otvori webinar'
        primaryActionExternal = true
      } else if (!isWebinar && locationUrl) {
        primaryActionHref = locationUrl
        primaryActionLabel = 'Otvori lokaciju'
        primaryActionExternal = true
      } else if (externalRegistrationUrl) {
        primaryActionHref = externalRegistrationUrl
        primaryActionLabel = 'Detalji događaja'
        primaryActionExternal = true
      }

      return {
        registrationId: row.id as string,
        contentId: content.id as string,
        status: row.status as RegistrationStatus,
        type: content.content_type as ContentType,
        title: content.title as string,
        description: (content.description as string | null) ?? 'Detalji će biti dostupni unutar edukacijskog centra.',
        tier: content.required_tier as TierName,
        startsAt,
        endsAt,
        locationLabel: isWebinar
          ? (meetingLink ?? locationName ?? locationUrl ?? 'Link će biti dostavljen prije početka')
          : (locationName ?? locationUrl ?? 'Detalji lokacije bit će potvrđeni nakon registracije'),
        primaryActionLabel,
        primaryActionHref,
        primaryActionExternal,
        subtypeLabel: subtype === 'workshop' ? 'Radionica' : subtype === 'open_day' ? 'Open day' : subtype === 'event' ? 'Događaj' : null,
        domainLabel: domainInfo?.label ?? null,
        domainColor: domainInfo?.color ?? '#9b51e0',
      }
    })
    .filter(Boolean) as Array<{
      registrationId: string
      contentId: string
      status: RegistrationStatus
      type: ContentType
      title: string
      description: string
      tier: TierName
      startsAt: string
      endsAt: string
      locationLabel: string
      primaryActionLabel: string
      primaryActionHref: string | null
      primaryActionExternal: boolean
      subtypeLabel: string | null
      domainLabel: string | null
      domainColor: string
    }>
})

const filteredItems = computed(() => {
  return normalizedItems.value.filter((item) => {
    if (activeTab.value !== 'all' && item.type !== activeTab.value) return false
    if (statusFilter.value !== 'all' && item.status !== statusFilter.value) return false
    if (domainFilter.value !== 'all') {
      const domainMatch = domains.find((entry) => entry.label === item.domainLabel)?.key
      if (domainMatch !== domainFilter.value) return false
    }
    return true
  })
})

const stats = computed(() => {
  const items = normalizedItems.value
  return [
    {
      label: 'Aktivne registracije',
      value: items.filter((item) => ['registered', 'confirmed'].includes(item.status)).length,
      description: 'Nadolazeći termini spremni za pregled.',
    },
    {
      label: 'Webinari',
      value: items.filter((item) => item.type === 'webinar').length,
      description: 'Online sesije i pristupni linkovi.',
    },
    {
      label: 'Prisustva',
      value: items.filter((item) => item.status === 'attended').length,
      description: 'Završeni događaji i webinari.',
    },
  ]
})

const recordings = computed(() => {
  const webinarIds = new Set(
    normalizedItems.value
      .filter((item) => item.type === 'webinar')
      .map((item) => item.contentId),
  )

  return (recordingsData.value ?? [])
    .filter((item: Record<string, any>) => webinarIds.has(item.content_id) && ['video', 'audio', 'document'].includes(item.file_type))
    .map((item: Record<string, any>) => {
      const parent = normalizedItems.value.find((entry) => entry.contentId === item.content_id)
      return {
        id: item.id as string,
        title: item.title as string,
        fileUrl: item.file_url as string,
        contentTitle: parent?.title ?? 'Webinar',
      }
    })
})

function formatDateTime(start?: string, end?: string) {
  if (!start) return 'Termin će biti potvrđen'
  const startDate = new Date(start)
  const dateLabel = startDate.toLocaleDateString('bs-BA', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
  const startTime = startDate.toLocaleTimeString('bs-BA', {
    hour: '2-digit',
    minute: '2-digit',
  })
  if (!end) return `${dateLabel} u ${startTime}`
  const endTime = new Date(end).toLocaleTimeString('bs-BA', {
    hour: '2-digit',
    minute: '2-digit',
  })
  return `${dateLabel} u ${startTime} - ${endTime}`
}

function statusLabel(status: RegistrationStatus) {
  const labels: Record<RegistrationStatus, string> = {
    registered: 'Registrovan',
    confirmed: 'Potvrđen',
    waitlist: 'Lista čekanja',
    cancelled: 'Otkazan',
    attended: 'Prisustvovao',
  }
  return labels[status]
}

function statusClass(status: RegistrationStatus) {
  const classes: Record<RegistrationStatus, string> = {
    registered: 'bg-primary-100 text-primary-700',
    confirmed: 'bg-brand-green/15 text-brand-green',
    waitlist: 'bg-brand-amber/15 text-brand-amber',
    cancelled: 'bg-brand-red/15 text-brand-red',
    attended: 'bg-brand-blue/15 text-brand-blue',
  }
  return classes[status]
}

function tierLabel(tier: TierName) {
  const labels: Record<TierName, string> = {
    free: 'Free',
    paid: 'Paid',
    premium: 'Premium',
  }
  return labels[tier]
}

function downloadCalendar(item: { title: string; startsAt?: string; endsAt?: string; description: string; locationLabel: string }) {
  const start = item.startsAt ? new Date(item.startsAt) : new Date()
  const end = item.endsAt ? new Date(item.endsAt) : new Date(start.getTime() + 60 * 60 * 1000)
  const formatIcsDate = (value: Date) => value.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}Z$/, 'Z')

  const ics = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Sarena Sfera//Education//BS',
    'BEGIN:VEVENT',
    `UID:${crypto.randomUUID()}`,
    `DTSTAMP:${formatIcsDate(new Date())}`,
    `DTSTART:${formatIcsDate(start)}`,
    `DTEND:${formatIcsDate(end)}`,
    `SUMMARY:${item.title}`,
    `DESCRIPTION:${item.description.replace(/\n/g, ' ')}`,
    `LOCATION:${item.locationLabel.replace(/\n/g, ' ')}`,
    'END:VEVENT',
    'END:VCALENDAR',
  ].join('\r\n')

  const blob = new Blob([ics], { type: 'text/calendar;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `${item.title.toLowerCase().replace(/[^a-z0-9]+/gi, '-')}.ics`
  link.click()
  URL.revokeObjectURL(url)
}
</script>
