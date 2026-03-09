<template>
  <div class="card space-y-4">
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <h2 class="text-lg font-bold text-gray-900">Mjesečni kalendar radionica</h2>
      <p class="text-sm text-gray-600">{{ monthLabel }}</p>
    </div>

    <div class="grid grid-cols-7 gap-2 text-center text-xs font-semibold text-gray-500">
      <span v-for="day in weekDays" :key="day">{{ day }}</span>
    </div>

    <div class="grid grid-cols-7 gap-2">
      <div
        v-for="cell in calendarCells"
        :key="cell.key"
        class="min-h-20 rounded-xl border p-2"
        :class="cell.isCurrentMonth ? 'border-gray-200 bg-white' : 'border-gray-100 bg-gray-50 text-gray-400'"
      >
        <p class="text-xs font-semibold">{{ cell.date.getDate() }}</p>
        <div class="mt-1 space-y-1">
          <p
            v-for="session in cell.sessions"
            :key="session.id"
            class="truncate rounded-md px-1.5 py-0.5 text-[11px] font-semibold"
            :class="session.isPast ? 'bg-gray-200 text-gray-700' : 'bg-primary-100 text-primary-700'"
            :title="session.title"
          >
            {{ session.title }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface SessionItem {
  id: string
  title: string
  date: string
  isPast: boolean
}

const props = defineProps<{
  sessions: SessionItem[]
  selectedMonth: Date
}>()

const weekDays = ['Pon', 'Uto', 'Sri', 'Čet', 'Pet', 'Sub', 'Ned']

const monthLabel = computed(() => props.selectedMonth.toLocaleDateString('bs-BA', {
  month: 'long',
  year: 'numeric',
}))

const startOfMonth = computed(() => new Date(props.selectedMonth.getFullYear(), props.selectedMonth.getMonth(), 1))
const endOfMonth = computed(() => new Date(props.selectedMonth.getFullYear(), props.selectedMonth.getMonth() + 1, 0))

const normalizedWeekday = (date: Date) => {
  const day = date.getDay()
  return day === 0 ? 7 : day
}

const calendarCells = computed(() => {
  const start = new Date(startOfMonth.value)
  start.setDate(start.getDate() - (normalizedWeekday(start) - 1))

  const end = new Date(endOfMonth.value)
  end.setDate(end.getDate() + (7 - normalizedWeekday(end)))

  const cells: Array<{ key: string; date: Date; isCurrentMonth: boolean; sessions: SessionItem[] }> = []

  for (const cursor = new Date(start); cursor <= end; cursor.setDate(cursor.getDate() + 1)) {
    const iso = cursor.toISOString().slice(0, 10)
    cells.push({
      key: iso,
      date: new Date(cursor),
      isCurrentMonth: cursor.getMonth() === props.selectedMonth.getMonth(),
      sessions: props.sessions.filter((session) => session.date === iso),
    })
  }

  return cells
})
</script>
