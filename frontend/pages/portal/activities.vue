<template>
  <div class="space-y-6">
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Kućne aktivnosti</h1>
      <p class="text-sm text-gray-500 mt-1">Aktivnosti zadane od voditelja za rad kod kuće</p>
    </div>

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
useSeoMeta({ title: 'Kućne aktivnosti — Šarena Sfera' })

const supabase = useSupabase()
const { user } = useAuth()

const activeFilter = ref('pending')
const filters = [
  { key: 'all',       label: 'Sve' },
  { key: 'pending',   label: 'Na čekanju' },
  { key: 'completed', label: 'Završene' },
]

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
</script>
