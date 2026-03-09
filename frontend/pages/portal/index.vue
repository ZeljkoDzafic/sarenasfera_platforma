<template>
  <div class="space-y-6">
    <section class="card-featured">
      <p class="text-sm font-semibold uppercase tracking-wide text-white/90">Dobro došli nazad</p>
      <h1 class="mt-2 text-2xl font-bold">{{ greetingName }}</h1>
      <p class="mt-2 text-sm text-white/90">
        Pratite napredak vašeg djeteta kroz domene razvoja, radionice i kućne aktivnosti.
      </p>
    </section>

    <section class="grid grid-cols-2 gap-3 sm:grid-cols-4">
      <article
        v-for="stat in stats"
        :key="stat.label"
        class="card p-4 text-center"
      >
        <div class="mx-auto mb-2 inline-flex h-10 w-10 items-center justify-center rounded-xl" :class="stat.iconBgClass">
          <span class="text-lg">{{ stat.icon }}</span>
        </div>
        <p class="text-xl font-bold text-gray-900">{{ stat.value }}</p>
        <p class="text-xs text-gray-600">{{ stat.label }}</p>
      </article>
    </section>

    <section>
      <div class="mb-3 flex items-center justify-between">
        <h2 class="text-xl font-bold text-gray-900">Moja djeca</h2>
        <NuxtLink to="/portal/children" class="text-sm font-semibold text-primary-600 hover:text-primary-700">
          Pogledaj sve
        </NuxtLink>
      </div>
      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <article v-for="child in children" :key="child.id" class="card-hover">
          <div class="mb-4 flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="h-12 w-12 rounded-full border-2 border-primary-300 bg-primary-100" />
              <div>
                <h3 class="text-base font-bold text-gray-900">{{ child.name }}</h3>
                <p class="text-xs text-gray-600">{{ child.age }} godina • {{ child.group }}</p>
              </div>
            </div>
            <NuxtLink :to="`/portal/children/${child.id}`" class="text-xs font-semibold text-primary-600">Pasoš</NuxtLink>
          </div>

          <div class="flex items-center justify-between gap-4">
            <MiniRadarChart :scores="child.scores" />
            <div class="space-y-1 text-xs text-gray-600">
              <p v-for="item in child.highlights" :key="item">• {{ item }}</p>
            </div>
          </div>
        </article>
      </div>
    </section>

    <section class="grid gap-4 lg:grid-cols-3">
      <article class="card lg:col-span-1">
        <h3 class="mb-3 text-lg font-bold">Naredne radionice</h3>
        <ul class="space-y-2 text-sm text-gray-700">
          <li v-for="workshop in upcomingWorkshops" :key="workshop.id" class="rounded-xl bg-primary-50 p-3">
            <p class="font-semibold text-primary-700">{{ workshop.title }}</p>
            <p>{{ workshop.date }}</p>
          </li>
        </ul>
      </article>

      <article class="card lg:col-span-1">
        <h3 class="mb-3 text-lg font-bold">Poslednje opservacije</h3>
        <ul class="space-y-2 text-sm text-gray-700">
          <li v-for="entry in recentObservations" :key="entry.id" class="rounded-xl bg-gray-50 p-3">
            <p class="font-semibold">{{ entry.childName }} — {{ entry.domain }}</p>
            <p>{{ entry.note }}</p>
          </li>
        </ul>
      </article>

      <article class="card lg:col-span-1">
        <h3 class="mb-3 text-lg font-bold">Kućne aktivnosti na čekanju</h3>
        <ul class="space-y-2 text-sm text-gray-700">
          <li v-for="activity in pendingActivities" :key="activity.id" class="rounded-xl bg-brand-amber/10 p-3">
            <p class="font-semibold">{{ activity.title }}</p>
            <p class="text-xs">Rok: {{ activity.deadline }}</p>
          </li>
        </ul>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'portal' })

interface ChildCard {
  id: string
  name: string
  age: number
  group: string
  highlights: string[]
  scores: Array<{ key: string; value: number; color: string }>
}

const { user } = useAuth()

const greetingName = computed(() => user.value?.email?.split('@')[0] ?? 'Roditelju')

const stats = [
  { label: 'Djeca', value: '2', icon: '👶', iconBgClass: 'bg-brand-pink/20' },
  { label: 'Radionice ove sedmice', value: '3', icon: '📅', iconBgClass: 'bg-brand-blue/20' },
  { label: 'Nove opservacije', value: '5', icon: '📝', iconBgClass: 'bg-brand-green/20' },
  { label: 'Aktivnosti na čekanju', value: '4', icon: '⭐', iconBgClass: 'bg-brand-amber/20' },
]

const children: ChildCard[] = [
  {
    id: 'ana-1',
    name: 'Ana K.',
    age: 4,
    group: 'Srednja grupa',
    highlights: ['Napredak u govoru', 'Bolja socijalizacija'],
    scores: [
      { key: 'emotional', value: 4, color: '#cf2e2e' },
      { key: 'social', value: 5, color: '#fcb900' },
      { key: 'creative', value: 4, color: '#9b51e0' },
      { key: 'cognitive', value: 3, color: '#0693e3' },
      { key: 'motor', value: 4, color: '#00d084' },
      { key: 'language', value: 5, color: '#f78da7' },
    ],
  },
  {
    id: 'hamza-2',
    name: 'Hamza M.',
    age: 5,
    group: 'Velika grupa',
    highlights: ['Fina motorika jača', 'Aktivno učestvuje'],
    scores: [
      { key: 'emotional', value: 3, color: '#cf2e2e' },
      { key: 'social', value: 4, color: '#fcb900' },
      { key: 'creative', value: 5, color: '#9b51e0' },
      { key: 'cognitive', value: 4, color: '#0693e3' },
      { key: 'motor', value: 4, color: '#00d084' },
      { key: 'language', value: 3, color: '#f78da7' },
    ],
  },
]

const upcomingWorkshops = [
  { id: 'w1', title: 'Mali istraživači boja', date: 'Utorak, 10:00' },
  { id: 'w2', title: 'Priče kroz pokret', date: 'Četvrtak, 11:30' },
  { id: 'w3', title: 'Muzika i ritam', date: 'Subota, 09:30' },
]

const recentObservations = [
  { id: 'o1', childName: 'Ana K.', domain: 'Jezički razvoj', note: 'Samostalno opisuje događaje.' },
  { id: 'o2', childName: 'Hamza M.', domain: 'Motorički razvoj', note: 'Sigurnije koristi makaze.' },
  { id: 'o3', childName: 'Ana K.', domain: 'Socijalni razvoj', note: 'Pokreće zajedničku igru.' },
  { id: 'o4', childName: 'Hamza M.', domain: 'Kognitivni razvoj', note: 'Brže povezuje zadatke.' },
  { id: 'o5', childName: 'Ana K.', domain: 'Emocionalni razvoj', note: 'Jasnije izražava osjećaje.' },
]

const pendingActivities = [
  { id: 'a1', title: 'Čitanje priče pred spavanje', deadline: 'Do petka' },
  { id: 'a2', title: 'Igra sortiranja boja', deadline: 'Do subote' },
  { id: 'a3', title: 'Mala kućna gimnastika', deadline: 'Do nedjelje' },
]
</script>
