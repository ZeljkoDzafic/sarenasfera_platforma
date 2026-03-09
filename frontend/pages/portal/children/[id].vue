<template>
  <div class="space-y-6">

    <div v-if="child">
      <!-- Back + title -->
      <div class="flex items-center gap-3">
        <NuxtLink to="/portal/children" class="p-2 rounded-xl hover:bg-gray-100 text-gray-500 hover:text-gray-700 transition-colors">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
        </NuxtLink>
        <div>
          <h1 class="font-display text-2xl font-bold text-gray-900">{{ child.full_name }}</h1>
          <p class="text-sm text-gray-500">{{ childAge(child.date_of_birth) }} • {{ child.age_group ?? 'Nema grupe' }}</p>
        </div>
      </div>

      <!-- Tabs -->
      <div class="flex gap-1 bg-gray-100 rounded-xl p-1">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          class="flex-1 py-2 px-3 rounded-lg text-sm font-semibold transition-all"
          :class="activeTab === tab.key ? 'bg-white shadow-sm text-gray-900' : 'text-gray-500 hover:text-gray-700'"
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

      <!-- Tab: Pasoš (Child Passport) -->
      <div v-if="activeTab === 'passport'" class="space-y-4">
        <div class="card">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Razvojni profil</h2>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
            <div
              v-for="domain in domains"
              :key="domain.key"
              class="rounded-xl p-3 text-center"
              :style="{ backgroundColor: domain.color + '15' }"
            >
              <div class="text-2xl mb-1">{{ domain.emoji }}</div>
              <p class="text-xs font-semibold text-gray-700 mb-2">{{ domain.name }}</p>
              <!-- Score display -->
              <div class="flex justify-center gap-0.5 mb-1">
                <div
                  v-for="n in 5"
                  :key="n"
                  class="w-4 h-4 rounded-sm"
                  :style="{ backgroundColor: n <= (domainScore(domain.key)) ? domain.color : domain.color + '30' }"
                />
              </div>
              <p class="text-xs" :style="{ color: domain.color }">
                {{ scoreLabel(domainScore(domain.key)) }}
              </p>
            </div>
          </div>
        </div>

        <!-- Latest observations -->
        <div class="card">
          <div class="flex items-center justify-between mb-4">
            <h2 class="font-display font-bold text-lg text-gray-900">Zadnje opservacije</h2>
          </div>
          <div v-if="observations && observations.length > 0" class="space-y-3">
            <div
              v-for="obs in observations"
              :key="obs.id"
              class="p-3 rounded-xl bg-gray-50 border-l-4"
              :style="{ borderColor: getDomainColor(obs.skill_area_id) }"
            >
              <p class="text-sm text-gray-700">{{ obs.content }}</p>
              <p class="text-xs text-gray-400 mt-1">{{ formatDate(obs.created_at) }}</p>
            </div>
          </div>
          <div v-else class="text-center py-6 text-gray-400 text-sm">
            Nema opservacija za ovo dijete.
          </div>
        </div>
      </div>

      <!-- Tab: Radionice -->
      <div v-else-if="activeTab === 'workshops'" class="space-y-4">
        <div class="card">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Posjećene radionice</h2>
          <div v-if="attendance && attendance.length > 0" class="space-y-2">
            <div
              v-for="att in attendance"
              :key="att.id"
              class="flex items-center gap-3 p-3 rounded-xl bg-gray-50"
            >
              <div
                class="w-10 h-10 rounded-xl flex items-center justify-center text-white font-bold text-sm flex-shrink-0"
                :class="att.status === 'present' ? 'bg-brand-green' : 'bg-gray-300'"
              >
                {{ att.status === 'present' ? '✓' : '–' }}
              </div>
              <div class="flex-1 min-w-0">
                <p class="font-semibold text-sm text-gray-900 truncate">{{ att.sessions?.workshops?.title ?? 'Radionica' }}</p>
                <p class="text-xs text-gray-500">{{ att.sessions?.scheduled_date ? formatDate(att.sessions.scheduled_date) : '' }}</p>
              </div>
              <span
                class="text-xs font-semibold px-2 py-0.5 rounded-full"
                :class="att.status === 'present' ? 'bg-brand-green/10 text-brand-green' : 'bg-gray-100 text-gray-500'"
              >
                {{ participationLabel(att.participation_level) }}
              </span>
            </div>
          </div>
          <div v-else class="text-center py-8 text-gray-400 text-sm">
            Nema evidencije prisustva.
          </div>
        </div>
      </div>

      <!-- Tab: Izvještaji -->
      <div v-else-if="activeTab === 'reports'" class="space-y-4">
        <div class="card">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Kvartalni izvještaji</h2>
          <div v-if="reports && reports.length > 0" class="space-y-3">
            <div v-for="report in reports" :key="report.id" class="p-4 rounded-xl border border-gray-200 flex items-center gap-4">
              <div class="w-10 h-10 rounded-xl bg-primary-100 flex items-center justify-center flex-shrink-0">
                <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <div class="flex-1">
                <p class="font-semibold text-gray-900">Izvještaj {{ report.period }}</p>
                <p class="text-sm text-gray-500">Prisustvo: {{ report.attendance_percentage ?? '–' }}%</p>
              </div>
              <a v-if="report.pdf_url" :href="report.pdf_url" target="_blank" class="btn-secondary text-sm">
                Preuzmi PDF
              </a>
            </div>
          </div>
          <div v-else class="text-center py-12 text-gray-400 text-sm">
            <div class="text-4xl mb-3">📋</div>
            Izvještaji se generišu na kraju svakog kvartala.
          </div>
        </div>
      </div>
    </div>

    <!-- Loading -->
    <div v-else-if="pending" class="space-y-4">
      <div class="card animate-pulse h-24" />
      <div class="card animate-pulse h-64" />
    </div>

    <!-- Not found -->
    <div v-else class="card text-center py-16">
      <div class="text-5xl mb-4">🔍</div>
      <h3 class="font-display font-bold text-xl text-gray-900 mb-3">Dijete nije pronađeno</h3>
      <NuxtLink to="/portal/children" class="btn-primary">Nazad na listu</NuxtLink>
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
definePageMeta({ middleware: 'auth', layout: 'portal' })

const route = useRoute()
const childId = route.params.id as string
const supabase = useSupabase()

const activeTab = ref('passport')
const tabs = [
  { key: 'passport', label: '🧩 Pasoš' },
  { key: 'workshops', label: '🎨 Radionice' },
  { key: 'reports', label: '📋 Izvještaji' },
]

const { data: child, pending } = await useAsyncData(`child-${childId}`, async () => {
  const { data } = await supabase
    .from('children')
    .select('id, full_name, nickname, date_of_birth, gender, photo_url, age_group, allergies, special_needs')
    .eq('id', childId)
    .eq('is_active', true)
    .single()
  return data
})

const { data: assessments } = await useAsyncData(`assessments-${childId}`, async () => {
  const { data } = await supabase
    .from('assessments')
    .select('skill_area_id, score, period')
    .eq('child_id', childId)
    .order('period', { ascending: false })
  return data ?? []
})

const { data: observations } = await useAsyncData(`obs-${childId}`, async () => {
  const { data } = await supabase
    .from('observations')
    .select('id, content, skill_area_id, observation_type, created_at')
    .eq('child_id', childId)
    .eq('is_visible_to_parent', true)
    .order('created_at', { ascending: false })
    .limit(5)
  return data ?? []
})

const { data: attendance } = await useAsyncData(`att-${childId}`, async () => {
  const { data } = await supabase
    .from('attendance')
    .select('id, status, participation_level, sessions(scheduled_date, workshops(title))')
    .eq('child_id', childId)
    .order('sessions(scheduled_date)', { ascending: false })
    .limit(10)
  return data ?? []
})

const { data: reports } = await useAsyncData(`reports-${childId}`, async () => {
  const { data } = await supabase
    .from('quarterly_reports')
    .select('id, period, status, pdf_url, attendance_percentage, domain_scores')
    .eq('child_id', childId)
    .eq('status', 'published')
    .order('period', { ascending: false })
  return data ?? []
})

useSeoMeta({ title: `${child.value?.full_name ?? 'Dijete'} — Šarena Sfera` })

const domains = [
  { key: 'emotional', name: 'Emocionalni', emoji: '❤️', color: '#cf2e2e' },
  { key: 'social',    name: 'Socijalni',   emoji: '🤝', color: '#fcb900' },
  { key: 'creative',  name: 'Kreativni',   emoji: '🎨', color: '#9b51e0' },
  { key: 'cognitive', name: 'Kognitivni',  emoji: '🧠', color: '#0693e3' },
  { key: 'motor',     name: 'Motorički',   emoji: '🏃', color: '#00d084' },
  { key: 'language',  name: 'Jezički',     emoji: '💬', color: '#f78da7' },
]

const domainColorMap: Record<string, string> = {
  emotional: '#cf2e2e', social: '#fcb900', creative: '#9b51e0',
  cognitive: '#0693e3', motor: '#00d084', language: '#f78da7',
}

function domainScore(key: string): number {
  // Find latest assessment for this domain
  const match = assessments.value?.find((a: { skill_area_id: string; score: number }) => a.skill_area_id === key)
  return match?.score ?? 0
}

function getDomainColor(areaId: string | null): string {
  if (!areaId) return '#9b51e0'
  return domainColorMap[areaId] ?? '#9b51e0'
}

function scoreLabel(score: number): string {
  const labels = ['–', 'Početak', 'Razvija se', 'Na putu', 'Napreduje', 'Odlično']
  return labels[score] ?? '–'
}

function childAge(dob: string): string {
  const months = Math.floor((Date.now() - new Date(dob).getTime()) / (1000 * 60 * 60 * 24 * 30.5))
  const y = Math.floor(months / 12), m = months % 12
  return m > 0 ? `${y} god. ${m} mj.` : `${y} ${y === 1 ? 'godina' : 'godine'}`
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'long', year: 'numeric' })
}

function participationLabel(level: string | null): string {
  const map: Record<string, string> = { observed: 'Posmatrao/la', partial: 'Djelimično', full: 'Potpuno', exceptional: 'Odlično' }
  return level ? (map[level] ?? level) : 'Prisutan/na'
}
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
