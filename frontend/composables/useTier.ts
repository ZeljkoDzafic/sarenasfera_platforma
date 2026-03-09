import type { Ref } from 'vue'

export type TierName = 'free' | 'paid' | 'premium'

interface TierState {
  tier: TierName
  loading: boolean
}

const tierState = reactive<TierState>({
  tier: 'free',
  loading: true,
})

export function useTier() {
  const supabase = useSupabase()
  const { user } = useAuth()

  // Load user's tier from profile
  async function loadTier() {
    if (!user.value) {
      tierState.tier = 'free'
      tierState.loading = false
      return
    }

    tierState.loading = true
    try {
      const { data } = await supabase
        .from('profiles')
        .select('subscription_tier')
        .eq('id', user.value.id)
        .single()

      tierState.tier = (data?.subscription_tier as TierName) ?? 'free'
    } catch (error) {
      console.error('Failed to load tier:', error)
      tierState.tier = 'free'
    } finally {
      tierState.loading = false
    }
  }

  // Check if user has access to a specific tier
  function hasAccess(requiredTier: TierName): boolean {
    const tierHierarchy: Record<TierName, number> = {
      free: 0,
      paid: 1,
      premium: 2,
    }

    const currentTier = tierHierarchy[tierState.tier] ?? 0
    const required = tierHierarchy[requiredTier] ?? 0

    return currentTier >= required
  }

  // Check if user can add more children (example tier-gated feature)
  function canAddChild(): boolean {
    // Free: 1 child, Paid: 3 children, Premium: unlimited
    return tierState.tier !== 'free'
  }

  // Get tier display name
  function getTierDisplayName(tier: TierName): string {
    const names: Record<TierName, string> = {
      free: 'Free',
      paid: 'Paid',
      premium: 'Premium',
    }
    return names[tier]
  }

  // Get tier price
  function getTierPrice(tier: TierName): string {
    const prices: Record<TierName, string> = {
      free: '0 KM',
      paid: '15 KM/mj',
      premium: '30 KM/mj',
    }
    return prices[tier]
  }

  // Initialize tier on auth change
  watch(user, () => {
    loadTier()
  }, { immediate: true })

  const tierName = computed(() => tierState.tier)
  const isFree = computed(() => tierState.tier === 'free')
  const isPaid = computed(() => tierState.tier === 'paid')
  const isPremium = computed(() => tierState.tier === 'premium')

  return {
    tierName,
    isFree,
    isPaid,
    isPremium,
    loading: toRef(tierState, 'loading'),
    loadTier,
    hasAccess,
    canAddChild,
    getTierDisplayName,
    getTierPrice,
  }
}
