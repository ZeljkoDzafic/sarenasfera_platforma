<template>
  <div class="space-y-6">
    <section class="card">
      <div class="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Kućne aktivnosti</h1>
          <p class="text-sm text-gray-600">Aktivnosti koje su predložili edukatori za rad kod kuće.</p>
        </div>

        <div class="grid gap-2 sm:grid-cols-2">
          <label class="text-xs font-semibold text-gray-600">
            Domena
            <select v-model="selectedDomain" class="input mt-1 min-h-11 py-2">
              <option value="all">Sve domene</option>
              <option v-for="domain in domainOptions" :key="domain.value" :value="domain.value">{{ domain.label }}</option>
            </select>
          </label>
          <label class="text-xs font-semibold text-gray-600">
            Status
            <select v-model="selectedStatus" class="input mt-1 min-h-11 py-2">
              <option value="all">Sve</option>
              <option value="pending">Na čekanju</option>
              <option value="done">Završeno</option>
            </select>
          </label>
        </div>
      </div>
    </section>

    <section class="grid gap-4 lg:grid-cols-2">
      <article v-for="activity in filteredActivities" :key="activity.id" class="card">
        <div class="mb-3 flex items-start justify-between gap-3">
          <div>
            <h2 class="text-lg font-bold text-gray-900">{{ activity.title }}</h2>
            <p class="text-sm text-gray-700">{{ activity.description }}</p>
          </div>
          <span class="badge" :class="activity.completed ? 'badge-free' : domainBadgeClass(activity.domain)">
            {{ activity.completed ? 'Završeno' : domainLabel(activity.domain) }}
          </span>
        </div>

        <div class="rounded-xl bg-gray-50 p-3 text-sm text-gray-700">
          <p class="font-semibold text-gray-800">Uputstvo</p>
          <p class="mt-1">{{ activity.instructions }}</p>
        </div>

        <div class="mt-3 grid gap-2 sm:grid-cols-2">
          <label class="text-xs font-semibold text-gray-600">
            Bilješka roditelja
            <textarea
              v-model="activity.note"
              rows="3"
              class="input mt-1"
              placeholder="Napišite kratak utisak..."
            />
          </label>
          <label class="text-xs font-semibold text-gray-600">
            Link fotografije (opciono)
            <input
              v-model="activity.photoUrl"
              type="url"
              class="input mt-1"
              placeholder="https://..."
            >
          </label>
        </div>

        <div class="mt-4 flex flex-wrap gap-2">
          <button
            class="btn-success"
            :disabled="activity.completed"
            @click="markCompleted(activity.id)"
          >
            Označi kao završeno
          </button>
          <button
            class="btn-secondary"
            :disabled="!activity.completed"
            @click="markPending(activity.id)"
          >
            Vrati na čekanje
          </button>
        </div>
      </article>
    </section>

    <section class="card">
      <h2 class="text-lg font-bold text-gray-900">Historija aktivnosti</h2>
      <ul class="mt-3 space-y-2 text-sm text-gray-700">
        <li v-for="item in completedHistory" :key="item.id" class="rounded-xl bg-gray-50 p-3">
          <p class="font-semibold">{{ item.title }} • {{ domainLabel(item.domain) }}</p>
          <p>Završeno: {{ item.completedAt }}</p>
          <p v-if="item.note">Bilješka: {{ item.note }}</p>
        </li>
        <li v-if="completedHistory.length === 0" class="rounded-xl bg-gray-50 p-3 text-gray-600">
          Još nema završenih aktivnosti.
        </li>
      </ul>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'portal' })

type DomainKey = 'emotional' | 'social' | 'creative' | 'cognitive' | 'motor' | 'language'
type StatusFilter = 'all' | 'pending' | 'done'

interface ActivityItem {
  id: string
  title: string
  description: string
  domain: DomainKey
  instructions: string
  completed: boolean
  completedAt: string | null
  note: string
  photoUrl: string
}

const selectedDomain = ref<'all' | DomainKey>('all')
const selectedStatus = ref<StatusFilter>('all')

const activities = ref<ActivityItem[]>([
  {
    id: 'a1',
    title: 'Čitanje priče o emocijama',
    description: 'Zajednički pročitajte kratku priču i razgovarajte o osjećajima likova.',
    domain: 'emotional',
    instructions: 'Postavite 3 pitanja: Kako se lik osjećao? Zašto? Šta bismo mi uradili?',
    completed: false,
    completedAt: null,
    note: '',
    photoUrl: '',
  },
  {
    id: 'a2',
    title: 'Sortiranje predmeta po boji',
    description: 'Koristite igračke ili kućne predmete za sortiranje u 4 grupe boja.',
    domain: 'cognitive',
    instructions: 'Nakon sortiranja pitajte dijete da objasni pravilo koje je koristilo.',
    completed: true,
    completedAt: '09.03.2026',
    note: 'Samostalno prepoznaje većinu boja.',
    photoUrl: '',
  },
  {
    id: 'a3',
    title: 'Mini poligon ravnoteže',
    description: 'Napravite jednostavan poligon sa jastucima i trakama na podu.',
    domain: 'motor',
    instructions: 'Dijete prelazi poligon 3 puta i svaki put mjerite sigurnost pokreta.',
    completed: false,
    completedAt: null,
    note: '',
    photoUrl: '',
  },
])

const domainOptions = [
  { value: 'emotional', label: 'Emocionalni' },
  { value: 'social', label: 'Socijalni' },
  { value: 'creative', label: 'Kreativni' },
  { value: 'cognitive', label: 'Kognitivni' },
  { value: 'motor', label: 'Motorički' },
  { value: 'language', label: 'Jezički' },
] as const

const domainLabel = (domain: DomainKey) => {
  const found = domainOptions.find((item) => item.value === domain)
  return found?.label ?? domain
}

const domainBadgeClass = (domain: DomainKey) => {
  const map: Record<DomainKey, string> = {
    emotional: 'domain-bg-emotional text-domain-emotional',
    social: 'domain-bg-social text-domain-social',
    creative: 'domain-bg-creative text-domain-creative',
    cognitive: 'domain-bg-cognitive text-domain-cognitive',
    motor: 'domain-bg-motor text-domain-motor',
    language: 'domain-bg-language text-domain-language',
  }
  return map[domain]
}

const filteredActivities = computed(() => {
  return activities.value.filter((activity) => {
    const domainMatch = selectedDomain.value === 'all' || activity.domain === selectedDomain.value
    const statusMatch =
      selectedStatus.value === 'all'
      || (selectedStatus.value === 'pending' && !activity.completed)
      || (selectedStatus.value === 'done' && activity.completed)

    return domainMatch && statusMatch
  })
})

const completedHistory = computed(() => activities.value.filter((activity) => activity.completed))

const markCompleted = (id: string) => {
  const target = activities.value.find((item) => item.id === id)
  if (!target) return
  target.completed = true
  target.completedAt = new Date().toLocaleDateString('bs-BA')
}

const markPending = (id: string) => {
  const target = activities.value.find((item) => item.id === id)
  if (!target) return
  target.completed = false
  target.completedAt = null
}
</script>
