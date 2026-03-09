<template>
  <div class="min-h-screen bg-gradient-to-b from-white via-primary-50/50 to-brand-amber/10 px-4 py-10">
    <div class="mx-auto grid max-w-6xl gap-8 lg:grid-cols-[1fr_1.1fr]">
      <section class="card order-2 lg:order-1">
        <p class="text-sm font-semibold uppercase tracking-[0.2em] text-primary-600">Šta dobijate</p>
        <h1 class="mt-3 text-3xl font-bold text-gray-900">Jedan nalog za kompletan put roditelja.</h1>

        <div class="mt-6 grid gap-4">
          <div class="rounded-2xl bg-primary-50 p-4">
            <p class="font-semibold text-gray-900">Besplatni ulaz</p>
            <p class="mt-1 text-sm text-gray-600">Pratite radionice, registrujte dijete i upoznajte platformu bez rizika.</p>
          </div>
          <div class="rounded-2xl bg-brand-green/10 p-4">
            <p class="font-semibold text-gray-900">Dječiji pasoš</p>
            <p class="mt-1 text-sm text-gray-600">Kada aktivirate plaćeni plan, pratite razvoj kroz 6 domena i opservacije.</p>
          </div>
          <div class="rounded-2xl bg-brand-amber/10 p-4">
            <p class="font-semibold text-gray-900">Brži onboarding</p>
            <p class="mt-1 text-sm text-gray-600">Možete odmah dodati prvo dijete i preskočiti kasniji ručni unos.</p>
          </div>
        </div>
      </section>

      <section class="card order-1 lg:order-2">
        <NuxtLink to="/" class="mb-6 inline-flex items-center gap-2 text-sm font-semibold text-gray-500 hover:text-primary-600">
          ← Nazad na početnu
        </NuxtLink>

        <div class="mb-6">
          <div class="mb-3 flex flex-wrap gap-2">
            <span class="badge-free">Plan: {{ selectedTierLabel }}</span>
            <span v-if="referralCode" class="badge-paid">Referral: {{ referralCode }}</span>
          </div>
          <h2 class="text-3xl font-bold text-gray-900">Registracija</h2>
          <p class="mt-2 text-sm text-gray-500">Kreirajte roditeljski nalog i pripremite prvi pristup portalu.</p>
        </div>

        <div
          v-if="error"
          class="mb-4 rounded-xl border border-brand-red/20 bg-brand-red/10 px-4 py-3 text-sm text-brand-red"
        >
          {{ error }}
        </div>

        <div
          v-if="successMessage"
          class="mb-4 rounded-xl border border-brand-green/20 bg-brand-green/10 px-4 py-3 text-sm text-brand-green"
        >
          {{ successMessage }}
        </div>

        <form class="space-y-5" @submit.prevent="handleRegister">
          <div class="grid gap-4 sm:grid-cols-2">
            <div class="sm:col-span-2">
              <label class="label" for="full-name">Ime i prezime</label>
              <input id="full-name" v-model="form.fullName" type="text" class="input" required />
            </div>
            <div>
              <label class="label" for="email">Email</label>
              <input id="email" v-model="form.email" type="email" class="input" autocomplete="email" required />
            </div>
            <div>
              <label class="label" for="phone">Telefon</label>
              <input id="phone" v-model="form.phone" type="tel" class="input" autocomplete="tel" />
            </div>
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <div>
              <label class="label" for="password">Lozinka</label>
              <input id="password" v-model="form.password" type="password" class="input" minlength="8" required />
            </div>
            <div>
              <label class="label" for="password-confirm">Potvrdite lozinku</label>
              <input id="password-confirm" v-model="form.confirmPassword" type="password" class="input" minlength="8" required />
            </div>
          </div>

          <div class="rounded-2xl border border-primary-100 bg-gray-50 p-4">
            <div class="mb-3 flex items-center justify-between gap-3">
              <div>
                <p class="font-semibold text-gray-900">Dodajte prvo dijete</p>
                <p class="text-sm text-gray-500">Opcionalno, ali ubrzava početni onboarding.</p>
              </div>
              <button type="button" class="btn-ghost px-3 py-2 text-xs" @click="showChildFields = !showChildFields">
                {{ showChildFields ? 'Sakrij' : 'Dodaj' }}
              </button>
            </div>

            <div v-if="showChildFields" class="grid gap-4 sm:grid-cols-2">
              <div>
                <label class="label" for="child-name">Ime djeteta</label>
                <input id="child-name" v-model="form.childName" type="text" class="input" />
              </div>
              <div>
                <label class="label" for="child-dob">Datum rođenja</label>
                <input id="child-dob" v-model="form.childDob" type="date" class="input" />
              </div>
            </div>
          </div>

          <div class="space-y-3">
            <label class="flex items-start gap-3 text-sm text-gray-600">
              <input v-model="form.acceptTerms" type="checkbox" class="mt-1 rounded" required />
              <span>
                Prihvatam <NuxtLink to="/terms" class="font-semibold text-primary-600 hover:text-primary-700">Uslove korištenja</NuxtLink>
                i <NuxtLink to="/privacy" class="font-semibold text-primary-600 hover:text-primary-700">Politiku privatnosti</NuxtLink>.
              </span>
            </label>

            <label class="flex items-start gap-3 text-sm text-gray-600">
              <input v-model="form.newsletter" type="checkbox" class="mt-1 rounded" />
              <span>Želim primati korisne savjete, novosti o radionicama i obavijesti o novim terminima.</span>
            </label>
          </div>

          <button type="submit" class="btn-primary w-full" :disabled="submitting">
            {{ submitting ? 'Kreiranje naloga...' : 'Kreiraj nalog' }}
          </button>
        </form>

        <p class="mt-6 text-center text-sm text-gray-500">
          Već imate nalog?
          <NuxtLink :to="loginLink" class="font-semibold text-primary-600 hover:text-primary-700">Prijavite se</NuxtLink>
        </p>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'guest' })

useSeoMeta({
  title: 'Registracija — Šarena Sfera',
  description: 'Kreirajte roditeljski nalog za pristup Šarena Sfera portalu.',
})

const route = useRoute()
const supabase = useSupabase()
const { signUp, init, user } = useAuth()

const selectedTier = computed(() => {
  const tier = typeof route.query.tier === 'string' ? route.query.tier.toLowerCase() : 'free'
  return ['free', 'paid', 'premium'].includes(tier) ? tier : 'free'
})

const selectedTierLabel = computed(() => {
  const labels: Record<string, string> = {
    free: 'Besplatni',
    paid: 'Osnovni',
    premium: 'Premium',
  }
  return labels[selectedTier.value] ?? 'Besplatni'
})

const referralCode = computed(() => typeof route.query.ref === 'string' ? route.query.ref : '')

const form = reactive({
  fullName: '',
  email: '',
  phone: '',
  password: '',
  confirmPassword: '',
  childName: '',
  childDob: '',
  acceptTerms: false,
  newsletter: true,
})

const showChildFields = ref(Boolean(route.query.child))
const submitting = ref(false)
const error = ref('')
const successMessage = ref('')

const loginLink = computed(() => {
  const params = new URLSearchParams()
  params.set('email', form.email || '')
  return `/auth/login?${params.toString()}`
})

async function createChildForParent(parentId: string) {
  if (!form.childName || !form.childDob) return

  const { data: child, error: childError } = await supabase
    .from('children')
    .insert({
      full_name: form.childName,
      date_of_birth: form.childDob,
      is_active: true,
    })
    .select('id')
    .single()

  if (childError || !child) {
    throw new Error(childError?.message ?? 'Nije moguće kreirati profil djeteta.')
  }

  const { error: relationError } = await supabase
    .from('parent_children')
    .insert({
      parent_id: parentId,
      child_id: child.id,
      relationship: 'parent',
      is_primary: true,
      can_pickup: true,
    })

  if (relationError) {
    throw new Error(relationError.message)
  }
}

async function handleRegister() {
  error.value = ''
  successMessage.value = ''

  if (form.password !== form.confirmPassword) {
    error.value = 'Lozinke se ne podudaraju.'
    return
  }

  submitting.value = true

  try {
    const { data } = await signUp(form.email, form.password, {
      full_name: form.fullName,
      role: 'parent',
      tier_intent: selectedTier.value,
      referral_code: referralCode.value || null,
      newsletter_opt_in: form.newsletter,
    })

    await init()

    const currentUserId = data.user?.id ?? user.value?.id

    if (currentUserId) {
      await supabase
        .from('profiles')
        .update({
          full_name: form.fullName,
          phone: form.phone || null,
        })
        .eq('id', currentUserId)

      await createChildForParent(currentUserId)

      await navigateTo('/portal')
      return
    }

    successMessage.value = 'Nalog je kreiran. Provjerite email za potvrdu naloga, a zatim se prijavite.'
    await navigateTo(`/auth/login?registered=1&email=${encodeURIComponent(form.email)}`)
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Registracija nije uspjela. Pokušajte ponovo.'
  } finally {
    submitting.value = false
  }
}
</script>
