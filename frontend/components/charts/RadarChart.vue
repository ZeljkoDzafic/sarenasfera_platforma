<template>
  <div class="card">
    <Radar
      :data="chartData"
      :options="chartOptions"
      aria-label="Radar grafikon razvoja djeteta"
    />
  </div>
</template>

<script setup lang="ts">
import {
  Chart as ChartJS,
  Filler,
  Legend,
  LineElement,
  PointElement,
  RadialLinearScale,
  Tooltip,
  type ChartData,
  type ChartOptions,
} from 'chart.js'
import { Radar } from 'vue-chartjs'

ChartJS.register(RadialLinearScale, PointElement, LineElement, Filler, Tooltip, Legend)

type DomainKey = 'emotional' | 'social' | 'creative' | 'cognitive' | 'motor' | 'language'

interface RadarDomainScore {
  key: DomainKey
  label: string
  value: number
}

interface RadarDataset {
  label: string
  scores: RadarDomainScore[]
  borderColor: string
  backgroundColor: string
}

const props = defineProps<{
  currentPeriodLabel: string
  currentScores: RadarDomainScore[]
  comparePeriodLabel?: string
  compareScores?: RadarDomainScore[]
}>()

const domainOrder: DomainKey[] = ['emotional', 'social', 'creative', 'cognitive', 'motor', 'language']

const mapScoresToOrder = (scores: RadarDomainScore[]) => {
  const scoreMap = new Map(scores.map((item) => [item.key, item]))
  return domainOrder.map((key) => scoreMap.get(key)?.value ?? 0)
}

const labels = computed(() => {
  const scoreMap = new Map(props.currentScores.map((item) => [item.key, item.label]))
  return domainOrder.map((key) => scoreMap.get(key) ?? key)
})

const datasets = computed(() => {
  const base: RadarDataset[] = [
    {
      label: props.currentPeriodLabel,
      scores: props.currentScores,
      borderColor: '#9b51e0',
      backgroundColor: 'rgba(155, 81, 224, 0.18)',
    },
  ]

  if (props.compareScores && props.comparePeriodLabel) {
    base.push({
      label: props.comparePeriodLabel,
      scores: props.compareScores,
      borderColor: '#0693e3',
      backgroundColor: 'rgba(6, 147, 227, 0.12)',
    })
  }

  return base
})

const chartData = computed<ChartData<'radar'>>(() => ({
  labels: labels.value,
  datasets: datasets.value.map((dataset) => ({
    label: dataset.label,
    data: mapScoresToOrder(dataset.scores),
    borderColor: dataset.borderColor,
    backgroundColor: dataset.backgroundColor,
    borderWidth: 2,
    pointRadius: 4,
    pointHoverRadius: 5,
    pointBackgroundColor: '#ffffff',
    pointBorderColor: dataset.borderColor,
    pointBorderWidth: 2,
  })),
}))

const chartOptions = computed<ChartOptions<'radar'>>(() => ({
  responsive: true,
  maintainAspectRatio: false,
  scales: {
    r: {
      min: 0,
      max: 5,
      ticks: {
        stepSize: 1,
        color: '#6b7280',
        backdropColor: 'transparent',
      },
      grid: {
        color: '#e5e7eb',
      },
      angleLines: {
        color: '#e5e7eb',
      },
      pointLabels: {
        color: '#374151',
        font: {
          size: 12,
          weight: '600',
        },
      },
    },
  },
  plugins: {
    legend: {
      position: 'bottom',
      labels: {
        usePointStyle: true,
        color: '#374151',
      },
    },
  },
}))
</script>

<style scoped>
.card {
  height: 320px;
}
</style>
