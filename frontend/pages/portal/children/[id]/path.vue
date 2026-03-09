<template>
  <div class="space-y-6">
    <!-- Back + title -->
    <div v-if="child" class="flex items-center gap-3">
      <NuxtLink :to="`/portal/children/${childId}`" class="p-2 rounded-xl hover:bg-gray-100 text-gray-500 hover:text-gray-700 transition-colors">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </NuxtLink>
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Razvojna Putanja</h1>
        <p class="text-sm text-gray-500">{{ child.full_name }} • Personalizirani plan razvoja</p>
      </div>
    </div>

    <!-- Loading -->
    <div v-else-if="pending" class="space-y-4">
      <div class="card animate-pulse h-32" />
      <div class="card animate-pulse h-64" />
    </div>

    <div v-else>
      <!-- Feature gate for paid tier -->
      <FeatureGate required-tier="paid">
        <template #locked>
          <div class="text-center py-12">
            <div class="text-5xl mb-4">🔒</div>
            <h3 class="font-display font-bold text-xl text-gray-900 mb-2">Razvojna putanja je Premium funkcija</h3>
            <p class="text-gray-600 mb-6">Nadogradite na Paid tier za pristup personaliziranom planu razvoja.</p>
            <NuxtLink to="/pricing" class="btn-primary">Pregledajte Planove</NuxtLink>
          </div>
        </template>

        <!-- Content -->
        <div class="space-y-6">
          <!-- Summary cards -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="card p-4">
              <div class="flex items-center gap-3 mb-2">
                <div class="w-10 h-10 rounded-xl bg-brand-green/20 flex items-center justify-center">
                  <svg class="w-5 h-5 text-brand-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <div>
                  <p class="text-sm text-gray-600">Postignuti Milestoni</p>
                  <p class="text-2xl font-bold text-gray-900">{{ milestonesAchieved }}/{{ totalMilestones }}</p>
                </div>
              </div>
            </div>

            <div class="card p-4">
              <div class="flex items-center gap-3 mb-2">
                <div class="w-10 h-10 rounded-xl bg-brand-amber/20 flex items-center justify-center">
                  <svg class="w-5 h-5 text-brand-amber" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                  </svg>
                </div>
                <div>
                  <p class="text-sm text-gray-600">Trenutni Fokus</p>
                  <p class="text-lg font-bold text-gray-900">{{ currentFocusArea }}</p>
                </div>
              </div>
            </div>

            <div class="card p-4">
              <div class="flex items-center gap-3 mb-2">
                <div class="w-10 h-10 rounded-xl bg-primary-100 flex items-center justify-center">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <div>
                  <p class="text-sm text-gray-600">Preporučene Aktivnosti</p>
                  <p class="text-2xl font-bold text-gray-900">{{ recommendedActivities.length }}</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Timeline -->
          <div class="card">
            <h2 class="font-display font-bold text-lg text-gray-900 mb-6">Put Razvoja</h2>

            <div class="relative">
              <!-- Vertical line -->
              <div class="absolute left-8 top-0 bottom-0 w-0.5 bg-gray-200" />

              <!-- Timeline items -->
              <div class="space-y-6">
                <!-- Past milestones -->
                <div
                  v-for="(item, index) in timelineItems"
                  :key="item.id"
                  class="relative flex gap-4"
                >
                  <!-- Icon -->
                  <div
                    class="relative z-10 w-16 h-16 rounded-2xl flex items-center justify-center flex-shrink-0 shadow-md"
                    :class="getItemBgClass(item.status)"
                  >
                    <span class="text-2xl">{{ item.icon }}</span>
                    <div
                      v-if="item.status === 'achieved'"
                      class="absolute -top-1 -right-1 w-5 h-5 bg-brand-green rounded-full flex items-center justify-center"
                    >
                      <svg class="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                  </div>

                  <!-- Content -->
                  <div class="flex-1 pt-2">
                    <div class="flex items-center gap-2 mb-1">
                      <h3 class="font-bold text-gray-900">{{ item.title }}</h3>
                      <span
                        class="text-xs font-semibold px-2 py-0.5 rounded-full"
                        :class="getStatusBadgeClass(item.status)"
                      >
                        {{ getStatusLabel(item.status) }}
                      </span>
                    </div>
                    <p class="text-sm text-gray-600 mb-2">{{ item.description }}</p>
                    <div class="flex items-center gap-4 text-xs text-gray-500">
                      <span class="flex items-center gap-1">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                        </svg>
                        {{ item.date }}
                      </span>
                      <span
                        class="px-2 py-0.5 rounded-full text-xs font-semibold"
                        :style="{ backgroundColor: getDomainColor(item.domain) + '20', color: getDomainColor(item.domain) }"
                      >
                        {{ getDomainName(item.domain) }}
                      </span>
                    </div>

                    <!-- Recommended actions for upcoming items -->
                    <div v-if="item.status === 'upcoming'" class="mt-3 p-3 bg-primary-50 rounded-xl">
                      <p class="text-xs font-semibold text-primary-700 mb-2">💡 Preporuke:</p>
                      <ul class="space-y-1">
                        <li v-for="(rec, i) in item.recommendations" :key="i" class="text-xs text-gray-700 flex items-start gap-2">
                          <span class="text-primary-600">•</span>
                          {{ rec }}
                        </li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Recommended activities -->
          <div class="card">
            <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Preporučene Aktivnosti</h2>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div
                v-for="activity in recommendedActivities"
                :key="activity.id"
                class="p-4 rounded-xl border border-gray-100 hover:border-primary-200 hover:shadow-md transition-all"
              >
                <div class="flex items-start gap-3">
                  <div
                    class="w-10 h-10 rounded-xl flex items-center justify-center text-lg flex-shrink-0"
                    :style="{ backgroundColor: getDomainColor(activity.domain) + '20' }"
                  >
                    {{ getDomainEmoji(activity.domain) }}
                  </div>
                  <div class="flex-1 min-w-0">
                    <h3 class="font-semibold text-gray-900">{{ activity.title }}</h3>
                    <p class="text-sm text-gray-600 mt-1 line-clamp-2">{{ activity.description }}</p>
                    <div class="flex items-center gap-3 mt-2 text-xs text-gray-500">
                      <span>{{ activity.duration }}</span>
                      <span>•</span>
                      <span>{{ activity.ageRange }}</span>
                    </div>
                  </div>
                </div>
                <NuxtLink
                  :to="`/portal/activities?activity=${activity.id}`"
                  class="btn-primary w-full mt-3 text-sm"
                >
                  Pogledaj Aktivnost
                </NuxtLink>
              </div>
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
const supabase = useSupabase()

const { tierName } = useTier()

const { data: child, pending } = await useAsyncData(`child-path-${childId}`, async () => {
  const { data } = await supabase
    .from('children')
    .select('id, full_name, nickname, date_of_birth, age_group')
    .eq('id', childId)
    .eq('is_active', true)
    .single()
  return data
})

// Sample timeline data - in production, this would come from assessments, milestones, observations
const timelineItems = ref([
  {
    id: '1',
    title: 'Prepoznavanje emocija',
    description: 'Dijete može imenovati 4 osnovne emocije (sreća, tuga, ljutnja, strah)',
    domain: 'emotional',
    status: 'achieved',
    date: 'Jan 2026',
    icon: '❤️',
    recommendations: [],
  },
  {
    id: '2',
    title: 'Dijeljenje s vršnjacima',
    description: 'Dijete dijeli igračke i materijale tokom grupnih aktivnosti',
    domain: 'social',
    status: 'achieved',
    date: 'Feb 2026',
    icon: '🤝',
    recommendations: [],
  },
  {
    id: '3',
    title: 'Kreativno izražavanje',
    description: 'Koristi više materijala u jednoj kreativnoj aktivnosti',
    domain: 'creative',
    status: 'current',
    date: 'Trenutno',
    icon: '🎨',
    recommendations: [
      'Crtanje uz muziku različitih žanrova',
      'Kolaž od različitih materijala (papir, tkanina, lišće)',
    ],
  },
  {
    id: '4',
    title: 'Brojanje do 10',
    description: 'Samostalno broji objekte do 10 i prepoznaje brojeve',
    domain: 'cognitive',
    status: 'upcoming',
    date: 'Mar - Apr 2026',
    icon: '🧠',
    recommendations: [
      'Igra prodavnice s brojanjem novca',
      'Slaganje predmeta po brojevima',
      'Pjevanje pjesmica s brojanjem',
    ],
  },
  {
    id: '5',
    title: 'Fina motorika - škare',
    description: 'Sigurno koristi škare i reže po liniji',
    domain: 'motor',
    status: 'upcoming',
    date: 'Apr - Maj 2026',
    icon: '✂️',
    recommendations: [
      'Rezanje papira po ravnim linijama',
      'Izrada jednostavnih figura od papira',
      'Aktivnosti s pincetom za jačanje prstiju',
    ],
  },
  {
    id: '6',
    title: 'Složene rečenice',
    description: 'Kreira rečenice od 5+ riječi s ispravnom gramatikom',
    domain: 'language',
    status: 'upcoming',
    date: 'Maj - Jun 2026',
    icon: '💬',
    recommendations: [
      'Zajedničko čitanje i prepričavanje priča',
      'Igranje uloga s dijalogom',
      'Opisivanje slika s puno detalja',
    ],
  },
])

const recommendedActivities = ref([
  {
    id: '1',
    title: 'Igranje uloga: Prodavnica',
    description: 'Dijete glumi prodavača, uči brojanje i socijalne vještine kroz igru.',
    domain: 'social',
    duration: '20-30 min',
    ageRange: '4-6 god',
  },
  {
    id: '2',
    title: 'Crtanje uz muziku',
    description: 'Razvoj kreativnosti kroz izražavanje uz različite muzičke žanrove.',
    domain: 'creative',
    duration: '15-20 min',
    ageRange: '3-6 god',
  },
  {
    id: '3',
    title: 'Poligon s preprekama',
    description: 'Kreirajte poligon za razvoj fine i grube motorike.',
    domain: 'motor',
    duration: '30 min',
    ageRange: '3-6 god',
  },
])

const milestonesAchieved = computed(() =>
  timelineItems.value.filter(i => i.status === 'achieved').length
)

const totalMilestones = timelineItems.value.length

const currentFocusArea = computed(() => {
  const current = timelineItems.value.find(i => i.status === 'current')
  return current ? current.title.split(' ')[0] : 'Razvoj'
})

function getItemBgClass(status: string): string {
  const map: Record<string, string> = {
    achieved: 'bg-brand-green/20 text-brand-green',
    current: 'bg-brand-amber/20 text-brand-amber',
    upcoming: 'bg-gray-100 text-gray-400',
  }
  return map[status] || 'bg-gray-100'
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = {
    achieved: 'Postignuto',
    current: 'U fokusu',
    upcoming: 'Sljedeće',
  }
  return map[status] || 'Nepoznato'
}

function getStatusBadgeClass(status: string): string {
  const map: Record<string, string> = {
    achieved: 'bg-brand-green/10 text-brand-green',
    current: 'bg-brand-amber/10 text-brand-amber',
    upcoming: 'bg-gray-100 text-gray-600',
  }
  return map[status] || 'bg-gray-100'
}

const domainColorMap: Record<string, string> = {
  emotional: '#cf2e2e',
  social: '#fcb900',
  creative: '#9b51e0',
  cognitive: '#0693e3',
  motor: '#00d084',
  language: '#f78da7',
}

const domainEmojiMap: Record<string, string> = {
  emotional: '❤️',
  social: '🤝',
  creative: '🎨',
  cognitive: '🧠',
  motor: '🏃',
  language: '💬',
}

const domainNameMap: Record<string, string> = {
  emotional: 'Emocionalni',
  social: 'Socijalni',
  creative: 'Kreativni',
  cognitive: 'Kognitivni',
  motor: 'Motorički',
  language: 'Jezički',
}

function getDomainColor(domain: string): string {
  return domainColorMap[domain] || '#9b51e0'
}

function getDomainEmoji(domain: string): string {
  return domainEmojiMap[domain] || '🎨'
}

function getDomainName(domain: string): string {
  return domainNameMap[domain] || 'Nepoznato'
}

useSeoMeta({ title: `Razvojna Putanja — ${child.value?.full_name ?? 'Dijete'}` })
</script>
