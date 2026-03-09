<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Djeca</h1>
        <p class="text-sm text-gray-500 mt-1">Upravljanje dječijim profilima</p>
      </div>
      <NuxtLink to="/admin/children/new" class="btn-primary text-sm">
        + Dodaj dijete
      </NuxtLink>
    </div>

    <!-- Filters -->
    <div class="card">
      <div class="flex flex-wrap gap-3">
        <input
          v-model="search"
          type="search"
          placeholder="Pretraži po imenu..."
          class="input flex-1 min-w-48 text-sm"
        />
        <select v-model="filterGroup" class="input w-auto text-sm">
          <option value="">Sve grupe</option>
          <option v-for="g in groups" :key="g.id" :value="g.id">{{ g.name }}</option>
        </select>
        <select v-model="filterStatus" class="input w-auto text-sm">
          <option value="">Svi statusi</option>
          <option value="active">Aktivni</option>
          <option value="inactive">Neaktivni</option>
        </select>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="pending" class="space-y-2">
      <div v-for="i in 8" :key="i" class="card h-16 animate-pulse" />
    </div>

    <!-- Table -->
    <div v-else-if="filteredChildren.length > 0" class="card overflow-hidden p-0">
      <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-100">
          <tr>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Ime</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600 hidden md:table-cell">Datum r.</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600 hidden md:table-cell">Grupa</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600 hidden lg:table-cell">Roditelj</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Status</th>
            <th class="px-4 py-3"></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr
            v-for="child in filteredChildren"
            :key="child.id"
            class="hover:bg-gray-50 transition-colors"
          >
            <td class="px-4 py-3">
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-xl bg-primary-100 flex items-center justify-center font-bold text-primary-600 text-xs flex-shrink-0">
                  {{ child.full_name[0] }}
                </div>
                <span class="font-semibold text-gray-900">{{ child.full_name }}</span>
              </div>
            </td>
            <td class="px-4 py-3 text-gray-500 hidden md:table-cell">
              {{ child.date_of_birth ? formatDate(child.date_of_birth) : '—' }}
              <span v-if="child.date_of_birth" class="text-gray-400 text-xs ml-1">({{ getAge(child.date_of_birth) }}g)</span>
            </td>
            <td class="px-4 py-3 text-gray-500 hidden md:table-cell">
              {{ child.child_groups?.[0]?.groups?.name ?? '—' }}
            </td>
            <td class="px-4 py-3 text-gray-500 hidden lg:table-cell">
              {{ child.parent_children?.[0]?.profiles?.full_name ?? '—' }}
            </td>
            <td class="px-4 py-3">
              <span
                class="text-xs font-semibold px-2 py-0.5 rounded-full"
                :class="child.is_active ? 'bg-brand-green/10 text-brand-green' : 'bg-gray-100 text-gray-400'"
              >
                {{ child.is_active ? 'Aktivan' : 'Neaktivan' }}
              </span>
            </td>
            <td class="px-4 py-3 text-right">
              <NuxtLink :to="`/admin/children/${child.id}`" class="text-primary-600 hover:underline font-semibold text-xs">
                Pregled →
              </NuxtLink>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Empty -->
    <div v-else class="card text-center py-14">
      <div class="text-4xl mb-3">👶</div>
      <h3 class="font-display font-bold text-lg text-gray-900 mb-2">Nema djece</h3>
      <p class="text-gray-500 text-sm mb-4">Dodajte dijete da biste počeli.</p>
      <NuxtLink to="/admin/children/new" class="btn-primary text-sm">Dodaj dijete</NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Djeca — Admin' })

const supabase = useSupabase()

const search = ref('')
const filterGroup = ref('')
const filterStatus = ref('')

const { data: groups } = await useAsyncData('admin-groups-list', async () => {
  const { data } = await supabase.from('groups').select('id, name').eq('is_active', true).order('name')
  return data ?? []
})

const { data: children, pending } = await useAsyncData('admin-children', async () => {
  const { data } = await supabase
    .from('children')
    .select(`
      id, full_name, date_of_birth, is_active,
      child_groups(groups(id, name)),
      parent_children(profiles(full_name, email))
    `)
    .order('full_name')
  return data ?? []
})

const filteredChildren = computed(() => {
  let list = children.value ?? []
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter((c: { full_name: string }) => c.full_name.toLowerCase().includes(q))
  }
  if (filterGroup.value) {
    list = list.filter((c: Record<string, unknown>) => {
      const groups = c.child_groups as Array<{ groups: { id: string } | null }> | null
      return groups?.some(cg => cg.groups?.id === filterGroup.value)
    })
  }
  if (filterStatus.value === 'active') list = list.filter((c: { is_active: boolean }) => c.is_active)
  if (filterStatus.value === 'inactive') list = list.filter((c: { is_active: boolean }) => !c.is_active)
  return list
})

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short', year: 'numeric' })
}

function getAge(dob: string): number {
  const birth = new Date(dob)
  const today = new Date()
  let age = today.getFullYear() - birth.getFullYear()
  if (today.getMonth() < birth.getMonth() || (today.getMonth() === birth.getMonth() && today.getDate() < birth.getDate())) age--
  return age
}
</script>
