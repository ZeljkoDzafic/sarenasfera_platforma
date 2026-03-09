<template>
  <div class="space-y-6">
    <!-- Back + title -->
    <div v-if="child && domainInfo" class="flex items-center gap-3">
      <NuxtLink :to="`/portal/children/${childId}`" class="p-2 rounded-xl hover:bg-gray-100 text-gray-500 hover:text-gray-700 transition-colors">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </NuxtLink>
      <div class="flex items-center gap-3">
        <div
          class="w-12 h-12 rounded-xl flex items-center justify-center text-2xl"
          :style="{ backgroundColor: domainInfo.color + '20' }"
        >
          {{ domainInfo.emoji }}
        </div>
        <div>
          <h1 class="font-display text-2xl font-bold text-gray-900">{{ domainInfo.name }}</h1>
          <p class="text-sm text-gray-500">{{ child.full_name }} • Detaljni pregled</p>
        </div>
      </div>
    </div>

    <!-- Loading -->
    <div v-else-if="pending" class="space-y-4">
      <div class="card animate-pulse h-32" />
      <div class="card animate-pulse h-64" />
    </div>

    <div v-else class="card text-center py-16">
      <div class="text-5xl mb-4">🔍</div>
      <h3 class="font-display font-bold text-xl text-gray-900 mb-2">Dijete nije pronađeno</h3>
      <NuxtLink to="/portal/children" class="btn-primary">Nazad na listu</NuxtLink>
    </div>

    <div v-if="child && domainInfo" class="space-y-6">
      <!-- Feature gate for paid tier -->
      <FeatureGate required-tier="paid">
        <template #locked>
          <div class="text-center py-12">
            <div class="text-5xl mb-4">🔒</div>
            <h3 class="font-display font-bold text-xl text-gray-900 mb-2">Detalji domene su Premium funkcija</h3>
            <p class="text-gray-600 mb-6">Nadogradite na Paid tier za pristup detaljnom pregledu domene.</p>
            <NuxtLink to="/pricing" class="btn-primary">Pregledajte Planove</NuxtLink>
          </div>
        </template>

        <!-- Content -->
        <div class="space-y-6">
          <!-- Score overview -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <!-- Current score -->
            <div class="card p-6">
              <p class="text-sm text-gray-600 mb-2">Trenutni nivo</p>
              <div class="flex items-end gap-3">
                <span class="text-4xl font-bold" :style="{ color: domainInfo.color }">
                  {{ currentScore }}
                </span>
                <span class="text-gray-400 mb-1">/ 5</span>
              </div>
              <p class="text-sm mt-2" :style="{ color: domainInfo.color }">
                {{ scoreLabel(currentScore) }}
              </p>
            </div>

            <!-- Progress -->
            <div class="card p-6">
              <p class="text-sm text-gray-600 mb-2">Napredak</p>
              <div class="flex items-center gap-3">
                <div class="flex-1 h-3 bg-gray-200 rounded-full overflow-hidden">
                  <div
                    class="h-full rounded-full transition-all"
                    :style="{ width: `${(currentScore / 5) * 100}%`, backgroundColor: domainInfo.color }"
                  />
                </div>
                <span class="text-sm font-bold">{{ Math.round((currentScore / 5) * 100) }}%</span>
              </div>
              <p class="text-sm mt-2 text-gray-600">
                {{ milestonesAchieved }} od {{ totalMilestones }} milestonea
              </p>
            </div>

            <!-- Trend -->
            <div class="card p-6">
              <p class="text-sm text-gray-600 mb-2">Trend (3 mjeseca)</p>
              <div class="flex items-center gap-2">
                <span class="text-3xl font-bold" :class="trend > 0 ? 'text-brand-green' : trend < 0 ? 'text-brand-red' : 'text-gray-400'">
                  {{ trend > 0 ? '+' : '' }}{{ trend }}
                </span>
                <svg v-if="trend > 0" class="w-6 h-6 text-brand-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                </svg>
                <svg v-else-if="trend < 0" class="w-6 h-6 text-brand-red" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6" />
                </svg>
                <svg v-else class="w-6 h-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14" />
                </svg>
              </div>
              <p class="text-sm mt-2 text-gray-600">
                {{ previousScore }} → {{ currentScore }}
              </p>
            </div>
          </div>

          <!-- Milestones checklist -->
          <div class="card">
            <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Milestoni Razvoja</h2>

            <div class="space-y-3">
              <div
                v-for="milestone in milestones"
                :key="milestone.id"
                class="p-4 rounded-xl border-2 transition-all"
                :class="milestone.status === 'achieved' ? 'border-brand-green bg-brand-green/5' : 'border-gray-100'"
              >
                <div class="flex items-start gap-3">
                  <div
                    class="w-6 h-6 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5"
                    :class="milestone.status === 'achieved' ? 'bg-brand-green text-white' : 'bg-gray-200 text-gray-400'"
                  >
                    <svg v-if="milestone.status === 'achieved'" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                  <div class="flex-1">
                    <h3 class="font-semibold text-gray-900">{{ milestone.title }}</h3>
                    <p class="text-sm text-gray-600 mt-1">{{ milestone.description }}</p>
                    <div class="flex items-center gap-3 mt-2">
                      <span
                        class="text-xs font-semibold px-2 py-0.5 rounded-full"
                        :class="getStatusBadgeClass(milestone.status)"
                      >
                        {{ getStatusLabel(milestone.status) }}
                      </span>
                      <span v-if="milestone.achievedAt" class="text-xs text-gray-500">
                        Postignuto: {{ formatDate(milestone.achievedAt) }}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Trend chart -->
          <div class="card">
            <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Trend Razvoja</h2>

            <div class="h-48 flex items-end gap-4 px-4">
              <div
                v-for="(score, index) in trendData"
                :key="index"
                class="flex-1 flex flex-col items-center gap-2"
              >
                <div class="w-full relative">
                  <div
                    class="w-full rounded-t-lg transition-all"
                    :style="{
                      height: `${(score / 5) * 160}px`,
                      backgroundColor: domainInfo.color + '80',
                    }"
                  />
                </div>
                <span class="text-xs text-gray-600 font-medium">{{ score }}</span>
                <span class="text-xs text-gray-500">{{ index + 1 }}. kvartal</span>
              </div>
            </div>
          </div>

          <!-- Recommended activities -->
          <div class="card">
            <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Preporučene Aktivnosti</h2>

            <div class="space-y-3">
              <div
                v-for="activity in recommendedActivities"
                :key="activity.id"
                class="p-4 rounded-xl bg-gray-50 hover:bg-gray-100 transition-all cursor-pointer"
                @click="openActivity(activity)"
              >
                <div class="flex items-start gap-3">
                  <div
                    class="w-10 h-10 rounded-xl flex items-center justify-center text-lg flex-shrink-0"
                    :style="{ backgroundColor: domainInfo.color + '20' }"
                  >
                    {{ activity.icon }}
                  </div>
                  <div class="flex-1">
                    <h3 class="font-semibold text-gray-900">{{ activity.title }}</h3>
                    <p class="text-sm text-gray-600 mt-1">{{ activity.description }}</p>
                    <div class="flex items-center gap-3 mt-2 text-xs text-gray-500">
                      <span>{{ activity.duration }}</span>
                      <span>•</span>
                      <span>{{ activity.difficulty }}</span>
                    </div>
                  </div>
                  <button class="btn-primary text-sm">
                    Pogledaj
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Recent observations -->
          <div class="card">
            <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Nedavne Opservacije</h2>

            <div v-if="observations && observations.length > 0" class="space-y-3">
              <div
                v-for="obs in observations"
                :key="obs.id"
                class="p-4 rounded-xl border-l-4 bg-gray-50"
                :style="{ borderColor: domainInfo.color }"
              >
                <p class="text-sm text-gray-700">{{ obs.content }}</p>
                <div class="flex items-center gap-3 mt-2 text-xs text-gray-500">
                  <span>{{ formatDate(obs.created_at) }}</span>
                  <span v-if="obs.observation_type">•</span>
                  <span v-if="obs.observation_type" class="capitalize">{{ obs.observation_type }}</span>
                </div>
              </div>
            </div>

            <div v-else class="text-center py-8 text-gray-400">
              <p class="text-sm">Nema opservacija za ovu domenu.</p>
            </div>
          </div>
        </div>
      </FeatureGate>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })

const route = useRoute()
const childId = route.params.id as string
const domainSlug = route.params.domain as string
const supabase = useSupabase()

const domainInfo = computed(() => {
  const domains: Record<string, { name: string; emoji: string; color: string }> = {
    emotional: { name: 'Emocionalni Razvoj', emoji: '❤️', color: '#cf2e2e' },
    social: { name: 'Socijalni Razvoj', emoji: '🤝', color: '#fcb900' },
    creative: { name: 'Kreativni Razvoj', emoji: '🎨', color: '#9b51e0' },
    cognitive: { name: 'Kognitivni Razvoj', emoji: '🧠', color: '#0693e3' },
    motor: { name: 'Motorički Razvoj', emoji: '🏃', color: '#00d084' },
    language: { name: 'Jezički Razvoj', emoji: '💬', color: '#f78da7' },
  }
  return domains[domainSlug] || { name: 'Nepoznata Domena', emoji: '❓', color: '#9b51e0' }
})

const { data: child, pending } = await useAsyncData(`child-domain-${childId}`, async () => {
  const { data } = await supabase
    .from('children')
    .select('id, full_name, nickname, date_of_birth, age_group')
    .eq('id', childId)
    .eq('is_active', true)
    .single()
  return data
})

// Sample data - in production, fetch from assessments, milestones, observations
const currentScore = ref(4)
const previousScore = ref(3)
const trend = computed(() => currentScore.value - previousScore.value)

const milestones = ref([
  {
    id: '1',
    title: 'Prepoznavanje i imenovanje emocija',
    description: 'Dijete može imenovati barem 4 osnovne emocije na sebi i drugima',
    status: 'achieved',
    achievedAt: '2026-01-15',
  },
  {
    id: '2',
    title: 'Regulacija emocija uz podršku',
    description: 'Dijete se smiruje uz pomoć odrasle osobe kada je uzrujano',
    status: 'achieved',
    achievedAt: '2026-02-10',
  },
  {
    id: '3',
    title: 'Samostalno upravljanje ljutnjom',
    description: 'Koristi strategije (duboko disanje, brojanje) za smirivanje',
    status: 'emerging',
    achievedAt: null,
  },
  {
    id: '4',
    title: 'Empatija i tješenje vršnjaka',
    description: 'Prepoznaje kada je drugo dijete tužno i pokušava utješiti',
    status: 'upcoming',
    achievedAt: null,
  },
])

const trendData = ref([3, 3, 4, 4]) // Q1, Q2, Q3, Q4 scores

const recommendedActivities = ref([
  {
    id: '1',
    title: 'Kartice emocija',
    description: 'Igra s karticama za prepoznavanje i imenovanje različitih emocija',
    icon: '😢',
    duration: '15 min',
    difficulty: 'Lahko',
  },
  {
    id: '2',
    title: 'Lutke osjećaja',
    description: 'Igranje uloga s lutkama koje izražavaju različite emocije',
    icon: '🎭',
    duration: '20 min',
    difficulty: 'Srednje',
  },
  {
    id: '3',
    title: 'Disanje balona',
    description: 'Vježba dubokog disanja za regulaciju emocija',
    icon: '🎈',
    duration: '5 min',
    difficulty: 'Lahko',
  },
])

const { data: observations } = await useAsyncData(`obs-domain-${childId}-${domainSlug}`, async () => {
  const { data } = await supabase
    .from('observations')
    .select('id, content, observation_type, created_at')
    .eq('child_id', childId)
    .eq('skill_area_id', domainSlug)
    .eq('is_visible_to_parent', true)
    .order('created_at', { ascending: false })
    .limit(5)
  return data ?? []
})

const milestonesAchieved = computed(() =>
  milestones.value.filter(m => m.status === 'achieved').length
)

const totalMilestones = milestones.value.length

function scoreLabel(score: number): string {
  const labels = ['Početak', 'Razvija se', 'Na putu', 'Napreduje', 'Odlično']
  return labels[score - 1] ?? '–'
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = {
    achieved: 'Postignuto',
    emerging: 'U razvoju',
    upcoming: 'Sljedeće',
  }
  return map[status] || 'Nepoznato'
}

function getStatusBadgeClass(status: string): string {
  const map: Record<string, string> = {
    achieved: 'bg-brand-green/10 text-brand-green',
    emerging: 'bg-brand-amber/10 text-brand-amber',
    upcoming: 'bg-gray-100 text-gray-600',
  }
  return map[status] || 'bg-gray-100'
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short', year: 'numeric' })
}

function openActivity(activity: any) {
  // TODO: Navigate to activity detail or open modal
  console.log('Opening activity:', activity)
}

useSeoMeta({ title: `${domainInfo.value.name} — ${child.value?.full_name ?? 'Dijete'}` })
</script>
