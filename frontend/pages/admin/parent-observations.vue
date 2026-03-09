<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Parent opservacije</h1>
        <p class="text-sm text-gray-500 mt-1">Pregledajte kućne opservacije i odlučite da li ulaze u child record.</p>
      </div>
    </div>

    <div class="card">
      <div class="flex flex-wrap gap-3">
        <select v-model="statusFilter" class="input w-auto text-sm">
          <option value="pending">Na pregledu</option>
          <option value="approved">Odobrene</option>
          <option value="rejected">Vraćene</option>
          <option value="all">Sve</option>
        </select>
        <select v-model="domainFilter" class="input w-auto text-sm">
          <option value="all">Sve domene</option>
          <option v-for="domain in domains" :key="domain.key" :value="domain.key">{{ domain.label }}</option>
        </select>
      </div>
    </div>

    <div v-if="pending" class="space-y-3">
      <div v-for="i in 4" :key="i" class="card h-28 animate-pulse" />
    </div>

    <div v-else-if="filteredItems.length > 0" class="space-y-4">
      <article v-for="item in filteredItems" :key="item.id" class="card">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div class="space-y-3">
            <div class="flex flex-wrap items-center gap-2">
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :style="{ backgroundColor: `${item.domainColor}20`, color: item.domainColor }">
                {{ item.domainLabel }}
              </span>
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="statusClass(item.status)">
                {{ statusLabel(item.status) }}
              </span>
            </div>

            <div>
              <h2 class="text-lg font-bold text-gray-900">{{ item.childName }}</h2>
              <p class="text-sm text-gray-500">{{ item.parentName }}</p>
            </div>

            <p class="text-sm text-gray-700">{{ item.content }}</p>
            <a v-if="item.photoUrl" :href="item.photoUrl" target="_blank" rel="noopener noreferrer" class="inline-flex text-sm font-semibold text-primary-600 hover:text-primary-700">
              Otvori fotografiju →
            </a>

            <div v-if="item.status !== 'pending'" class="rounded-2xl bg-gray-50 p-3 text-sm text-gray-600">
              <p>Pregledao: {{ item.reviewerName ?? 'Staff' }}</p>
              <p v-if="item.reviewNote" class="mt-1">Napomena: {{ item.reviewNote }}</p>
            </div>
          </div>

          <div class="w-full max-w-sm space-y-3">
            <NuxtLink :to="`/admin/children/${item.childId}`" class="btn-secondary block w-full text-center">
              Otvori child record
            </NuxtLink>

            <div v-if="item.status === 'pending'" class="space-y-3 rounded-2xl bg-gray-50 p-4">
              <label class="text-xs font-semibold text-gray-600">
                Napomena za roditelja
                <textarea v-model="reviewState[item.id]" class="input mt-1" rows="3" placeholder="Opcionalna napomena..." />
              </label>
              <div class="grid grid-cols-2 gap-3">
                <button type="button" class="btn-secondary" :disabled="processingId === item.id" @click="review(item, 'rejected')">
                  Odbij
                </button>
                <button type="button" class="btn-primary" :disabled="processingId === item.id" @click="review(item, 'approved')">
                  {{ processingId === item.id ? 'Čuvam...' : 'Odobri' }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </article>
    </div>

    <div v-else class="card py-14 text-center">
      <div class="mb-4 text-5xl">📭</div>
      <h2 class="font-display text-xl font-bold text-gray-900">Nema opservacija za ovaj filter</h2>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Parent opservacije — Admin' })

type DomainKey = 'emotional' | 'social' | 'creative' | 'cognitive' | 'motor' | 'language'
type ReviewStatus = 'pending' | 'approved' | 'rejected'

interface ReviewItem {
  id: string
  childId: string
  childName: string
  parentId: string
  parentName: string
  domain: DomainKey
  domainLabel: string
  domainColor: string
  content: string
  photoUrl: string | null
  status: ReviewStatus
  reviewNote: string | null
  reviewerName: string | null
}

const supabase = useSupabase()
const { user } = useAuth()

const statusFilter = ref<'pending' | 'approved' | 'rejected' | 'all'>('pending')
const domainFilter = ref<'all' | DomainKey>('all')
const processingId = ref<string | null>(null)
const reviewState = reactive<Record<string, string>>({})

const domains: Array<{ key: DomainKey; label: string; color: string }> = [
  { key: 'emotional', label: 'Emocionalni', color: '#cf2e2e' },
  { key: 'social', label: 'Socijalni', color: '#fcb900' },
  { key: 'creative', label: 'Kreativni', color: '#9b51e0' },
  { key: 'cognitive', label: 'Kognitivni', color: '#0693e3' },
  { key: 'motor', label: 'Motorički', color: '#00d084' },
  { key: 'language', label: 'Jezički', color: '#f78da7' },
]

const { data: skillAreas } = await useAsyncData('parent-obs-skill-areas', async () => {
  const { data } = await supabase.from('skill_areas').select('id, key')
  return data ?? []
})

const skillAreaMap = computed(() => {
  return new Map((skillAreas.value ?? []).map((item: Record<string, any>) => [item.key, item.id]))
})

const { data: rows, pending, refresh } = await useAsyncData('admin-parent-observations', async () => {
  const { data } = await supabase
    .from('parent_observations')
    .select(`
      id,
      child_id,
      parent_id,
      domain,
      content,
      photo_url,
      status,
      review_note,
      reviewed_at,
      reviewed_by,
      approved_observation_id,
      children(full_name),
      parent:profiles!parent_observations_parent_id_fkey(full_name, email),
      reviewer:profiles!parent_observations_reviewed_by_fkey(full_name)
    `)
    .order('created_at', { ascending: false })

  return data ?? []
})

const filteredItems = computed(() => {
  return (rows.value ?? []).filter((item: Record<string, any>) => {
    if (statusFilter.value !== 'all' && item.status !== statusFilter.value) return false
    if (domainFilter.value !== 'all' && item.domain !== domainFilter.value) return false
    return true
  }).map((item: Record<string, any>) => {
    const domain = domains.find((entry) => entry.key === item.domain) || domains[0]
    return {
      id: item.id as string,
      childId: item.child_id as string,
      childName: item.children?.full_name ?? 'Dijete',
      parentId: item.parent_id as string,
      parentName: item.parent?.full_name ?? item.parent?.email ?? 'Roditelj',
      domain: item.domain as DomainKey,
      domainLabel: domain?.label ?? 'Kreativni',
      domainColor: domain?.color ?? '#9b51e0',
      content: item.content as string,
      photoUrl: item.photo_url as string | null,
      status: item.status as ReviewStatus,
      reviewNote: item.review_note as string | null,
      reviewerName: item.reviewer?.full_name as string | null,
    }
  })
})

async function review(item: ReviewItem, nextStatus: 'approved' | 'rejected') {
  if (!user.value) return
  processingId.value = item.id
  try {
    let approvedObservationId: string | null = null

    if (nextStatus === 'approved') {
      const skillAreaId = skillAreaMap.value.get(item.domain)

      const { data: observation, error: observationError } = await supabase
        .from('observations')
        .insert({
          child_id: item.childId,
          staff_id: user.value.id,
          content: item.content,
          skill_area_id: skillAreaId ?? null,
          observation_type: 'adhoc',
          is_visible_to_parent: true,
        })
        .select('id')
        .single()

      if (observationError) throw observationError
      approvedObservationId = observation.id

      if (item.photoUrl) {
        const { error: mediaError } = await supabase
          .from('observation_media')
          .insert({
            observation_id: observation.id,
            file_url: item.photoUrl,
            file_type: 'photo',
            caption: 'Parent observation attachment',
          })

        if (mediaError) throw mediaError
      }
    }

    const reviewNote = reviewState[item.id] || null

    const { error: parentObservationError } = await supabase
      .from('parent_observations')
      .update({
        status: nextStatus,
        review_note: reviewNote,
        reviewed_by: user.value.id,
        reviewed_at: new Date().toISOString(),
        approved_observation_id: approvedObservationId,
      })
      .eq('id', item.id)

    if (parentObservationError) throw parentObservationError

    await supabase
      .from('notifications')
      .insert({
        user_id: item.parentId,
        type: 'activity',
        title: nextStatus === 'approved' ? 'Kućna opservacija je odobrena' : 'Kućna opservacija traži doradu',
        body: nextStatus === 'approved'
          ? 'Vaša kućna opservacija je pregledana i dodana u child record.'
          : (reviewNote || 'Staff je pregledao opservaciju i ostavio povratnu informaciju.'),
        action_url: `/portal/children/${item.childId}/observe`,
        data: { parent_observation_id: item.id, status: nextStatus },
      })

    delete reviewState[item.id]
    await refresh()
  } finally {
    processingId.value = null
  }
}

function statusLabel(status: ReviewStatus) {
  const labels = {
    pending: 'Na pregledu',
    approved: 'Odobreno',
    rejected: 'Vraćeno',
  }
  return labels[status]
}

function statusClass(status: ReviewStatus) {
  const classes = {
    pending: 'bg-brand-amber/15 text-brand-amber',
    approved: 'bg-brand-green/15 text-brand-green',
    rejected: 'bg-brand-red/15 text-brand-red',
  }
  return classes[status]
}
</script>
