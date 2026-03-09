<template>
  <section class="space-y-6">
    <div class="card">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <h2 class="text-xl font-bold text-gray-900">Timeline razvoja</h2>
          <p class="mt-1 text-sm text-gray-600">Mjesečni pregled postignutih milestonea, opservacija i dodanih fotografija.</p>
        </div>

        <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
          <div class="flex flex-wrap gap-2">
            <button
              v-for="domain in domainOptions"
              :key="domain.value"
              class="rounded-full px-3 py-1.5 text-xs font-semibold transition-all"
              :class="activeDomain === domain.value ? 'bg-primary-500 text-white shadow-colorful' : 'bg-gray-100 text-gray-600 hover:bg-primary-50 hover:text-primary-700'"
              @click="$emit('update:active-domain', domain.value)"
            >
              {{ domain.label }}
            </button>
          </div>

          <select
            :value="statusFilter"
            class="input w-auto min-w-44 text-sm"
            @change="$emit('update:status-filter', ($event.target as HTMLSelectElement).value)"
          >
            <option value="all">Svi statusi</option>
            <option value="achieved">Postignuto</option>
            <option value="emerging">U nastajanju</option>
          </select>
        </div>
      </div>
    </div>

    <div v-if="items.length === 0" class="card py-14 text-center">
      <div class="mb-4 text-5xl">🌱</div>
      <h3 class="font-display text-xl font-bold text-gray-900">Još nema razvoja za prikaz</h3>
      <p class="mt-2 text-sm text-gray-500">Kada počnu pristizati milestonei i opservacije, ovdje ćete vidjeti jasan mjesečni pregled.</p>
    </div>

    <div v-else class="relative space-y-6 pl-4 sm:pl-6">
      <div class="absolute bottom-0 left-4 top-2 w-px bg-gray-200 sm:left-6" />

      <article v-for="item in items" :key="item.monthKey" class="relative">
        <div class="absolute left-0 top-1 z-10 h-8 w-8 rounded-full border-4 border-white bg-primary-500 shadow-colorful sm:h-10 sm:w-10" />

        <div class="ml-12 rounded-2xl border border-gray-100 bg-white p-5 shadow-card sm:ml-16">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.25em] text-primary-600">{{ item.label }}</p>
              <h3 class="mt-1 text-lg font-bold text-gray-900">{{ item.summary }}</h3>
            </div>
            <div class="flex flex-wrap gap-2">
              <span class="badge bg-brand-green/15 text-brand-green">
                {{ item.achievedCount }} postignuto
              </span>
              <span class="badge bg-brand-amber/15 text-brand-amber">
                {{ item.emergingCount }} u nastajanju
              </span>
              <span class="badge bg-brand-blue/15 text-brand-blue">
                {{ item.observationCount }} opservacija
              </span>
              <span class="badge bg-brand-pink/15 text-brand-pink">
                {{ item.photoCount }} fotografija
              </span>
            </div>
          </div>

          <div class="mt-5 grid gap-4 lg:grid-cols-[1.3fr_0.7fr]">
            <div class="space-y-3">
              <div v-if="item.milestones.length > 0" class="space-y-3">
                <div
                  v-for="milestone in item.milestones"
                  :key="milestone.id"
                  class="rounded-2xl border px-4 py-3"
                  :class="milestone.status === 'achieved' ? 'border-brand-green/30 bg-brand-green/5' : 'border-brand-amber/30 bg-brand-amber/5'"
                >
                  <div class="flex items-start gap-3">
                    <div
                      class="flex h-10 w-10 items-center justify-center rounded-xl text-lg"
                      :style="{ backgroundColor: `${milestone.color}20`, color: milestone.color }"
                    >
                      {{ milestone.emoji }}
                    </div>
                    <div class="flex-1">
                      <div class="flex flex-wrap items-center gap-2">
                        <h4 class="font-semibold text-gray-900">{{ milestone.title }}</h4>
                        <span
                          class="rounded-full px-2 py-0.5 text-xs font-semibold"
                          :class="milestone.status === 'achieved' ? 'bg-brand-green/15 text-brand-green' : 'bg-brand-amber/15 text-brand-amber'"
                        >
                          {{ milestone.status === 'achieved' ? 'Postignuto' : 'U nastajanju' }}
                        </span>
                      </div>
                      <p v-if="milestone.description" class="mt-1 text-sm text-gray-600">{{ milestone.description }}</p>
                    </div>
                  </div>
                </div>
              </div>

              <div v-else class="rounded-2xl bg-gray-50 px-4 py-3 text-sm text-gray-500">
                Nema milestone zapisa za ovaj mjesec.
              </div>
            </div>

            <div class="space-y-3">
              <div class="rounded-2xl bg-gray-50 p-4">
                <h4 class="text-sm font-bold text-gray-900">Nedavne opservacije</h4>
                <ul class="mt-3 space-y-2">
                  <li v-for="observation in item.observations" :key="observation.id" class="text-sm text-gray-600">
                    <span class="font-semibold text-gray-800">{{ observation.domainLabel }}:</span>
                    {{ observation.content }}
                  </li>
                </ul>
                <p v-if="item.observations.length === 0" class="mt-3 text-sm text-gray-400">Nema opservacija za ovaj period.</p>
              </div>

              <div class="rounded-2xl bg-gray-50 p-4">
                <h4 class="text-sm font-bold text-gray-900">Brzi pregled</h4>
                <dl class="mt-3 space-y-2 text-sm text-gray-600">
                  <div class="flex items-center justify-between gap-3">
                    <dt>Najjači domen</dt>
                    <dd class="font-semibold text-gray-900">{{ item.topDomainLabel }}</dd>
                  </div>
                  <div class="flex items-center justify-between gap-3">
                    <dt>Milestone fokus</dt>
                    <dd class="font-semibold text-gray-900">{{ item.focusLabel }}</dd>
                  </div>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </article>
    </div>
  </section>
</template>

<script setup lang="ts">
export interface GrowthTimelineMonth {
  monthKey: string
  label: string
  summary: string
  achievedCount: number
  emergingCount: number
  observationCount: number
  photoCount: number
  topDomainLabel: string
  focusLabel: string
  milestones: Array<{
    id: string
    title: string
    description: string
    status: 'achieved' | 'emerging'
    color: string
    emoji: string
  }>
  observations: Array<{
    id: string
    domainLabel: string
    content: string
  }>
}

defineProps<{
  items: GrowthTimelineMonth[]
  activeDomain: string
  statusFilter: string
  domainOptions: Array<{ label: string; value: string }>
}>()

defineEmits<{
  (event: 'update:active-domain', value: string): void
  (event: 'update:status-filter', value: string): void
}>()
</script>
