<template>
  <div class="space-y-6">
    <div class="flex items-center gap-3">
      <NuxtLink to="/admin/groups" class="text-gray-400 hover:text-gray-600">←</NuxtLink>
      <div class="flex-1">
        <h1 class="font-display text-2xl font-bold text-gray-900">{{ group?.name ?? '...' }}</h1>
        <p class="text-sm text-gray-500 mt-0.5">
          {{ formatAgeRange(group?.age_range_min, group?.age_range_max) }}
          • {{ rosterItems.length }}/{{ group?.max_capacity }} djece
        </p>
      </div>
    </div>

    <div v-if="pending" class="card h-40 animate-pulse" />

    <div v-else-if="group" class="space-y-6">
      <!-- Stats row -->
      <div class="grid grid-cols-3 gap-4">
        <div class="card text-center">
          <div class="text-2xl font-bold text-primary-600">{{ rosterItems.length }}</div>
          <div class="text-xs text-gray-400">Djece</div>
        </div>
        <div class="card text-center">
          <div class="text-2xl font-bold text-primary-600">{{ staffItems.length }}</div>
          <div class="text-xs text-gray-400">Voditelja</div>
        </div>
        <div class="card text-center">
          <div class="text-2xl font-bold text-primary-600">{{ upcomingSessionItems.length }}</div>
          <div class="text-xs text-gray-400">Nadolazećih</div>
        </div>
      </div>

      <!-- Children roster -->
      <div class="card">
        <div class="flex items-center justify-between mb-4">
          <h2 class="font-display font-bold text-lg text-gray-900">Djeca u grupi</h2>
          <button class="btn-secondary text-xs" @click="showAddChild = true">+ Dodaj dijete</button>
        </div>

        <div v-if="rosterItems.length > 0" class="space-y-2">
          <div
            v-for="child in rosterItems"
            :key="child.id"
            class="flex items-center justify-between py-2 border-b border-gray-50 last:border-0"
          >
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-xl bg-primary-100 flex items-center justify-center font-bold text-primary-600 text-xs">
                {{ firstRosterChildName(child.children)[0] }}
              </div>
              <div>
                <p class="text-sm font-semibold text-gray-900">{{ firstRosterChildName(child.children) }}</p>
                <p class="text-xs text-gray-400">{{ firstRosterChildDob(child.children) ? getAge(firstRosterChildDob(child.children)!) + ' god.' : '' }}</p>
              </div>
            </div>
            <button class="text-xs text-brand-red hover:underline" @click="removeChild(child.child_id)">Ukloni</button>
          </div>
        </div>
        <p v-else class="text-center text-gray-400 text-sm py-4">Nema djece u ovoj grupi.</p>
      </div>

      <!-- Staff -->
      <div class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Voditelji</h2>
        <div v-if="staffItems.length > 0" class="space-y-2">
          <div v-for="s in staffItems" :key="s.id" class="flex items-center gap-3 py-2">
            <div class="w-8 h-8 rounded-xl bg-brand-blue/10 flex items-center justify-center font-bold text-brand-blue text-xs">
              {{ firstStaffName(s.profiles)[0] ?? '?' }}
            </div>
            <div>
              <p class="text-sm font-semibold text-gray-900">{{ firstStaffName(s.profiles) }}</p>
              <p class="text-xs text-gray-400 capitalize">{{ s.role }}</p>
            </div>
          </div>
        </div>
        <p v-else class="text-gray-400 text-sm">Nema voditelja dodijeljenih ovoj grupi.</p>
      </div>

      <!-- Upcoming sessions -->
      <div class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Nadolazeće radionice</h2>
        <div v-if="upcomingSessionItems.length > 0" class="space-y-2">
          <div v-for="s in upcomingSessionItems" :key="s.id" class="flex items-center gap-3 py-2 border-b border-gray-50 last:border-0">
            <div class="w-10 h-10 rounded-xl bg-primary-500 text-white flex flex-col items-center justify-center">
              <span class="text-xs font-bold leading-none">{{ new Date(s.scheduled_date).getDate() }}</span>
              <span class="text-xs opacity-80">{{ new Date(s.scheduled_date).toLocaleDateString('bs-BA', { month: 'short' }) }}</span>
            </div>
            <div>
              <p class="text-sm font-semibold text-gray-900">{{ firstUpcomingWorkshopTitle(s.workshops) }}</p>
              <p class="text-xs text-gray-400">{{ s.scheduled_time_start?.slice(0,5) }}</p>
            </div>
          </div>
        </div>
        <p v-else class="text-gray-400 text-sm">Nema nadolazećih radionica.</p>
      </div>
    </div>

    <!-- Add child modal -->
    <Teleport to="body">
      <div v-if="showAddChild" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
        <div class="bg-white rounded-2xl w-full max-w-sm p-6">
          <h3 class="font-display font-bold text-lg text-gray-900 mb-4">Dodaj dijete u grupu</h3>
          <select v-model="selectedChildId" class="input mb-4">
            <option value="">— odaberite dijete —</option>
            <option v-for="c in availableChildren" :key="c.id" :value="c.id">{{ c.full_name }}</option>
          </select>
          <div class="flex gap-3">
            <button class="btn-secondary flex-1" @click="showAddChild = false">Otkaži</button>
            <button class="btn-primary flex-1" :disabled="!selectedChildId || addingChild" @click="addChild">
              {{ addingChild ? 'Dodaje...' : 'Dodaj' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })

const supabase = useSupabase()
const route = useRoute()
const groupId = route.params.id as string

const showAddChild = ref(false)
const selectedChildId = ref('')
const addingChild = ref(false)

const { data: group, pending } = await useAsyncData(`admin-group-${groupId}`, async () => {
  const { data } = await supabase
    .from('groups')
    .select('id, name, description, age_range_min, age_range_max, max_capacity, is_active')
    .eq('id', groupId)
    .single()
  return data
})

useSeoMeta({ title: computed(() => `${group.value?.name ?? 'Grupa'} — Admin`) })

const { data: roster, refresh: refreshRoster } = await useAsyncData(`admin-group-roster-${groupId}`, async () => {
  const { data } = await supabase
    .from('child_groups')
    .select('id, child_id, children(full_name, date_of_birth)')
    .eq('group_id', groupId)
  return data ?? []
})

const { data: staff } = await useAsyncData(`admin-group-staff-${groupId}`, async () => {
  const { data } = await supabase
    .from('group_staff')
    .select('id, role, profiles(full_name)')
    .eq('group_id', groupId)
  return data ?? []
})

const { data: upcomingSessions } = await useAsyncData(`admin-group-sessions-${groupId}`, async () => {
  const today = new Date().toISOString().slice(0, 10)
  const { data } = await supabase
    .from('sessions')
    .select('id, scheduled_date, scheduled_time_start, workshops(title)')
    .eq('group_id', groupId)
    .gte('scheduled_date', today)
    .order('scheduled_date')
    .limit(5)
  return data ?? []
})

const { data: allChildren } = await useAsyncData('admin-all-children', async () => {
  const { data } = await supabase.from('children').select('id, full_name').eq('is_active', true).order('full_name')
  return data ?? []
})

const availableChildren = computed(() => {
  const inGroup = new Set((roster.value ?? []).map((r: { child_id: string }) => r.child_id))
  return (allChildren.value ?? []).filter((c: { id: string }) => !inGroup.has(c.id))
})

const rosterItems = computed(() => roster.value ?? [])
const staffItems = computed(() => staff.value ?? [])
const upcomingSessionItems = computed(() => upcomingSessions.value ?? [])

async function addChild() {
  if (!selectedChildId.value) return
  addingChild.value = true
  await supabase.from('child_groups').insert({ child_id: selectedChildId.value, group_id: groupId })
  selectedChildId.value = ''
  showAddChild.value = false
  addingChild.value = false
  await refreshRoster()
}

async function removeChild(childId: string) {
  await supabase.from('child_groups').delete().eq('child_id', childId).eq('group_id', groupId)
  await refreshRoster()
}

function getAge(dob: string): number {
  const birth = new Date(dob)
  const today = new Date()
  let age = today.getFullYear() - birth.getFullYear()
  if (today.getMonth() < birth.getMonth() || (today.getMonth() === birth.getMonth() && today.getDate() < birth.getDate())) age--
  return age
}

function firstRosterChildName(children: Array<{ full_name: string | null; date_of_birth: string | null }> | null | undefined): string {
  return children?.[0]?.full_name ?? '—'
}

function firstRosterChildDob(children: Array<{ full_name: string | null; date_of_birth: string | null }> | null | undefined): string | null {
  return children?.[0]?.date_of_birth ?? null
}

function firstStaffName(profiles: Array<{ full_name: string | null }> | null | undefined): string {
  return profiles?.[0]?.full_name ?? '—'
}

function firstUpcomingWorkshopTitle(workshops: Array<{ title: string | null }> | null | undefined): string {
  return workshops?.[0]?.title ?? 'Radionica'
}

function formatAgeRange(minMonths: number | null | undefined, maxMonths: number | null | undefined): string {
  if (minMonths === null || minMonths === undefined || maxMonths === null || maxMonths === undefined) return 'Uzrast nije definisan'
  return `${minMonths}-${maxMonths} mjeseci`
}
</script>
