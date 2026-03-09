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
</script>
