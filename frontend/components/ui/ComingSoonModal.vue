<template>
  <Teleport to="body">
    <div
      v-if="modelValue"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
      @click.self="$emit('update:modelValue', false)"
    >
      <div class="bg-white rounded-2xl w-full max-w-md shadow-xl overflow-hidden">
        <!-- Header with gradient -->
        <div class="bg-gradient-to-r from-brand-amber/20 to-primary-50 p-6 text-center">
          <div class="text-5xl mb-3">🔜</div>
          <h2 class="font-display font-bold text-xl text-gray-900">{{ featureName }}</h2>
          <p class="text-sm text-gray-600 mt-2">Ova funkcija je uskoro dostupna</p>
        </div>

        <!-- Content -->
        <div class="p-6">
          <p v-if="description" class="text-gray-700 text-sm mb-4">
            {{ description }}
          </p>

          <div class="bg-primary-50 rounded-xl p-4 mb-4">
            <p class="text-xs font-semibold text-primary-700 mb-2">Šta možete očekivati:</p>
            <ul class="space-y-1 text-xs text-gray-700">
              <li v-for="(benefit, i) in benefits" :key="i" class="flex items-start gap-2">
                <span class="text-primary-600">✓</span>
                {{ benefit }}
              </li>
            </ul>
          </div>

          <!-- Interest form -->
          <div v-if="!interested" class="space-y-3">
            <p class="text-xs text-gray-600 text-center">
              Obavijestite me kada bude dostupno:
            </p>
            <button
              class="btn-primary w-full"
              :disabled="savingInterest"
              @click="saveInterest"
            >
              {{ savingInterest ? 'Čuva...' : '📬 Obavijesti me' }}
            </button>
          </div>

          <div v-else class="text-center py-3 bg-brand-green/5 rounded-xl">
            <p class="text-sm text-brand-green font-semibold">
              ✓ Sačuvano! Obavijestićemo vas kada bude spremno.
            </p>
          </div>

          <!-- Close button -->
          <button
            class="btn-ghost w-full mt-4"
            @click="$emit('update:modelValue', false)"
          >
            Zatvori
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue: boolean
  featureKey: string
  featureName: string
  description?: string
  benefits?: string[]
}>()

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
}>()

const supabase = useSupabase()
const { user } = useAuth()

const savingInterest = ref(false)
const interested = ref(false)

async function saveInterest() {
  if (!user.value || !props.featureKey) return

  savingInterest.value = true

  try {
    const { error } = await supabase
      .from('feature_interests')
      .insert({
        user_id: user.value.id,
        feature_key: props.featureKey,
      })

    if (error) throw error
    interested.value = true
  } catch (err) {
    console.error('Failed to save interest:', err)
  } finally {
    savingInterest.value = false
  }
}

// Check if already interested
onMounted(async () => {
  if (!user.value || !props.featureKey) return

  const { data } = await supabase
    .from('feature_interests')
    .select('id')
    .eq('user_id', user.value.id)
    .eq('feature_key', props.featureKey)
    .maybeSingle()

  interested.value = !!data
})
</script>
