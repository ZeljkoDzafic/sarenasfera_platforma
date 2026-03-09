<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Moja djeca</h1>
        <p class="mt-1 text-sm text-gray-500">Pratite razvoj svakog djeteta</p>
      </div>
      <button class="btn-primary flex items-center gap-2 text-sm" @click="showAddChild = true">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Dodaj dijete
      </button>
    </div>

    <div v-if="pending" class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
      <div v-for="i in 3" :key="i" class="card animate-pulse">
        <div class="mb-4 h-32 rounded-xl bg-gray-100" />
        <div class="mb-2 h-4 w-3/4 rounded bg-gray-100" />
        <div class="h-3 w-1/2 rounded bg-gray-100" />
      </div>
    </div>

    <div v-else-if="children && children.length > 0" class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
      <NuxtLink
        v-for="child in children"
        :key="child.id"
        :to="`/portal/children/${child.id}`"
        class="card group transition-all hover:shadow-lg"
      >
        <div class="mb-4 flex items-center gap-4">
          <div class="relative">
            <div
              v-if="child.photo_url"
              class="h-14 w-14 rounded-2xl bg-cover bg-center"
              :style="{ backgroundImage: `url(${child.photo_url})` }"
            />
            <div v-else class="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-primary-400 to-brand-pink font-display text-xl font-bold text-white">
              {{ child.full_name[0] }}
            </div>
            <div class="absolute -bottom-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-brand-green">
              <svg class="h-3 w-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
              </svg>
            </div>
          </div>
          <div class="min-w-0 flex-1">
            <h3 class="truncate font-display font-bold text-gray-900">{{ child.full_name }}</h3>
            <p class="text-sm text-gray-500">{{ childAge(child.date_of_birth) }}</p>
          </div>
          <svg class="h-4 w-4 flex-shrink-0 text-gray-400 transition-colors group-hover:text-primary-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </div>

        <div class="space-y-1.5">
          <div v-for="domain in domains" :key="domain.key" class="flex items-center gap-2">
            <span class="w-20 truncate text-xs text-gray-500">{{ domain.name }}</span>
            <div class="h-1.5 flex-1 overflow-hidden rounded-full bg-gray-100">
              <div class="h-full rounded-full" :style="{ width: '60%', backgroundColor: domain.color }" />
            </div>
          </div>
        </div>

        <div class="mt-4 flex items-center justify-between border-t border-gray-100 pt-4 text-xs text-gray-500">
          <span>{{ child.age_group ?? 'Nema grupe' }}</span>
          <span class="font-semibold text-primary-600 group-hover:underline">Pogledaj pasoš →</span>
        </div>
      </NuxtLink>
    </div>

    <div v-else class="card py-16 text-center">
      <div class="mb-4 text-5xl">👶</div>
      <h3 class="mb-2 font-display text-xl font-bold text-gray-900">Nema dodane djece</h3>
      <p class="mx-auto mb-6 max-w-sm text-gray-600">
        Dodajte dijete da biste mogli pratiti njegov razvoj kroz sve domene.
      </p>
      <button class="btn-primary" @click="showAddChild = true">Dodaj prvo dijete</button>
    </div>

    <Teleport to="body">
      <div v-if="showAddChild" class="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-4 md:items-center">
        <div class="w-full max-w-md rounded-2xl bg-white shadow-xl">
          <div class="border-b border-gray-100 p-6">
            <h2 class="font-display text-xl font-bold text-gray-900">Dodaj dijete</h2>
          </div>
          <form class="space-y-4 p-6" @submit.prevent="addChild">
            <div>
              <label class="label">Ime i prezime *</label>
              <input v-model="newChild.full_name" type="text" class="input" placeholder="Ime djeteta" required />
            </div>
            <div>
              <label class="label">Nadimak</label>
              <input v-model="newChild.nickname" type="text" class="input" placeholder="Ime koje dijete preferira" />
            </div>
            <div>
              <label class="label">Datum rođenja *</label>
              <input v-model="newChild.date_of_birth" type="date" class="input" required />
            </div>
            <div>
              <label class="label">Spol</label>
              <select v-model="newChild.gender" class="input">
                <option value="">Odaberite...</option>
                <option value="female">Žensko</option>
                <option value="male">Muško</option>
                <option value="other">Ostalo</option>
              </select>
            </div>
            <div>
              <label class="label">Alergije / posebne napomene</label>
              <textarea v-model="newChild.allergies" class="input" rows="2" placeholder="Alergije, posebne potrebe..." />
            </div>
            <p v-if="addError" class="text-sm text-brand-red">{{ addError }}</p>
            <div class="flex gap-3">
              <button type="button" class="btn-secondary flex-1" @click="showAddChild = false">Otkaži</button>
              <button type="submit" class="btn-primary flex-1" :disabled="addLoading">
                {{ addLoading ? 'Čuva...' : 'Dodaj dijete' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })

useSeoMeta({ title: 'Moja djeca — Šarena Sfera' })

const supabase = useSupabase()
const { user } = useAuth()

interface PortalChildRecord {
  id: string
  full_name: string
  nickname: string | null
  date_of_birth: string
  gender: string | null
  photo_url?: string | null
  age_group: string | null
  enrollment_date?: string | null
}

const { data: children, pending, refresh } = await useAsyncData<PortalChildRecord[]>('portal-children', async () => {
  if (!user.value) return []
  const { data } = await supabase
    .from('children')
    .select(`
      id, full_name, nickname, date_of_birth, gender, photo_url,
      age_group, enrollment_date,
      parent_children!inner(parent_id)
    `)
    .eq('parent_children.parent_id', user.value.id)
    .eq('is_active', true)
    .order('full_name')
  return (data as PortalChildRecord[] | null) ?? []
})

const domains = [
  { key: 'emotional', name: 'Emocionalni', color: '#cf2e2e' },
  { key: 'social', name: 'Socijalni', color: '#fcb900' },
  { key: 'creative', name: 'Kreativni', color: '#9b51e0' },
  { key: 'cognitive', name: 'Kognitivni', color: '#0693e3' },
  { key: 'motor', name: 'Motorički', color: '#00d084' },
  { key: 'language', name: 'Jezički', color: '#f78da7' },
] as const

function childAge(dob: string): string {
  const today = new Date()
  const birth = new Date(dob)
  const months = (today.getFullYear() - birth.getFullYear()) * 12 + (today.getMonth() - birth.getMonth())
  const years = Math.floor(months / 12)
  const rem = months % 12
  if (rem === 0) return `${years} ${years === 1 ? 'godina' : 'godine'}`
  return `${years} god. ${rem} mj.`
}

const showAddChild = ref(false)
const addLoading = ref(false)
const addError = ref('')
const newChild = reactive({ full_name: '', nickname: '', date_of_birth: '', gender: '', allergies: '' })

async function addChild() {
  if (!user.value) return
  addLoading.value = true
  addError.value = ''

  try {
    const { data: child, error: childErr } = await supabase
      .from('children')
      .insert({
        full_name: newChild.full_name,
        nickname: newChild.nickname || null,
        date_of_birth: newChild.date_of_birth,
        gender: newChild.gender || null,
        allergies: newChild.allergies || null,
      })
      .select('id')
      .single()

    if (childErr || !child) throw childErr

    await supabase.from('parent_children').insert({
      parent_id: user.value.id,
      child_id: child.id,
      relationship: 'parent',
      is_primary: true,
    })

    showAddChild.value = false
    Object.assign(newChild, { full_name: '', nickname: '', date_of_birth: '', gender: '', allergies: '' })
    await refresh()
  } catch {
    addError.value = 'Greška pri dodavanju. Pokušajte ponovo.'
  } finally {
    addLoading.value = false
  }
}
</script>
