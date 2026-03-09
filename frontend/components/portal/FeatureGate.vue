<template>
  <div v-if="!hasAccess">
    <slot name="locked">
      <div class="card relative overflow-hidden">
        <!-- Blur overlay -->
        <div class="absolute inset-0 bg-white/60 backdrop-blur-sm z-10 flex items-center justify-center p-6">
          <div class="text-center max-w-sm">
            <!-- Lock icon -->
            <div class="w-16 h-16 mx-auto mb-4 rounded-2xl bg-primary-100 flex items-center justify-center">
              <svg class="w-8 h-8 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            </div>
            
            <h3 class="font-display font-bold text-lg text-gray-900 mb-2">
              {{ title || 'Ova funkcija zahtijeva nadogradnju' }}
            </h3>
            
            <p class="text-sm text-gray-600 mb-4">
              {{ message || 'Nadogradite na ' + requiredTierName + ' tier za pristup.' }}
            </p>
            
            <div class="flex gap-2 justify-center">
              <NuxtLink to="/pricing" class="btn-primary text-sm">
                Pregledajte planove
              </NuxtLink>
              <button class="btn-secondary text-sm" @click="$emit('dismiss')">
                Možda kasnije
              </button>
            </div>
          </div>
        </div>
        
        <!-- Blurred content -->
        <div class="opacity-20 pointer-events-none">
          <slot />
        </div>
      </div>
    </slot>
  </div>
  
  <slot v-else />
</template>

<script setup lang="ts">
export type TierName = 'free' | 'paid' | 'premium'

const props = defineProps<{
  requiredTier: TierName
  title?: string
  message?: string
}>()

defineEmits<{
  dismiss: []
}>()

const { tierName } = useTier()

const tierHierarchy: Record<TierName, number> = {
  free: 0,
  paid: 1,
  premium: 2,
}

const hasAccess = computed(() => {
  const currentTier = tierHierarchy[tierName.value] ?? 0
  const requiredTier = tierHierarchy[props.requiredTier] ?? 0
  return currentTier >= requiredTier
})

const requiredTierName = computed(() => {
  const names: Record<TierName, string> = {
    free: 'Free',
    paid: 'Paid',
    premium: 'Premium',
  }
  return names[props.requiredTier]
})
</script>
