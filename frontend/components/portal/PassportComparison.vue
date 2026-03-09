<template>
  <section class="space-y-4">
    <div class="card">
      <div class="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <h3 class="text-xl font-bold text-gray-900">Poređenje perioda</h3>
          <p class="mt-1 text-sm text-gray-600">Uporedite trenutni period sa prethodnim i prosjekom uzrasta.</p>
        </div>
        <div class="flex flex-wrap gap-2">
          <button
            v-for="period in periods"
            :key="period"
            class="rounded-xl px-3 py-2 text-sm font-semibold"
            :class="selectedPeriod === period ? 'bg-primary-500 text-white shadow-colorful' : 'bg-primary-50 text-primary-700 hover:bg-primary-100'"
            @click="$emit('update:selected-period', period)"
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
      :benchmark-period-label="benchmarkLabel"
      :benchmark-scores="benchmarkScores"
    />

    <div class="grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
      <div class="card overflow-hidden p-0">
        <table class="min-w-full text-sm">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-4 py-3 text-left font-semibold text-gray-600">Domena</th>
              <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ selectedPeriod }}</th>
              <th class="px-4 py-3 text-left font-semibold text-gray-600">{{ compareLabel ?? 'Prethodno' }}</th>
              <th class="px-4 py-3 text-left font-semibold text-gray-600">Prosjek uzrasta</th>
              <th class="px-4 py-3 text-left font-semibold text-gray-600">Promjena</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in comparisonRows" :key="row.key">
              <td class="px-4 py-3">
                <div class="flex items-center gap-2">
                  <span class="inline-flex h-8 w-8 items-center justify-center rounded-xl text-sm" :style="{ backgroundColor: `${row.color}20`, color: row.color }">
                    {{ row.emoji }}
                  </span>
                  <span class="font-semibold text-gray-900">{{ row.label }}</span>
                </div>
              </td>
              <td class="px-4 py-3 font-semibold text-gray-900">{{ row.current }}</td>
              <td class="px-4 py-3 text-gray-600">{{ row.previous }}</td>
              <td class="px-4 py-3 text-gray-600">{{ row.ageAverage }}</td>
              <td class="px-4 py-3">
                <span
                  class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold"
                  :class="row.change > 0 ? 'bg-brand-green/15 text-brand-green' : row.change < 0 ? 'bg-brand-red/15 text-brand-red' : 'bg-gray-100 text-gray-500'"
                >
                  <span v-if="row.change > 0">↑</span>
                  <span v-else-if="row.change < 0">↓</span>
                  <span v-else>→</span>
                  {{ row.change > 0 ? '+' : '' }}{{ row.change.toFixed(1) }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="space-y-4">
        <div class="card">
          <p class="text-xs font-semibold uppercase tracking-[0.25em] text-brand-green">Najveći pomak</p>
          <h4 class="mt-2 text-lg font-bold text-gray-900">{{ biggestImprovement.label }}</h4>
          <p class="mt-1 text-sm text-gray-600">Napredak od {{ biggestImprovement.change > 0 ? '+' : '' }}{{ biggestImprovement.change.toFixed(1) }} u odnosu na prethodni period.</p>
        </div>

        <div class="card">
          <p class="text-xs font-semibold uppercase tracking-[0.25em] text-brand-amber">Potrebna pažnja</p>
          <h4 class="mt-2 text-lg font-bold text-gray-900">{{ attentionArea.label }}</h4>
          <p class="mt-1 text-sm text-gray-600">Trenutni rezultat je {{ attentionArea.current.toFixed(1) }} i ispod ličnog prosjeka u odnosu na druge domene.</p>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import RadarChart from '~/components/charts/RadarChart.vue'

type DomainKey = 'emotional' | 'social' | 'creative' | 'cognitive' | 'motor' | 'language'
type PeriodKey = 'Q1' | 'Q2' | 'Q3' | 'Q4' | 'Godišnje'

interface ScoreRecord {
  period: PeriodKey
  scores: Record<DomainKey, number>
}

const props = defineProps<{
  records: ScoreRecord[]
  selectedPeriod: PeriodKey
}>()

defineEmits<{
  (event: 'update:selected-period', value: PeriodKey): void
}>()

const periods: PeriodKey[] = ['Q1', 'Q2', 'Q3', 'Q4', 'Godišnje']

const domainMeta = [
  { key: 'emotional', label: 'Emocionalni', color: '#cf2e2e', emoji: '❤️' },
  { key: 'social', label: 'Socijalni', color: '#fcb900', emoji: '🤝' },
  { key: 'creative', label: 'Kreativni', color: '#9b51e0', emoji: '🎨' },
  { key: 'cognitive', label: 'Kognitivni', color: '#0693e3', emoji: '🧠' },
  { key: 'motor', label: 'Motorički', color: '#00d084', emoji: '🏃' },
  { key: 'language', label: 'Jezički', color: '#f78da7', emoji: '💬' },
] as const

function scoreForPeriod(period: PeriodKey) {
  const record = props.records.find((item) => item.period === period)
  return record?.scores ?? props.records[0]?.scores ?? {
    emotional: 0,
    social: 0,
    creative: 0,
    cognitive: 0,
    motor: 0,
    language: 0,
  }
}

const compareLabel = computed<PeriodKey | undefined>(() => {
  const index = periods.indexOf(props.selectedPeriod)
  if (index <= 0) return undefined
  return periods[index - 1]
})

const currentScores = computed(() => {
  const scores = scoreForPeriod(props.selectedPeriod)
  return domainMeta.map((domain) => ({
    key: domain.key,
    label: domain.label,
    value: scores[domain.key],
  }))
})

const compareScores = computed(() => {
  if (!compareLabel.value) return undefined
  const scores = scoreForPeriod(compareLabel.value)
  return domainMeta.map((domain) => ({
    key: domain.key,
    label: domain.label,
    value: scores[domain.key],
  }))
})

const benchmarkLabel = 'Prosjek uzrasta'

const benchmarkScores = computed(() => {
  const totals = domainMeta.map((domain) => {
    const values = props.records.map((record) => record.scores[domain.key]).filter((value) => typeof value === 'number')
    const average = values.length > 0 ? values.reduce((sum, value) => sum + value, 0) / values.length : 0
    return {
      key: domain.key,
      label: domain.label,
      value: Number(average.toFixed(1)),
    }
  })

  return totals
})

const comparisonRows = computed(() => {
  const current = scoreForPeriod(props.selectedPeriod)
  const previous = compareLabel.value ? scoreForPeriod(compareLabel.value) : current
  const benchmark = Object.fromEntries(benchmarkScores.value.map((item) => [item.key, item.value])) as Record<DomainKey, number>

  return domainMeta.map((domain) => ({
    ...domain,
    current: current[domain.key],
    previous: previous[domain.key],
    ageAverage: benchmark[domain.key],
    change: Number((current[domain.key] - previous[domain.key]).toFixed(1)),
  }))
})

const biggestImprovement = computed(() => {
  const sorted = [...comparisonRows.value].sort((a, b) => b.change - a.change)
  return sorted[0]
})

const attentionArea = computed(() => {
  const sorted = [...comparisonRows.value].sort((a, b) => a.current - b.current || a.change - b.change)
  return sorted[0]
})
</script>
