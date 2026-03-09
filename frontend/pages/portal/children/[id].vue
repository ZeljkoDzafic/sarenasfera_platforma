<template>
  <div class="space-y-6">
    <section class="card">
      <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex items-center gap-4">
          <div class="h-16 w-16 rounded-2xl border-2 border-primary-300 bg-primary-100" />
          <div>
            <h1 class="text-2xl font-bold text-gray-900">{{ child.name }}</h1>
            <p class="text-sm text-gray-600">{{ child.age }} godina • {{ child.group }}</p>
          </div>
        </div>
        <NuxtLink to="/portal/children" class="btn-ghost">Nazad na listu</NuxtLink>
      </div>
    </section>

    <section class="card p-3">
      <div class="grid grid-cols-2 gap-2 sm:grid-cols-5">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          class="min-h-11 rounded-xl px-3 py-2 text-sm font-semibold transition-colors"
          :class="activeTab === tab.key ? 'bg-primary-500 text-white shadow-colorful' : 'bg-gray-100 text-gray-700 hover:bg-primary-50 hover:text-primary-700'"
          @click="activeTab = tab.key"
        >
          {{ tab.label }}
        </button>
      </div>
    </section>

    <section v-if="activeTab === 'overview'" class="card space-y-4">
      <h2 class="text-xl font-bold">Pregled</h2>
      <div class="grid gap-3 md:grid-cols-2">
        <article class="rounded-xl bg-gray-50 p-4">
          <h3 class="font-semibold text-gray-900">Osnovne informacije</h3>
          <p class="text-sm text-gray-700">Datum rođenja: {{ child.birthDate }}</p>
          <p class="text-sm text-gray-700">Aktivna grupa: {{ child.group }}</p>
          <p class="text-sm text-gray-700">Mentor: {{ child.mentor }}</p>
        </article>
        <article class="rounded-xl bg-gray-50 p-4">
          <h3 class="font-semibold text-gray-900">Brzi status</h3>
          <p class="text-sm text-gray-700">Prisustvo mjesec: {{ child.attendanceMonth }}</p>
          <p class="text-sm text-gray-700">Posljednja opservacija: {{ child.lastObservation }}</p>
          <p class="text-sm text-gray-700">Sljedeća radionica: {{ child.nextWorkshop }}</p>
        </article>
      </div>
    </section>

    <PassportView
      v-else-if="activeTab === 'passport'"
      :records="passportRecords"
      :notes="passportNotes"
    />

    <section v-else-if="activeTab === 'observations'" class="card space-y-3">
      <h2 class="text-xl font-bold">Opservacije</h2>
      <article v-for="item in observations" :key="item.id" class="rounded-xl bg-gray-50 p-4">
        <p class="text-sm font-semibold text-gray-900">{{ item.date }} • {{ item.domain }}</p>
        <p class="text-sm text-gray-700">{{ item.note }}</p>
      </article>
    </section>

    <section v-else-if="activeTab === 'attendance'" class="card space-y-3">
      <h2 class="text-xl font-bold">Prisustvo</h2>
      <div class="grid grid-cols-7 gap-2">
        <div
          v-for="(status, index) in attendanceHeatmap"
          :key="`day-${index}`"
          class="aspect-square rounded-lg"
          :class="status === 'present' ? 'bg-brand-green/70' : status === 'late' ? 'bg-brand-amber/70' : 'bg-gray-200'"
        />
      </div>
      <p class="text-sm text-gray-600">Zeleno: prisutan, žuto: kasni, sivo: bez dolaska.</p>
    </section>

    <section v-else class="card space-y-3">
      <h2 class="text-xl font-bold">Izvještaji</h2>
      <article v-for="report in reports" :key="report.id" class="rounded-xl border border-primary-100 p-4">
        <p class="font-semibold text-gray-900">{{ report.title }}</p>
        <p class="text-sm text-gray-600">Period: {{ report.period }}</p>
        <button class="btn-secondary mt-3">Preuzmi PDF</button>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'portal' })

const route = useRoute()
const childId = computed(() => String(route.params.id ?? ''))

type TabKey = 'overview' | 'passport' | 'observations' | 'attendance' | 'reports'

const tabs: Array<{ key: TabKey; label: string }> = [
  { key: 'overview', label: 'Pregled' },
  { key: 'passport', label: 'Pasoš' },
  { key: 'observations', label: 'Opservacije' },
  { key: 'attendance', label: 'Prisustvo' },
  { key: 'reports', label: 'Izvještaji' },
]

const activeTab = ref<TabKey>('overview')

const child = computed(() => {
  if (childId.value === 'hamza-2') {
    return {
      name: 'Hamza M.',
      age: 5,
      group: 'Velika grupa',
      birthDate: '16.06.2020',
      mentor: 'Emina S.',
      attendanceMonth: '86%',
      lastObservation: 'Prije 2 dana',
      nextWorkshop: 'Muzika i ritam',
    }
  }

  return {
    name: 'Ana K.',
    age: 4,
    group: 'Srednja grupa',
    birthDate: '03.02.2021',
    mentor: 'Lejla H.',
    attendanceMonth: '92%',
    lastObservation: 'Jučer',
    nextWorkshop: 'Mali istraživači boja',
  }
})

const passportRecords = computed(() => {
  if (childId.value === 'hamza-2') {
    return [
      { period: 'Q1', scores: { emotional: 3, social: 4, creative: 5, cognitive: 4, motor: 4, language: 3 } },
      { period: 'Q2', scores: { emotional: 4, social: 4, creative: 5, cognitive: 4, motor: 4, language: 4 } },
      { period: 'Q3', scores: { emotional: 4, social: 4, creative: 5, cognitive: 5, motor: 4, language: 4 } },
      { period: 'Q4', scores: { emotional: 4, social: 5, creative: 5, cognitive: 5, motor: 5, language: 4 } },
      { period: 'Godišnje', scores: { emotional: 4, social: 4, creative: 5, cognitive: 5, motor: 4, language: 4 } },
    ] as const
  }

  return [
    { period: 'Q1', scores: { emotional: 4, social: 5, creative: 4, cognitive: 3, motor: 4, language: 5 } },
    { period: 'Q2', scores: { emotional: 4, social: 5, creative: 4, cognitive: 4, motor: 4, language: 5 } },
    { period: 'Q3', scores: { emotional: 5, social: 5, creative: 4, cognitive: 4, motor: 5, language: 5 } },
    { period: 'Q4', scores: { emotional: 5, social: 5, creative: 5, cognitive: 4, motor: 5, language: 5 } },
    { period: 'Godišnje', scores: { emotional: 5, social: 5, creative: 4, cognitive: 4, motor: 5, language: 5 } },
  ] as const
})

const passportNotes = computed(() => {
  if (childId.value === 'hamza-2') {
    return [
      { key: 'emotional', note: 'Bolje prepoznaje i imenuje emocije u grupi.' },
      { key: 'social', note: 'Rado učestvuje u timskim igrama.' },
      { key: 'creative', note: 'Pokazuje originalne ideje u likovnim aktivnostima.' },
      { key: 'cognitive', note: 'Samostalno rješava zadatke srednje složenosti.' },
      { key: 'motor', note: 'Sigurniji u zadacima koordinacije pokreta.' },
      { key: 'language', note: 'Širi vokabular kroz vođene priče.' },
    ] as const
  }

  return [
    { key: 'emotional', note: 'Jasnije izražava osjećaje i empatiju.' },
    { key: 'social', note: 'Inicira saradnju sa vršnjacima bez podsticaja.' },
    { key: 'creative', note: 'Eksperimentiše sa više materijala u jednoj aktivnosti.' },
    { key: 'cognitive', note: 'Brže uočava obrasce i logičke veze.' },
    { key: 'motor', note: 'Napredak u finoj motorici i preciznosti.' },
    { key: 'language', note: 'Samostalno prepričava događaje sa više detalja.' },
  ] as const
})

const observations = [
  { id: 'o1', date: '08.03.2026', domain: 'Socijalni razvoj', note: 'Inicira zajedničku igru sa vršnjacima.' },
  { id: 'o2', date: '05.03.2026', domain: 'Jezički razvoj', note: 'Kreira duže rečenice uz manje podsticaja.' },
  { id: 'o3', date: '01.03.2026', domain: 'Motorički razvoj', note: 'Bolja koordinacija u poligonu.' },
]

const attendanceHeatmap: Array<'present' | 'late' | 'absent'> = [
  'present', 'present', 'late', 'present', 'absent', 'present', 'present',
  'present', 'absent', 'present', 'late', 'present', 'present', 'present',
  'absent', 'present', 'present', 'present', 'late', 'present', 'present',
  'present', 'present', 'absent', 'present', 'present', 'late', 'present',
]

const reports = [
  { id: 'r1', title: 'Kvartalni izvještaj razvoja', period: 'Q1 2026' },
  { id: 'r2', title: 'Sažetak opservacija', period: 'Februar 2026' },
]
</script>
