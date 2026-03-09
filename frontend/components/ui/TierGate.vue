<template>
  <div v-if="!hasAccess" class="relative">
    <!-- Blurred content -->
    <div class="opacity-30 pointer-events-none">
      <slot />
    </div>

    <!-- Lock overlay -->
    <div class="absolute inset-0 flex items-center justify-center">
      <div class="text-center bg-white/90 backdrop-blur-sm rounded-2xl p-6 shadow-lg">
        <div class="w-16 h-16 mx-auto mb-3 rounded-2xl bg-primary-100 flex items-center justify-center">
          <svg class="w-8 h-8 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
        </div>

        <h3 class="font-display font-bold text-lg text-gray-900 mb-2">
          {{ title || 'Potrebna nadogradnja' }}
        </h3>

        <p class="text-sm text-gray-600 mb-4">
          Ova funkcija je dostupna samo na
          <span class="font-semibold text-primary-600">{{ tierName }}</span>
          tieru.
        </p>

        <div class="flex gap-2 justify-center">
          <NuxtLink :to="ctaLink" class="btn-primary text-sm">
            Nadogradi
          </NuxtLink>
          <button v-if="dismissible" class="btn-ghost text-sm" @click="$emit('dismiss')">
            Zatvori
          </button>
        </div>
      </div>
    </div>
  </div>

  <slot v-else name="unlocked" />
</template>

<script setup lang="ts">
export type TierType = 'free' | 'paid' | 'premium'

const props = withDefaults(defineProps<{
  requiredTier: TierType
  title?: string
  dismissible?: boolean
  ctaLink?: string
}>(), {
  dismissible: true,
})

defineEmits<{
  dismiss: []
}>()

const { tierName } = useTier()

const tierHierarchy: Record<TierType, number> = {
  free: 0,
  paid: 1,
  premium: 2,
}

const hasAccess = computed(() => {
  const currentTier = tierHierarchy[tierName.value] ?? 0
  const requiredTier = tierHierarchy[props.requiredTier] ?? 0
  return currentTier >= requiredTier
})

const ctaLink = computed(() => props.ctaLink || '/pricing')
</script>
