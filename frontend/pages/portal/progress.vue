<template>
  <div class="space-y-6">
    <!-- Feature Gate for Paid Tier -->
    <FeatureGate required-tier="paid">
      <template #locked>
        <UpgradeBanner
          tier-name="paid"
          title="Pratite svoj napredak"
          message="Nadogradite na Osnovni plan da vidite vaš angažman, osvojene bedževe i statistike aktivnosti."
          :features="['Praćenje angažmana i poena', 'Bedževi i postignuća', 'Statistike aktivnosti']"
        />
      </template>

      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="font-display text-2xl font-bold text-gray-900">Moj Napredak</h1>
          <p class="text-sm text-gray-500 mt-1">Pratite svoj angažman i osvojene bedževe</p>
        </div>
        <div v-if="score" class="text-right">
          <div class="text-3xl font-display font-bold text-primary-600">{{ score.total_points }}</div>
          <div class="text-xs text-gray-500">ukupno poena</div>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="space-y-4">
        <div v-for="i in 3" :key="i" class="card h-32 animate-pulse bg-gray-100" />
      </div>

      <!-- Content -->
      <div v-else class="space-y-6">
        <!-- KPI Cards -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div class="card text-center">
            <div class="text-3xl mb-2">🎨</div>
            <div class="text-2xl font-bold text-gray-900">{{ workshopsThisMonth }} / {{ score?.workshops_attended || 0 }}</div>
            <div class="text-xs text-gray-500 mt-1">Radionice ovaj mj. / ukupno</div>
          </div>

          <div class="card text-center">
            <div class="text-3xl mb-2">🏠</div>
            <div class="text-2xl font-bold text-gray-900">{{ score?.activities_completed || 0 }}</div>
            <div class="text-xs text-gray-500 mt-1">Kućne aktivnosti</div>
          </div>

          <div class="card text-center">
            <div class="text-3xl mb-2">💬</div>
            <div class="text-2xl font-bold text-gray-900">{{ score?.forum_posts || 0 }}</div>
            <div class="text-xs text-gray-500 mt-1">Forum postovi</div>
          </div>

          <div class="card text-center">
            <div class="text-3xl mb-2">🔥</div>
            <div class="text-2xl font-bold text-primary-600">{{ score?.current_streak || 0 }}</div>
            <div class="text-xs text-gray-500 mt-1">Uzastopne sedmice</div>
          </div>
        </div>

        <!-- Engagement Score Breakdown -->
        <div class="card">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Angažman Score</h2>

          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <span class="text-sm text-gray-700">Prisustvo na radionicama</span>
              <div class="flex items-center gap-2">
                <div class="w-32 h-2 bg-gray-100 rounded-full overflow-hidden">
                  <div
                    class="h-full bg-brand-green"
                    :style="{ width: `${Math.min((score?.workshops_attended || 0) / 96 * 100, 100)}%` }"
                  />
                </div>
                <span class="text-sm font-semibold text-gray-900 w-16 text-right">
                  {{ score?.workshops_attended || 0 }} / 96
                </span>
              </div>
            </div>

            <div class="flex items-center justify-between">
              <span class="text-sm text-gray-700">Kućne aktivnosti</span>
              <div class="flex items-center gap-2">
                <div class="w-32 h-2 bg-gray-100 rounded-full overflow-hidden">
                  <div
                    class="h-full bg-primary-500"
                    :style="{ width: `${Math.min((score?.activities_completed || 0) / 50 * 100, 100)}%` }"
                  />
                </div>
                <span class="text-sm font-semibold text-gray-900 w-16 text-right">
                  {{ score?.activities_completed || 0 }} / 50
                </span>
              </div>
            </div>

            <div class="flex items-center justify-between">
              <span class="text-sm text-gray-700">Preporuke</span>
              <div class="flex items-center gap-2">
                <div class="w-32 h-2 bg-gray-100 rounded-full overflow-hidden">
                  <div
                    class="h-full bg-brand-amber"
                    :style="{ width: `${Math.min((score?.referrals_made || 0) / 10 * 100, 100)}%` }"
                  />
                </div>
                <span class="text-sm font-semibold text-gray-900 w-16 text-right">
                  {{ score?.referrals_made || 0 }} / 10
                </span>
              </div>
            </div>

            <div class="flex items-center justify-between">
              <span class="text-sm text-gray-700">Forum učešće</span>
              <div class="flex items-center gap-2">
                <div class="w-32 h-2 bg-gray-100 rounded-full overflow-hidden">
                  <div
                    class="h-full bg-brand-blue"
                    :style="{ width: `${Math.min((score?.forum_posts || 0) / 50 * 100, 100)}%` }"
                  />
                </div>
                <span class="text-sm font-semibold text-gray-900 w-16 text-right">
                  {{ score?.forum_posts || 0 }} / 50
                </span>
              </div>
            </div>
          </div>

          <div class="mt-6 pt-6 border-t border-gray-100 flex items-center justify-between">
            <span class="font-semibold text-gray-900">Ukupno poena</span>
            <span class="text-2xl font-display font-bold text-primary-600">{{ score?.total_points || 0 }}</span>
          </div>
        </div>

        <!-- Earned Badges -->
        <div class="card">
          <div class="flex items-center justify-between mb-4">
            <h2 class="font-display font-bold text-lg text-gray-900">Osvojeni Bedževi</h2>
            <span class="text-sm text-gray-500">{{ earnedBadges.length }} / {{ allBadges.length }}</span>
          </div>

          <div v-if="earnedBadges.length > 0" class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            <div
              v-for="badge in earnedBadges"
              :key="badge.id"
              class="text-center p-3 rounded-xl bg-gradient-to-br from-primary-50 to-brand-pink/10 hover:shadow-md transition-shadow"
            >
              <div class="text-4xl mb-2">{{ badge.badges?.icon || '🏆' }}</div>
              <div class="text-xs font-semibold text-gray-900">{{ badge.badges?.name }}</div>
              <div class="text-xs text-gray-500 mt-1">
                {{ formatDate(badge.earned_at) }}
              </div>
            </div>
          </div>

          <div v-else class="text-center py-8">
            <div class="text-5xl mb-4">🎯</div>
            <p class="text-gray-500">Još nema osvojenih bedževa.</p>
            <p class="text-sm text-gray-400 mt-2">Nastavite biti aktivni da zaradite bedževe!</p>
          </div>
        </div>

        <!-- Available Badges (locked) -->
        <div class="card">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Dostupni Bedževi</h2>

          <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            <div
              v-for="badge in lockedBadges"
              :key="badge.id"
              class="text-center p-3 rounded-xl bg-gray-50 opacity-60 hover:opacity-100 transition-opacity"
            >
              <div class="text-4xl mb-2 grayscale">{{ badge.icon || '🏆' }}</div>
              <div class="text-xs font-semibold text-gray-700">{{ badge.name }}</div>
              <div class="text-xs text-gray-500 mt-1">{{ badge.description }}</div>
            </div>
          </div>
        </div>

        <!-- Activity Timeline -->
        <div class="card">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Nedavne Aktivnosti</h2>

          <div v-if="recentEvents.length > 0" class="space-y-3">
            <div
              v-for="event in recentEvents"
              :key="event.id"
              class="flex items-start gap-3 p-3 rounded-xl hover:bg-gray-50"
            >
              <div class="text-2xl">{{ getEventIcon(event.event_type) }}</div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold text-gray-900">{{ getEventLabel(event.event_type) }}</p>
                <p class="text-xs text-gray-500">{{ formatDate(event.created_at) }}</p>
              </div>
              <div class="text-sm font-semibold text-primary-600">+{{ event.points }}</div>
            </div>
          </div>

          <div v-else class="text-center py-8 text-gray-500 text-sm">
            Nema nedavnih aktivnosti.
          </div>
        </div>

        <!-- Streak Calendar -->
        <div class="card">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">
            Aktivnost Kalendar
            <span v-if="score?.current_streak" class="text-sm font-normal text-gray-500">
              (🔥 {{ score.current_streak }} uzastopnih sedmica)
            </span>
          </h2>

          <div class="grid grid-cols-7 gap-2">
            <div v-for="week in 12" :key="week" class="text-center">
              <div
                class="w-full aspect-square rounded-lg"
                :class="week <= (score?.current_streak || 0)
                  ? 'bg-gradient-to-br from-brand-amber to-brand-red'
                  : 'bg-gray-100'"
              >
                <div v-if="week <= (score?.current_streak || 0)" class="flex items-center justify-center h-full text-white font-bold text-xs">
                  ✓
                </div>
              </div>
              <div class="text-xs text-gray-400 mt-1">{{ week }}</div>
            </div>
          </div>
        </div>
      </div>
    </FeatureGate>
  </div>
</template>

<script setup lang="ts">
// T-905: Parent Progress & Engagement Tracking
// Parent's engagement dashboard with metrics, badges, and activity timeline

definePageMeta({ middleware: ['auth'], layout: 'portal' })
useSeoMeta({ title: 'Moj Napredak — Šarena Sfera' })

const supabase = useSupabase()
const { user } = useAuth()

const loading = ref(true)
const score = ref<any>(null)
const earnedBadges = ref<any[]>([])
const allBadges = ref<any[]>([])
const recentEvents = ref<any[]>([])
const workshopsThisMonth = ref(0)

const lockedBadges = computed(() => {
  const earnedIds = new Set(earnedBadges.value.map(b => b.badge_id))
  return allBadges.value.filter(b => !earnedIds.has(b.id))
})

onMounted(async () => {
  if (!user.value) return

  loading.value = true

  try {
    // Load engagement score
    const { data: scoreData } = await supabase
      .from('user_engagement_scores')
      .select('*')
      .eq('user_id', user.value.id)
      .single()
    score.value = scoreData

    // Load earned badges
    const { data: badgesData } = await supabase
      .from('user_badges')
      .select('*, badges(*)')
      .eq('user_id', user.value.id)
      .order('earned_at', { ascending: false })
    earnedBadges.value = badgesData || []

    // Load all badges
    const { data: allBadgesData } = await supabase
      .from('badges')
      .select('*')
      .eq('is_active', true)
      .eq('type', 'parent')
      .order('sort_order')
    allBadges.value = allBadgesData || []

    // Load recent events
    const { data: eventsData } = await supabase
      .from('engagement_events')
      .select('*')
      .eq('user_id', user.value.id)
      .order('created_at', { ascending: false })
      .limit(10)
    recentEvents.value = eventsData || []

    // Calculate workshops this month
    const startOfMonth = new Date()
    startOfMonth.setDate(1)
    startOfMonth.setHours(0, 0, 0, 0)

    const { count } = await supabase
      .from('engagement_events')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.value.id)
      .eq('event_type', 'workshop_attended')
      .gte('created_at', startOfMonth.toISOString())

    workshopsThisMonth.value = count || 0

  } catch (err) {
    console.error('Failed to load progress data:', err)
  } finally {
    loading.value = false
  }
})

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', {
    day: 'numeric',
    month: 'short',
  })
}

function getEventIcon(type: string): string {
  const icons: Record<string, string> = {
    workshop_attended: '🎨',
    home_activity_completed: '🏠',
    forum_post: '💬',
    forum_reply: '💬',
    referral_made: '🎯',
    login: '🔐',
    profile_updated: '👤',
    resource_downloaded: '📄',
    certificate_earned: '🎓',
  }
  return icons[type] || '✅'
}

function getEventLabel(type: string): string {
  const labels: Record<string, string> = {
    workshop_attended: 'Prisustvo na radionici',
    home_activity_completed: 'Završena kućna aktivnost',
    forum_post: 'Novi post na forumu',
    forum_reply: 'Odgovor na forumu',
    referral_made: 'Preporučen prijatelj',
    login: 'Prijava na platformu',
    profile_updated: 'Ažuriran profil',
    resource_downloaded: 'Preuzet resurs',
    certificate_earned: 'Osvojen sertifikat',
  }
  return labels[type] || type
}
</script>
