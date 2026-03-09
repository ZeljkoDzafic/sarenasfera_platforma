<template>
  <div class="space-y-6">
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Admin Panel</h1>
      <p class="text-sm text-gray-500 mt-1">Pregled platforme u realnom vremenu</p>
    </div>

    <!-- KPI Cards -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
      <div v-for="kpi in kpis" :key="kpi.label" class="card">
        <div class="flex items-center justify-between mb-3">
          <div
            class="w-10 h-10 rounded-xl flex items-center justify-center"
            :style="{ backgroundColor: kpi.color + '20' }"
          >
            <span class="text-xl">{{ kpi.icon }}</span>
          </div>
          <span v-if="kpi.trend" class="text-xs font-semibold" :class="kpi.trend > 0 ? 'text-brand-green' : 'text-brand-red'">
            {{ kpi.trend > 0 ? '+' : '' }}{{ kpi.trend }}%
          </span>
        </div>
        <div class="text-2xl font-bold text-gray-900" :style="{ color: kpi.color }">
          <span v-if="statsLoading">–</span>
          <span v-else>{{ stats?.[kpi.key] ?? '–' }}</span>
        </div>
        <p class="text-xs text-gray-500 mt-1">{{ kpi.label }}</p>
      </div>
    </div>

    <!-- Charts row -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Recent registrations -->
      <div class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Nedavne registracije</h2>
        <div v-if="statsLoading" class="space-y-3">
          <div v-for="i in 5" :key="i" class="h-10 bg-gray-100 rounded-xl animate-pulse" />
        </div>
        <div v-else-if="recentLeads && recentLeads.length > 0" class="space-y-2">
          <div
            v-for="lead in recentLeads"
            :key="lead.id"
            class="flex items-center gap-3 p-2 rounded-xl hover:bg-gray-50"
          >
            <div class="w-8 h-8 rounded-xl bg-primary-100 flex items-center justify-center font-bold text-primary-600 text-sm">
              {{ lead.name?.[0] ?? lead.email[0].toUpperCase() }}
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-semibold text-gray-900 truncate">{{ lead.name ?? lead.email }}</p>
              <p class="text-xs text-gray-400">{{ lead.source }} • {{ formatDate(lead.created_at) }}</p>
            </div>
          </div>
        </div>
        <div v-else class="text-center py-8 text-gray-400 text-sm">Nema novih registracija.</div>
      </div>

      <!-- Upcoming sessions -->
      <div class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Nadolazeće radionice</h2>
        <div v-if="sessionsLoading" class="space-y-3">
          <div v-for="i in 4" :key="i" class="h-14 bg-gray-100 rounded-xl animate-pulse" />
        </div>
        <div v-else-if="upcomingSessions && upcomingSessions.length > 0" class="space-y-2">
          <div
            v-for="session in upcomingSessions"
            :key="session.id"
            class="flex items-start gap-3 p-3 rounded-xl bg-gray-50"
          >
            <div class="w-10 h-10 rounded-xl bg-primary-500 text-white flex flex-col items-center justify-center flex-shrink-0">
              <span class="text-xs font-bold leading-none">{{ formatDayNum(session.scheduled_date) }}</span>
              <span class="text-xs opacity-80 leading-none">{{ formatMonthShort(session.scheduled_date) }}</span>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-semibold text-gray-900 truncate">{{ session.workshops?.title ?? 'Radionica' }}</p>
              <p class="text-xs text-gray-500">{{ session.groups?.name }} • {{ session.scheduled_time_start?.slice(0,5) }}</p>
            </div>
          </div>
        </div>
        <div v-else class="text-center py-8 text-gray-400 text-sm">Nema nadolazećih radionica.</div>
      </div>
    </div>

    <!-- Quick actions -->
    <div class="card">
      <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Brze akcije</h2>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
        <NuxtLink
          v-for="action in quickActions"
          :key="action.label"
          :to="action.to"
          class="flex flex-col items-center gap-2 p-4 rounded-xl hover:bg-gray-50 border-2 border-dashed border-gray-200 hover:border-primary-300 transition-all text-center group"
        >
          <span class="text-2xl">{{ action.icon }}</span>
          <span class="text-xs font-semibold text-gray-600 group-hover:text-primary-600">{{ action.label }}</span>
        </NuxtLink>
      </div>
    </div>

    <!-- Domain distribution (from assessments) -->
    <div class="card">
      <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Razvojna distribucija djece</h2>
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
        <div
          v-for="domain in domains"
          :key="domain.key"
          class="text-center p-3 rounded-xl"
          :style="{ backgroundColor: domain.color + '10' }"
        >
          <div class="text-2xl mb-1">{{ domain.emoji }}</div>
          <div class="text-lg font-bold" :style="{ color: domain.color }">{{ domain.avg }}</div>
          <div class="text-xs text-gray-500">{{ domain.name }}</div>
          <div class="text-xs text-gray-400">prosjek</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })

useSeoMeta({ title: 'Admin Dashboard — Šarena Sfera' })

const supabase = useSupabase()

const statsLoading = ref(true)
const sessionsLoading = ref(true)
const stats = ref<Record<string, number | string>>({})
const recentLeads = ref<Array<Record<string, string>>>([])
const upcomingSessions = ref<Array<Record<string, unknown>>>([])

const kpis = [
  { key: 'total_children', label: 'Ukupno djece', icon: '👶', color: '#9b51e0', trend: 5 },
  { key: 'active_parents', label: 'Aktivnih roditelja', icon: '👨‍👩‍👧', color: '#0693e3', trend: 3 },
  { key: 'total_leads', label: 'Novih leadova', icon: '📧', color: '#fcb900', trend: 12 },
  { key: 'sessions_this_month', label: 'Radionica ovaj mj.', icon: '🎨', color: '#00d084', trend: null },
]

const domains = [
  { key: 'emotional', name: 'Emocionalni', emoji: '❤️', color: '#cf2e2e', avg: '3.8' },
  { key: 'social',    name: 'Socijalni',   emoji: '🤝', color: '#fcb900', avg: '4.1' },
  { key: 'creative',  name: 'Kreativni',   emoji: '🎨', color: '#9b51e0', avg: '4.3' },
  { key: 'cognitive', name: 'Kognitivni',  emoji: '🧠', color: '#0693e3', avg: '3.6' },
  { key: 'motor',     name: 'Motorički',   emoji: '🏃', color: '#00d084', avg: '4.0' },
  { key: 'language',  name: 'Jezički',     emoji: '💬', color: '#f78da7', avg: '3.9' },
]

const quickActions = [
  { label: 'Dodaj dijete', icon: '👶', to: '/admin/children/new' },
  { label: 'Nova sesija', icon: '📅', to: '/admin/sessions/new' },
  { label: 'Opservacija', icon: '📝', to: '/admin/observe' },
  { label: 'Pošalji poruku', icon: '💬', to: '/admin/messages' },
]

onMounted(async () => {
  // Load stats in parallel
  const [childrenRes, parentsRes, leadsRes, sessionsRes, upcomingRes] = await Promise.all([
    supabase.from('children').select('id', { count: 'exact', head: true }).eq('is_active', true),
    supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'parent').eq('is_active', true),
    supabase.from('leads').select('id', { count: 'exact', head: true }),
    supabase.from('sessions').select('id', { count: 'exact', head: true })
      .gte('scheduled_date', new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString()),
    supabase.from('sessions').select('id, scheduled_date, scheduled_time_start, workshops(title), groups(name)')
      .gte('scheduled_date', new Date().toISOString().slice(0, 10))
      .order('scheduled_date')
      .limit(5),
  ])

  stats.value = {
    total_children: childrenRes.count ?? 0,
    active_parents: parentsRes.count ?? 0,
    total_leads: leadsRes.count ?? 0,
    sessions_this_month: sessionsRes.count ?? 0,
  }

  upcomingSessions.value = upcomingRes.data ?? []
  statsLoading.value = false
  sessionsLoading.value = false

  // Recent leads
  const { data: leads } = await supabase
    .from('leads')
    .select('id, email, name, source, created_at')
    .order('created_at', { ascending: false })
    .limit(8)
  recentLeads.value = leads ?? []
})

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short' })
}
function formatDayNum(iso: string): string { return new Date(iso).getDate().toString() }
function formatMonthShort(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { month: 'short' }).replace('.', '')
}
</script>
