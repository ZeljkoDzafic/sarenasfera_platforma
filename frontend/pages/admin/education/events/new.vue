<template>
  <div class="max-w-6xl space-y-6">
    <div>
      <NuxtLink to="/admin/education" class="text-sm text-gray-500 hover:text-gray-700">← Nazad na edukaciju</NuxtLink>
      <h1 class="mt-2 font-display text-2xl font-bold text-gray-900">{{ isEditing ? 'Uredi event' : 'Novi event / webinar' }}</h1>
    </div>

    <form class="grid gap-6 xl:grid-cols-[1.1fr_0.9fr]" @submit.prevent="saveEvent">
      <div class="space-y-6">
        <section class="card space-y-4">
          <h2 class="font-display font-bold text-lg text-gray-900">Osnovno</h2>
          <input v-model="form.title" class="input" placeholder="Naziv" required />
          <input v-model="form.slug" class="input" placeholder="Slug" required />
          <textarea v-model="form.description" class="input" rows="4" placeholder="Opis" />
          <div class="grid gap-4 sm:grid-cols-2">
            <select v-model="form.event_subtype" class="input">
              <option value="workshop">Offline radionica</option>
              <option value="webinar">Webinar</option>
              <option value="event">Offline događaj</option>
              <option value="open_day">Open day</option>
            </select>
            <select v-model="form.required_tier" class="input">
              <option value="free">Free</option>
              <option value="paid">Paid</option>
              <option value="premium">Premium</option>
            </select>
            <input v-model="form.starts_at" type="datetime-local" class="input" />
            <input v-model="form.ends_at" type="datetime-local" class="input" />
            <input v-model="form.location_name" class="input" placeholder="Lokacija / Zoom naziv" />
            <input v-model="form.location_url" class="input" placeholder="Link / mapa" />
            <input v-model="form.external_registration_url" class="input" placeholder="Eksterni registration URL" />
            <input v-model.number="form.capacity" type="number" min="0" class="input" placeholder="Kapacitet" />
            <select v-model="form.status" class="input">
              <option value="draft">Draft</option>
              <option value="published">Published</option>
              <option value="archived">Archived</option>
            </select>
          </div>
        </section>

        <section v-if="registrations.length > 0" class="card space-y-4">
          <div class="flex items-center justify-between">
            <h2 class="font-display font-bold text-lg text-gray-900">Registracije</h2>
            <span class="badge bg-primary-50 text-primary-700">{{ registrations.length }}</span>
          </div>
          <article v-for="registration in registrations" :key="registration.id" class="rounded-2xl bg-gray-50 p-4">
            <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
              <div>
                <p class="font-semibold text-gray-900">{{ registration.userLabel }}</p>
                <p class="text-sm text-gray-500">{{ registration.status }}</p>
              </div>
              <div class="flex flex-wrap gap-2">
                <button type="button" class="btn-secondary text-sm" @click="updateRegistrationStatus(registration.id, 'confirmed')">Potvrdi</button>
                <button type="button" class="btn-secondary text-sm" @click="updateRegistrationStatus(registration.id, 'waitlist')">Waitlist</button>
                <button type="button" class="btn-secondary text-sm" @click="updateRegistrationStatus(registration.id, 'cancelled')">Otkaži</button>
              </div>
            </div>
          </article>
        </section>
      </div>

      <div class="space-y-6">
        <section class="card">
          <h2 class="font-display font-bold text-lg text-gray-900">Preview</h2>
          <div class="mt-4 rounded-2xl bg-gray-50 p-4">
            <h3 class="font-semibold text-gray-900">{{ form.title || 'Naziv eventa' }}</h3>
            <p class="mt-2 text-sm text-gray-600">{{ form.description || 'Opis eventa.' }}</p>
            <p class="mt-3 text-xs text-gray-500">{{ form.starts_at || 'Bez termina' }} • {{ form.location_name || 'Bez lokacije' }}</p>
          </div>
          <NuxtLink
            v-if="form.slug"
            :to="`/events/${form.slug}`"
            target="_blank"
            class="btn-secondary mt-4 block w-full text-center"
          >
            Otvori preview
          </NuxtLink>
        </section>
        <section class="card">
          <button type="submit" class="btn-primary w-full" :disabled="saving">
            {{ saving ? 'Čuvam...' : (isEditing ? 'Sačuvaj izmjene' : 'Kreiraj event') }}
          </button>
        </section>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Event creator — Admin' })

const route = useRoute()
const router = useRouter()
const supabase = useSupabase()

const editId = computed(() => route.query.edit as string | undefined)
const sourceId = computed(() => (route.query.from as string | undefined) ?? editId.value)
const isEditing = computed(() => Boolean(editId.value))
const saving = ref(false)

const form = reactive({
  title: '',
  slug: '',
  description: '',
  event_subtype: 'workshop',
  required_tier: 'free',
  starts_at: '',
  ends_at: '',
  location_name: '',
  location_url: '',
  external_registration_url: '',
  capacity: 20,
  status: 'draft',
})

if (sourceId.value) {
  const { data } = await useAsyncData(`admin-event-source-${sourceId.value}`, async () => {
    const { data } = await supabase
      .from('educational_content')
      .select('id, title, slug, description, required_tier, starts_at, ends_at, location_name, location_url, external_registration_url, capacity, status, content_type, event_subtype')
      .eq('id', sourceId.value)
      .maybeSingle()
    return data
  })
  if (data.value) {
    Object.assign(form, {
      title: editId.value ? data.value.title : `${data.value.title} kopija`,
      slug: editId.value ? data.value.slug : `${data.value.slug}-copy`,
      description: data.value.description ?? '',
      event_subtype: data.value.event_subtype ?? (data.value.content_type === 'webinar' ? 'webinar' : 'event'),
      required_tier: data.value.required_tier ?? 'free',
      starts_at: data.value.starts_at ? new Date(data.value.starts_at).toISOString().slice(0, 16) : '',
      ends_at: data.value.ends_at ? new Date(data.value.ends_at).toISOString().slice(0, 16) : '',
      location_name: data.value.location_name ?? '',
      location_url: data.value.location_url ?? '',
      external_registration_url: data.value.external_registration_url ?? '',
      capacity: Number(data.value.capacity ?? 20),
      status: editId.value ? data.value.status : 'draft',
    })
  }
}

watch(() => form.title, (value) => {
  if (!isEditing.value && !route.query.from) {
    form.slug = value.toLowerCase().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-').replace(/-+/g, '-').trim()
  }
})

const { data: registrationRows, refresh: refreshRegistrations } = await useAsyncData(`admin-event-registrations-${editId.value ?? 'new'}`, async () => {
  if (!editId.value) return []
  const { data } = await supabase
    .from('content_registrations')
    .select('id, status, user_id, profiles!content_registrations_user_id_fkey(full_name, email)')
    .eq('content_id', editId.value)
    .order('registered_at', { ascending: false })
  return data ?? []
})

const registrations = computed(() => {
  return (registrationRows.value ?? []).map((item: Record<string, any>) => ({
    id: item.id as string,
    status: item.status as string,
    userLabel: item.profiles?.full_name ?? item.profiles?.email ?? 'Korisnik',
  }))
})

async function saveEvent() {
  saving.value = true
  try {
    const contentType = form.event_subtype === 'webinar' ? 'webinar' : 'event'
    const payload = {
      title: form.title,
      slug: form.slug,
      description: form.description,
      short_description: form.description.slice(0, 160) || null,
      required_tier: form.required_tier,
      starts_at: form.starts_at ? new Date(form.starts_at).toISOString() : null,
      ends_at: form.ends_at ? new Date(form.ends_at).toISOString() : null,
      location_type: form.event_subtype === 'webinar' ? 'online' : 'in_person',
      location_name: form.location_name || null,
      location_url: form.location_url || null,
      external_registration_url: form.external_registration_url || null,
      capacity: form.capacity || null,
      status: form.status,
      content_type: contentType,
      event_subtype: form.event_subtype,
    }

    if (editId.value) {
      await supabase.from('educational_content').update(payload).eq('id', editId.value)
    } else {
      await supabase.from('educational_content').insert(payload)
    }

    await router.push('/admin/education')
  } finally {
    saving.value = false
  }
}

async function updateRegistrationStatus(id: string, status: 'confirmed' | 'waitlist' | 'cancelled') {
  await supabase.from('content_registrations').update({ status }).eq('id', id)
  await refreshRegistrations()
}
</script>
