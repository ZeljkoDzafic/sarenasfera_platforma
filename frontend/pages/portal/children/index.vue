<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Moja djeca</h1>
        <p class="text-sm text-gray-500 mt-1">Pratite razvoj svakog djeteta</p>
      </div>
      <button class="btn-primary text-sm flex items-center gap-2" @click="showAddChild = true">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Dodaj dijete
      </button>
    </div>

    <!-- Loading -->
    <div v-if="pending" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="i in 3" :key="i" class="card animate-pulse">
        <div class="h-32 bg-gray-100 rounded-xl mb-4" />
        <div class="h-4 bg-gray-100 rounded w-3/4 mb-2" />
        <div class="h-3 bg-gray-100 rounded w-1/2" />
      </div>
    </div>

    <!-- Children grid -->
    <div v-else-if="children && children.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <NuxtLink
        v-for="child in children"
        :key="child.id"
        :to="`/portal/children/${child.id}`"
        class="card hover:shadow-lg transition-all group"
      >
        <!-- Avatar / photo -->
        <div class="flex items-center gap-4 mb-4">
          <div class="relative">
            <div
              v-if="child.photo_url"
              class="w-14 h-14 rounded-2xl bg-cover bg-center"
              :style="{ backgroundImage: `url(${child.photo_url})` }"
            />
            <div v-else class="w-14 h-14 rounded-2xl bg-gradient-to-br from-primary-400 to-brand-pink flex items-center justify-center text-white font-display font-bold text-xl">
              {{ child.full_name[0] }}
            </div>
            <div class="absolute -bottom-1 -right-1 w-5 h-5 bg-brand-green rounded-full flex items-center justify-center">
              <svg class="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
              </svg>
            </div>
          </div>
          <div class="flex-1 min-w-0">
            <h3 class="font-display font-bold text-gray-900 truncate">{{ child.full_name }}</h3>
            <p class="text-sm text-gray-500">{{ childAge(child.date_of_birth) }}</p>
          </div>
          <svg class="w-4 h-4 text-gray-400 group-hover:text-primary-500 transition-colors flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </div>

        <!-- Domain mini-bars -->
        <div class="space-y-1.5">
          <div
            v-for="domain in domains"
            :key="domain.key"
            class="flex items-center gap-2"
          >
            <span class="text-xs w-20 text-gray-500 truncate">{{ domain.name }}</span>
            <div class="flex-1 h-1.5 bg-gray-100 rounded-full overflow-hidden">
              <div
                class="h-full rounded-full transition-all"
                :style="{ width: '60%', backgroundColor: domain.color }"
              />
            </div>
          </div>
        </div>

        <div class="mt-4 pt-4 border-t border-gray-100 flex items-center justify-between text-xs text-gray-500">
          <span>{{ child.age_group ?? 'Nema grupe' }}</span>
          <span class="text-primary-600 font-semibold group-hover:underline">Pogledaj pasoš →</span>
        </div>
      </NuxtLink>
    </div>

    <!-- Empty state -->
    <div v-else class="card text-center py-16">
      <div class="text-5xl mb-4">👶</div>
      <h3 class="font-display font-bold text-xl text-gray-900 mb-2">Nema dodane djece</h3>
      <p class="text-gray-600 mb-6 max-w-sm mx-auto">
        Dodajte dijete da biste mogli pratiti njegov razvoj kroz sve domene.
      </p>
      <button class="btn-primary" @click="showAddChild = true">Dodaj prvo dijete</button>
    </div>

    <!-- Add Child Modal -->
    <Teleport to="body">
      <div v-if="showAddChild" class="fixed inset-0 bg-black/50 flex items-end md:items-center justify-center z-50 p-4">
        <div class="bg-white rounded-2xl w-full max-w-md shadow-xl">
          <div class="p-6 border-b border-gray-100">
            <h2 class="font-display font-bold text-xl text-gray-900">Dodaj dijete</h2>
          </div>
          <form class="p-6 space-y-4" @submit.prevent="addChild">
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
            <p v-if="addError" class="text-brand-red text-sm">{{ addError }}</p>
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

const { data: children, pending, refresh } = await useAsyncData('portal-children', async () => {
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
  return data ?? []
})

const domains = [
  { key: 'emotional', name: 'Emocionalni', color: '#cf2e2e' },
  { key: 'social',    name: 'Socijalni',   color: '#fcb900' },
  { key: 'creative',  name: 'Kreativni',   color: '#9b51e0' },
  { key: 'cognitive', name: 'Kognitivni',  color: '#0693e3' },
  { key: 'motor',     name: 'Motorički',   color: '#00d084' },
  { key: 'language',  name: 'Jezički',     color: '#f78da7' },
]

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
  } catch (err: unknown) {
    addError.value = 'Greška pri dodavanju. Pokušajte ponovo.'
  } finally {
    addLoading.value = false
  }
}
</script>
