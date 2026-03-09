<template>
  <div class="space-y-6">
    <div v-if="child" class="flex items-center gap-3">
      <NuxtLink :to="`/portal/children/${childId}`" class="rounded-xl p-2 text-gray-500 transition-colors hover:bg-gray-100 hover:text-gray-700">
        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </NuxtLink>
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Kućna opservacija</h1>
        <p class="text-sm text-gray-500">{{ child.full_name }} • pošaljite zapažanje za staff review</p>
      </div>
    </div>

    <div v-else-if="pending" class="space-y-4">
      <div class="card h-28 animate-pulse" />
      <div class="card h-80 animate-pulse" />
    </div>

    <div v-else class="card py-14 text-center">
      <div class="mb-4 text-5xl">🧭</div>
      <h2 class="font-display text-xl font-bold text-gray-900">Dijete nije pronađeno</h2>
      <NuxtLink to="/portal/children" class="btn-primary mt-5">Nazad na listu</NuxtLink>
    </div>

    <template v-if="child">
      <section class="card">
        <h2 class="text-lg font-bold text-gray-900">Pošaljite novu opservaciju</h2>
        <p class="mt-1 text-sm text-gray-600">Staff će pregledati sadržaj prije nego što se pojavi u timelineu i dječijem pasošu.</p>

        <form class="mt-5 space-y-4" @submit.prevent="submitObservation">
          <div>
            <label class="label">Domena razvoja *</label>
            <div class="grid grid-cols-2 gap-2 sm:grid-cols-3">
              <button
                v-for="domain in domains"
                :key="domain.key"
                type="button"
                class="rounded-2xl border-2 px-3 py-3 text-left transition-all"
                :class="form.domain === domain.key ? 'shadow-colorful' : 'border-gray-200 hover:border-primary-200'"
                :style="form.domain === domain.key ? { borderColor: domain.color, backgroundColor: `${domain.color}12` } : {}"
                @click="form.domain = domain.key"
              >
                <div class="text-lg">{{ domain.emoji }}</div>
                <div class="mt-1 text-sm font-semibold text-gray-900">{{ domain.label }}</div>
              </button>
            </div>
          </div>

          <div>
            <label class="label">Bilješka *</label>
            <textarea
              v-model="form.content"
              class="input"
              rows="5"
              placeholder="Opišite šta ste primijetili kod kuće..."
              required
            />
          </div>

          <div>
            <label class="label">Fotografija</label>
            <input
              type="file"
              accept="image/*"
              class="input"
              @change="onPhotoSelected"
            />
            <p class="mt-1 text-xs text-gray-500">Opcionalno priložite fotografiju. Datoteka se šalje zajedno s opservacijom na staff pregled.</p>
            <p v-if="selectedPhotoName" class="mt-1 text-xs text-primary-600">Odabrano: {{ selectedPhotoName }}</p>
          </div>

          <p v-if="errorMessage" class="text-sm text-brand-red">{{ errorMessage }}</p>
          <p v-if="successMessage" class="text-sm text-brand-green">{{ successMessage }}</p>

          <div class="flex gap-3">
            <NuxtLink :to="`/portal/children/${childId}`" class="btn-secondary flex-1 text-center">Otkaži</NuxtLink>
            <button type="submit" class="btn-primary flex-1" :disabled="submitting">
              {{ submitting ? 'Šaljem...' : 'Pošalji na pregled' }}
            </button>
          </div>
        </form>
      </section>

      <section class="card">
        <div class="flex items-center justify-between gap-3">
          <div>
            <h2 class="text-lg font-bold text-gray-900">Moje prethodne prijave</h2>
            <p class="mt-1 text-sm text-gray-600">Statusi kućnih opservacija za ovo dijete.</p>
          </div>
          <span class="badge bg-primary-50 text-primary-700">{{ submissions.length }}</span>
        </div>

        <div v-if="submissions.length > 0" class="mt-4 space-y-3">
          <article v-for="submission in submissions" :key="submission.id" class="rounded-2xl bg-gray-50 p-4">
            <div class="flex flex-wrap items-center gap-2">
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :style="{ backgroundColor: `${submission.domainColor}20`, color: submission.domainColor }">
                {{ submission.domainLabel }}
              </span>
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="statusClass(submission.status)">
                {{ statusLabel(submission.status) }}
              </span>
            </div>
            <p class="mt-3 text-sm text-gray-700">{{ submission.content }}</p>
            <a v-if="submission.photoUrl" :href="submission.photoUrl" target="_blank" rel="noopener noreferrer" class="mt-3 inline-flex text-sm font-semibold text-primary-600 hover:text-primary-700">
              Otvori priloženu fotografiju →
            </a>
            <p v-if="submission.reviewNote" class="mt-3 text-xs text-gray-500">Napomena staffa: {{ submission.reviewNote }}</p>
          </article>
        </div>
        <p v-else class="mt-4 text-sm text-gray-500">Još nema poslanih kućnih opservacija za ovo dijete.</p>
      </section>
    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })

useSeoMeta({
  title: 'Kućna opservacija — Šarena Sfera',
  description: 'Pošaljite kućnu opservaciju za dijete na staff pregled.',
})

type DomainKey = 'emotional' | 'social' | 'creative' | 'cognitive' | 'motor' | 'language'

const route = useRoute()
const supabase = useSupabase()
const { user } = useAuth()
const childId = route.params.id as string

const submitting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const selectedPhoto = ref<File | null>(null)

const domains: Array<{ key: DomainKey; label: string; color: string; emoji: string }> = [
  { key: 'emotional', label: 'Emocionalni', color: '#cf2e2e', emoji: '❤️' },
  { key: 'social', label: 'Socijalni', color: '#fcb900', emoji: '🤝' },
  { key: 'creative', label: 'Kreativni', color: '#9b51e0', emoji: '🎨' },
  { key: 'cognitive', label: 'Kognitivni', color: '#0693e3', emoji: '🧠' },
  { key: 'motor', label: 'Motorički', color: '#00d084', emoji: '🏃' },
  { key: 'language', label: 'Jezički', color: '#f78da7', emoji: '💬' },
]

const form = reactive({
  domain: '' as DomainKey | '',
  content: '',
})

const { data: child, pending } = await useAsyncData(`parent-observe-child-${childId}`, async () => {
  if (!user.value) return null

  const { data } = await supabase
    .from('children')
    .select('id, full_name, parent_children!inner(parent_id)')
    .eq('id', childId)
    .eq('parent_children.parent_id', user.value.id)
    .maybeSingle()

  return data
})

const { data: submissionRows, refresh } = await useAsyncData(`parent-observe-submissions-${childId}`, async () => {
  if (!user.value) return []

  const { data } = await supabase
    .from('parent_observations')
    .select('id, domain, content, photo_url, status, review_note, created_at')
    .eq('child_id', childId)
    .eq('parent_id', user.value.id)
    .order('created_at', { ascending: false })

  return data ?? []
})

const submissions = computed(() => {
  return (submissionRows.value ?? []).map((item: Record<string, any>) => {
    const domain = domains.find((entry) => entry.key === item.domain) ?? domains[0]
    return {
      id: item.id as string,
      domainLabel: domain.label,
      domainColor: domain.color,
      content: item.content as string,
      photoUrl: item.photo_url as string | null,
      status: item.status as 'pending' | 'approved' | 'rejected',
      reviewNote: item.review_note as string | null,
    }
  })
})

async function submitObservation() {
  if (!user.value || !form.domain || !form.content.trim()) return
  submitting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    let photoUrl: string | null = null

    if (selectedPhoto.value) {
      const extension = selectedPhoto.value.name.split('.').pop() || 'jpg'
      const path = `${user.value.id}/${childId}/${Date.now()}.${extension}`
      const { error: uploadError } = await supabase
        .storage
        .from('parent-observations')
        .upload(path, selectedPhoto.value, { upsert: false })

      if (uploadError) throw uploadError
      photoUrl = supabase.storage.from('parent-observations').getPublicUrl(path).data.publicUrl
    }

    const { error } = await supabase
      .from('parent_observations')
      .insert({
        child_id: childId,
        parent_id: user.value.id,
        domain: form.domain,
        content: form.content.trim(),
        photo_url: photoUrl,
      })

    if (error) throw error

    Object.assign(form, { domain: '', content: '' })
    selectedPhoto.value = null
    successMessage.value = 'Opservacija je poslana na pregled.'
    await refresh()
  } catch {
    errorMessage.value = 'Greška pri slanju opservacije. Pokušajte ponovo.'
  } finally {
    submitting.value = false
  }
}

const selectedPhotoName = computed(() => selectedPhoto.value?.name ?? '')

function onPhotoSelected(event: Event) {
  const input = event.target as HTMLInputElement
  selectedPhoto.value = input.files?.[0] ?? null
}

function statusLabel(status: 'pending' | 'approved' | 'rejected') {
  const labels = {
    pending: 'Na pregledu',
    approved: 'Odobreno',
    rejected: 'Vraćeno',
  }
  return labels[status]
}

function statusClass(status: 'pending' | 'approved' | 'rejected') {
  const classes = {
    pending: 'bg-brand-amber/15 text-brand-amber',
    approved: 'bg-brand-green/15 text-brand-green',
    rejected: 'bg-brand-red/15 text-brand-red',
  }
  return classes[status]
}
</script>
