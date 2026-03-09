<template>
  <div class="space-y-6">
    <!-- Header with tabs -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Aktivnosti</h1>
        <p class="text-sm text-gray-500 mt-1">Zadane aktivnosti i biblioteka aktivnosti</p>
      </div>
      <div class="flex gap-1 bg-gray-100 rounded-xl p-1">
        <button
          class="px-4 py-2 rounded-lg text-sm font-semibold transition-all"
          :class="activeTab === 'assigned' ? 'bg-white shadow-sm text-gray-900' : 'text-gray-500 hover:text-gray-700'"
          @click="activeTab = 'assigned'"
        >
          Moje Aktivnosti
        </button>
        <button
          class="px-4 py-2 rounded-lg text-sm font-semibold transition-all"
          :class="activeTab === 'library' ? 'bg-white shadow-sm text-gray-900' : 'text-gray-500 hover:text-gray-700'"
          @click="activeTab = 'library'"
        >
          Biblioteka
        </button>
      </div>
    </div>

    <!-- Assigned activities tab -->
    <div v-if="activeTab === 'assigned'" class="space-y-6">
      <!-- Filter bar -->
      <div class="flex flex-wrap gap-2">
        <button
          v-for="filter in filters"
          :key="filter.key"
          class="px-4 py-1.5 rounded-full text-sm font-semibold transition-all border-2"
          :class="activeFilter === filter.key
            ? 'border-primary-500 bg-primary-50 text-primary-700'
            : 'border-gray-200 text-gray-600 hover:border-gray-300'"
          @click="activeFilter = filter.key"
        >
          {{ filter.label }}
        </button>
      </div>

    <!-- Loading -->
    <div v-if="pending" class="space-y-3">
      <div v-for="i in 4" :key="i" class="card animate-pulse h-28" />
    </div>

    <!-- Activities list -->
    <div v-else-if="filteredActivities.length > 0" class="space-y-3">
      <div
        v-for="activity in filteredActivities"
        :key="activity.id"
        class="card"
      >
        <div class="flex items-start gap-4">
          <!-- Domain color indicator -->
          <div
            class="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 text-white font-bold text-lg"
            :style="{ backgroundColor: getDomainColor(activity.workshops?.domains?.[0]) }"
          >
            {{ getDomainEmoji(activity.workshops?.domains?.[0]) }}
          </div>

          <div class="flex-1 min-w-0">
            <div class="flex items-start justify-between gap-2">
              <div>
                <h3 class="font-semibold text-gray-900">{{ activity.workshops?.home_activity_title ?? 'Aktivnost' }}</h3>
                <p class="text-xs text-gray-500 mt-0.5">
                  {{ activity.children?.full_name }} •
                  Zadano: {{ formatDate(activity.assigned_at) }}
                </p>
              </div>
              <span
                class="text-xs font-semibold px-2 py-0.5 rounded-full flex-shrink-0"
                :class="activity.completed ? 'bg-brand-green/10 text-brand-green' : 'bg-brand-amber/10 text-brand-amber'"
              >
                {{ activity.completed ? '✓ Završeno' : 'Na čekanju' }}
              </span>
            </div>

            <p v-if="activity.workshops?.home_activity_description" class="text-sm text-gray-600 mt-2 line-clamp-2">
              {{ activity.workshops.home_activity_description }}
            </p>

            <div class="flex items-center gap-3 mt-3">
              <button
                v-if="!activity.completed"
                class="btn-success text-xs"
                @click="markComplete(activity.id)"
              >
                Označi kao završeno
              </button>
              <button
                v-if="!activity.completed"
                class="btn-secondary text-xs"
                @click="openFeedback(activity)"
              >
                Dodaj komentar
              </button>
              <a
                v-if="activity.workshops?.home_activity_pdf_url"
                :href="activity.workshops.home_activity_pdf_url"
                target="_blank"
                class="text-xs text-primary-600 hover:underline font-semibold"
              >
                📄 Preuzmi upute
              </a>
            </div>
          </div>
        </div>

        <!-- Feedback (if exists) -->
        <div v-if="activity.parent_comment" class="mt-3 pt-3 border-t border-gray-100">
          <p class="text-xs text-gray-500 font-semibold mb-1">Vaš komentar:</p>
          <p class="text-sm text-gray-700 italic">"{{ activity.parent_comment }}"</p>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-else class="card text-center py-14">
      <div class="text-5xl mb-4">🏠</div>
      <h3 class="font-display font-bold text-xl text-gray-900 mb-2">
        {{ activeFilter === 'completed' ? 'Nema završenih aktivnosti' : 'Nema aktivnosti za obaviti' }}
      </h3>
      <p class="text-gray-600 text-sm">Voditelji će vam zadati aktivnosti nakon radionice.</p>
    </div>
    </div>

    <!-- Library tab -->
    <div v-else-if="activeTab === 'library'" class="space-y-6">
      <!-- Search and filters -->
      <div class="card p-4">
        <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <!-- Search -->
          <div class="relative flex-1 max-w-md">
            <svg class="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input
              v-model="librarySearch"
              type="text"
              class="input pl-10"
              placeholder="Pretraži aktivnosti..."
            />
          </div>
          
          <!-- Filter buttons -->
          <div class="flex flex-wrap gap-2">
            <select v-model="libraryFilters.domain" class="input text-sm">
              <option value="">Sve domene</option>
              <option value="emotional">Emocionalni</option>
              <option value="social">Socijalni</option>
              <option value="creative">Kreativni</option>
              <option value="cognitive">Kognitivni</option>
              <option value="motor">Motorički</option>
              <option value="language">Jezički</option>
            </select>
            
            <select v-model="libraryFilters.type" class="input text-sm">
              <option value="">Svi tipovi</option>
              <option value="indoor">Unutra</option>
              <option value="outdoor">Vani</option>
              <option value="creative">Kreativno</option>
              <option value="physical">Fizički</option>
              <option value="sensory">Senzorno</option>
            </select>
            
            <select v-model="libraryFilters.duration" class="input text-sm">
              <option value="">Sva trajanja</option>
              <option value="short">&lt; 15 min</option>
              <option value="medium">15-30 min</option>
              <option value="long">&gt; 30 min</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Activity library grid -->
      <div v-if="filteredLibraryActivities.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div
          v-for="activity in filteredLibraryActivities"
          :key="activity.id"
          class="card hover:shadow-lg transition-all group cursor-pointer"
          @click="openActivityDetail(activity)"
        >
          <!-- Domain color header -->
          <div
            class="h-24 rounded-t-xl flex items-center justify-center text-4xl"
            :style="{ backgroundColor: getDomainColor(activity.domain) + '20' }"
          >
            {{ getDomainEmoji(activity.domain) }}
          </div>
          
          <div class="p-4">
            <div class="flex items-start justify-between gap-2 mb-2">
              <h3 class="font-bold text-gray-900 line-clamp-2">{{ activity.title }}</h3>
              <span
                class="text-xs font-semibold px-2 py-1 rounded-full bg-gray-100 text-gray-600 flex-shrink-0"
              >
                {{ activity.difficulty || 'Srednje' }}
              </span>
            </div>
            
            <p class="text-sm text-gray-600 line-clamp-2 mb-3">{{ activity.description }}</p>
            
            <!-- Meta info -->
            <div class="flex items-center gap-3 text-xs text-gray-500">
              <span class="flex items-center gap-1">
                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {{ activity.duration || '15-30 min' }}
              </span>
              <span class="flex items-center gap-1">
                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857m0 0a5.002 5.002 0 019.288 0M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0z" />
                </svg>
                {{ activity.age_range || '3-6 god' }}
              </span>
            </div>
            
            <!-- View button -->
            <button class="btn-primary w-full mt-3 text-sm group-hover:shadow-colorful">
              Pogledaj aktivnost
            </button>
          </div>
        </div>
      </div>

      <!-- Empty state -->
      <div v-else class="card text-center py-14">
        <div class="text-5xl mb-4">🔍</div>
        <h3 class="font-display font-bold text-xl text-gray-900 mb-2">Nema pronađenih aktivnosti</h3>
        <p class="text-gray-600 text-sm">Pokušajte promijeniti filtere ili pretragu.</p>
      </div>
    </div>

    <!-- Feedback Modal -->
    <Teleport to="body">
      <div v-if="feedbackActivity" class="fixed inset-0 bg-black/50 flex items-end md:items-center justify-center z-50 p-4">
        <div class="bg-white rounded-2xl w-full max-w-md shadow-xl">
          <div class="p-6 border-b border-gray-100">
            <h2 class="font-display font-bold text-lg text-gray-900">Vaše iskustvo</h2>
          </div>
          <div class="p-6 space-y-4">
            <div>
              <label class="label text-sm">Kako je dijete prihvatilo aktivnost?</label>
              <div class="flex gap-2 mt-2">
                <button
                  v-for="n in 5"
                  :key="n"
                  class="flex-1 py-2 rounded-xl border-2 text-lg transition-all"
                  :class="feedbackRating === n ? 'border-brand-amber bg-brand-amber/10' : 'border-gray-200'"
                  @click="feedbackRating = n"
                >
                  {{ ['😴', '😐', '🙂', '😊', '🤩'][n-1] }}
                </button>
              </div>
            </div>
            <div>
              <label class="label text-sm">Komentar (opciono)</label>
              <textarea v-model="feedbackComment" class="input text-sm" rows="3" placeholder="Kako je prošlo? Ima li poteškoća?" />
            </div>
            <div class="flex gap-3">
              <button class="btn-secondary flex-1" @click="feedbackActivity = null">Otkaži</button>
              <button class="btn-primary flex-1" @click="submitFeedback">Sačuvaj</button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })
useSeoMeta({ title: 'Aktivnosti — Šarena Sfera' })

const supabase = useSupabase()
const { user } = useAuth()

const activeTab = ref('assigned')

const activeFilter = ref('pending')
const filters = [
  { key: 'all',       label: 'Sve' },
  { key: 'pending',   label: 'Na čekanju' },
  { key: 'completed', label: 'Završene' },
]

// Library state
const librarySearch = ref('')
const libraryFilters = ref({
  domain: '',
  type: '',
  duration: '',
})

const { data: activities, pending, refresh } = await useAsyncData('portal-activities', async () => {
  if (!user.value) return []
  const { data } = await supabase
    .from('home_activities')
    .select(`
      id, assigned_at, completed, completed_at, parent_comment, enjoyment_rating,
      workshops(home_activity_title, home_activity_description, home_activity_pdf_url, domains),
      children(full_name)
    `)
    .eq('parent_id', user.value.id)
    .order('assigned_at', { ascending: false })
  return data ?? []
})

// Library activities (sample data for now)
const libraryActivities = ref([
  {
    id: '1',
    title: 'Igranje uloga: Prodavnica',
    description: 'Dijete glumi prodavača, uči brojanje i socijalne vještine kroz igru.',
    domain: 'social',
    type: 'indoor',
    duration: 'medium',
    age_range: '4-6 god',
    difficulty: 'Lahko',
  },
  {
    id: '2',
    title: 'Crtanje uz muziku',
    description: 'Razvoj kreativnosti i motorike kroz crtanje uz različite muzičke žanrove.',
    domain: 'creative',
    type: 'creative',
    duration: 'medium',
    age_range: '3-6 god',
    difficulty: 'Lahko',
  },
  {
    id: '3',
    title: 'Poligon s preprekama',
    description: 'Kreirajte poligon s jastucima i stolicama za razvoj motorike.',
    domain: 'motor',
    type: 'physical',
    duration: 'long',
    age_range: '3-6 god',
    difficulty: 'Srednje',
  },
  {
    id: '4',
    title: 'Prepoznavanje emocija',
    description: 'Igra s karticama emocija za prepoznavanje i imenovanje osjećaja.',
    domain: 'emotional',
    type: 'indoor',
    duration: 'short',
    age_range: '3-5 god',
    difficulty: 'Lahko',
  },
  {
    id: '5',
    title: 'Slaganje po bojama',
    description: 'Sortiranje predmeta po bojama za razvoj kognitivnih vještina.',
    domain: 'cognitive',
    type: 'indoor',
    duration: 'short',
    age_range: '2-4 god',
    difficulty: 'Lahko',
  },
  {
    id: '6',
    title: 'Priča bez riječi',
    description: 'Izražavanje kroz geste i mimiku za razvoj jezičkih vještina.',
    domain: 'language',
    type: 'creative',
    duration: 'medium',
    age_range: '4-6 god',
    difficulty: 'Srednje',
  },
])

const filteredLibraryActivities = computed(() => {
  let filtered = libraryActivities.value
  
  // Search filter
  if (librarySearch.value) {
    const search = librarySearch.value.toLowerCase()
    filtered = filtered.filter(a =>
      a.title.toLowerCase().includes(search) ||
      a.description.toLowerCase().includes(search)
    )
  }
  
  // Domain filter
  if (libraryFilters.value.domain) {
    filtered = filtered.filter(a => a.domain === libraryFilters.value.domain)
  }
  
  // Type filter
  if (libraryFilters.value.type) {
    filtered = filtered.filter(a => a.type === libraryFilters.value.type)
  }
  
  // Duration filter
  if (libraryFilters.value.duration) {
    filtered = filtered.filter(a => a.duration === libraryFilters.value.duration)
  }
  
  return filtered
})

const filteredActivities = computed(() => {
  if (!activities.value) return []
  if (activeFilter.value === 'pending') return activities.value.filter((a: { completed: boolean }) => !a.completed)
  if (activeFilter.value === 'completed') return activities.value.filter((a: { completed: boolean }) => a.completed)
  return activities.value
})

const domainColors: Record<string, string> = {
  emotional: '#cf2e2e', social: '#fcb900', creative: '#9b51e0',
  cognitive: '#0693e3', motor: '#00d084', language: '#f78da7',
}
const domainEmojis: Record<string, string> = {
  emotional: '❤️', social: '🤝', creative: '🎨',
  cognitive: '🧠', motor: '🏃', language: '💬',
}
function getDomainColor(d?: string): string { return d ? (domainColors[d] ?? '#9b51e0') : '#9b51e0' }
function getDomainEmoji(d?: string): string { return d ? (domainEmojis[d] ?? '🎨') : '🎨' }

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'long' })
}

async function markComplete(id: string) {
  await supabase.from('home_activities').update({ completed: true, completed_at: new Date().toISOString() }).eq('id', id)
  await refresh()
}

// Feedback modal state
const feedbackActivity = ref<{ id: string } | null>(null)
const feedbackRating = ref(0)
const feedbackComment = ref('')

function openFeedback(activity: { id: string }) {
  feedbackActivity.value = activity
  feedbackRating.value = 0
  feedbackComment.value = ''
}

async function submitFeedback() {
  if (!feedbackActivity.value) return
  await supabase.from('home_activities').update({
    enjoyment_rating: feedbackRating.value || null,
    parent_comment: feedbackComment.value || null,
    completed: true,
    completed_at: new Date().toISOString(),
  }).eq('id', feedbackActivity.value.id)
  feedbackActivity.value = null
  await refresh()
}

function openActivityDetail(activity: any) {
  // TODO: Open activity detail modal or navigate to detail page
  console.log('Opening activity:', activity)
}
</script>
