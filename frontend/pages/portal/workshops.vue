<template>
  <div class="space-y-6">
    <section class="card">
      <div class="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Radionice</h1>
          <p class="text-sm text-gray-600">Kalendar termina, detalji sesija i materijali za preuzimanje.</p>
        </div>

        <div class="grid gap-2 sm:grid-cols-3">
          <label class="text-xs font-semibold text-gray-600">
            Dijete
            <select v-model="selectedChild" class="input mt-1 min-h-11 py-2">
              <option value="all">Sva djeca</option>
              <option v-for="child in childOptions" :key="child" :value="child">{{ child }}</option>
            </select>
          </label>
          <label class="text-xs font-semibold text-gray-600">
            Grupa
            <select v-model="selectedGroup" class="input mt-1 min-h-11 py-2">
              <option value="all">Sve grupe</option>
              <option v-for="group in groupOptions" :key="group" :value="group">{{ group }}</option>
            </select>
          </label>
          <label class="text-xs font-semibold text-gray-600">
            Prikaz
            <select v-model="viewMode" class="input mt-1 min-h-11 py-2">
              <option value="calendar">Kalendar</option>
              <option value="list">Lista</option>
            </select>
          </label>
        </div>
      </div>
    </section>

    <WorkshopCalendar
      v-if="viewMode === 'calendar'"
      :sessions="calendarSessions"
      :selected-month="selectedMonth"
    />

    <section v-else class="space-y-3">
      <article
        v-for="session in filteredSessions"
        :key="session.id"
        class="card"
      >
        <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <h2 class="text-lg font-bold text-gray-900">{{ session.title }}</h2>
            <p class="text-sm text-gray-700">{{ session.description }}</p>
            <p class="mt-1 text-sm text-gray-600">{{ session.dateLabel }} • {{ session.group }} • {{ session.child }}</p>
          </div>
          <span class="badge" :class="session.isPast ? 'badge-free' : 'badge-paid'">
            {{ session.isPast ? `Prošlo (${session.attendanceStatus})` : 'Nadolazeće' }}
          </span>
        </div>

        <div class="mt-4 flex flex-wrap gap-2">
          <a
            v-for="material in session.materials"
            :key="material.name"
            href="#"
            class="btn-secondary"
            @click.prevent
          >
            Preuzmi {{ material.type }}: {{ material.name }}
          </a>
        </div>
      </article>
    </section>

    <section class="card">
      <h2 class="text-lg font-bold text-gray-900">Nedavne radionice</h2>
      <ul class="mt-3 space-y-2 text-sm text-gray-700">
        <li
          v-for="session in pastSessions"
          :key="session.id"
          class="rounded-xl bg-gray-50 p-3"
        >
          <p class="font-semibold">{{ session.title }}</p>
          <p>{{ session.dateLabel }} • Status prisustva: {{ session.attendanceStatus }}</p>
        </li>
      </ul>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'portal' })

type ViewMode = 'calendar' | 'list'

interface MaterialItem {
  name: string
  type: 'PDF' | 'slika'
}

interface WorkshopSession {
  id: string
  title: string
  description: string
  date: string
  dateLabel: string
  group: string
  child: string
  materials: MaterialItem[]
  isPast: boolean
  attendanceStatus: 'prisutan' | 'odsutan' | 'kasni'
}

const selectedMonth = new Date(2026, 2, 1)
const viewMode = ref<ViewMode>('calendar')
const selectedChild = ref('all')
const selectedGroup = ref('all')

const sessions: WorkshopSession[] = [
  {
    id: 'w1',
    title: 'Mali istraživači boja',
    description: 'Eksperimenti sa miješanjem boja i prepoznavanjem emocija kroz boje.',
    date: '2026-03-10',
    dateLabel: '10.03.2026 10:00',
    group: 'Srednja grupa',
    child: 'Ana K.',
    materials: [{ name: 'Kartice boja', type: 'PDF' }, { name: 'Radni list 1', type: 'slika' }],
    isPast: false,
    attendanceStatus: 'prisutan',
  },
  {
    id: 'w2',
    title: 'Priče kroz pokret',
    description: 'Razvoj motorike i jezika kroz dramsku igru.',
    date: '2026-03-14',
    dateLabel: '14.03.2026 11:30',
    group: 'Velika grupa',
    child: 'Hamza M.',
    materials: [{ name: 'Scenarij priče', type: 'PDF' }],
    isPast: false,
    attendanceStatus: 'prisutan',
  },
  {
    id: 'w3',
    title: 'Muzika i ritam',
    description: 'Vježbe slušanja, ritma i grupne koordinacije.',
    date: '2026-02-28',
    dateLabel: '28.02.2026 09:30',
    group: 'Velika grupa',
    child: 'Hamza M.',
    materials: [{ name: 'Ritam kartice', type: 'PDF' }],
    isPast: true,
    attendanceStatus: 'prisutan',
  },
]

const childOptions = computed(() => [...new Set(sessions.map((session) => session.child))])
const groupOptions = computed(() => [...new Set(sessions.map((session) => session.group))])

const filteredSessions = computed(() => {
  return sessions.filter((session) => {
    const childMatch = selectedChild.value === 'all' || session.child === selectedChild.value
    const groupMatch = selectedGroup.value === 'all' || session.group === selectedGroup.value
    return childMatch && groupMatch
  })
})

const calendarSessions = computed(() => {
  return filteredSessions.value.map((session) => ({
    id: session.id,
    title: session.title,
    date: session.date,
    isPast: session.isPast,
  }))
})

const pastSessions = computed(() => filteredSessions.value.filter((session) => session.isPast))
</script>
