<template>
  <span
    v-if="visible"
    class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold"
    :class="variantClasses[variant]"
  >
    <slot name="icon">
      <span v-if="variant === 'coming_soon'">🔜</span>
      <span v-else-if="variant === 'beta'">🧪</span>
      <span v-else-if="variant === 'locked'">🔒</span>
    </slot>
    {{ label }}
  </span>
</template>

<script setup lang="ts">
export type BadgeVariant = 'coming_soon' | 'beta' | 'locked' | 'new' | 'popular'

const props = defineProps<{
  variant?: BadgeVariant
  label?: string
  visible?: boolean
}>()

const variantClasses: Record<BadgeVariant, string> = {
  coming_soon: 'bg-brand-amber/15 text-brand-amber border border-brand-amber/20',
  beta: 'bg-primary-100 text-primary-700 border border-primary-200',
  locked: 'bg-gray-100 text-gray-500 border border-gray-200',
  new: 'bg-brand-green/15 text-brand-green border border-brand-green/20',
  popular: 'bg-brand-pink/15 text-brand-pink border border-brand-pink/20',
}

const defaultLabels: Record<BadgeVariant, string> = {
  coming_soon: 'Uskoro',
  beta: 'Beta',
  locked: 'Zaključano',
  new: 'Novo',
  popular: 'Popularno',
}

const visible = computed(() => props.visible ?? true)
const label = computed(() => props.label ?? defaultLabels[props.variant || 'coming_soon'])
</script>
