<template>
  <div class="min-h-screen bg-gradient-to-br from-purple-50 to-white py-12 px-4">
    <div class="max-w-xl mx-auto">
      <!-- Back link -->
      <NuxtLink :to="`/events/${slug}`" class="flex items-center gap-2 text-gray-500 hover:text-gray-700 text-sm mb-6">
        ← Nazad na detalje
      </NuxtLink>

      <!-- Success state -->
      <div v-if="success" class="card text-center py-12">
        <div class="text-6xl mb-4">🎉</div>
        <h1 class="font-display text-3xl font-bold text-gray-900 mb-3">Uspješna prijava!</h1>
        <p class="text-gray-600 mb-2">
          <strong>{{ form.parent_name }}</strong>, vaše dijete <strong>{{ form.child_name }}</strong>
          je prijavljeno na radionicu.
        </p>
        <div v-if="registrationStatus === 'waitlist'" class="mt-4 p-3 bg-brand-amber/10 border border-brand-amber/20 rounded-xl">
          <p class="text-sm font-semibold text-brand-amber">⏳ Lista čekanja</p>
          <p class="text-xs text-gray-600 mt-1">Radionica je popunjena. Dodani ste na listu čekanja i bit ćete obaviješteni ako se oslobodi mjesto.</p>
        </div>
        <div class="mt-6 p-4 bg-gray-50 rounded-xl text-left text-sm">
          <p class="font-semibold text-gray-900 mb-2">📧 Provjerite email</p>
          <p class="text-gray-600">Poslali smo potvrdu na <strong>{{ form.parent_email }}</strong> s detaljima radionice i pristupnim podacima za vaš nalog.</p>
        </div>
        <div class="flex gap-3 mt-8">
          <NuxtLink to="/auth/login" class="btn-primary flex-1">Prijavite se →</NuxtLink>
          <NuxtLink to="/events" class="btn-secondary flex-1">Sve radionice</NuxtLink>
        </div>
      </div>

      <!-- Registration form -->
      <div v-else>
        <!-- Event summary -->
        <div v-if="event" class="card mb-6 border-l-4 border-primary-500">
          <p class="text-xs font-semibold text-primary-600 uppercase tracking-wide mb-1">Prijava na radionicu</p>
          <h2 class="font-display font-bold text-xl text-gray-900">{{ event.title }}</h2>
          <div class="flex flex-wrap gap-3 mt-2 text-sm text-gray-500">
            <span>📅 {{ formatDate(event.event_date) }}</span>
            <span>🕐 {{ event.start_time?.slice(0,5) }}</span>
            <span>📍 {{ event.location }}</span>
            <span :class="spotsLeft <= 3 ? 'text-brand-red font-semibold' : ''">
              🪑 {{ spotsLeft }} mjesta
            </span>
          </div>
        </div>

        <!-- Already have account -->
        <div class="card mb-6 bg-gray-50 border-dashed border-gray-200">
          <p class="text-sm text-gray-600">
            Već imate nalog?
            <NuxtLink :to="`/auth/login?redirect=/events/${slug}`" class="text-primary-600 hover:underline font-semibold ml-1">
              Prijavite se ovdje →
            </NuxtLink>
          </p>
        </div>

        <div v-if="error" class="p-3 mb-4 bg-brand-red/10 border border-brand-red/20 rounded-xl text-brand-red text-sm">
          {{ error }}
        </div>

        <form class="space-y-6" @submit.prevent="submit">
          <!-- Parent info -->
          <div class="card space-y-4">
            <h3 class="font-display font-bold text-lg text-gray-900">Podaci o roditelju / skrbniku</h3>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label class="label">Ime i prezime *</label>
                <input v-model="form.parent_name" type="text" class="input" required placeholder="Vaše ime i prezime" />
              </div>
              <div>
                <label class="label">Telefon</label>
                <input v-model="form.parent_phone" type="tel" class="input" placeholder="+387 61 123 456" />
              </div>
            </div>

            <div>
              <label class="label">Email adresa *</label>
              <input v-model="form.parent_email" type="email" class="input" required placeholder="vas@email.com" />
              <p class="text-xs text-gray-400 mt-1">Na ovu adresu šaljemo potvrdu i pristupne podatke.</p>
            </div>
          </div>

          <!-- Child info -->
          <div class="card space-y-4">
            <h3 class="font-display font-bold text-lg text-gray-900">Podaci o djetetu</h3>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label class="label">Ime djeteta *</label>
                <input v-model="form.child_name" type="text" class="input" required placeholder="Ime djeteta" />
              </div>
              <div>
                <label class="label">Datum rođenja *</label>
                <input v-model="form.child_dob" type="date" class="input" required :max="maxChildDob" :min="minChildDob" />
              </div>
            </div>

            <div>
              <label class="label">Alergije ili posebne napomene</label>
              <textarea v-model="form.allergies" class="input" rows="2" placeholder="Alergije na hranu, lijekovi, posebne potrebe..." />
            </div>
          </div>

          <!-- Consent -->
          <div class="card space-y-3">
            <h3 class="font-display font-bold text-lg text-gray-900">Saglasnost</h3>

            <label class="flex items-start gap-3 cursor-pointer">
              <input v-model="form.consent_terms" type="checkbox" class="rounded mt-0.5 flex-shrink-0" required />
              <span class="text-sm text-gray-600">
                Prihvatam <a href="/terms" target="_blank" class="text-primary-600 underline">Uslove korištenja</a> i
                <a href="/privacy" target="_blank" class="text-primary-600 underline">Politiku privatnosti</a> platforme Sarena Sfera. *
              </span>
            </label>

            <label class="flex items-start gap-3 cursor-pointer">
              <input v-model="form.consent_photos" type="checkbox" class="rounded mt-0.5 flex-shrink-0" />
              <span class="text-sm text-gray-600">
                Slažem se da se fotografije i videi s radionice koriste u edukativne i marketinške svrhe. (Opcionalno)
              </span>
            </label>

            <label class="flex items-start gap-3 cursor-pointer">
              <input v-model="form.newsletter" type="checkbox" class="rounded mt-0.5 flex-shrink-0" />
              <span class="text-sm text-gray-600">
                Želim primati newsletter s informacijama o novim radionicama i razvojnim savjetima.
              </span>
            </label>
          </div>

          <!-- Submit -->
          <button
            type="submit"
            class="btn-primary w-full py-4 text-lg"
            :disabled="submitting || !form.consent_terms"
          >
            <span v-if="submitting">Prijavljujem... ⏳</span>
            <span v-else-if="spotsLeft === 0">Pridruži se listi čekanja 📋</span>
            <span v-else>Prijavi se na radionicu 🎉</span>
          </button>

          <p class="text-center text-xs text-gray-400">
            Kreiraćemo vam nalog na platformi. Lozinku možete postaviti putem linka koji dobijete na email.
          </p>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: false })

const route = useRoute()
const slug = route.params.slug as string

const supabase = useSupabase()

const success = ref(false)
const submitting = ref(false)
const error = ref('')
const registrationStatus = ref<'confirmed' | 'waitlist'>('confirmed')

const form = reactive({
  parent_name: '',
  parent_email: '',
  parent_phone: '',
  child_name: '',
  child_dob: '',
  allergies: '',
  consent_terms: false,
  consent_photos: false,
  newsletter: false,
})

// Child age constraints: 2–6 years
const maxChildDob = computed(() => {
  const d = new Date()
  d.setFullYear(d.getFullYear() - 2)
  return d.toISOString().slice(0, 10)
})
const minChildDob = computed(() => {
  const d = new Date()
  d.setFullYear(d.getFullYear() - 7)
  return d.toISOString().slice(0, 10)
})

const { data: event } = await useAsyncData(`event-register-${slug}`, async () => {
  const { data } = await supabase
    .from('events')
    .select('id, title, event_date, start_time, location, max_spots, spots_taken, age_min, age_max, price')
    .eq('slug', slug)
    .single()
  return data
})

useSeoMeta({
  title: computed(() => event.value ? `Prijava — ${event.value.title}` : 'Prijava na radionicu'),
})

const spotsLeft = computed(() => {
  if (!event.value?.max_spots) return 999
  return Math.max(0, event.value.max_spots - (event.value.spots_taken ?? 0))
})

async function submit() {
  if (!form.consent_terms) return
  submitting.value = true
  error.value = ''

  try {
    if (!event.value) throw new Error('Radionica nije pronađena.')

    const isWaitlist = spotsLeft.value === 0
    const status = isWaitlist ? 'waitlist' : 'confirmed'

    // 1. Check if parent profile exists
    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('id')
      .eq('email', form.parent_email)
      .single()

    let parentId: string | null = existingProfile?.id ?? null

    // 2. Create auth user if doesn't exist (send magic link)
    if (!parentId) {
      const { data: authData, error: authErr } = await supabase.auth.signInWithOtp({
        email: form.parent_email,
        options: {
          data: { full_name: form.parent_name, role: 'parent' },
          shouldCreateUser: true,
        },
      })
      if (authErr) throw new Error(authErr.message)
      // Profile will be auto-created by trigger; we'll rely on email for lookup
    }

    // 3. Create child record
    const childId = crypto.randomUUID()

    const { error: childErr } = await supabase
      .from('children')
      .insert({
        id: childId,
        full_name: form.child_name,
        date_of_birth: form.child_dob,
        allergies: form.allergies || null,
        is_active: true,
      })

    if (childErr) throw new Error(childErr?.message ?? 'Greška pri kreiranju profila djeteta.')

    // 4. Create event registration
    const { error: regErr } = await supabase
      .from('event_registrations')
      .insert({
        event_id: event.value.id,
        child_name: form.child_name,
        child_dob: form.child_dob,
        parent_name: form.parent_name,
        parent_email: form.parent_email,
        parent_phone: form.parent_phone || null,
        allergies: form.allergies || null,
        consent_photos: form.consent_photos,
        status,
      })

    if (regErr) throw new Error(regErr.message)

    // 5. Update spots_taken if confirmed
    if (!isWaitlist) {
      await supabase
        .from('events')
        .update({ spots_taken: (event.value.spots_taken ?? 0) + 1 })
        .eq('id', event.value.id)
    }

    // 6. Save to leads if newsletter opt-in
    if (form.newsletter) {
      await supabase.from('leads').upsert({
        email: form.parent_email,
        name: form.parent_name,
        phone: form.parent_phone || null,
        source: 'event_registration',
        newsletter_consent: true,
      }, { onConflict: 'email' })
    }

    registrationStatus.value = status
    success.value = true
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'Neočekivana greška. Pokušajte ponovo.'
  } finally {
    submitting.value = false
  }
}

function formatDate(iso?: string): string {
  if (!iso) return '—'
  return new Date(iso).toLocaleDateString('bs-BA', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })
}
</script>
