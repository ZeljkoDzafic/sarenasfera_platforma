<template>
  <div class="space-y-6">
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Kalendar radionica</h1>
      <p class="text-sm text-gray-500 mt-1">Nadolazeće i prošle radionice</p>
    </div>

    <!-- Month navigation -->
    <div class="card">
      <div class="flex items-center justify-between mb-4">
        <button class="p-2 rounded-xl hover:bg-gray-100 text-gray-500" @click="prevMonth">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <h2 class="font-display font-bold text-lg text-gray-900">{{ monthLabel }}</h2>
        <button class="p-2 rounded-xl hover:bg-gray-100 text-gray-500" @click="nextMonth">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </button>
      </div>

      <!-- Calendar grid -->
      <div class="grid grid-cols-7 gap-1 mb-2">
        <div v-for="day in ['Pon', 'Uto', 'Sri', 'Čet', 'Pet', 'Sub', 'Ned']" :key="day"
          class="text-center text-xs font-semibold text-gray-400 py-1">{{ day }}</div>
      </div>
      <div class="grid grid-cols-7 gap-1">
        <div v-for="(cell, idx) in calendarCells" :key="idx"
          class="aspect-square flex items-center justify-center rounded-xl text-sm relative"
          :class="[
            cell.isToday ? 'bg-primary-500 text-white font-bold' : '',
            cell.hasSession ? 'bg-primary-50 text-primary-700 font-semibold cursor-pointer hover:bg-primary-100' : '',
            !cell.isCurrentMonth ? 'text-gray-300' : 'text-gray-700',
            !cell.isToday && !cell.hasSession ? 'hover:bg-gray-50' : '',
          ]"
          @click="cell.hasSession && selectDay(cell.date)"
        >
          {{ cell.day }}
          <div v-if="cell.hasSession && !cell.isToday"
            class="absolute bottom-0.5 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-primary-500" />
        </div>
      </div>
    </div>

    <!-- Sessions list -->
    <div>
      <h2 class="font-display font-bold text-lg text-gray-900 mb-3">
        {{ selectedDate ? `Radionice — ${formatDay(selectedDate)}` : 'Nadolazeće radionice' }}
      </h2>

      <div v-if="pending" class="space-y-3">
        <div v-for="i in 3" :key="i" class="card animate-pulse h-20" />
      </div>

      <div v-else-if="displayedSessions.length > 0" class="space-y-3">
        <div
          v-for="session in displayedSessions"
          :key="session.id"
          class="card-domain"
          :style="{ borderColor: getDomainColor(firstSessionWorkshopDomain(session.workshops)) }"
        >
          <div class="flex items-start gap-3">
            <div
              class="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 text-white font-bold text-xs"
              :style="{ backgroundColor: getDomainColor(firstSessionWorkshopDomain(session.workshops)) }"
            >
              {{ formatDayNum(session.scheduled_date) }}
            </div>
            <div class="flex-1 min-w-0">
              <p class="font-semibold text-gray-900 truncate">{{ firstSessionWorkshopTitle(session.workshops) }}</p>
              <p class="text-sm text-gray-500">
                {{ formatDate(session.scheduled_date) }}
                {{ session.scheduled_time_start ? `• ${session.scheduled_time_start.slice(0,5)}` : '' }}
                {{ firstSessionGroupName(session.groups) ? `• ${firstSessionGroupName(session.groups)}` : '' }}
              </p>
            </div>
            <span
              class="text-xs font-semibold px-2 py-0.5 rounded-full flex-shrink-0"
              :class="sessionStatusClass(session.status)"
            >
              {{ sessionStatusLabel(session.status) }}
            </span>
          </div>
        </div>
      </div>

      <div v-else class="card text-center py-10">
        <div class="text-4xl mb-3">📅</div>
        <p class="text-gray-500">
          {{ selectedDate ? 'Nema radionica na ovaj datum.' : 'Nema nadolazećih radionica.' }}
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })
useSeoMeta({ title: 'Kalendar — Šarena Sfera' })

const supabase = useSupabase()
const { user } = useAuth()

const today = new Date()
const currentDate = ref(new Date(today.getFullYear(), today.getMonth(), 1))
const selectedDate = ref<Date | null>(null)

const monthLabel = computed(() =>
  currentDate.value.toLocaleDateString('bs-BA', { month: 'long', year: 'numeric' })
)

function prevMonth() { currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() - 1, 1) }
function nextMonth() { currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() + 1, 1) }

const { data: sessions, pending } = await useAsyncData('portal-sessions', async () => {
  if (!user.value) return []
  const { data } = await supabase
    .from('sessions')
    .select(`
      id, scheduled_date, scheduled_time_start, status,
      workshops(title, domains),
      groups(name, child_groups!inner(child_id, children!inner(parent_children!inner(parent_id))))
    `)
    .gte('scheduled_date', new Date(today.getFullYear(), today.getMonth() - 1, 1).toISOString())
    .lte('scheduled_date', new Date(today.getFullYear(), today.getMonth() + 2, 0).toISOString())
    .order('scheduled_date')
  return (data ?? []).filter((s: Record<string, unknown>) => {
    // Keep sessions where user's children are enrolled
    return true // RLS handles this
  })
})

const sessionDates = computed(() => new Set((sessions.value ?? []).map((s: { scheduled_date: string }) => s.scheduled_date)))

const calendarCells = computed(() => {
  const year = currentDate.value.getFullYear()
  const month = currentDate.value.getMonth()
  const firstDay = new Date(year, month, 1)
  const lastDay = new Date(year, month + 1, 0)
  // Monday-first: 0=Mon,...6=Sun
  let startDow = firstDay.getDay() - 1; if (startDow < 0) startDow = 6

  const cells = []
  for (let i = 0; i < startDow; i++) {
    const d = new Date(year, month, -startDow + i + 1)
    cells.push({ day: d.getDate(), date: d, isCurrentMonth: false, isToday: false, hasSession: false })
  }
  for (let d = 1; d <= lastDay.getDate(); d++) {
    const date = new Date(year, month, d)
    const iso = date.toISOString().slice(0, 10)
    const isToday = date.toDateString() === today.toDateString()
    cells.push({ day: d, date, isCurrentMonth: true, isToday, hasSession: sessionDates.value.has(iso) })
  }
  const rem = 7 - (cells.length % 7); if (rem < 7) {
    for (let i = 1; i <= rem; i++) {
      const d = new Date(year, month + 1, i)
      cells.push({ day: d.getDate(), date: d, isCurrentMonth: false, isToday: false, hasSession: false })
    }
  }
  return cells
})

function selectDay(date: Date) {
  selectedDate.value = selectedDate.value?.toDateString() === date.toDateString() ? null : date
}

const displayedSessions = computed(() => {
  if (selectedDate.value) {
    const iso = selectedDate.value.toISOString().slice(0, 10)
    return (sessions.value ?? []).filter((s: { scheduled_date: string }) => s.scheduled_date === iso)
  }
  const todayIso = today.toISOString().slice(0, 10)
  return (sessions.value ?? []).filter((s: { scheduled_date: string }) => s.scheduled_date >= todayIso)
})

const domainColors: Record<string, string> = {
  emotional: '#cf2e2e', social: '#fcb900', creative: '#9b51e0',
  cognitive: '#0693e3', motor: '#00d084', language: '#f78da7',
}
function getDomainColor(domain?: string): string { return domain ? (domainColors[domain] ?? '#9b51e0') : '#9b51e0' }

function firstSessionWorkshopDomain(workshops: Array<{ domains?: string[] | null }> | null | undefined): string | undefined {
  return workshops?.[0]?.domains?.[0] ?? undefined
}

function firstSessionWorkshopTitle(workshops: Array<{ title?: string | null }> | null | undefined): string {
  return workshops?.[0]?.title ?? 'Radionica'
}

function firstSessionGroupName(groups: Array<{ name?: string | null }> | null | undefined): string {
  return groups?.[0]?.name ?? ''
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'long' })
}
function formatDay(d: Date): string { return d.toLocaleDateString('bs-BA', { day: 'numeric', month: 'long' }) }
function formatDayNum(iso: string): string { return new Date(iso).getDate().toString() }

function sessionStatusClass(status: string): string {
  return { scheduled: 'bg-primary-100 text-primary-700', completed: 'bg-brand-green/10 text-brand-green', cancelled: 'bg-gray-100 text-gray-400' }[status] ?? 'bg-gray-100 text-gray-500'
}
function sessionStatusLabel(status: string): string {
  return { scheduled: 'Planirana', in_progress: 'U toku', completed: 'Završena', cancelled: 'Otkazana', postponed: 'Odgođena' }[status] ?? status
}
</script>
