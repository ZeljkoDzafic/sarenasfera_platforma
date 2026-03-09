<template>
  <div class="min-h-screen bg-gradient-to-br from-primary-50 via-white to-brand-pink/10 px-4 py-10">
    <div class="mx-auto grid max-w-5xl gap-8 lg:grid-cols-[1.1fr_0.9fr] lg:items-center">
      <section class="card-featured hidden min-h-[560px] flex-col justify-between lg:flex">
        <div>
          <p class="text-sm font-semibold uppercase tracking-[0.2em] text-white/80">Prijava</p>
          <h1 class="mt-3 text-4xl font-bold">Vratite se u svoj prostor za rast i praćenje razvoja.</h1>
          <p class="mt-4 max-w-xl text-sm text-white/85">
            Roditelji dobijaju pregled djetetovog napretka, a tim Šarene Sfere operativne alate za rad s grupama i opservacijama.
          </p>
        </div>

        <div class="grid gap-3">
          <div class="rounded-2xl bg-white/10 p-4">
            <p class="text-sm font-semibold">Roditelji</p>
            <p class="mt-1 text-sm text-white/80">Portal za pasoš, radionice, aktivnosti i preporuke.</p>
          </div>
          <div class="rounded-2xl bg-white/10 p-4">
            <p class="text-sm font-semibold">Tim</p>
            <p class="mt-1 text-sm text-white/80">Brz pristup djeci, grupama, događajima i opservacijama.</p>
          </div>
        </div>
      </section>

      <section class="card mx-auto w-full max-w-md">
        <NuxtLink to="/" class="mb-6 inline-flex items-center gap-2 text-sm font-semibold text-gray-500 hover:text-primary-600">
          ← Nazad na početnu
        </NuxtLink>

        <div class="mb-6">
          <h1 class="text-3xl font-bold text-gray-900">Prijava</h1>
          <p class="mt-2 text-sm text-gray-500">Unesite email i lozinku za pristup svom nalogu.</p>
        </div>

        <div
          v-if="route.query.registered === '1' || successMessage"
          class="mb-4 rounded-xl border border-brand-green/20 bg-brand-green/10 px-4 py-3 text-sm text-brand-green"
        >
          {{ successMessage || 'Nalog je kreiran. Ako je potrebna potvrda emaila, provjerite inbox prije prve prijave.' }}
        </div>

        <div
          v-if="route.query.reset === '1'"
          class="mb-4 rounded-xl border border-primary-200 bg-primary-50 px-4 py-3 text-sm text-primary-700"
        >
          Lozinka je ažurirana. Prijavite se novom lozinkom.
        </div>

        <div
          v-if="error"
          class="mb-4 rounded-xl border border-brand-red/20 bg-brand-red/10 px-4 py-3 text-sm text-brand-red"
        >
          {{ error }}
        </div>

        <form class="space-y-4" @submit.prevent="handleLogin">
          <div>
            <label class="label" for="email">Email</label>
            <input id="email" v-model="form.email" type="email" class="input" autocomplete="email" required />
          </div>

          <div>
            <div class="mb-1.5 flex items-center justify-between">
              <label class="label mb-0" for="password">Lozinka</label>
              <NuxtLink to="/auth/forgot-password" class="text-sm font-semibold text-primary-600 hover:text-primary-700">
                Zaboravili ste lozinku?
              </NuxtLink>
            </div>
            <div class="relative">
              <input
                id="password"
                v-model="form.password"
                :type="showPassword ? 'text' : 'password'"
                class="input pr-12"
                autocomplete="current-password"
                required
              />
              <button
                type="button"
                class="absolute inset-y-0 right-0 px-4 text-sm font-semibold text-gray-500 hover:text-primary-600"
                @click="showPassword = !showPassword"
              >
                {{ showPassword ? 'Sakrij' : 'Prikaži' }}
              </button>
            </div>
          </div>

          <button type="submit" class="btn-primary w-full" :disabled="submitting">
            {{ submitting ? 'Prijava u toku...' : 'Prijavite se' }}
          </button>
        </form>

        <p class="mt-6 text-center text-sm text-gray-500">
          Nemate nalog?
          <NuxtLink :to="registerLink" class="font-semibold text-primary-600 hover:text-primary-700">
            Registrujte se
          </NuxtLink>
        </p>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'guest' })

useSeoMeta({
  title: 'Prijava — Šarena Sfera',
  description: 'Prijavite se u Šarena Sfera portal za roditelje i tim.',
})

const route = useRoute()
const { signIn, init, role } = useAuth()

const form = reactive({
  email: typeof route.query.email === 'string' ? route.query.email : '',
  password: '',
})

const showPassword = ref(false)
const submitting = ref(false)
const error = ref('')
const successMessage = ref(typeof route.query.message === 'string' ? route.query.message : '')

const registerLink = computed(() => {
  const params = new URLSearchParams()
  if (typeof route.query.redirect === 'string') params.set('redirect', route.query.redirect)
  return params.size > 0 ? `/auth/register?${params.toString()}` : '/auth/register'
})

async function handleLogin() {
  submitting.value = true
  error.value = ''

  try {
    await signIn(form.email, form.password)
    await init()

    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : ''
    if (redirect.startsWith('/')) {
      await navigateTo(redirect)
      return
    }

    if (role.value === 'staff' || role.value === 'admin' || role.value === 'expert') {
      await navigateTo('/admin')
      return
    }

    await navigateTo('/portal')
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Prijava nije uspjela. Pokušajte ponovo.'
  } finally {
    submitting.value = false
  }
}
</script>
