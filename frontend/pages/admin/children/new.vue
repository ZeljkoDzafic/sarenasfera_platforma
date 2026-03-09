<template>
  <div class="max-w-2xl space-y-6">
    <div class="flex items-center gap-3">
      <NuxtLink to="/admin/children" class="text-gray-400 hover:text-gray-600">←</NuxtLink>
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Novo dijete</h1>
        <p class="text-sm text-gray-500 mt-0.5">Dodajte novi dječiji profil</p>
      </div>
    </div>

    <div v-if="error" class="p-3 bg-brand-red/10 border border-brand-red/20 rounded-xl text-brand-red text-sm">
      {{ error }}
    </div>

    <form class="card space-y-5" @submit.prevent="submit">
      <h2 class="font-display font-bold text-lg text-gray-900">Podaci o djetetu</h2>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="label">Ime i prezime *</label>
          <input v-model="form.full_name" type="text" class="input" required placeholder="Ime Prezime" />
        </div>
        <div>
          <label class="label">Datum rođenja *</label>
          <input v-model="form.date_of_birth" type="date" class="input" required />
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="label">Spol</label>
          <select v-model="form.gender" class="input">
            <option value="">— nije odabrano —</option>
            <option value="male">Muški</option>
            <option value="female">Ženski</option>
          </select>
        </div>
        <div>
          <label class="label">Lokacija / centar</label>
          <select v-model="form.location_id" class="input">
            <option value="">— nije odabrano —</option>
            <option v-for="loc in locations" :key="loc.id" :value="loc.id">{{ loc.name }}</option>
          </select>
        </div>
      </div>

      <div>
        <label class="label">Alergije / posebne napomene</label>
        <textarea v-model="form.allergies" class="input" rows="2" placeholder="Alergije, dijete, posebne potrebe..." />
      </div>

      <div>
        <label class="label">Medicinske napomene</label>
        <textarea v-model="form.medical_notes" class="input" rows="2" placeholder="Lijekovi, stanja, doktor..." />
      </div>

      <h2 class="font-display font-bold text-lg text-gray-900 pt-2 border-t border-gray-100">Roditelj / skrbnik</h2>

      <div>
        <label class="label">Email roditelja *</label>
        <input v-model="parentEmail" type="email" class="input" required placeholder="roditelj@email.com" />
        <p class="text-xs text-gray-400 mt-1">Ako roditelj već ima nalog, dijete će se vezati za njega.</p>
      </div>

      <div>
        <label class="label">Grupa (opcionalno)</label>
        <select v-model="form.group_id" class="input">
          <option value="">— bez grupe —</option>
          <option v-for="g in groups" :key="g.id" :value="g.id">{{ g.name }}</option>
        </select>
      </div>

      <div class="flex gap-3 pt-2">
        <NuxtLink to="/admin/children" class="btn-secondary flex-1 text-center">Otkaži</NuxtLink>
        <button type="submit" class="btn-primary flex-1" :disabled="saving">
          {{ saving ? 'Čuva...' : 'Dodaj dijete' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Novo dijete — Admin' })

const supabase = useSupabase()
const router = useRouter()

const saving = ref(false)
const error = ref('')
const parentEmail = ref('')

const form = reactive({
  full_name: '',
  date_of_birth: '',
  gender: '',
  location_id: '',
  allergies: '',
  medical_notes: '',
  group_id: '',
})

const { data: groups } = await useAsyncData('admin-groups-new-child', async () => {
  const { data } = await supabase.from('groups').select('id, name').eq('is_active', true).order('name')
  return data ?? []
})

const { data: locations } = await useAsyncData('admin-locations', async () => {
  const { data } = await supabase.from('locations').select('id, name').eq('is_active', true).order('name')
  return data ?? []
})

async function submit() {
  if (!form.full_name || !form.date_of_birth || !parentEmail.value) return
  saving.value = true
  error.value = ''

  try {
    // Create child
    const { data: child, error: childErr } = await supabase
      .from('children')
      .insert({
        full_name: form.full_name,
        date_of_birth: form.date_of_birth,
        gender: form.gender || null,
        location_id: form.location_id || null,
        allergies: form.allergies || null,
        medical_notes: form.medical_notes || null,
        is_active: true,
      })
      .select('id')
      .single()

    if (childErr || !child) throw new Error(childErr?.message ?? 'Greška pri kreiranju djeteta')

    // Find parent by email
    const { data: parentProfile } = await supabase
      .from('profiles')
      .select('id')
      .eq('email', parentEmail.value)
      .single()

    if (parentProfile) {
      await supabase.from('parent_children').insert({ parent_id: parentProfile.id, child_id: child.id })
    }

    // Assign to group
    if (form.group_id) {
      await supabase.from('child_groups').insert({ child_id: child.id, group_id: form.group_id })
    }

    router.push(`/admin/children/${child.id}`)
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'Neočekivana greška'
  } finally {
    saving.value = false
  }
}
</script>
