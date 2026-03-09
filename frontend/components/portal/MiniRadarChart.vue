<template>
  <div class="relative h-28 w-28" role="img" aria-label="Mini radar prikaz razvoja djeteta">
    <svg viewBox="0 0 120 120" class="h-full w-full">
      <polygon
        v-for="level in gridLevels"
        :key="level"
        :points="buildPolygonPoints(level)"
        fill="none"
        stroke="#e5e7eb"
        stroke-width="1"
      />

      <line
        v-for="(axis, index) in axes"
        :key="axis.key"
        x1="60"
        y1="60"
        :x2="axisPoints[index]?.x ?? center.x"
        :y2="axisPoints[index]?.y ?? center.y"
        stroke="#e5e7eb"
        stroke-width="1"
      />

      <polygon
        :points="dataPoints"
        fill="rgba(155, 81, 224, 0.18)"
        stroke="#9b51e0"
        stroke-width="2"
      />

      <circle
        v-for="point in valuePoints"
        :key="point.key"
        :cx="point.x"
        :cy="point.y"
        r="3"
        :fill="point.color"
      />
    </svg>
  </div>
</template>

<script setup lang="ts">
interface DomainScore {
  key: string
  value: number
  color: string
}

const props = defineProps<{
  scores: DomainScore[]
}>()

const gridLevels = [1, 2, 3, 4, 5]
const center = { x: 60, y: 60 }
const radius = 44
const axes = computed(() => props.scores.slice(0, 6))

const axisPoints = computed(() => {
  return axes.value.map((_, index) => {
    const angle = (Math.PI * 2 * index) / axes.value.length - Math.PI / 2
    return {
      x: center.x + Math.cos(angle) * radius,
      y: center.y + Math.sin(angle) * radius,
    }
  })
})

const valuePoints = computed(() => {
  return axes.value.map((axis, index) => {
    const angle = (Math.PI * 2 * index) / axes.value.length - Math.PI / 2
    const scaledRadius = (Math.max(1, Math.min(5, axis.value)) / 5) * radius
    return {
      key: axis.key,
      color: axis.color,
      x: center.x + Math.cos(angle) * scaledRadius,
      y: center.y + Math.sin(angle) * scaledRadius,
    }
  })
})

const dataPoints = computed(() => valuePoints.value.map((point) => `${point.x},${point.y}`).join(' '))

const buildPolygonPoints = (level: number) => {
  const scaledRadius = (level / 5) * radius
  return axes.value
    .map((_, index) => {
      const angle = (Math.PI * 2 * index) / axes.value.length - Math.PI / 2
      return `${center.x + Math.cos(angle) * scaledRadius},${center.y + Math.sin(angle) * scaledRadius}`
    })
    .join(' ')
}
</script>
