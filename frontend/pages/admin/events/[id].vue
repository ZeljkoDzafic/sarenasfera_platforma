<template>
  <div class="max-w-4xl">
    <!-- Loading State -->
    <div v-if="loading" class="space-y-4">
      <div class="h-10 bg-gray-100 rounded-xl animate-pulse" />
      <div class="card h-64 bg-gray-100 animate-pulse" />
    </div>

    <!-- Event Edit Form -->
    <div v-else-if="event">
      <!-- Header -->
      <div class="mb-6 flex items-start justify-between gap-4">
        <div>
          <NuxtLink to="/admin/events" class="text-sm text-gray-500 hover:text-gray-700 mb-2 inline-block">
            ← Nazad na događaje
          </NuxtLink>
          <h1 class="font-display text-2xl font-bold text-gray-900">Uredi Događaj</h1>
          <p class="text-sm text-gray-500 mt-1">{{ event.title }}</p>
        </div>
        <div class="flex gap-2">
          <NuxtLink :to="`/admin/events/${event.id}/registrations`" class="btn-secondary text-sm">
            📋 Prijave
          </NuxtLink>
          <button @click="handleDelete" class="btn-danger text-sm">
            🗑️ Obriši
          </button>
        </div>
      </div>

      <!-- Form (Same structure as new.vue, but with event data) -->
      <form @submit.prevent="handleSubmit" class="space-y-6">
        <!-- Basic Info Card -->
        <div class="card">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Osnovne Informacije</h2>

          <div class="space-y-4">
            <div>
              <label class="label">Naziv događaja *</label>
              <input v-model="form.title" type="text" required class="input" />
            </div>

            <div>
              <label class="label">URL slug *</label>
              <input v-model="form.slug" type="text" required pattern="[a-z0-9-]+" class="input" />
              <p class="text-xs text-gray-500 mt-1">URL: /events/{{ form.slug }}</p>
            </div>

            <div>
              <label class="label">Kratki opis</label>
              <input v-model="form.short_desc" type="text" class="input" />
            </div>

            <div>
              <label class="label">Detaljan opis</label>
              <textarea v-model="form.description" rows="5" class="input" />
            </div>
          </div>
        </div>

        <!-- Date & Time Card -->
        <div class="card">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Datum i Vrijeme</h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="label">Datum *</label>
              <input v-model="form.date" type="date" required class="input" />
            </div>

            <div>
              <label class="label">Početak *</label>
              <input v-model="form.start_time" type="time" required class="input" />
            </div>

            <div>
              <label class="label">Kraj *</label>
              <input v-model="form.end_time" type="time" required class="input" />
            </div>
          </div>
        </div>

        <!-- Location Card -->
        <div class="card">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Lokacija</h2>

          <div class="space-y-4">
            <div>
              <label class="label">Naziv lokacije *</label>
              <input v-model="form.location" type="text" required class="input" />
            </div>

            <div>
              <label class="label">Google Maps link</label>
              <input v-model="form.location_url" type="url" class="input" />
            </div>
          </div>
        </div>

        <!-- Details Card -->
        <div class="card">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Detalji</h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="label">Minimalan uzrast (godine) *</label>
              <input v-model.number="form.age_min" type="number" min="1" max="10" required class="input" />
            </div>

            <div>
              <label class="label">Maksimalan uzrast (godine) *</label>
              <input v-model.number="form.age_max" type="number" min="1" max="10" required class="input" />
            </div>

            <div>
              <label class="label">Kapacitet (broj mjesta) *</label>
              <input v-model.number="form.capacity" type="number" min="1" required class="input" />
            </div>

            <div>
              <label class="label">Razvojna domena</label>
              <select v-model="form.domain" class="input">
                <option value="all">Sve domene</option>
                <option value="emotional">Emocionalni razvoj</option>
                <option value="social">Socijalni razvoj</option>
                <option value="creative">Kreativni razvoj</option>
                <option value="cognitive">Kognitivni razvoj</option>
                <option value="motor">Motorički razvoj</option>
                <option value="language">Jezički razvoj</option>
              </select>
            </div>

            <div>
              <label class="label">Cijena (KM)</label>
              <input v-model.number="form.price_km" type="number" step="0.01" min="0" class="input" />
              <div class="mt-2">
                <label class="flex items-center gap-2">
                  <input v-model="form.is_free" type="checkbox" class="w-4 h-4 text-primary-600 rounded" />
                  <span class="text-sm text-gray-700">Besplatan događaj</span>
                </label>
              </div>
            </div>

            <div class="md:col-span-2">
              <label class="label">URL slike</label>
              <input v-model="form.image_url" type="url" class="input" />
            </div>
          </div>
        </div>

        <!-- Publishing Options -->
        <div class="card">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Opcije Objavljivanja</h2>

          <div class="space-y-3">
            <label class="flex items-start gap-3">
              <input v-model="form.is_published" type="checkbox" class="w-5 h-5 text-primary-600 rounded mt-0.5" />
              <div>
                <span class="text-sm font-semibold text-gray-900">Objavi odmah</span>
                <p class="text-xs text-gray-500">Događaj će biti vidljiv javno na /events stranici</p>
              </div>
            </label>

            <label class="flex items-start gap-3">
              <input v-model="form.is_active" type="checkbox" class="w-5 h-5 text-primary-600 rounded mt-0.5" />
              <div>
                <span class="text-sm font-semibold text-gray-900">Aktivan</span>
                <p class="text-xs text-gray-500">Deaktivirani događaji se ne prikazuju</p>
              </div>
            </label>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex flex-col sm:flex-row gap-3">
          <button type="submit" :disabled="submitting" class="btn-primary">
            {{ submitting ? 'Ažuriranje...' : '✅ Sačuvaj promjene' }}
          </button>
          <NuxtLink to="/admin/events" class="btn-secondary text-center">
            Otkaži
          </NuxtLink>
        </div>
      </form>
    </div>

    <!-- Not Found -->
    <div v-else class="card text-center py-12">
      <p class="text-gray-500">Događaj nije pronađen.</p>
      <NuxtLink to="/admin/events" class="btn-primary mt-4 inline-block">
        Nazad na događaje
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
// T-832: Admin Events Management — Edit Event Page
// Edit existing event details

definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Uredi Događaj — Admin — Šarena Sfera' })

const supabase = useSupabase()
const route = useRoute()
const router = useRouter()

const eventId = route.params.id as string

const loading = ref(true)
const submitting = ref(false)
const event = ref<any>(null)

const form = reactive({
  title: '',
  slug: '',
  short_desc: '',
  description: '',
  date: '',
  start_time: '',
  end_time: '',
  location: '',
  location_url: '',
  age_min: 2,
  age_max: 6,
  capacity: 20,
  domain: 'all',
  price_km: 0,
  is_free: true,
  image_url: '',
  is_published: false,
  is_active: true,
})

async function loadEvent() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('events')
      .select('*')
      .eq('id', eventId)
      .single()

    if (error) throw error
    event.value = data

    // Populate form
    const startsAt = new Date(data.starts_at)
    const endsAt = new Date(data.ends_at)

    form.title = data.title
    form.slug = data.slug
    form.short_desc = data.short_desc || ''
    form.description = data.description || ''
    form.date = startsAt.toISOString().split('T')[0]
    form.start_time = startsAt.toTimeString().slice(0, 5)
    form.end_time = endsAt.toTimeString().slice(0, 5)
    form.location = data.location
    form.location_url = data.location_url || ''
    form.age_min = data.age_min
    form.age_max = data.age_max
    form.capacity = data.capacity
    form.domain = data.domain || 'all'
    form.price_km = data.price_km || 0
    form.is_free = data.is_free
    form.image_url = data.image_url || ''
    form.is_published = data.is_published
    form.is_active = data.is_active
  } catch (err) {
    console.error('Failed to load event:', err)
  } finally {
    loading.value = false
  }
}

async function handleSubmit() {
  submitting.value = true

  try {
    const starts_at = new Date(`${form.date}T${form.start_time}:00`).toISOString()
    const ends_at = new Date(`${form.date}T${form.end_time}:00`).toISOString()

    const { error } = await supabase
      .from('events')
      .update({
        title: form.title,
        slug: form.slug,
        short_desc: form.short_desc || null,
        description: form.description || null,
        starts_at,
        ends_at,
        location: form.location,
        location_url: form.location_url || null,
        age_min: form.age_min,
        age_max: form.age_max,
        capacity: form.capacity,
        domain: form.domain,
        price_km: form.is_free ? 0 : form.price_km,
        is_free: form.is_free,
        image_url: form.image_url || null,
        is_published: form.is_published,
        is_active: form.is_active,
        updated_at: new Date().toISOString(),
      })
      .eq('id', eventId)

    if (error) throw error

    alert('Događaj uspješno ažuriran!')
    router.push('/admin/events')
  } catch (err: any) {
    console.error('Failed to update event:', err)
    alert(`Greška: ${err.message}`)
  } finally {
    submitting.value = false
  }
}

async function handleDelete() {
  if (!confirm('Da li ste sigurni da želite obrisati ovaj događaj? Ova akcija je nepovratna.')) return

  try {
    const { error } = await supabase
      .from('events')
      .delete()
      .eq('id', eventId)

    if (error) throw error

    alert('Događaj obrisan.')
    router.push('/admin/events')
  } catch (err: any) {
    console.error('Failed to delete event:', err)
    alert(`Greška: ${err.message}`)
  }
}

onMounted(() => {
  loadEvent()
})
</script>
