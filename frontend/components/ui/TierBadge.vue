<template>
  <span
    class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold"
    :class="tierClasses[tier]"
  >
    <span v-if="showIcon" class="mr-1">{{ tierIcon }}</span>
    {{ tierLabel }}
  </span>
</template>

<script setup lang="ts">
export type TierType = 'free' | 'paid' | 'premium'

const props = withDefaults(defineProps<{
  tier: TierType
  showIcon?: boolean
  size?: 'sm' | 'md'
}>(), {
  showIcon: true,
  size: 'sm',
})

const tierClasses: Record<TierType, string> = {
  free: 'bg-gray-100 text-gray-700 border border-gray-200',
  paid: 'bg-primary-100 text-primary-700 border border-primary-200',
  premium: 'bg-gradient-to-r from-primary-500 to-brand-pink text-white',
}

const tierIcons: Record<TierType, string> = {
  free: '🆓',
  paid: '⭐',
  premium: '👑',
}

const tierLabels: Record<TierType, string> = {
  free: 'Free',
  paid: 'Paid',
  premium: 'Premium',
}

const tierIcon = computed(() => props.showIcon ? tierIcons[props.tier] : '')
const tierLabel = computed(() => tierLabels[props.tier])
</script>
