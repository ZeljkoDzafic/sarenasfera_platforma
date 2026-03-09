<template>
  <div>
    <div v-if="event">
      <!-- Hero -->
      <section
        class="py-16 px-4 text-white"
        :style="{ background: `linear-gradient(135deg, ${domainColor}, #9b51e0)` }"
      >
        <div class="max-w-4xl mx-auto">
          <NuxtLink to="/events" class="inline-flex items-center gap-1 text-white/80 hover:text-white text-sm mb-6 transition-colors">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            Sve radionice
          </NuxtLink>

          <div class="flex items-center gap-3 mb-4">
            <span class="bg-white/20 text-white text-sm font-semibold px-3 py-1 rounded-full">
              {{ domainName }}
            </span>
            <span v-if="event.is_free" class="bg-brand-green/80 text-white text-sm font-semibold px-3 py-1 rounded-full">
              Besplatno
            </span>
          </div>

          <h1 class="font-display text-3xl md:text-4xl font-bold mb-4">{{ event.title }}</h1>
          <p class="text-white/90 text-lg">{{ event.short_desc }}</p>

          <!-- Quick info pills -->
          <div class="flex flex-wrap gap-3 mt-6">
            <div class="bg-white/15 rounded-xl px-4 py-2 text-sm">
              📅 {{ formatDate(event.starts_at) }}
            </div>
            <div class="bg-white/15 rounded-xl px-4 py-2 text-sm">
              🕙 {{ formatTime(event.starts_at) }} – {{ formatTime(event.ends_at) }}
            </div>
            <div class="bg-white/15 rounded-xl px-4 py-2 text-sm">
              👶 {{ event.age_min }}–{{ event.age_max }} godina
            </div>
            <div class="bg-white/15 rounded-xl px-4 py-2 text-sm">
              👥 {{ event.capacity }} mjesta
            </div>
          </div>
        </div>
      </section>

      <section class="py-12 px-4">
        <div class="max-w-5xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-8">

          <!-- Main content -->
          <div class="lg:col-span-2 space-y-6">
            <div class="card">
              <h2 class="font-display font-bold text-xl text-gray-900 mb-4">O radionici</h2>
              <p class="text-gray-700 leading-relaxed">{{ event.description }}</p>
            </div>

            <div class="card">
              <h2 class="font-display font-bold text-xl text-gray-900 mb-4">Lokacija</h2>
              <div class="flex items-start gap-3">
                <div class="w-10 h-10 rounded-xl bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  </svg>
                </div>
                <div>
                  <p class="font-semibold text-gray-900">{{ event.location }}</p>
                  <a v-if="event.location_url" :href="event.location_url" target="_blank" class="text-primary-600 text-sm hover:underline">
                    Otvori na mapi →
                  </a>
                </div>
              </div>
            </div>
          </div>

          <!-- Registration Card -->
          <div class="lg:col-span-1">
            <div class="card sticky top-6">
              <h2 class="font-display font-bold text-xl text-gray-900 mb-2">Prijavite dijete</h2>
              <p class="text-gray-500 text-sm mb-4">Popunite formu i mi ćemo vas kontaktirati za potvrdu.</p>

              <div v-if="registrationSuccess" class="text-center py-6">
                <div class="w-14 h-14 rounded-full bg-brand-green/10 flex items-center justify-center mx-auto mb-3">
                  <svg class="w-7 h-7 text-brand-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <h3 class="font-bold text-gray-900 mb-1">Prijava primljena!</h3>
                <p class="text-sm text-gray-600">Kontaktiraćemo vas uskoro za potvrdu.</p>
              </div>

              <form v-else class="space-y-3" @submit.prevent="register">
                <div>
                  <label class="label text-xs">Ime roditelja *</label>
                  <input v-model="regForm.parent_name" type="text" class="input text-sm" placeholder="Ime i prezime" required />
                </div>
                <div>
                  <label class="label text-xs">Email *</label>
                  <input v-model="regForm.parent_email" type="email" class="input text-sm" placeholder="vas@email.com" required />
                </div>
                <div>
                  <label class="label text-xs">Telefon</label>
                  <input v-model="regForm.parent_phone" type="tel" class="input text-sm" placeholder="+387 61..." />
                </div>
                <div>
                  <label class="label text-xs">Ime djeteta *</label>
                  <input v-model="regForm.child_name" type="text" class="input text-sm" placeholder="Ime djeteta" required />
                </div>
                <div>
                  <label class="label text-xs">Datum rođenja</label>
                  <input v-model="regForm.child_dob" type="date" class="input text-sm" />
                </div>
                <div>
                  <label class="label text-xs">Napomena</label>
                  <textarea v-model="regForm.notes" class="input text-sm" rows="2" placeholder="Alergije, posebne potrebe..." />
                </div>

                <button type="submit" class="btn-primary w-full" :disabled="regLoading">
                  {{ regLoading ? 'Šalje...' : 'Prijavi dijete' }}
                </button>
                <p v-if="regError" class="text-brand-red text-xs text-center">{{ regError }}</p>
              </form>

              <div class="mt-4 pt-4 border-t border-gray-100 text-center">
                <p class="text-xs text-gray-400">
                  Prijavom prihvatate naše
                  <NuxtLink to="/privacy" class="text-primary-500 hover:underline">uvjete korišćenja</NuxtLink>.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>

    <!-- 404 -->
    <div v-else class="py-24 text-center">
      <p class="text-6xl mb-4">📅</p>
      <h2 class="font-display font-bold text-2xl text-gray-900 mb-3">Radionica nije pronađena</h2>
      <NuxtLink to="/events" class="btn-primary">Sve radionice</NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
const route = useRoute()
const slug = route.params.slug as string

const supabase = useSupabase()

const { data: event } = await useAsyncData(`event-${slug}`, async () => {
  const { data } = await supabase
    .from('events')
    .select('*')
    .eq('slug', slug)
    .eq('is_published', true)
    .single()
  return data
})

const domains: Record<string, { name: string; color: string }> = {
  emotional: { name: 'Emocionalni razvoj', color: '#cf2e2e' },
  social: { name: 'Socijalni razvoj', color: '#fcb900' },
  creative: { name: 'Kreativni razvoj', color: '#9b51e0' },
  cognitive: { name: 'Kognitivni razvoj', color: '#0693e3' },
  motor: { name: 'Motorički razvoj', color: '#00d084' },
  language: { name: 'Jezički razvoj', color: '#f78da7' },
  all: { name: 'Svi domeni', color: '#9b51e0' },
}

const domainColor = computed(() => event.value ? (domains[event.value.domain]?.color ?? '#9b51e0') : '#9b51e0')
const domainName = computed(() => event.value ? (domains[event.value.domain]?.name ?? event.value.domain) : '')

if (event.value) {
  useSeoMeta({
    title: `${event.value.title} — Šarena Sfera`,
    description: event.value.short_desc ?? '',
    ogTitle: event.value.title,
  })
}

const regForm = reactive({
  parent_name: '',
  parent_email: '',
  parent_phone: '',
  child_name: '',
  child_dob: '',
  notes: '',
})

const regLoading = ref(false)
const registrationSuccess = ref(false)
const regError = ref('')

async function register() {
  if (!event.value) return
  regLoading.value = true
  regError.value = ''

  try {
    const { error } = await supabase.from('event_registrations').insert({
      event_id: event.value.id,
      parent_name: regForm.parent_name,
      parent_email: regForm.parent_email,
      parent_phone: regForm.parent_phone || null,
      child_name: regForm.child_name,
      child_dob: regForm.child_dob || null,
      notes: regForm.notes || null,
      source: 'website',
    })

    if (error) throw error
    registrationSuccess.value = true
  } catch {
    regError.value = 'Greška pri prijavi. Pokušajte ponovo ili nas kontaktirajte.'
  } finally {
    regLoading.value = false
  }
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })
}

function formatTime(iso: string): string {
  return new Date(iso).toLocaleTimeString('bs-BA', { hour: '2-digit', minute: '2-digit' })
}
</script>
