<template>
  <div class="space-y-6">
    <div class="flex items-center gap-3">
      <NuxtLink to="/admin/children" class="text-gray-400 hover:text-gray-600">←</NuxtLink>
      <div class="flex-1">
        <h1 class="font-display text-2xl font-bold text-gray-900">{{ child?.full_name ?? '...' }}</h1>
        <p class="text-sm text-gray-500 mt-0.5">Dječiji profil</p>
      </div>
      <button class="btn-secondary text-sm" @click="editing = !editing">
        {{ editing ? 'Otkaži' : 'Uredi' }}
      </button>
    </div>

    <div v-if="pending" class="card animate-pulse h-32" />

    <div v-else-if="child">
      <!-- Edit form -->
      <div v-if="editing" class="card space-y-4">
        <h2 class="font-display font-bold text-lg text-gray-900">Uredi podatke</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="label">Ime i prezime</label>
            <input v-model="editForm.full_name" type="text" class="input" />
          </div>
          <div>
            <label class="label">Datum rođenja</label>
            <input v-model="editForm.date_of_birth" type="date" class="input" />
          </div>
        </div>
        <div>
          <label class="label">Alergije</label>
          <textarea v-model="editForm.allergies" class="input" rows="2" />
        </div>
        <div>
          <label class="label">Medicinske napomene</label>
          <textarea v-model="editForm.medical_notes" class="input" rows="2" />
        </div>
        <div class="flex items-center gap-3">
          <label class="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" v-model="editForm.is_active" class="rounded" />
            <span class="text-sm font-semibold text-gray-700">Aktivan profil</span>
          </label>
        </div>
        <button class="btn-primary text-sm" :disabled="saving" @click="saveEdits">
          {{ saving ? 'Čuva...' : 'Sačuvaj promjene' }}
        </button>
      </div>

      <!-- Info cards -->
      <div v-else class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div class="card text-center">
          <div class="text-3xl mb-2">🎂</div>
          <div class="font-bold text-gray-900">{{ getAge(child.date_of_birth) }} god.</div>
          <div class="text-xs text-gray-400">{{ formatDate(child.date_of_birth) }}</div>
        </div>
        <div class="card text-center">
          <div class="text-3xl mb-2">👥</div>
          <div class="font-bold text-gray-900">{{ firstGroupName(child.child_groups) }}</div>
          <div class="text-xs text-gray-400">Grupa</div>
        </div>
        <div class="card text-center">
          <div class="text-3xl mb-2">👨‍👩‍👧</div>
          <div class="font-bold text-gray-900 text-sm truncate">{{ firstParentName(child.parent_children) }}</div>
          <div class="text-xs text-gray-400">Roditelj</div>
        </div>
        <div class="card text-center">
          <div class="text-3xl mb-2">{{ child.is_active ? '✅' : '⛔' }}</div>
          <div class="font-bold" :class="child.is_active ? 'text-brand-green' : 'text-gray-400'">
            {{ child.is_active ? 'Aktivan' : 'Neaktivan' }}
          </div>
          <div class="text-xs text-gray-400">Status</div>
        </div>
      </div>

      <!-- Allergies -->
      <div v-if="child.allergies" class="card border-l-4 border-brand-amber">
        <p class="text-sm font-semibold text-brand-amber mb-1">⚠️ Alergije / napomene</p>
        <p class="text-sm text-gray-700">{{ child.allergies }}</p>
      </div>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-100">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          class="px-4 py-2.5 text-sm font-semibold transition-colors border-b-2 -mb-px"
          :class="activeTab === tab.key ? 'border-primary-500 text-primary-700' : 'border-transparent text-gray-500 hover:text-gray-700'"
          @click="activeTab = tab.key"
        >
          {{ tab.label }}
        </button>
      </div>

      <!-- Observations tab -->
      <div v-if="activeTab === 'observations'" class="space-y-3">
        <div v-if="observations.length === 0" class="card text-center py-10 text-gray-400">
          Nema opservacija za ovo dijete.
        </div>
        <div v-for="obs in observations" :key="obs.id" class="card-domain" :style="{ borderColor: domainColors[obs.domain] }">
          <div class="flex items-start gap-3">
            <div class="w-8 h-8 rounded-xl flex items-center justify-center text-white text-sm font-bold" :style="{ backgroundColor: domainColors[obs.domain] }">
              {{ domainEmojis[obs.domain] }}
            </div>
            <div class="flex-1">
              <p class="text-sm text-gray-700">{{ obs.content }}</p>
              <p class="text-xs text-gray-400 mt-1">{{ formatDate(obs.observed_at ?? obs.created_at) }} • {{ firstProfileName(obs.profiles) }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Assessments tab -->
      <div v-if="activeTab === 'assessments'" class="card">
        <h3 class="font-semibold text-gray-900 mb-4">Posljednje procjene po domenama</h3>
        <div class="space-y-3">
          <div v-for="domain in domainList" :key="domain.key" class="flex items-center gap-3">
            <span class="text-lg w-6">{{ domain.emoji }}</span>
            <span class="text-sm text-gray-600 w-28">{{ domain.label }}</span>
            <div class="flex-1 h-2 bg-gray-100 rounded-full overflow-hidden">
              <div
                class="h-full rounded-full transition-all"
                :style="{ width: `${(getScore(domain.key) / 5) * 100}%`, backgroundColor: domain.color }"
              />
            </div>
            <span class="text-sm font-bold w-8 text-right" :style="{ color: domain.color }">
              {{ getScore(domain.key) > 0 ? getScore(domain.key).toFixed(1) : '—' }}
            </span>
          </div>
        </div>
      </div>

      <!-- Attendance tab -->
      <div v-if="activeTab === 'attendance'" class="card">
        <p class="text-sm text-gray-500">Prisustvo na radionicama</p>
        <div class="mt-4 space-y-2">
          <div v-for="att in attendance" :key="att.id" class="flex items-center justify-between py-2 border-b border-gray-50">
            <div>
              <p class="text-sm font-semibold text-gray-900">{{ firstSessionWorkshopTitle(att.sessions) }}</p>
              <p class="text-xs text-gray-400">{{ formatDate(firstSessionDate(att.sessions)) }}</p>
            </div>
            <span class="text-xs font-semibold px-2 py-0.5 rounded-full"
              :class="{
                'bg-brand-green/10 text-brand-green': att.status === 'present',
                'bg-brand-red/10 text-brand-red': att.status === 'absent',
                'bg-brand-amber/10 text-brand-amber': att.status === 'late',
                'bg-gray-100 text-gray-400': att.status === 'excused',
              }"
            >
              {{ attendanceStatusLabel(att.status) }}
            </span>
          </div>
          <p v-if="attendance.length === 0" class="text-center text-gray-400 text-sm py-6">Nema evidencije prisustva.</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })

const supabase = useSupabase()
const route = useRoute()
const childId = route.params.id as string

const editing = ref(false)
const saving = ref(false)
type AdminChildTab = 'observations' | 'assessments' | 'attendance'

const activeTab = ref<AdminChildTab>('observations')

const tabs: Array<{ key: AdminChildTab; label: string }> = [
  { key: 'observations', label: 'Opservacije' },
  { key: 'assessments', label: 'Procjene' },
  { key: 'attendance', label: 'Prisustvo' },
]

const domainColors: Record<string, string> = {
  emotional: '#cf2e2e', social: '#fcb900', creative: '#9b51e0',
  cognitive: '#0693e3', motor: '#00d084', language: '#f78da7',
}
const domainEmojis: Record<string, string> = {
  emotional: '❤️', social: '🤝', creative: '🎨',
  cognitive: '🧠', motor: '🏃', language: '💬',
}
const domainList = [
  { key: 'emotional', label: 'Emocionalni', emoji: '❤️', color: '#cf2e2e' },
  { key: 'social', label: 'Socijalni', emoji: '🤝', color: '#fcb900' },
  { key: 'creative', label: 'Kreativni', emoji: '🎨', color: '#9b51e0' },
  { key: 'cognitive', label: 'Kognitivni', emoji: '🧠', color: '#0693e3' },
  { key: 'motor', label: 'Motorički', emoji: '🏃', color: '#00d084' },
  { key: 'language', label: 'Jezički', emoji: '💬', color: '#f78da7' },
]

const { data: child, pending, refresh } = await useAsyncData(`admin-child-${childId}`, async () => {
  const { data } = await supabase
    .from('children')
    .select(`
      id, full_name, date_of_birth, gender, is_active, allergies, medical_notes,
      child_groups(groups(name)),
      parent_children(profiles(full_name, email))
    `)
    .eq('id', childId)
    .single()
  return data
})

useSeoMeta({ title: computed(() => `${child.value?.full_name ?? 'Dijete'} — Admin`) })

const editForm = reactive({
  full_name: '',
  date_of_birth: '',
  allergies: '',
  medical_notes: '',
  is_active: true,
})

watch(child, (c) => {
  if (c) {
    editForm.full_name = c.full_name
    editForm.date_of_birth = c.date_of_birth ?? ''
    editForm.allergies = c.allergies ?? ''
    editForm.medical_notes = c.medical_notes ?? ''
    editForm.is_active = c.is_active
  }
}, { immediate: true })

const { data: observationsData } = await useAsyncData(`admin-child-obs-${childId}`, async () => {
  const { data } = await supabase
    .from('observations')
    .select('id, domain, content, observed_at, created_at, profiles(full_name)')
    .eq('child_id', childId)
    .order('created_at', { ascending: false })
    .limit(20)
  return data ?? []
})

const { data: assessmentsData } = await useAsyncData(`admin-child-assess-${childId}`, async () => {
  const { data } = await supabase
    .from('assessments')
    .select('*')
    .eq('child_id', childId)
    .order('assessed_at', { ascending: false })
    .limit(6)
  return data ?? []
})

const { data: attendanceData } = await useAsyncData(`admin-child-att-${childId}`, async () => {
  const { data } = await supabase
    .from('attendance')
    .select('id, status, sessions(scheduled_date, workshops(title))')
    .eq('child_id', childId)
    .order('created_at', { ascending: false })
    .limit(20)
  return data ?? []
})

const observations = computed(() => observationsData.value ?? [])
const assessments = computed(() => assessmentsData.value ?? [])
const attendance = computed(() => attendanceData.value ?? [])

function getScore(domain: string): number {
  const latest = assessments.value.find((a: Record<string, unknown>) => a.domain === domain)
  return latest ? Number(latest.score) : 0
}

function firstGroupName(relations: Array<{ groups?: Array<{ name: string | null }> | null }> | null | undefined): string {
  return relations?.[0]?.groups?.[0]?.name ?? '—'
}

function firstParentName(relations: Array<{ profiles?: Array<{ full_name: string | null; email: string | null }> | null }> | null | undefined): string {
  return relations?.[0]?.profiles?.[0]?.full_name ?? '—'
}

function firstProfileName(relations: Array<{ full_name: string | null }> | null | undefined): string {
  return relations?.[0]?.full_name ?? '—'
}

function firstSessionWorkshopTitle(relations: Array<{ scheduled_date: string | null; workshops?: Array<{ title: string | null }> | null }> | null | undefined): string {
  return relations?.[0]?.workshops?.[0]?.title ?? 'Radionica'
}

function firstSessionDate(relations: Array<{ scheduled_date: string | null; workshops?: Array<{ title: string | null }> | null }> | null | undefined): string {
  return relations?.[0]?.scheduled_date ?? new Date().toISOString()
}

function attendanceStatusLabel(status: string | null): string {
  const labels: Record<string, string> = {
    present: 'Prisutan',
    absent: 'Odsutan',
    late: 'Zakasnio',
    excused: 'Opravdano',
  }
  return status ? (labels[status] ?? status) : '—'
}

async function saveEdits() {
  saving.value = true
  await supabase.from('children').update({
    full_name: editForm.full_name,
    date_of_birth: editForm.date_of_birth || null,
    allergies: editForm.allergies || null,
    medical_notes: editForm.medical_notes || null,
    is_active: editForm.is_active,
  }).eq('id', childId)
  editing.value = false
  saving.value = false
  await refresh()
}

function formatDate(iso?: string): string {
  if (!iso) return '—'
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'long', year: 'numeric' })
}

function getAge(dob?: string): number {
  if (!dob) return 0
  const birth = new Date(dob)
  const today = new Date()
  let age = today.getFullYear() - birth.getFullYear()
  if (today.getMonth() < birth.getMonth() || (today.getMonth() === birth.getMonth() && today.getDate() < birth.getDate())) age--
  return age
}
</script>
