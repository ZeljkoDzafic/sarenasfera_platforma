<template>
  <div class="min-h-screen bg-gradient-to-br from-primary-50 via-white to-brand-green/10 px-4 py-10">
    <div class="card mx-auto max-w-md">
      <NuxtLink to="/auth/login" class="mb-6 inline-flex items-center gap-2 text-sm font-semibold text-gray-500 hover:text-primary-600">
        ← Nazad na prijavu
      </NuxtLink>

      <h1 class="text-3xl font-bold text-gray-900">Nova lozinka</h1>
      <p class="mt-2 text-sm text-gray-500">
        Postavite novu lozinku za svoj nalog. Koristite najmanje 8 karaktera.
      </p>

      <div
        v-if="message"
        class="mt-5 rounded-xl border border-primary-200 bg-primary-50 px-4 py-3 text-sm text-primary-700"
      >
        {{ message }}
      </div>

      <div
        v-if="error"
        class="mt-5 rounded-xl border border-brand-red/20 bg-brand-red/10 px-4 py-3 text-sm text-brand-red"
      >
        {{ error }}
      </div>

      <form class="mt-6 space-y-4" @submit.prevent="handlePasswordUpdate">
        <div>
          <label class="label" for="password">Nova lozinka</label>
          <input id="password" v-model="password" type="password" class="input" minlength="8" required />
        </div>

        <div>
          <label class="label" for="confirm-password">Potvrda lozinke</label>
          <input id="confirm-password" v-model="confirmPassword" type="password" class="input" minlength="8" required />
        </div>

        <button type="submit" class="btn-primary w-full" :disabled="submitting">
          {{ submitting ? 'Ažuriranje...' : 'Sačuvaj novu lozinku' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: false })

useSeoMeta({
  title: 'Nova lozinka — Šarena Sfera',
  description: 'Postavite novu lozinku za svoj Šarena Sfera nalog.',
})

const { init, updatePassword } = useAuth()

const password = ref('')
const confirmPassword = ref('')
const submitting = ref(false)
const message = ref('Ako ste otvorili validan email link, ovdje možete postaviti novu lozinku.')
const error = ref('')

onMounted(async () => {
  await init()
})

async function handlePasswordUpdate() {
  error.value = ''

  if (password.value !== confirmPassword.value) {
    error.value = 'Lozinke se ne podudaraju.'
    return
  }

  submitting.value = true

  try {
    await updatePassword(password.value)
    await navigateTo('/auth/login?reset=1')
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Ažuriranje lozinke nije uspjelo.'
  } finally {
    submitting.value = false
  }
}
</script>
