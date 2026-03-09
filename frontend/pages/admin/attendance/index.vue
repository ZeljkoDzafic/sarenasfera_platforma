<template>
  <div class="space-y-6">
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Evidencija prisustva</h1>
      <p class="text-sm text-gray-500 mt-1">Označite prisustvo djece na radionicama</p>
    </div>

    <!-- Session selector -->
    <div class="card">
      <div class="flex flex-wrap gap-3 items-end">
        <div class="flex-1 min-w-48">
          <label class="label">Sesija / radionica</label>
          <select v-model="selectedSession" class="input text-sm">
            <option value="">— odaberite sesiju —</option>
            <option v-for="s in sessions" :key="s.id" :value="s.id">
              {{ formatDate(s.scheduled_date) }} — {{ firstWorkshopTitle(s.workshops) }} ({{ firstGroupName(s.groups) }})
            </option>
          </select>
        </div>
        <button v-if="selectedSession" class="btn-primary text-sm" :disabled="saving" @click="saveAll">
          {{ saving ? 'Čuva...' : '✓ Sačuvaj sve' }}
        </button>
      </div>
    </div>

    <div v-if="selectedSession">
      <!-- Quick stats -->
      <div class="grid grid-cols-4 gap-3 mb-4">
        <div class="card text-center py-3">
          <div class="text-xl font-bold text-brand-green">{{ countStatus('present') }}</div>
          <div class="text-xs text-gray-400">Prisutni</div>
        </div>
        <div class="card text-center py-3">
          <div class="text-xl font-bold text-brand-red">{{ countStatus('absent') }}</div>
          <div class="text-xs text-gray-400">Odsutni</div>
        </div>
        <div class="card text-center py-3">
          <div class="text-xl font-bold text-brand-amber">{{ countStatus('late') }}</div>
          <div class="text-xs text-gray-400">Zakasnili</div>
        </div>
        <div class="card text-center py-3">
          <div class="text-xl font-bold text-gray-400">{{ countStatus('excused') }}</div>
          <div class="text-xs text-gray-400">Opravdano</div>
        </div>
      </div>

      <!-- Bulk actions -->
      <div class="flex gap-2 mb-4">
        <button class="text-xs btn-secondary py-1.5 px-3" @click="markAll('present')">✓ Svi prisutni</button>
        <button class="text-xs btn-secondary py-1.5 px-3" @click="markAll('absent')">✗ Svi odsutni</button>
      </div>

      <!-- Children attendance list -->
      <div v-if="attendanceLoading" class="space-y-2">
        <div v-for="i in 8" :key="i" class="card h-14 animate-pulse" />
      </div>

      <div v-else-if="attendanceList.length > 0" class="card overflow-hidden p-0">
        <div
          v-for="child in attendanceList"
          :key="child.child_id"
          class="flex items-center gap-3 px-4 py-3 border-b border-gray-50 last:border-0"
        >
          <div class="w-8 h-8 rounded-xl bg-primary-100 flex items-center justify-center font-bold text-primary-600 text-xs flex-shrink-0">
            {{ child.name[0] }}
          </div>
          <span class="text-sm font-semibold text-gray-900 flex-1">{{ child.name }}</span>

          <div class="flex gap-1">
            <button
              v-for="s in statusOptions"
              :key="s.value"
              class="px-2.5 py-1 rounded-lg text-xs font-semibold border-2 transition-all"
              :class="child.status === s.value ? s.activeClass : 'border-gray-200 text-gray-400'"
              @click="child.status = s.value"
            >
              {{ s.label }}
            </button>
          </div>

          <input
            v-model="child.note"
            type="text"
            placeholder="Bilješka"
            class="input text-xs w-28 hidden md:block"
          />
        </div>
      </div>

      <div v-else class="card text-center py-10 text-gray-400 text-sm">
        Nema djece raspoređenih na ovu sesiju.
      </div>
    </div>

    <div v-else class="card text-center py-14">
      <div class="text-4xl mb-3">📋</div>
      <p class="text-gray-500 text-sm">Odaberite sesiju da biste evidentirali prisustvo.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Prisustvo — Admin' })

const supabase = useSupabase()
const selectedSession = ref('')
const saving = ref(false)
const attendanceLoading = ref(false)

interface AttendanceRow {
  child_id: string
  name: string
  status: string
  note: string
  attendance_id?: string
}

interface SessionRecord {
  id: string
  scheduled_date: string
  workshops?: Array<{ title: string | null }> | null
  groups?: Array<{ id: string; name: string | null }> | null
}

const attendanceList = ref<AttendanceRow[]>([])

const statusOptions = [
  { value: 'present', label: '✓', activeClass: 'border-brand-green bg-brand-green/10 text-brand-green' },
  { value: 'absent', label: '✗', activeClass: 'border-brand-red bg-brand-red/10 text-brand-red' },
  { value: 'late', label: '⏰', activeClass: 'border-brand-amber bg-brand-amber/10 text-brand-amber' },
  { value: 'excused', label: '📋', activeClass: 'border-gray-400 bg-gray-100 text-gray-500' },
]

// Upcoming + recent sessions
const { data: sessions } = await useAsyncData<SessionRecord[]>('admin-sessions-att', async () => {
  const twoWeeksAgo = new Date(Date.now() - 14 * 86400000).toISOString().slice(0, 10)
  const twoWeeksAhead = new Date(Date.now() + 14 * 86400000).toISOString().slice(0, 10)
  const { data } = await supabase
    .from('sessions')
    .select('id, scheduled_date, workshops(title), groups(id, name)')
    .gte('scheduled_date', twoWeeksAgo)
    .lte('scheduled_date', twoWeeksAhead)
    .order('scheduled_date', { ascending: false })
  return data ?? []
})

watch(selectedSession, async (sessionId) => {
  if (!sessionId) return
  attendanceLoading.value = true

  // Find group for this session
  const session = sessions.value?.find((s) => s.id === sessionId)
  const groupId = session?.groups?.[0]?.id

  if (!groupId) { attendanceLoading.value = false; return }

  // Get children in group
  const { data: groupChildren } = await supabase
    .from('child_groups')
    .select('child_id, children(full_name)')
    .eq('group_id', groupId)

  // Get existing attendance records
  const { data: existing } = await supabase
    .from('attendance')
    .select('id, child_id, status, notes')
    .eq('session_id', sessionId)

  const existingMap = new Map((existing ?? []).map((a: { child_id: string; id: string; status: string; notes?: string }) => [a.child_id, a]))

  attendanceList.value = (groupChildren ?? []).map((gc: { child_id: string; children: Array<{ full_name: string | null }> | null }) => {
    const att = existingMap.get(gc.child_id)
    return {
      child_id: gc.child_id,
      name: gc.children?.[0]?.full_name ?? '—',
      status: att?.status ?? 'present',
      note: att?.notes ?? '',
      attendance_id: att?.id,
    }
  })

  attendanceLoading.value = false
})

function countStatus(status: string): number {
  return attendanceList.value.filter(a => a.status === status).length
}

function markAll(status: string) {
  attendanceList.value.forEach(a => { a.status = status })
}

async function saveAll() {
  saving.value = true
  for (const row of attendanceList.value) {
    if (row.attendance_id) {
      await supabase.from('attendance').update({ status: row.status, notes: row.note || null }).eq('id', row.attendance_id)
    } else {
      const { data: newAtt } = await supabase.from('attendance').insert({
        session_id: selectedSession.value,
        child_id: row.child_id,
        status: row.status,
        notes: row.note || null,
      }).select('id').single()
      if (newAtt) row.attendance_id = newAtt.id
    }
  }
  saving.value = false
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { weekday: 'short', day: 'numeric', month: 'short' })
}

function firstWorkshopTitle(workshops?: Array<{ title: string | null }> | null): string {
  return workshops?.[0]?.title ?? 'Radionica'
}

function firstGroupName(groups?: Array<{ name: string | null }> | null): string {
  return groups?.[0]?.name ?? '—'
}
</script>
