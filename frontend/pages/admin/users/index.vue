<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Korisnici</h1>
        <p class="text-sm text-gray-500 mt-1">Upravljanje korisničkim nalozima</p>
      </div>
    </div>

    <!-- Filters -->
    <div class="card">
      <div class="flex flex-wrap gap-3">
        <input v-model="search" type="search" placeholder="Pretraži po imenu ili emailu..." class="input flex-1 min-w-48 text-sm" />
        <select v-model="filterRole" class="input w-auto text-sm">
          <option value="">Sve uloge</option>
          <option value="parent">Roditelji</option>
          <option value="staff">Osoblje</option>
          <option value="admin">Admini</option>
          <option value="expert">Eksperti</option>
        </select>
      </div>
    </div>

    <!-- Stats row -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
      <div v-for="role in roleCounts" :key="role.key" class="card text-center py-3">
        <div class="text-xl font-bold" :class="role.color">{{ role.count }}</div>
        <div class="text-xs text-gray-400">{{ role.label }}</div>
      </div>
    </div>

    <div v-if="pending" class="space-y-2">
      <div v-for="i in 8" :key="i" class="card h-14 animate-pulse" />
    </div>

    <div v-else-if="filteredUsers.length > 0" class="card overflow-hidden p-0">
      <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-100">
          <tr>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Korisnik</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600 hidden md:table-cell">Email</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Uloga</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600 hidden lg:table-cell">Registrovan</th>
            <th class="px-4 py-3"></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr v-for="user in filteredUsers" :key="user.id" class="hover:bg-gray-50">
            <td class="px-4 py-3">
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-xl bg-primary-100 flex items-center justify-center font-bold text-primary-600 text-xs">
                  {{ user.full_name?.[0] ?? user.email?.[0]?.toUpperCase() ?? '?' }}
                </div>
                <span class="font-semibold text-gray-900">{{ user.full_name ?? 'Bez imena' }}</span>
              </div>
            </td>
            <td class="px-4 py-3 text-gray-500 hidden md:table-cell">{{ user.email }}</td>
            <td class="px-4 py-3">
              <select
                :value="user.role"
                class="text-xs font-semibold px-2 py-1 rounded-lg border border-gray-200 bg-white"
                @change="changeRole(user.id, ($event.target as HTMLSelectElement).value)"
              >
                <option value="parent">Roditelj</option>
                <option value="staff">Osoblje</option>
                <option value="expert">Ekspert</option>
                <option value="admin">Admin</option>
              </select>
            </td>
            <td class="px-4 py-3 text-gray-400 text-xs hidden lg:table-cell">
              {{ formatDate(user.created_at) }}
            </td>
            <td class="px-4 py-3 text-right">
              <button class="text-xs text-brand-red hover:underline" @click="confirmDeactivate(user)">
                {{ user.is_active ? 'Deaktiviraj' : 'Aktiviraj' }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-else class="card text-center py-14">
      <div class="text-4xl mb-3">👤</div>
      <p class="text-gray-500 text-sm">Nema korisnika koji odgovaraju filteru.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Korisnici — Admin' })

const supabase = useSupabase()
const search = ref('')
const filterRole = ref('')

const { data: users, pending, refresh } = await useAsyncData('admin-users', async () => {
  const { data } = await supabase
    .from('profiles')
    .select('id, full_name, email, role, is_active, created_at')
    .order('created_at', { ascending: false })
  return data ?? []
})

const filteredUsers = computed(() => {
  let list = users.value ?? []
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter((u: { full_name?: string; email?: string }) =>
      u.full_name?.toLowerCase().includes(q) || u.email?.toLowerCase().includes(q)
    )
  }
  if (filterRole.value) {
    list = list.filter((u: { role: string }) => u.role === filterRole.value)
  }
  return list
})

const roleCounts = computed(() => {
  const all = users.value ?? []
  return [
    { key: 'parent', label: 'Roditelji', count: all.filter((u: { role: string }) => u.role === 'parent').length, color: 'text-brand-blue' },
    { key: 'staff', label: 'Osoblje', count: all.filter((u: { role: string }) => u.role === 'staff').length, color: 'text-brand-green' },
    { key: 'admin', label: 'Admini', count: all.filter((u: { role: string }) => u.role === 'admin').length, color: 'text-primary-600' },
    { key: 'expert', label: 'Eksperti', count: all.filter((u: { role: string }) => u.role === 'expert').length, color: 'text-brand-amber' },
  ]
})

async function changeRole(userId: string, newRole: string) {
  await supabase.from('profiles').update({ role: newRole }).eq('id', userId)
  await refresh()
}

async function confirmDeactivate(user: { id: string; is_active: boolean; full_name?: string }) {
  const action = user.is_active ? 'deaktivirate' : 'aktivirate'
  if (!confirm(`Jeste li sigurni da želite ${action} korisnika ${user.full_name ?? ''}?`)) return
  await supabase.from('profiles').update({ is_active: !user.is_active }).eq('id', user.id)
  await refresh()
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short', year: 'numeric' })
}
</script>
