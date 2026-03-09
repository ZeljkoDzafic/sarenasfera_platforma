<template>
  <div class="max-w-4xl">
    <!-- Header -->
    <div class="mb-6">
      <NuxtLink to="/admin/events" class="text-sm text-gray-500 hover:text-gray-700 mb-2 inline-block">
        ← Nazad na događaje
      </NuxtLink>
      <h1 class="font-display text-2xl font-bold text-gray-900">Novi Događaj</h1>
      <p class="text-sm text-gray-500 mt-1">Kreirajte novi javni događaj ili radionicu</p>
    </div>

    <!-- Form -->
    <form @submit.prevent="handleSubmit" class="space-y-6">
      <!-- Basic Info Card -->
      <div class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Osnovne Informacije</h2>

        <div class="space-y-4">
          <!-- Title -->
          <div>
            <label class="label">Naziv događaja *</label>
            <input
              v-model="form.title"
              type="text"
              required
              class="input"
              placeholder="npr. Kreativna radionica: Proljeće u bojama"
            />
          </div>

          <!-- Slug -->
          <div>
            <label class="label">URL slug *</label>
            <input
              v-model="form.slug"
              type="text"
              required
              pattern="[a-z0-9-]+"
              class="input"
              placeholder="npr. kreativna-radionica-mart-2026"
            />
            <p class="text-xs text-gray-500 mt-1">
              URL: /events/{{ form.slug || 'url-slug' }}
            </p>
          </div>

          <!-- Short Description -->
          <div>
            <label class="label">Kratki opis</label>
            <input
              v-model="form.short_desc"
              type="text"
              class="input"
              placeholder="Kratak opis u jednoj rečenici (za karticu)"
            />
          </div>

          <!-- Full Description -->
          <div>
            <label class="label">Detaljan opis</label>
            <textarea
              v-model="form.description"
              rows="5"
              class="input"
              placeholder="Pun opis događaja koji će biti prikazan na detaljnoj stranici..."
            />
          </div>
        </div>
      </div>

      <!-- Date & Time Card -->
      <div class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Datum i Vrijeme</h2>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- Date -->
          <div>
            <label class="label">Datum *</label>
            <input
              v-model="form.date"
              type="date"
              required
              class="input"
            />
          </div>

          <!-- Start Time -->
          <div>
            <label class="label">Početak *</label>
            <input
              v-model="form.start_time"
              type="time"
              required
              class="input"
            />
          </div>

          <!-- End Time -->
          <div>
            <label class="label">Kraj *</label>
            <input
              v-model="form.end_time"
              type="time"
              required
              class="input"
            />
          </div>
        </div>
      </div>

      <!-- Location Card -->
      <div class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Lokacija</h2>

        <div class="space-y-4">
          <!-- Location Name -->
          <div>
            <label class="label">Naziv lokacije *</label>
            <input
              v-model="form.location"
              type="text"
              required
              class="input"
              placeholder="npr. Šarena Sfera Centar, Sarajevo"
            />
          </div>

          <!-- Google Maps URL -->
          <div>
            <label class="label">Google Maps link</label>
            <input
              v-model="form.location_url"
              type="url"
              class="input"
              placeholder="https://maps.google.com/..."
            />
          </div>
        </div>
      </div>

      <!-- Details Card -->
      <div class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Detalji</h2>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- Age Range -->
          <div>
            <label class="label">Minimalan uzrast (godine) *</label>
            <input
              v-model.number="form.age_min"
              type="number"
              min="1"
              max="10"
              required
              class="input"
            />
          </div>

          <div>
            <label class="label">Maksimalan uzrast (godine) *</label>
            <input
              v-model.number="form.age_max"
              type="number"
              min="1"
              max="10"
              required
              class="input"
            />
          </div>

          <!-- Capacity -->
          <div>
            <label class="label">Kapacitet (broj mjesta) *</label>
            <input
              v-model.number="form.capacity"
              type="number"
              min="1"
              required
              class="input"
            />
          </div>

          <!-- Domain -->
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

          <!-- Price -->
          <div>
            <label class="label">Cijena (KM)</label>
            <input
              v-model.number="form.price_km"
              type="number"
              step="0.01"
              min="0"
              class="input"
            />
            <div class="mt-2">
              <label class="flex items-center gap-2">
                <input
                  v-model="form.is_free"
                  type="checkbox"
                  class="w-4 h-4 text-primary-600 rounded focus:ring-primary-500"
                />
                <span class="text-sm text-gray-700">Besplatan događaj</span>
              </label>
            </div>
          </div>

          <!-- Image URL -->
          <div class="md:col-span-2">
            <label class="label">URL slike</label>
            <input
              v-model="form.image_url"
              type="url"
              class="input"
              placeholder="https://..."
            />
            <p class="text-xs text-gray-500 mt-1">
              URL javne slike (npr. iz Unsplash ili uploaded na storage)
            </p>
          </div>
        </div>
      </div>

      <!-- Publishing Options -->
      <div class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Opcije Objavljivanja</h2>

        <div class="space-y-3">
          <label class="flex items-start gap-3">
            <input
              v-model="form.is_published"
              type="checkbox"
              class="w-5 h-5 text-primary-600 rounded focus:ring-primary-500 mt-0.5"
            />
            <div>
              <span class="text-sm font-semibold text-gray-900">Objavi odmah</span>
              <p class="text-xs text-gray-500">Događaj će biti vidljiv javno na /events stranici</p>
            </div>
          </label>

          <label class="flex items-start gap-3">
            <input
              v-model="form.is_active"
              type="checkbox"
              class="w-5 h-5 text-primary-600 rounded focus:ring-primary-500 mt-0.5"
            />
            <div>
              <span class="text-sm font-semibold text-gray-900">Aktivan</span>
              <p class="text-xs text-gray-500">Deaktivirani događaji se ne prikazuju čak ni adminu</p>
            </div>
          </label>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex flex-col sm:flex-row gap-3">
        <button
          type="submit"
          :disabled="submitting"
          class="btn-primary"
        >
          {{ submitting ? 'Kreiranje...' : '✅ Kreiraj događaj' }}
        </button>
        <NuxtLink to="/admin/events" class="btn-secondary text-center">
          Otkaži
        </NuxtLink>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
// T-832: Admin Events Management — New Event Page
// Form for creating new public events/workshops

definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Novi Događaj — Admin — Šarena Sfera' })

const supabase = useSupabase()
const router = useRouter()

const submitting = ref(false)

const form = reactive({
  title: '',
  slug: '',
  short_desc: '',
  description: '',
  date: '',
  start_time: '',
  end_time: '',
  location: 'Šarena Sfera Centar, Sarajevo',
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

// Auto-generate slug from title
watch(() => form.title, (newTitle) => {
  if (!form.slug) {
    form.slug = newTitle
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .trim()
  }
})

async function handleSubmit() {
  submitting.value = true

  try {
    // Combine date + time
    const starts_at = new Date(`${form.date}T${form.start_time}:00`).toISOString()
    const ends_at = new Date(`${form.date}T${form.end_time}:00`).toISOString()

    const { data, error } = await supabase
      .from('events')
      .insert({
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
      })
      .select()
      .single()

    if (error) throw error

    alert('Događaj uspješno kreiran!')
    router.push(`/admin/events/${data.id}`)
  } catch (err: any) {
    console.error('Failed to create event:', err)
    alert(`Greška: ${err.message}`)
  } finally {
    submitting.value = false
  }
}
</script>
