<template>
  <section class="space-y-4">
    <div class="card">
      <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 class="text-xl font-bold text-gray-900">Dječiji pasoš</h2>
          <p class="text-sm text-gray-600">Pregled razvoja po domenama i poređenje perioda.</p>
        </div>
        <div class="flex flex-wrap gap-2">
          <button
            v-for="period in periods"
            :key="period"
            class="min-h-11 rounded-xl px-3 py-2 text-sm font-semibold"
            :class="selectedPeriod === period ? 'bg-primary-500 text-white shadow-colorful' : 'bg-primary-50 text-primary-700 hover:bg-primary-100'"
            @click="selectedPeriod = period"
          >
            {{ period }}
          </button>
        </div>
      </div>
    </div>

    <RadarChart
      :current-period-label="selectedPeriod"
      :current-scores="currentScores"
      :compare-period-label="compareLabel"
      :compare-scores="compareScores"
    />

    <PassportComparison
      :records="records"
      :selected-period="selectedPeriod"
      @update:selected-period="selectedPeriod = $event"
    />

    <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
      <article v-for="domain in domainCards" :key="domain.key" class="card-domain" :class="domain.className">
        <h3 class="font-semibold text-gray-900">{{ domain.label }}</h3>
        <p class="text-sm text-gray-700">Ocjena: {{ domain.score }}/5</p>
        <p class="mt-1 text-sm text-gray-600">{{ domain.note }}</p>
      </article>
    </div>

    <div class="card">
      <h3 class="mb-3 text-lg font-bold text-gray-900">Timeline napretka</h3>
      <div class="space-y-2">
        <div
          v-for="item in timeline"
          :key="item.period"
          class="rounded-xl bg-gray-50 p-3"
        >
          <div class="mb-1 flex items-center justify-between text-sm">
            <span class="font-semibold text-gray-800">{{ item.period }}</span>
            <span class="text-gray-600">Prosjek {{ item.average.toFixed(1) }}</span>
          </div>
          <div class="h-2 rounded-full bg-gray-200">
            <div class="h-2 rounded-full bg-primary-500" :style="{ width: `${(item.average / 5) * 100}%` }" />
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import PassportComparison from '~/components/portal/PassportComparison.vue'

type DomainKey = 'emotional' | 'social' | 'creative' | 'cognitive' | 'motor' | 'language'
type PeriodKey = 'Q1' | 'Q2' | 'Q3' | 'Q4' | 'Godišnje'

interface DomainData {
  key: DomainKey
  label: string
  className: string
}

interface ScoreRecord {
  period: PeriodKey
  scores: Record<DomainKey, number>
}

interface ObservationNote {
  key: DomainKey
  note: string
}

const props = defineProps<{
  records: ScoreRecord[]
  notes: ObservationNote[]
}>()

const periods: PeriodKey[] = ['Q1', 'Q2', 'Q3', 'Q4', 'Godišnje']
const selectedPeriod = ref<PeriodKey>('Q1')

const domainMeta: DomainData[] = [
  { key: 'emotional', label: 'Emocionalni', className: 'domain-emotional' },
  { key: 'social', label: 'Socijalni', className: 'domain-social' },
  { key: 'creative', label: 'Kreativni', className: 'domain-creative' },
  { key: 'cognitive', label: 'Kognitivni', className: 'domain-cognitive' },
  { key: 'motor', label: 'Motorički', className: 'domain-motor' },
  { key: 'language', label: 'Jezički', className: 'domain-language' },
]

const scoreForPeriod = (period: PeriodKey) => {
  const entry = props.records.find((record) => record.period === period)
  if (entry) {
    return entry.scores
  }

  const fallback = props.records[0]
  return fallback?.scores ?? {
    emotional: 0,
    social: 0,
    creative: 0,
    cognitive: 0,
    motor: 0,
    language: 0,
  }
}

const currentScores = computed(() => {
  const scores = scoreForPeriod(selectedPeriod.value)
  return domainMeta.map((domain) => ({
    key: domain.key,
    label: domain.label,
    value: scores[domain.key],
  }))
})

const compareLabel = computed(() => {
  const index = periods.indexOf(selectedPeriod.value)
  if (index <= 0) {
    return undefined
  }
  return periods[index - 1]
})

const compareScores = computed(() => {
  if (!compareLabel.value) {
    return undefined
  }

  const scores = scoreForPeriod(compareLabel.value)
  return domainMeta.map((domain) => ({
    key: domain.key,
    label: domain.label,
    value: scores[domain.key],
  }))
})

const domainCards = computed(() => {
  const noteMap = new Map(props.notes.map((note) => [note.key, note.note]))
  const scores = scoreForPeriod(selectedPeriod.value)

  return domainMeta.map((domain) => ({
    ...domain,
    score: scores[domain.key],
    note: noteMap.get(domain.key) ?? 'Nema dodatne bilješke.',
  }))
})

const timeline = computed(() => {
  return props.records.map((record) => {
    const values = Object.values(record.scores)
    const average = values.reduce((sum, value) => sum + value, 0) / values.length
    return {
      period: record.period,
      average,
    }
  })
})
</script>
