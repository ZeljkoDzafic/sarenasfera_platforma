<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Opservacije</h1>
        <p class="text-sm text-gray-500 mt-1">Bilježi razvoj djece po domenama</p>
      </div>
      <button class="btn-primary text-sm" @click="showCreate = true">+ Nova opservacija</button>
    </div>

    <!-- Filters -->
    <div class="card">
      <div class="flex flex-wrap gap-3">
        <select v-model="filterChild" class="input w-auto text-sm flex-1 min-w-40">
          <option value="">Sva djeca</option>
          <option v-for="c in children" :key="c.id" :value="c.id">{{ c.full_name }}</option>
        </select>
        <select v-model="filterDomain" class="input w-auto text-sm">
          <option value="">Sve domene</option>
          <option v-for="d in domainList" :key="d.key" :value="d.key">{{ d.emoji }} {{ d.label }}</option>
        </select>
        <select v-model="filterGroup" class="input w-auto text-sm">
          <option value="">Sve grupe</option>
          <option v-for="g in groups" :key="g.id" :value="g.id">{{ g.name }}</option>
        </select>
      </div>
    </div>

    <!-- Observations list -->
    <div v-if="pending" class="space-y-3">
      <div v-for="i in 5" :key="i" class="card h-20 animate-pulse" />
    </div>

    <div v-else-if="observations && observations.length > 0" class="space-y-3">
      <div
        v-for="obs in observations"
        :key="obs.id"
        class="card border-l-4"
        :style="{ borderColor: getDomainColor(obs.domain) }"
      >
        <div class="flex items-start gap-3">
          <div class="w-9 h-9 rounded-xl flex items-center justify-center text-white text-base flex-shrink-0"
            :style="{ backgroundColor: getDomainColor(obs.domain) }">
            {{ getDomainEmoji(obs.domain) }}
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-start justify-between gap-2">
              <p class="text-sm font-semibold text-gray-900">{{ firstChildName(obs.children) }}</p>
              <span class="text-xs text-gray-400 whitespace-nowrap">{{ formatDate(obs.observed_at ?? obs.created_at) }}</span>
            </div>
            <p class="text-sm text-gray-600 mt-1">{{ obs.content }}</p>
            <div class="flex items-center gap-2 mt-1.5">
              <span class="text-xs font-semibold px-2 py-0.5 rounded-full text-white" :style="{ backgroundColor: getDomainColor(obs.domain) }">
                {{ getDomainLabel(obs.domain) }}
              </span>
              <span v-if="firstProfileName(obs.profiles)" class="text-xs text-gray-400">• {{ firstProfileName(obs.profiles) }}</span>
              <span v-if="obs.is_highlight" class="text-xs">⭐ Istaknuto</span>
            </div>
          </div>
          <button class="text-gray-300 hover:text-brand-red transition-colors ml-2" @click="deleteObs(obs.id)">✕</button>
        </div>
      </div>
    </div>

    <div v-else class="card text-center py-14">
      <div class="text-4xl mb-3">👁️</div>
      <h3 class="font-display font-bold text-lg text-gray-900 mb-2">Nema opservacija</h3>
      <p class="text-gray-500 text-sm mb-4">Počnite bilježiti razvoj djece.</p>
      <button class="btn-primary text-sm" @click="showCreate = true">+ Dodaj opservaciju</button>
    </div>

    <!-- Create observation modal -->
    <Teleport to="body">
      <div v-if="showCreate" class="fixed inset-0 bg-black/50 flex items-end md:items-center justify-center z-50 p-4">
        <div class="bg-white rounded-2xl w-full max-w-lg shadow-xl max-h-[90vh] overflow-y-auto">
          <div class="p-6 border-b border-gray-100">
            <h2 class="font-display font-bold text-xl text-gray-900">Nova opservacija</h2>
          </div>
          <form class="p-6 space-y-4" @submit.prevent="createObs">
            <div>
              <label class="label">Dijete *</label>
              <select v-model="form.child_id" class="input" required>
                <option value="">— odaberite dijete —</option>
                <option v-for="c in children" :key="c.id" :value="c.id">{{ c.full_name }}</option>
              </select>
            </div>
            <div>
              <label class="label">Domena razvoja *</label>
              <div class="grid grid-cols-3 gap-2 mt-1">
                <button
                  v-for="d in domainList"
                  :key="d.key"
                  type="button"
                  class="flex flex-col items-center gap-1 py-2 rounded-xl border-2 transition-all text-xs font-semibold"
                  :style="form.domain === d.key ? { borderColor: d.color, backgroundColor: d.color + '15', color: d.color } : {}"
                  :class="form.domain !== d.key ? 'border-gray-200 text-gray-500' : ''"
                  @click="form.domain = d.key"
                >
                  <span class="text-lg">{{ d.emoji }}</span>
                  {{ d.label }}
                </button>
              </div>
            </div>
            <div>
              <label class="label">Bilješka *</label>
              <textarea
                v-model="form.content"
                class="input"
                rows="4"
                required
                placeholder="Opišite što ste primijetili..."
              />
            </div>
            <div>
              <label class="label">Datum opservacije</label>
              <input v-model="form.observed_at" type="date" class="input" />
            </div>
            <div v-if="availableMilestones.length > 0" class="space-y-3">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <label class="label">Miljokazi za brzo označavanje</label>
                  <p class="text-xs text-gray-500">Prikazujemo miljokaze za odabranu domenu i procijenjeni uzrast djeteta.</p>
                </div>
                <span class="rounded-full bg-primary-50 px-2.5 py-1 text-xs font-semibold text-primary-700">
                  {{ availableMilestones.length }}
                </span>
              </div>

              <div class="space-y-2 rounded-2xl bg-gray-50 p-3">
                <div
                  v-for="milestone in availableMilestones"
                  :key="milestone.id"
                  class="rounded-2xl border border-gray-200 bg-white p-3"
                >
                  <div class="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
                    <div class="min-w-0">
                      <p class="text-sm font-semibold text-gray-900">{{ milestone.title }}</p>
                      <p v-if="milestone.description" class="mt-1 text-xs text-gray-500">{{ milestone.description }}</p>
                    </div>
                    <div class="flex flex-wrap gap-2">
                      <button
                        type="button"
                        class="rounded-xl px-3 py-2 text-xs font-semibold transition-all"
                        :class="milestoneSelections[milestone.id] === 'emerging' ? 'bg-brand-amber/15 text-brand-amber ring-2 ring-brand-amber/30' : 'bg-gray-100 text-gray-600 hover:bg-brand-amber/10'"
                        @click="toggleMilestoneSelection(milestone.id, 'emerging')"
                      >
                        U nastajanju
                      </button>
                      <button
                        type="button"
                        class="rounded-xl px-3 py-2 text-xs font-semibold transition-all"
                        :class="milestoneSelections[milestone.id] === 'achieved' ? 'bg-brand-green/15 text-brand-green ring-2 ring-brand-green/30' : 'bg-gray-100 text-gray-600 hover:bg-brand-green/10'"
                        @click="toggleMilestoneSelection(milestone.id, 'achieved')"
                      >
                        Postignuto
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <input type="checkbox" id="highlight" v-model="form.is_highlight" class="rounded" />
              <label for="highlight" class="text-sm font-semibold text-gray-700 cursor-pointer">⭐ Istakni ovu opservaciju</label>
            </div>
            <div class="flex gap-3">
              <button type="button" class="btn-secondary flex-1" @click="showCreate = false">Otkaži</button>
              <button type="submit" class="btn-primary flex-1" :disabled="creating">
                {{ creating ? 'Čuva...' : 'Sačuvaj' }}
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
useSeoMeta({ title: 'Opservacije — Admin' })

const supabase = useSupabase()
const { user } = useAuth()
const showCreate = ref(false)
const creating = ref(false)

const filterChild = ref('')
const filterDomain = ref('')
const filterGroup = ref('')

const form = reactive({
  child_id: '',
  domain: '',
  content: '',
  observed_at: new Date().toISOString().slice(0, 10),
  is_highlight: false,
})
const milestoneSelections = reactive<Record<string, 'emerging' | 'achieved' | undefined>>({})

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
function getDomainColor(d: string): string { return domainColors[d] ?? '#9b51e0' }
function getDomainEmoji(d: string): string { return domainEmojis[d] ?? '🎨' }
function getDomainLabel(d: string): string { return domainLabels[d] ?? d }

const { data: children } = await useAsyncData('admin-obs-children', async () => {
  const { data } = await supabase
    .from('children')
    .select('id, full_name, date_of_birth')
    .eq('is_active', true)
    .order('full_name')
  return data ?? []
})

const { data: groups } = await useAsyncData('admin-obs-groups', async () => {
  const { data } = await supabase.from('groups').select('id, name').eq('is_active', true).order('name')
  return data ?? []
})

const { data: milestoneCatalog } = await useAsyncData('admin-obs-milestones', async () => {
  const { data } = await supabase
    .from('developmental_milestones')
    .select('id, domain, age_range_min, age_range_max, title, description, sort_order')
    .eq('is_active', true)
    .order('sort_order', { ascending: true })

  return data ?? []
})

const { data: observations, pending, refresh } = await useAsyncData('admin-observations', async () => {
  let query = supabase
    .from('observations')
    .select('id, domain, content, observed_at, is_highlight, created_at, children(id, full_name), profiles(full_name)')
    .order('created_at', { ascending: false })
    .limit(50)

  if (filterChild.value) query = query.eq('child_id', filterChild.value)
  if (filterDomain.value) query = query.eq('domain', filterDomain.value)

  const { data } = await query
  return data ?? []
})

watch([filterChild, filterDomain, filterGroup], () => refresh())

const selectedChild = computed(() => {
  return (children.value ?? []).find((child: Record<string, any>) => child.id === form.child_id) ?? null
})

const selectedChildAgeMonths = computed(() => {
  const dob = selectedChild.value?.date_of_birth
  if (!dob) return null

  const birthDate = new Date(dob)
  const today = new Date()
  let months = (today.getFullYear() - birthDate.getFullYear()) * 12
  months += today.getMonth() - birthDate.getMonth()
  if (today.getDate() < birthDate.getDate()) months -= 1
  return Math.max(months, 0)
})

const availableMilestones = computed(() => {
  if (!form.child_id || !form.domain || selectedChildAgeMonths.value === null) return []
  const ageMonths = selectedChildAgeMonths.value
  if (ageMonths === null) return []

  return (milestoneCatalog.value ?? []).filter((milestone: Record<string, any>) => {
    return milestone.domain === form.domain
      && milestone.age_range_min <= ageMonths
      && milestone.age_range_max >= ageMonths
  })
})

watch(() => [form.child_id, form.domain], () => {
  for (const key of Object.keys(milestoneSelections)) {
    delete milestoneSelections[key]
  }
}, { deep: true })

function toggleMilestoneSelection(milestoneId: string, status: 'emerging' | 'achieved') {
  milestoneSelections[milestoneId] = milestoneSelections[milestoneId] === status ? undefined : status
}

async function createObs() {
  if (!form.child_id || !form.domain || !form.content) return
  creating.value = true
  try {
    const { data: observation, error: observationError } = await supabase
      .from('observations')
      .insert({
        child_id: form.child_id,
        domain: form.domain,
        content: form.content,
        observed_at: form.observed_at || null,
        is_highlight: form.is_highlight,
      })
      .select('id')
      .single()

    if (observationError) throw observationError

    const selectedMilestones = Object.entries(milestoneSelections)
      .filter(([, status]) => Boolean(status))
      .map(([milestoneId, status]) => ({
        child_id: form.child_id,
        milestone_id: milestoneId,
        status,
        achieved_at: status === 'achieved' ? (form.observed_at || new Date().toISOString().slice(0, 10)) : null,
        observed_by: user.value?.id ?? null,
        observation_id: observation.id,
        notes: form.content,
      }))

    if (selectedMilestones.length > 0) {
      const { error: milestoneError } = await supabase
        .from('child_milestones')
        .upsert(selectedMilestones, {
          onConflict: 'child_id,milestone_id',
        })

      if (milestoneError) throw milestoneError
    }

    showCreate.value = false
    Object.assign(form, {
      child_id: '',
      domain: '',
      content: '',
      observed_at: new Date().toISOString().slice(0, 10),
      is_highlight: false,
    })
    for (const key of Object.keys(milestoneSelections)) {
      delete milestoneSelections[key]
    }
    await refresh()
  } finally {
    creating.value = false
  }
}

async function deleteObs(id: string) {
  await supabase.from('observations').delete().eq('id', id)
  await refresh()
}

function formatDate(iso?: string): string {
  if (!iso) return '—'
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short', year: 'numeric' })
}

function firstChildName(children: Array<{ id?: string; full_name?: string | null }> | null | undefined): string {
  return children?.[0]?.full_name ?? 'Dijete'
}

function firstProfileName(profiles: Array<{ full_name?: string | null }> | null | undefined): string {
  return profiles?.[0]?.full_name ?? ''
}
</script>
