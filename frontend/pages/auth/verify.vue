<template>
  <div class="min-h-screen bg-gradient-to-br from-primary-50 via-white to-brand-blue/10 px-4 py-10">
    <div class="card mx-auto max-w-md text-center">
      <div class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-primary-100 text-3xl">
        {{ stateIcon }}
      </div>

      <h1 class="text-2xl font-bold text-gray-900">{{ title }}</h1>
      <p class="mt-3 text-sm leading-6 text-gray-500">{{ message }}</p>

      <div class="mt-6 flex flex-col gap-3 sm:flex-row sm:justify-center">
        <NuxtLink v-if="primaryAction" :to="primaryAction.to" class="btn-primary">
          {{ primaryAction.label }}
        </NuxtLink>
        <NuxtLink to="/" class="btn-secondary">
          Početna
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: false })

useSeoMeta({
  title: 'Verifikacija naloga — Šarena Sfera',
  description: 'Obrada verifikacije emaila i sigurnosnih auth linkova.',
})

const route = useRoute()
const { init, role } = useAuth()

const status = ref<'loading' | 'success' | 'recovery' | 'error'>('loading')
const title = ref('Provjeravamo link...')
const message = ref('Molimo sačekajte dok obradimo sigurnosni link i usmjerimo vas na odgovarajuću stranicu.')

const stateIcon = computed(() => {
  const icons = {
    loading: '⏳',
    success: '✅',
    recovery: '🔐',
    error: '⚠️',
  }
  return icons[status.value]
})

const primaryAction = computed(() => {
  if (status.value === 'recovery') {
    return { to: '/auth/reset-password', label: 'Postavi novu lozinku' }
  }

  if (status.value === 'success') {
    if (role.value === 'staff' || role.value === 'admin' || role.value === 'expert') {
      return { to: '/admin', label: 'Idi na admin' }
    }
    return { to: '/portal', label: 'Idi na portal' }
  }

  if (status.value === 'error') {
    return { to: '/auth/login', label: 'Nazad na prijavu' }
  }

  return null
})

onMounted(async () => {
  const type = typeof route.query.type === 'string' ? route.query.type : ''
  const errorDescription = typeof route.query.error_description === 'string'
    ? decodeURIComponent(route.query.error_description)
    : ''

  if (errorDescription) {
    status.value = 'error'
    title.value = 'Link nije validan'
    message.value = errorDescription
    return
  }

  await init()

  if (type === 'recovery') {
    status.value = 'recovery'
    title.value = 'Reset lozinke'
    message.value = 'Link je potvrđen. Nastavite na ekran za postavljanje nove lozinke.'
    return
  }

  status.value = 'success'
  title.value = 'Email je potvrđen'
  message.value = 'Vaš nalog je aktiviran. Nastavite u odgovarajući dio platforme.'
})
</script>
