<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Radionice</h1>
        <p class="text-sm text-gray-500 mt-1">Predlošci i zakazane sesije</p>
      </div>
      <div class="flex gap-2">
        <button class="btn-secondary text-sm" @click="activeView = activeView === 'templates' ? 'sessions' : 'templates'">
          {{ activeView === 'templates' ? 'Sesije' : 'Predlošci' }}
        </button>
        <button class="btn-primary text-sm" @click="showCreateTemplate = true">+ Novi predložak</button>
      </div>
    </div>

    <!-- Workshop templates -->
    <div v-if="activeView === 'templates'">
      <div v-if="templatesLoading" class="space-y-2">
        <div v-for="i in 6" :key="i" class="card h-20 animate-pulse" />
      </div>

      <div v-else-if="workshops && workshops.length > 0" class="space-y-3">
        <div
          v-for="ws in workshops"
          :key="ws.id"
          class="card-domain cursor-pointer hover:shadow-md transition-shadow"
          :style="{ borderColor: getDomainColor(ws.domains?.[0]) }"
          @click="router.push(`/admin/workshops/${ws.id}`)"
        >
          <div class="flex items-start gap-3">
            <div class="w-10 h-10 rounded-xl flex items-center justify-center text-white text-lg"
              :style="{ backgroundColor: getDomainColor(ws.domains?.[0]) }">
              {{ getDomainEmoji(ws.domains?.[0]) }}
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-start justify-between gap-2">
                <h3 class="font-semibold text-gray-900">{{ ws.title }}</h3>
                <span class="text-xs font-semibold text-gray-400 whitespace-nowrap">Mj. {{ ws.month_number }}</span>
              </div>
              <p class="text-xs text-gray-500 mt-0.5">{{ ws.description?.slice(0, 100) }}{{ ws.description && ws.description.length > 100 ? '...' : '' }}</p>
              <div class="flex items-center gap-3 mt-1">
                <span v-for="d in (ws.domains ?? [])" :key="d" class="text-xs font-semibold px-2 py-0.5 rounded-full text-white" :style="{ backgroundColor: getDomainColor(d) }">
                  {{ getDomainLabel(d) }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="card text-center py-14">
        <div class="text-4xl mb-3">🎨</div>
        <h3 class="font-display font-bold text-lg text-gray-900 mb-2">Nema predložaka</h3>
        <button class="btn-primary text-sm mt-2" @click="showCreateTemplate = true">Kreirajte prvi predložak</button>
      </div>
    </div>

    <!-- Sessions calendar view -->
    <div v-else class="space-y-3">
      <div v-if="sessionsLoading" class="space-y-2">
        <div v-for="i in 5" :key="i" class="card h-16 animate-pulse" />
      </div>
      <div v-else-if="sessions && sessions.length > 0">
        <div
          v-for="session in sessions"
          :key="session.id"
          class="card flex items-center gap-4"
        >
          <div class="w-12 h-12 rounded-xl bg-primary-500 text-white flex flex-col items-center justify-center flex-shrink-0">
            <span class="text-sm font-bold leading-none">{{ new Date(session.scheduled_date).getDate() }}</span>
            <span class="text-xs opacity-80">{{ new Date(session.scheduled_date).toLocaleDateString('bs-BA', { month: 'short' }) }}</span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="font-semibold text-gray-900 truncate">{{ session.workshops?.title ?? 'Radionica' }}</p>
            <p class="text-xs text-gray-500">
              {{ session.groups?.name }} • {{ session.scheduled_time_start?.slice(0,5) }}
            </p>
          </div>
          <span class="text-xs font-semibold px-2 py-0.5 rounded-full"
            :class="{
              'bg-primary-100 text-primary-700': session.status === 'scheduled',
              'bg-brand-amber/10 text-brand-amber': session.status === 'in_progress',
              'bg-brand-green/10 text-brand-green': session.status === 'completed',
              'bg-gray-100 text-gray-400': session.status === 'cancelled',
            }"
          >
            {{ { scheduled: 'Planirana', in_progress: 'U toku', completed: 'Završena', cancelled: 'Otkazana' }[session.status] ?? session.status }}
          </span>
        </div>
      </div>
      <div v-else class="card text-center py-10 text-gray-400">Nema sesija.</div>
    </div>

    <!-- Create template modal -->
    <Teleport to="body">
      <div v-if="showCreateTemplate" class="fixed inset-0 bg-black/50 flex items-end md:items-center justify-center z-50 p-4">
        <div class="bg-white rounded-2xl w-full max-w-lg shadow-xl max-h-[90vh] overflow-y-auto">
          <div class="p-6 border-b border-gray-100">
            <h2 class="font-display font-bold text-xl text-gray-900">Novi predložak radionice</h2>
          </div>
          <form class="p-6 space-y-4" @submit.prevent="createTemplate">
            <div>
              <label class="label">Naziv radionice *</label>
              <input v-model="tForm.title" type="text" class="input" required placeholder="npr. Igra uloga — emocije" />
            </div>
            <div>
              <label class="label">Opis</label>
              <textarea v-model="tForm.description" class="input" rows="3" />
            </div>
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="label">Trajanje (min)</label>
                <input v-model.number="tForm.duration_minutes" type="number" class="input" min="15" max="180" />
              </div>
              <div>
                <label class="label">Broj u programu</label>
                <input v-model.number="tForm.month_number" type="number" class="input" min="1" max="12" />
              </div>
            </div>
            <div>
              <label class="label">Domene razvoja</label>
              <div class="flex flex-wrap gap-2 mt-1">
                <button
                  v-for="d in domainList"
                  :key="d.key"
                  type="button"
                  class="px-3 py-1 rounded-full text-xs font-semibold border-2 transition-all"
                  :style="tForm.domains.includes(d.key) ? { borderColor: d.color, backgroundColor: d.color + '20', color: d.color } : {}"
                  :class="!tForm.domains.includes(d.key) ? 'border-gray-200 text-gray-500' : ''"
                  @click="toggleDomain(d.key)"
                >
                  {{ d.emoji }} {{ d.label }}
                </button>
              </div>
            </div>
            <div>
              <label class="label">Aktivnost za kod kuće — naslov</label>
              <input v-model="tForm.home_activity_title" type="text" class="input" placeholder="Opciono" />
            </div>
            <div>
              <label class="label">Aktivnost za kod kuće — opis</label>
              <textarea v-model="tForm.home_activity_description" class="input" rows="2" />
            </div>
            <div class="flex gap-3">
              <button type="button" class="btn-secondary flex-1" @click="showCreateTemplate = false">Otkaži</button>
              <button type="submit" class="btn-primary flex-1" :disabled="creating">
                {{ creating ? 'Kreira...' : 'Kreiraj predložak' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Radionice — Admin' })

const supabase = useSupabase()
const router = useRouter()

const activeView = ref<'templates' | 'sessions'>('templates')
const showCreateTemplate = ref(false)
const creating = ref(false)

const tForm = reactive({
  title: '',
  description: '',
  duration_minutes: 60,
  month_number: 1,
  domains: [] as string[],
  home_activity_title: '',
  home_activity_description: '',
})

const domainList = [
  { key: 'emotional', label: 'Emocionalni', emoji: '❤️', color: '#cf2e2e' },
  { key: 'social', label: 'Socijalni', emoji: '🤝', color: '#fcb900' },
  { key: 'creative', label: 'Kreativni', emoji: '🎨', color: '#9b51e0' },
  { key: 'cognitive', label: 'Kognitivni', emoji: '🧠', color: '#0693e3' },
  { key: 'motor', label: 'Motorički', emoji: '🏃', color: '#00d084' },
  { key: 'language', label: 'Jezički', emoji: '💬', color: '#f78da7' },
]

const domainColors: Record<string, string> = Object.fromEntries(domainList.map(d => [d.key, d.color]))
const domainEmojis: Record<string, string> = Object.fromEntries(domainList.map(d => [d.key, d.emoji]))
const domainLabels: Record<string, string> = Object.fromEntries(domainList.map(d => [d.key, d.label]))

function getDomainColor(d?: string): string { return d ? (domainColors[d] ?? '#9b51e0') : '#9b51e0' }
function getDomainEmoji(d?: string): string { return d ? (domainEmojis[d] ?? '🎨') : '🎨' }
function getDomainLabel(d: string): string { return domainLabels[d] ?? d }
function toggleDomain(key: string) {
  const idx = tForm.domains.indexOf(key)
  if (idx >= 0) tForm.domains.splice(idx, 1)
  else tForm.domains.push(key)
}

const { data: workshops, pending: templatesLoading, refresh: refreshTemplates } = await useAsyncData('admin-workshops', async () => {
  const { data } = await supabase
    .from('workshops')
    .select('id, title, description, domains, month_number, duration_minutes')
    .order('month_number', { ascending: true })
  return data ?? []
})

const { data: sessions, pending: sessionsLoading } = await useAsyncData('admin-sessions', async () => {
  const today = new Date().toISOString().slice(0, 10)
  const { data } = await supabase
    .from('sessions')
    .select('id, scheduled_date, scheduled_time_start, status, workshops(title), groups(name)')
    .gte('scheduled_date', today)
    .order('scheduled_date')
    .limit(20)
  return data ?? []
})

async function createTemplate() {
  if (!tForm.title) return
  creating.value = true
  await supabase.from('workshops').insert({
    title: tForm.title,
    description: tForm.description || null,
    duration_minutes: tForm.duration_minutes,
    month_number: tForm.month_number,
    domains: tForm.domains,
    home_activity_title: tForm.home_activity_title || null,
    home_activity_description: tForm.home_activity_description || null,
  })
  showCreateTemplate.value = false
  creating.value = false
  Object.assign(tForm, { title: '', description: '', duration_minutes: 60, month_number: 1, domains: [], home_activity_title: '', home_activity_description: '' })
  await refreshTemplates()
}
</script>
