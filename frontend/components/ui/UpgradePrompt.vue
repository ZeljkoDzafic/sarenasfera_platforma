<template>
  <div
    v-if="!hasAccess"
    class="card bg-gradient-to-r from-primary-50 to-brand-pink/10 border-2 border-primary-200"
  >
    <div class="flex items-start gap-4">
      <!-- Icon -->
      <div class="w-12 h-12 rounded-xl bg-primary-100 flex items-center justify-center flex-shrink-0">
        <svg class="w-6 h-6 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
        </svg>
      </div>

      <!-- Content -->
      <div class="flex-1 min-w-0">
        <h3 class="font-display font-bold text-gray-900 mb-1">
          {{ title || 'Otključajte sve mogućnosti' }}
        </h3>

        <p class="text-sm text-gray-600 mb-3">
          Nadogradite na
          <span class="font-semibold text-primary-600">{{ requiredTierName }}</span>
          tier i pristupite svim funkcijama platforme.
        </p>

        <!-- Feature highlights -->
        <ul v-if="features && features.length > 0" class="space-y-1 mb-3">
          <li v-for="feature in features" :key="feature" class="flex items-center gap-2 text-sm text-gray-700">
            <svg class="w-4 h-4 text-brand-green flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            {{ feature }}
          </li>
        </ul>

        <!-- CTA buttons -->
        <div class="flex gap-2">
          <NuxtLink :to="ctaLink" class="btn-primary text-sm">
            Nadogradi na {{ requiredTierName }}
          </NuxtLink>
          <button v-if="dismissible" class="btn-ghost text-sm" @click="$emit('dismiss')">
            Možda kasnije
          </button>
        </div>
      </div>

      <!-- Close button -->
      <button v-if="dismissible" class="p-1 text-gray-400 hover:text-gray-600" @click="$emit('dismiss')">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
export type TierName = 'paid' | 'premium'

const props = defineProps<{
  requiredTier?: TierName
  title?: string
  features?: string[]
  dismissible?: boolean
  ctaLink?: string
  hasAccess?: boolean
}>()

defineEmits<{
  dismiss: []
}>()

const requiredTierName = computed(() => {
  const names: Record<TierName, string> = {
    paid: 'Paid',
    premium: 'Premium',
  }
  return props.requiredTier ? names[props.requiredTier] : 'Paid'
})

const ctaLink = computed(() => props.ctaLink || '/pricing')
const hasAccess = computed(() => props.hasAccess ?? false)
</script>
