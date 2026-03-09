<template>
  <div class="space-y-6">
    <div v-if="child" class="flex items-center gap-3">
      <NuxtLink :to="`/portal/children/${childId}`" class="rounded-xl p-2 text-gray-500 transition-colors hover:bg-gray-100 hover:text-gray-700">
        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </NuxtLink>
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Razvojni timeline</h1>
        <p class="text-sm text-gray-500">{{ child.full_name }} • mjesečni pregled milestonea i opservacija</p>
      </div>
      <NuxtLink :to="`/portal/children/${childId}/observe`" class="btn-secondary ml-auto text-sm">
        Dodaj kućnu opservaciju
      </NuxtLink>
    </div>

    <div v-else-if="pending" class="space-y-4">
      <div class="card h-24 animate-pulse" />
      <div class="card h-96 animate-pulse" />
    </div>

    <div v-else class="card py-14 text-center">
      <div class="mb-4 text-5xl">🧭</div>
      <h2 class="font-display text-xl font-bold text-gray-900">Dijete nije pronađeno</h2>
      <NuxtLink to="/portal/children" class="btn-primary mt-5">Nazad na listu</NuxtLink>
    </div>

    <FeatureGate v-if="child" required-tier="paid">
      <template #locked>
        <UpgradeBanner
          tier-name="paid"
          title="Razvojni timeline je dostupan u plaćenom planu"
          message="Otključajte mjesečni pregled milestonea, opservacija i fotografija kako biste pratili razvoj bez nagađanja."
          :features="[
            'Mjesečno grupisani milestonei',
            'Brz pregled opservacija po domenama',
            'Praćenje fotografija i trenutnog fokusa',
          ]"
        />
      </template>

      <GrowthTimeline
        :items="timelineItems"
        :active-domain="activeDomain"
        :status-filter="statusFilter"
        :domain-options="domainOptions"
        @update:active-domain="activeDomain = $event as 'all' | DomainKey"
        @update:status-filter="statusFilter = $event as 'all' | 'achieved' | 'emerging'"
      />
    </FeatureGate>
  </div>
</template>

<script setup lang="ts">
import type { GrowthTimelineMonth } from '~/components/portal/GrowthTimeline.vue'
import FeatureGate from '~/components/portal/FeatureGate.vue'
import GrowthTimeline from '~/components/portal/GrowthTimeline.vue'
import UpgradeBanner from '~/components/portal/UpgradeBanner.vue'

definePageMeta({ middleware: 'auth', layout: 'portal' })

useSeoMeta({
  title: 'Razvojni timeline — Šarena Sfera',
  description: 'Mjesečni pregled milestonea, opservacija i fotografija za dijete.',
})

type DomainKey = 'emotional' | 'social' | 'creative' | 'cognitive' | 'motor' | 'language'

const route = useRoute()
const childId = route.params.id as string
const supabase = useSupabase()

const activeDomain = ref<'all' | DomainKey>('all')
const statusFilter = ref<'all' | 'achieved' | 'emerging'>('all')

const domainMeta: Record<DomainKey, { label: string; color: string; emoji: string }> = {
  emotional: { label: 'Emocionalni', color: '#cf2e2e', emoji: '❤️' },
  social: { label: 'Socijalni', color: '#fcb900', emoji: '🤝' },
  creative: { label: 'Kreativni', color: '#9b51e0', emoji: '🎨' },
  cognitive: { label: 'Kognitivni', color: '#0693e3', emoji: '🧠' },
  motor: { label: 'Motorički', color: '#00d084', emoji: '🏃' },
  language: { label: 'Jezički', color: '#f78da7', emoji: '💬' },
}

const domainOptions: Array<{ label: string; value: 'all' | DomainKey }> = [
  { label: 'Sve domene', value: 'all' },
  ...Object.entries(domainMeta).map(([key, value]) => ({ label: value.label, value: key as DomainKey })),
]

const { data: child, pending } = await useAsyncData(`child-progress-${childId}`, async () => {
  const { data } = await supabase
    .from('children')
    .select('id, full_name, date_of_birth, age_group')
    .eq('id', childId)
    .eq('is_active', true)
    .single()

  return data
})

const { data: skillAreas } = await useAsyncData('skill-areas-progress', async () => {
  const { data } = await supabase
    .from('skill_areas')
    .select('id, key, name_local')
  return data ?? []
})

const skillAreaMap = computed(() => {
  const map = new Map<string, DomainKey>()
  for (const item of skillAreas.value ?? []) {
    if (item.key in domainMeta) {
      map.set(item.id, item.key as DomainKey)
    }
  }
  return map
})

const { data: milestoneRows } = await useAsyncData(`child-milestones-${childId}`, async () => {
  const { data } = await supabase
    .from('child_milestones')
    .select('id, status, achieved_at, updated_at, developmental_milestones(title, description, domain)')
    .eq('child_id', childId)
    .in('status', ['emerging', 'achieved'])
    .order('updated_at', { ascending: false })

  return data ?? []
})

const { data: observationRows } = await useAsyncData(`child-progress-observations-${childId}`, async () => {
  const { data } = await supabase
    .from('observations')
    .select('id, content, created_at, skill_area_id, observation_media(id)')
    .eq('child_id', childId)
    .eq('is_visible_to_parent', true)
    .order('created_at', { ascending: false })
    .limit(100)

  return data ?? []
})

function monthKeyFromDate(date: string) {
  const value = new Date(date)
  return `${value.getFullYear()}-${String(value.getMonth() + 1).padStart(2, '0')}`
}

function monthLabelFromKey(key: string) {
  const [year, month] = key.split('-').map(Number)
  const safeYear = Number.isFinite(year) ? Number(year) : new Date().getFullYear()
  const safeMonth = Number.isFinite(month) ? Number(month) : 1
  return new Date(safeYear, safeMonth - 1, 1).toLocaleDateString('bs-BA', { month: 'long', year: 'numeric' })
}

const filteredMilestones = computed(() => {
  const rows = milestoneRows.value ?? []
  return rows.filter((row: Record<string, any>) => {
    const milestone = row.developmental_milestones
    if (!milestone) return false
    if (activeDomain.value !== 'all' && milestone.domain !== activeDomain.value) return false
    if (statusFilter.value !== 'all' && row.status !== statusFilter.value) return false
    return true
  })
})

const filteredObservations = computed(() => {
  const rows = observationRows.value ?? []
  return rows.filter((row: Record<string, any>) => {
    const domain = skillAreaMap.value.get(row.skill_area_id)
    if (activeDomain.value !== 'all' && domain !== activeDomain.value) return false
    return true
  })
})

const timelineItems = computed<GrowthTimelineMonth[]>(() => {
  const months = new Map<string, GrowthTimelineMonth>()

  for (const row of filteredMilestones.value as Array<Record<string, any>>) {
    const dateSource = row.achieved_at || row.updated_at
    if (!dateSource || !row.developmental_milestones) continue

    const milestone = row.developmental_milestones as { title: string; description: string; domain: DomainKey }
    const key = monthKeyFromDate(dateSource)
    const month = months.get(key) ?? {
      monthKey: key,
      label: monthLabelFromKey(key),
      summary: '',
      achievedCount: 0,
      emergingCount: 0,
      observationCount: 0,
      photoCount: 0,
      topDomainLabel: '—',
      focusLabel: '—',
      milestones: [],
      observations: [],
    }

    if (row.status === 'achieved') month.achievedCount += 1
    if (row.status === 'emerging') month.emergingCount += 1

    month.milestones.push({
      id: row.id,
      title: milestone.title,
      description: milestone.description ?? '',
      status: row.status,
      color: domainMeta[milestone.domain].color,
      emoji: domainMeta[milestone.domain].emoji,
    })

    months.set(key, month)
  }

  for (const row of filteredObservations.value as Array<Record<string, any>>) {
    const key = monthKeyFromDate(row.created_at)
    const domain = skillAreaMap.value.get(row.skill_area_id) ?? 'creative'
    const month = months.get(key) ?? {
      monthKey: key,
      label: monthLabelFromKey(key),
      summary: '',
      achievedCount: 0,
      emergingCount: 0,
      observationCount: 0,
      photoCount: 0,
      topDomainLabel: '—',
      focusLabel: '—',
      milestones: [],
      observations: [],
    }

    month.observationCount += 1
    month.photoCount += Array.isArray(row.observation_media) ? row.observation_media.length : 0
    if (month.observations.length < 3) {
      month.observations.push({
        id: row.id,
        domainLabel: domainMeta[domain].label,
        content: row.content,
      })
    }

    months.set(key, month)
  }

  const items = [...months.values()]
    .map((item) => {
      const domainCounts = new Map<string, number>()
      for (const milestone of item.milestones) {
        const current = domainCounts.get(milestone.title) ?? 0
        domainCounts.set(milestone.title, current + 1)
      }

      const focusMilestone = item.milestones.find((entry) => entry.status === 'emerging') ?? item.milestones[0]
      const topDomain = item.milestones[0]?.title ?? (item.observations[0]?.domainLabel ?? 'Bez izraženog domena')

      return {
        ...item,
        summary: `${item.achievedCount + item.emergingCount} milestone zapisa i ${item.observationCount} opservacija`,
        topDomainLabel: topDomain,
        focusLabel: focusMilestone?.title ?? 'Bez posebnog fokusa',
      }
    })
    .sort((a, b) => b.monthKey.localeCompare(a.monthKey))

  return items
})
</script>
