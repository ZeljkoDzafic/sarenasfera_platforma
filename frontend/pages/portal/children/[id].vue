<template>
  <div class="space-y-6">
    <div v-if="child">
      <div class="flex items-center gap-3">
        <NuxtLink to="/portal/children" class="rounded-xl p-2 text-gray-500 transition-colors hover:bg-gray-100 hover:text-gray-700">
          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
        </NuxtLink>
        <div>
          <h1 class="font-display text-2xl font-bold text-gray-900">{{ child.full_name }}</h1>
          <p class="text-sm text-gray-500">{{ childAge(child.date_of_birth) }} • {{ child.age_group ?? 'Nema grupe' }}</p>
        </div>
      </div>

      <div class="flex gap-1 rounded-xl bg-gray-100 p-1">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          class="flex-1 rounded-lg px-3 py-2 text-sm font-semibold transition-all"
          :class="activeTab === tab.key ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'"
          @click="activeTab = tab.key"
        >
          {{ tab.label }}
        </button>
      </div>

      <div v-if="activeTab === 'passport'" class="space-y-4">
        <div class="card">
          <h2 class="mb-4 font-display text-lg font-bold text-gray-900">Razvojni profil</h2>
          <div class="grid grid-cols-2 gap-3 md:grid-cols-3">
            <div
              v-for="domain in domains"
              :key="domain.key"
              class="rounded-xl p-3 text-center"
              :style="{ backgroundColor: `${domain.color}15` }"
            >
              <div class="mb-1 text-2xl">{{ domain.emoji }}</div>
              <p class="mb-2 text-xs font-semibold text-gray-700">{{ domain.name }}</p>
              <div class="mb-1 flex justify-center gap-0.5">
                <div
                  v-for="n in 5"
                  :key="n"
                  class="h-4 w-4 rounded-sm"
                  :style="{ backgroundColor: n <= domainScore(domain.key) ? domain.color : `${domain.color}30` }"
                />
              </div>
              <p class="text-xs" :style="{ color: domain.color }">{{ scoreLabel(domainScore(domain.key)) }}</p>
            </div>
          </div>
        </div>

        <div class="card">
          <h2 class="mb-4 font-display text-lg font-bold text-gray-900">Zadnje opservacije</h2>
          <div v-if="observations.length > 0" class="space-y-3">
            <div
              v-for="obs in observations"
              :key="obs.id"
              class="rounded-xl border-l-4 bg-gray-50 p-3"
              :style="{ borderColor: getDomainColor(obs.skill_area_id) }"
            >
              <p class="text-sm text-gray-700">{{ obs.content }}</p>
              <p class="mt-1 text-xs text-gray-400">{{ formatDate(obs.created_at) }}</p>
            </div>
          </div>
          <div v-else class="py-6 text-center text-sm text-gray-400">Nema opservacija za ovo dijete.</div>
        </div>
      </div>

      <div v-else-if="activeTab === 'workshops'" class="space-y-4">
        <div class="card">
          <h2 class="mb-4 font-display text-lg font-bold text-gray-900">Posjećene radionice</h2>
          <div v-if="attendance.length > 0" class="space-y-2">
            <div
              v-for="att in attendance"
              :key="att.id"
              class="flex items-center gap-3 rounded-xl bg-gray-50 p-3"
            >
              <div
                class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-xl text-sm font-bold text-white"
                :class="att.status === 'present' ? 'bg-brand-green' : 'bg-gray-300'"
              >
                {{ att.status === 'present' ? '✓' : '–' }}
              </div>
              <div class="min-w-0 flex-1">
                <p class="truncate text-sm font-semibold text-gray-900">{{ att.sessions?.workshops?.title ?? 'Radionica' }}</p>
                <p class="text-xs text-gray-500">{{ att.sessions?.scheduled_date ? formatDate(att.sessions.scheduled_date) : '' }}</p>
              </div>
              <span
                class="rounded-full px-2 py-0.5 text-xs font-semibold"
                :class="att.status === 'present' ? 'bg-brand-green/10 text-brand-green' : 'bg-gray-100 text-gray-500'"
              >
                {{ participationLabel(att.participation_level) }}
              </span>
            </div>
          </div>
          <div v-else class="py-8 text-center text-sm text-gray-400">Nema evidencije prisustva.</div>
        </div>
      </div>

      <div v-else class="space-y-4">
        <div class="card">
          <h2 class="mb-4 font-display text-lg font-bold text-gray-900">Kvartalni izvještaji</h2>
          <div v-if="reports.length > 0" class="space-y-3">
            <div v-for="report in reports" :key="report.id" class="flex items-center gap-4 rounded-xl border border-gray-200 p-4">
              <div class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-xl bg-primary-100">
                <svg class="h-5 w-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
          <div v-else class="py-12 text-center text-sm text-gray-400">
            <div class="mb-3 text-4xl">📋</div>
            Izvještaji se generišu na kraju svakog kvartala.
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="pending" class="space-y-4">
      <div class="card h-24 animate-pulse" />
      <div class="card h-64 animate-pulse" />
    </div>

    <div v-else class="card py-16 text-center">
      <div class="mb-4 text-5xl">🔍</div>
      <h3 class="mb-3 font-display text-xl font-bold text-gray-900">Dijete nije pronađeno</h3>
      <NuxtLink to="/portal/children" class="btn-primary">Nazad na listu</NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })

type TabKey = 'passport' | 'workshops' | 'reports'

interface ChildRecord {
  id: string
  full_name: string
  date_of_birth: string
  age_group: string | null
}

interface AssessmentRecord {
  skill_area_id: string
  score: number
}

interface ObservationRecord {
  id: string
  content: string
  skill_area_id: string | null
  created_at: string
}

interface AttendanceRecord {
  id: string
  status: string | null
  participation_level: string | null
  sessions?: {
    scheduled_date?: string | null
    workshops?: { title?: string | null } | null
  } | null
}

interface ReportRecord {
  id: string
  period: string
  attendance_percentage: number | null
  pdf_url: string | null
}

const route = useRoute()
const childId = String(route.params.id ?? '')
const supabase = useSupabase()

const activeTab = ref<TabKey>('passport')
const tabs: Array<{ key: TabKey; label: string }> = [
  { key: 'passport', label: '🧩 Pasoš' },
  { key: 'workshops', label: '🎨 Radionice' },
  { key: 'reports', label: '📋 Izvještaji' },
]

const { data: child, pending } = await useAsyncData<ChildRecord | null>(`child-${childId}`, async () => {
  const { data } = await supabase
    .from('children')
    .select('id, full_name, date_of_birth, age_group')
    .eq('id', childId)
    .eq('is_active', true)
    .single()
  return (data as ChildRecord | null) ?? null
})

const { data: assessmentsData } = await useAsyncData<AssessmentRecord[]>(`assessments-${childId}`, async () => {
  const { data } = await supabase
    .from('assessments')
    .select('skill_area_id, score')
    .eq('child_id', childId)
  return (data as AssessmentRecord[] | null) ?? []
})

const { data: observationsData } = await useAsyncData<ObservationRecord[]>(`obs-${childId}`, async () => {
  const { data } = await supabase
    .from('observations')
    .select('id, content, skill_area_id, created_at')
    .eq('child_id', childId)
    .eq('is_visible_to_parent', true)
    .order('created_at', { ascending: false })
    .limit(5)
  return (data as ObservationRecord[] | null) ?? []
})

const { data: attendanceData } = await useAsyncData<AttendanceRecord[]>(`att-${childId}`, async () => {
  const { data } = await supabase
    .from('attendance')
    .select('id, status, participation_level, sessions(scheduled_date, workshops(title))')
    .eq('child_id', childId)
    .limit(10)
  return (data as AttendanceRecord[] | null) ?? []
})

const { data: reportsData } = await useAsyncData<ReportRecord[]>(`reports-${childId}`, async () => {
  const { data } = await supabase
    .from('quarterly_reports')
    .select('id, period, attendance_percentage, pdf_url')
    .eq('child_id', childId)
    .eq('status', 'published')
    .order('period', { ascending: false })
  return (data as ReportRecord[] | null) ?? []
})

const observations = computed(() => observationsData.value ?? [])
const attendance = computed(() => attendanceData.value ?? [])
const reports = computed(() => reportsData.value ?? [])
const assessments = computed(() => assessmentsData.value ?? [])

useSeoMeta({ title: `${child.value?.full_name ?? 'Dijete'} — Šarena Sfera` })

const domains = [
  { key: 'emotional', name: 'Emocionalni', emoji: '❤️', color: '#cf2e2e' },
  { key: 'social', name: 'Socijalni', emoji: '🤝', color: '#fcb900' },
  { key: 'creative', name: 'Kreativni', emoji: '🎨', color: '#9b51e0' },
  { key: 'cognitive', name: 'Kognitivni', emoji: '🧠', color: '#0693e3' },
  { key: 'motor', name: 'Motorički', emoji: '🏃', color: '#00d084' },
  { key: 'language', name: 'Jezički', emoji: '💬', color: '#f78da7' },
] as const

const domainColorMap: Record<string, string> = {
  emotional: '#cf2e2e',
  social: '#fcb900',
  creative: '#9b51e0',
  cognitive: '#0693e3',
  motor: '#00d084',
  language: '#f78da7',
}

function domainScore(key: string): number {
  const match = assessments.value.find((assessment) => assessment.skill_area_id === key)
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
  const years = Math.floor(months / 12)
  const remainingMonths = months % 12
  return remainingMonths > 0 ? `${years} god. ${remainingMonths} mj.` : `${years} godine`
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'long', year: 'numeric' })
}

function participationLabel(level: string | null): string {
  const map: Record<string, string> = {
    observed: 'Posmatrao/la',
    partial: 'Djelimično',
    full: 'Potpuno',
    exceptional: 'Odlično',
  }
  return level ? (map[level] ?? level) : 'Prisutan/na'
}
</script>
