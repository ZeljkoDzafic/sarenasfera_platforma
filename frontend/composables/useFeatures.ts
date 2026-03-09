// T-810: Feature Flags Composable
// Manages feature flags system for platform staged rollout

export type FeatureStatus = 'active' | 'coming_soon' | 'hidden' | 'beta'
export type SubscriptionTier = 'free' | 'paid' | 'premium'

export interface FeatureFlag {
  id: string
  key: string
  name: string
  description: string | null
  status: FeatureStatus
  min_tier: SubscriptionTier
  location_id: string | null
  updated_by: string | null
  created_at: string
  updated_at: string
}

interface FeaturesState {
  flags: FeatureFlag[]
  loading: boolean
  loaded: boolean
}

const featuresState = reactive<FeaturesState>({
  flags: [],
  loading: false,
  loaded: false,
})

export function useFeatures() {
  const supabase = useSupabase()
  const { role } = useAuth()

  // Load all feature flags from database
  async function loadFeatures() {
    if (featuresState.loaded) return // Already loaded

    featuresState.loading = true
    try {
      const { data, error } = await supabase
        .from('feature_flags')
        .select('*')
        .order('key')

      if (error) throw error
      featuresState.flags = data ?? []
      featuresState.loaded = true
    } catch (err) {
      console.error('Failed to load feature flags:', err)
      featuresState.flags = []
    } finally {
      featuresState.loading = false
    }
  }

  // Check if a feature is fully active
  function isActive(key: string): boolean {
    const flag = featuresState.flags.find((f) => f.key === key)
    return flag?.status === 'active'
  }

  // Check if a feature is in "coming soon" state
  function isComingSoon(key: string): boolean {
    const flag = featuresState.flags.find((f) => f.key === key)
    return flag?.status === 'coming_soon'
  }

  // Check if a feature is in beta
  function isBeta(key: string): boolean {
    const flag = featuresState.flags.find((f) => f.key === key)
    return flag?.status === 'beta'
  }

  // Check if a feature is visible (active, coming_soon, or beta)
  function isVisible(key: string): boolean {
    const flag = featuresState.flags.find((f) => f.key === key)
    return flag?.status === 'active' || flag?.status === 'coming_soon' || flag?.status === 'beta'
  }

  // Check if a feature is hidden
  function isHidden(key: string): boolean {
    const flag = featuresState.flags.find((f) => f.key === key)
    return flag?.status === 'hidden' || !flag
  }

  // Get the minimum required tier for a feature
  function requiredTier(key: string): SubscriptionTier {
    const flag = featuresState.flags.find((f) => f.key === key)
    return flag?.min_tier ?? 'free'
  }

  // Get feature flag details
  function getFeature(key: string): FeatureFlag | undefined {
    return featuresState.flags.find((f) => f.key === key)
  }

  // Get all features by status
  function getByStatus(status: FeatureStatus): FeatureFlag[] {
    return featuresState.flags.filter((f) => f.status === status)
  }

  // Get all features by tier
  function getByTier(tier: SubscriptionTier): FeatureFlag[] {
    return featuresState.flags.filter((f) => f.min_tier === tier)
  }

  // Check if user has access to a feature (based on status and tier)
  // Note: Tier checking should be combined with useTier() composable
  function canAccess(key: string, userTier: SubscriptionTier = 'free'): boolean {
    const flag = featuresState.flags.find((f) => f.key === key)
    if (!flag || flag.status === 'hidden') return false
    if (flag.status === 'coming_soon') return false // Coming soon = not accessible yet

    // Check tier access
    const tierHierarchy: Record<SubscriptionTier, number> = {
      free: 0,
      paid: 1,
      premium: 2,
    }

    const userLevel = tierHierarchy[userTier] ?? 0
    const requiredLevel = tierHierarchy[flag.min_tier] ?? 0

    return userLevel >= requiredLevel
  }

  // Admin: Update feature flag status
  async function updateFeatureStatus(key: string, status: FeatureStatus): Promise<void> {
    if (role.value !== 'admin') {
      throw new Error('Only admins can update feature flags')
    }

    const { error } = await supabase
      .from('feature_flags')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('key', key)

    if (error) throw error

    // Update local state
    const flag = featuresState.flags.find((f) => f.key === key)
    if (flag) {
      flag.status = status
      flag.updated_at = new Date().toISOString()
    }
  }

  // Admin: Update feature minimum tier
  async function updateFeatureTier(key: string, minTier: SubscriptionTier): Promise<void> {
    if (role.value !== 'admin') {
      throw new Error('Only admins can update feature flags')
    }

    const { error } = await supabase
      .from('feature_flags')
      .update({ min_tier: minTier, updated_at: new Date().toISOString() })
      .eq('key', key)

    if (error) throw error

    // Update local state
    const flag = featuresState.flags.find((f) => f.key === key)
    if (flag) {
      flag.min_tier = minTier
      flag.updated_at = new Date().toISOString()
    }
  }

  // Save interest in a coming_soon feature
  async function saveInterest(featureKey: string, userId: string): Promise<void> {
    const { error } = await supabase
      .from('feature_interests')
      .insert({
        user_id: userId,
        feature_key: featureKey,
        created_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (error && error.code !== '23505') { // Ignore unique constraint violation (already interested)
      throw error
    }
  }

  // Get interest count for a feature (admin only)
  async function getInterestCount(featureKey: string): Promise<number> {
    if (role.value !== 'admin') return 0

    const { count, error } = await supabase
      .from('feature_interests')
      .select('*', { count: 'exact', head: true })
      .eq('feature_key', featureKey)

    if (error) throw error
    return count ?? 0
  }

  // Computed properties
  const activeFeatures = computed(() => featuresState.flags.filter((f) => f.status === 'active'))
  const comingSoonFeatures = computed(() => featuresState.flags.filter((f) => f.status === 'coming_soon'))
  const betaFeatures = computed(() => featuresState.flags.filter((f) => f.status === 'beta'))

  return {
    // State
    ...toRefs(featuresState),

    // Actions
    loadFeatures,

    // Checkers
    isActive,
    isComingSoon,
    isBeta,
    isVisible,
    isHidden,
    requiredTier,
    canAccess,

    // Getters
    getFeature,
    getByStatus,
    getByTier,

    // Admin actions
    updateFeatureStatus,
    updateFeatureTier,

    // Interest tracking
    saveInterest,
    getInterestCount,

    // Computed
    activeFeatures,
    comingSoonFeatures,
    betaFeatures,
  }
}
