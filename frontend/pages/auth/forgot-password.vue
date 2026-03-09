<template>
  <div class="min-h-screen bg-gradient-to-br from-brand-blue/10 via-white to-primary-50 px-4 py-10">
    <div class="card mx-auto max-w-md">
      <NuxtLink to="/auth/login" class="mb-6 inline-flex items-center gap-2 text-sm font-semibold text-gray-500 hover:text-primary-600">
        ← Nazad na prijavu
      </NuxtLink>

      <h1 class="text-3xl font-bold text-gray-900">Reset lozinke</h1>
      <p class="mt-2 text-sm text-gray-500">
        Unesite email adresu i poslat ćemo vam link za postavljanje nove lozinke.
      </p>

      <div
        v-if="message"
        class="mt-5 rounded-xl border border-brand-green/20 bg-brand-green/10 px-4 py-3 text-sm text-brand-green"
      >
        {{ message }}
      </div>

      <div
        v-if="error"
        class="mt-5 rounded-xl border border-brand-red/20 bg-brand-red/10 px-4 py-3 text-sm text-brand-red"
      >
        {{ error }}
      </div>

      <form class="mt-6 space-y-4" @submit.prevent="handleReset">
        <div>
          <label class="label" for="email">Email</label>
          <input id="email" v-model="email" type="email" class="input" autocomplete="email" required />
        </div>

        <button type="submit" class="btn-primary w-full" :disabled="submitting">
          {{ submitting ? 'Slanje linka...' : 'Pošalji reset link' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'guest' })

useSeoMeta({
  title: 'Zaboravljena lozinka — Šarena Sfera',
  description: 'Pošaljite sebi link za reset lozinke.',
})

const route = useRoute()
const { resetPassword } = useAuth()

const email = ref(typeof route.query.email === 'string' ? route.query.email : '')
const submitting = ref(false)
const message = ref('')
const error = ref('')

async function handleReset() {
  submitting.value = true
  message.value = ''
  error.value = ''

  try {
    await resetPassword(email.value)
    message.value = 'Link za reset je poslan. Provjerite inbox i spam folder.'
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Slanje linka nije uspjelo.'
  } finally {
    submitting.value = false
  }
}
</script>
