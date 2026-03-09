<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Grupe</h1>
        <p class="text-sm text-gray-500 mt-1">Upravljanje grupama djece</p>
      </div>
      <button class="btn-primary text-sm" @click="showCreate = true">+ Nova grupa</button>
    </div>

    <div v-if="pending" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="i in 3" :key="i" class="card h-40 animate-pulse" />
    </div>

    <div v-else-if="groups && groups.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div
        v-for="group in groups"
        :key="group.id"
        class="card hover:shadow-lg transition-shadow"
      >
        <div class="flex items-start justify-between mb-3">
          <div>
            <h3 class="font-display font-bold text-lg text-gray-900">{{ group.name }}</h3>
            <p class="text-xs text-gray-500 mt-0.5">
              {{ group.age_min }}–{{ group.age_max }} godina
              {{ group.schedule_days?.join(', ') ? `• ${group.schedule_days.join(', ')}` : '' }}
            </p>
          </div>
          <span
            class="text-xs font-semibold px-2 py-0.5 rounded-full"
            :class="group.is_active ? 'bg-brand-green/10 text-brand-green' : 'bg-gray-100 text-gray-400'"
          >
            {{ group.is_active ? 'Aktivna' : 'Neaktivna' }}
          </span>
        </div>

        <!-- Capacity bar -->
        <div class="mb-3">
          <div class="flex justify-between text-xs text-gray-500 mb-1">
            <span>Kapacitet</span>
            <span>{{ group.child_groups?.length ?? 0 }} / {{ group.max_children ?? '—' }}</span>
          </div>
          <div class="h-1.5 bg-gray-100 rounded-full overflow-hidden">
            <div
              class="h-full rounded-full bg-primary-500 transition-all"
              :style="{ width: group.max_children ? `${Math.min(100, ((group.child_groups?.length ?? 0) / group.max_children) * 100)}%` : '0%' }"
            />
          </div>
        </div>

        <p v-if="group.description" class="text-xs text-gray-500 line-clamp-2 mb-3">{{ group.description }}</p>

        <NuxtLink :to="`/admin/groups/${group.id}`" class="text-primary-600 hover:underline font-semibold text-sm">
          Pregled grupe →
        </NuxtLink>
      </div>
    </div>

    <div v-else class="card text-center py-14">
      <div class="text-4xl mb-3">👥</div>
      <h3 class="font-display font-bold text-lg text-gray-900 mb-2">Nema grupa</h3>
      <button class="btn-primary text-sm mt-2" @click="showCreate = true">Kreirajte prvu grupu</button>
    </div>

    <!-- Create group modal -->
    <Teleport to="body">
      <div v-if="showCreate" class="fixed inset-0 bg-black/50 flex items-end md:items-center justify-center z-50 p-4">
        <div class="bg-white rounded-2xl w-full max-w-lg shadow-xl">
          <div class="p-6 border-b border-gray-100">
            <h2 class="font-display font-bold text-xl text-gray-900">Nova grupa</h2>
          </div>
          <form class="p-6 space-y-4" @submit.prevent="createGroup">
            <div>
              <label class="label">Naziv grupe *</label>
              <input v-model="createForm.name" type="text" class="input" required placeholder="npr. Leptirići" />
            </div>
            <div class="grid grid-cols-3 gap-3">
              <div>
                <label class="label">Min. dob (god.)</label>
                <input v-model.number="createForm.age_min" type="number" class="input" min="1" max="6" />
              </div>
              <div>
                <label class="label">Max. dob (god.)</label>
                <input v-model.number="createForm.age_max" type="number" class="input" min="1" max="8" />
              </div>
              <div>
                <label class="label">Kapacitet</label>
                <input v-model.number="createForm.max_children" type="number" class="input" min="1" max="30" />
              </div>
            </div>
            <div>
              <label class="label">Opis</label>
              <textarea v-model="createForm.description" class="input" rows="2" />
            </div>
            <div class="flex gap-3">
              <button type="button" class="btn-secondary flex-1" @click="showCreate = false">Otkaži</button>
              <button type="submit" class="btn-primary flex-1" :disabled="creating">
                {{ creating ? 'Kreira...' : 'Kreiraj grupu' }}
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
useSeoMeta({ title: 'Grupe — Admin' })

const supabase = useSupabase()
const showCreate = ref(false)
const creating = ref(false)

const createForm = reactive({
  name: '',
  age_min: 2,
  age_max: 4,
  max_children: 12,
  description: '',
})

const { data: groups, pending, refresh } = await useAsyncData('admin-groups', async () => {
  const { data } = await supabase
    .from('groups')
    .select('id, name, description, age_min, age_max, max_children, schedule_days, is_active, child_groups(id)')
    .order('name')
  return data ?? []
})

async function createGroup() {
  if (!createForm.name) return
  creating.value = true
  await supabase.from('groups').insert({
    name: createForm.name,
    age_min: createForm.age_min,
    age_max: createForm.age_max,
    max_children: createForm.max_children,
    description: createForm.description || null,
    is_active: true,
  })
  showCreate.value = false
  creating.value = false
  Object.assign(createForm, { name: '', age_min: 2, age_max: 4, max_children: 12, description: '' })
  await refresh()
}
</script>
