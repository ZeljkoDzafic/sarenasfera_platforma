<template>
  <div class="space-y-6 max-w-2xl">
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Postavke profila</h1>
      <p class="text-sm text-gray-500 mt-1">Upravljajte podacima svog naloga</p>
    </div>

    <!-- Profile Form -->
    <div class="card">
      <h2 class="font-display font-bold text-lg text-gray-900 mb-5">Lični podaci</h2>

      <div v-if="saved" class="mb-4 p-3 bg-brand-green/10 border border-brand-green/20 rounded-xl text-brand-green text-sm font-semibold">
        ✓ Podaci su sačuvani.
      </div>

      <form class="space-y-4" @submit.prevent="saveProfile">
        <div>
          <label class="label">Ime i prezime</label>
          <input v-model="form.full_name" type="text" class="input" placeholder="Vaše puno ime" />
        </div>
        <div>
          <label class="label">Email</label>
          <input :value="userEmail" type="email" class="input bg-gray-50 cursor-not-allowed" disabled />
          <p class="text-xs text-gray-400 mt-1">Email se ne može mijenjati direktno.</p>
        </div>
        <div>
          <label class="label">Telefon</label>
          <input v-model="form.phone" type="tel" class="input" placeholder="+387 61 000 000" />
        </div>
        <div>
          <label class="label">Grad</label>
          <input v-model="form.city" type="text" class="input" placeholder="Vaš grad" />
        </div>

        <div class="pt-2">
          <button type="submit" class="btn-primary" :disabled="saving">
            {{ saving ? 'Čuva...' : 'Sačuvaj promjene' }}
          </button>
        </div>
      </form>
    </div>

    <!-- Notifications -->
    <div class="card">
      <h2 class="font-display font-bold text-lg text-gray-900 mb-5">Obavještenja</h2>
      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <div>
            <p class="font-semibold text-gray-900 text-sm">Email obavještenja</p>
            <p class="text-xs text-gray-500">Radionice, izvještaji, novosti</p>
          </div>
          <button
            class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors"
            :class="notifs.email ? 'bg-primary-500' : 'bg-gray-200'"
            @click="notifs.email = !notifs.email"
          >
            <span class="inline-block h-4 w-4 transform rounded-full bg-white transition-transform"
              :class="notifs.email ? 'translate-x-6' : 'translate-x-1'" />
          </button>
        </div>
        <div class="flex items-center justify-between">
          <div>
            <p class="font-semibold text-gray-900 text-sm">Push notifikacije</p>
            <p class="text-xs text-gray-500">Poruke od voditelja</p>
          </div>
          <button
            class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors"
            :class="notifs.push ? 'bg-primary-500' : 'bg-gray-200'"
            @click="notifs.push = !notifs.push"
          >
            <span class="inline-block h-4 w-4 transform rounded-full bg-white transition-transform"
              :class="notifs.push ? 'translate-x-6' : 'translate-x-1'" />
          </button>
        </div>
      </div>
    </div>

    <!-- Danger Zone -->
    <div class="card border border-brand-red/20">
      <h2 class="font-display font-bold text-lg text-brand-red mb-3">Zona opasnosti</h2>
      <p class="text-sm text-gray-600 mb-4">
        Brisanje naloga je trajno i ne može se poništiti. Svi podaci o vašoj djeci biće trajno obrisani.
      </p>
      <button class="btn-danger text-sm" @click="showDeleteConfirm = true">
        Obriši nalog
      </button>
    </div>

    <!-- Delete confirm dialog -->
    <Teleport to="body">
      <div v-if="showDeleteConfirm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
        <div class="bg-white rounded-2xl w-full max-w-sm p-6">
          <h3 class="font-display font-bold text-xl text-gray-900 mb-3">Jeste li sigurni?</h3>
          <p class="text-sm text-gray-600 mb-6">Unesite svoju email adresu za potvrdu brisanja naloga.</p>
          <input v-model="deleteConfirmEmail" type="email" class="input mb-4" :placeholder="userEmail" />
          <div class="flex gap-3">
            <button class="btn-secondary flex-1" @click="showDeleteConfirm = false">Otkaži</button>
            <button
              class="btn-danger flex-1"
              :disabled="deleteConfirmEmail !== userEmail"
              @click="deleteAccount"
            >
              Obriši nalog
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })
useSeoMeta({ title: 'Postavke — Šarena Sfera' })

const supabase = useSupabase()
const { user, logout } = useAuth()
const router = useRouter()

const userEmail = computed(() => user.value?.email ?? '')

const form = reactive({ full_name: '', phone: '', city: '' })
const notifs = reactive({ email: true, push: true })
const saving = ref(false)
const saved = ref(false)
const showDeleteConfirm = ref(false)
const deleteConfirmEmail = ref('')

// Load profile
onMounted(async () => {
  if (!user.value) return
  const { data } = await supabase
    .from('profiles')
    .select('full_name, phone, city, notification_preferences')
    .eq('id', user.value.id)
    .single()
  if (data) {
    form.full_name = data.full_name ?? ''
    form.phone = data.phone ?? ''
    form.city = data.city ?? ''
    if (data.notification_preferences) {
      notifs.email = data.notification_preferences.email ?? true
      notifs.push = data.notification_preferences.push ?? true
    }
  }
})

async function saveProfile() {
  if (!user.value) return
  saving.value = true
  try {
    await supabase.from('profiles').update({
      full_name: form.full_name,
      phone: form.phone || null,
      city: form.city || null,
      notification_preferences: { email: notifs.email, push: notifs.push, sms: false },
    }).eq('id', user.value.id)
    saved.value = true
    setTimeout(() => { saved.value = false }, 3000)
  } finally {
    saving.value = false
  }
}

async function deleteAccount() {
  if (deleteConfirmEmail.value !== userEmail.value) return
  // In production: call a secure edge function or API to delete account
  await logout()
  router.push('/')
}
</script>
