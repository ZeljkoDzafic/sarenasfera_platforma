// test/unit/composables/useFeatures.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest'

describe('useFeatures', () => {
  let mockSupabase: any
  let mockRole: any

  beforeEach(() => {
    vi.clearAllMocks()
    
    mockRole = { ref: vi.fn(() => ({ value: 'parent' })) }
    
    mockSupabase = {
      from: vi.fn(() => ({
        select: vi.fn(() => ({
          order: vi.fn(() => Promise.resolve({ 
            data: [
              { 
                key: 'portal.dashboard', 
                status: 'active', 
                min_tier: 'free' 
              },
              { 
                key: 'portal.passport', 
                status: 'active', 
                min_tier: 'paid' 
              },
              { 
                key: 'portal.forum', 
                status: 'coming_soon', 
                min_tier: 'free' 
              },
            ], 
            error: null 
          }))
        }))
      }))
    }

    vi.mock('~/composables/useSupabase', () => ({
      useSupabase: () => mockSupabase
    }))

    vi.mock('~/composables/useAuth', () => ({
      useAuth: () => ({ role: mockRole.ref })
    }))
  })

  describe('loadFeatures', () => {
    it('should load features from database', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, activeFeatures } = useFeatures.useFeatures()
      await loadFeatures()
      expect(activeFeatures.value.length).toBeGreaterThan(0)
    })

    it('should handle empty features list', async () => {
      mockSupabase.from = vi.fn(() => ({
        select: vi.fn(() => ({
          order: vi.fn(() => Promise.resolve({ data: [], error: null }))
        }))
      }))

      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures } = useFeatures.useFeatures()
      await loadFeatures()
      
      expect(useFeatures.useFeatures().flags.value).toEqual([])
    })
  })

  describe('isActive', () => {
    it('should return true for active feature', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, isActive } = useFeatures.useFeatures()
      await loadFeatures()
      expect(isActive('portal.dashboard')).toBe(true)
    })

    it('should return false for coming_soon feature', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, isActive } = useFeatures.useFeatures()
      await loadFeatures()
      expect(isActive('portal.forum')).toBe(false)
    })

    it('should return false for non-existent feature', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, isActive } = useFeatures.useFeatures()
      await loadFeatures()
      expect(isActive('nonexistent.feature')).toBe(false)
    })
  })

  describe('isComingSoon', () => {
    it('should return true for coming_soon feature', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, isComingSoon } = useFeatures.useFeatures()
      await loadFeatures()
      expect(isComingSoon('portal.forum')).toBe(true)
    })

    it('should return false for active feature', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, isComingSoon } = useFeatures.useFeatures()
      await loadFeatures()
      expect(isComingSoon('portal.dashboard')).toBe(false)
    })
  })

  describe('isVisible', () => {
    it('should return true for active feature', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, isVisible } = useFeatures.useFeatures()
      await loadFeatures()
      expect(isVisible('portal.dashboard')).toBe(true)
    })

    it('should return true for coming_soon feature', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, isVisible } = useFeatures.useFeatures()
      await loadFeatures()
      expect(isVisible('portal.forum')).toBe(true)
    })

    it('should return false for hidden feature', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, isVisible } = useFeatures.useFeatures()
      await loadFeatures()
      expect(isVisible('hidden.feature')).toBe(false)
    })
  })

  describe('requiredTier', () => {
    it('should return min_tier for feature', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, requiredTier } = useFeatures.useFeatures()
      await loadFeatures()
      expect(requiredTier('portal.passport')).toBe('paid')
    })

    it('should default to free for non-existent feature', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, requiredTier } = useFeatures.useFeatures()
      await loadFeatures()
      expect(requiredTier('nonexistent.feature')).toBe('free')
    })
  })

  describe('canAccess', () => {
    it('should return true when user tier meets requirement', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, canAccess } = useFeatures.useFeatures()
      await loadFeatures()
      expect(canAccess('portal.dashboard', 'free')).toBe(true)
    })

    it('should return false when user tier is below requirement', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, canAccess } = useFeatures.useFeatures()
      await loadFeatures()
      expect(canAccess('portal.passport', 'free')).toBe(false)
    })

    it('should return false for hidden feature', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, canAccess } = useFeatures.useFeatures()
      await loadFeatures()
      expect(canAccess('hidden.feature', 'premium')).toBe(false)
    })
  })

  describe('getFeature', () => {
    it('should return feature details', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, getFeature } = useFeatures.useFeatures()
      await loadFeatures()
      const feature = getFeature('portal.dashboard')
      expect(feature).toBeDefined()
      expect(feature?.key).toBe('portal.dashboard')
    })

    it('should return undefined for non-existent feature', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, getFeature } = useFeatures.useFeatures()
      await loadFeatures()
      expect(getFeature('nonexistent.feature')).toBeUndefined()
    })
  })

  describe('getByStatus', () => {
    it('should return features filtered by status', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, getByStatus } = useFeatures.useFeatures()
      await loadFeatures()
      const activeFeatures = getByStatus('active')
      expect(activeFeatures.length).toBeGreaterThan(0)
      activeFeatures.forEach(f => expect(f.status).toBe('active'))
    })
  })

  describe('getByTier', () => {
    it('should return features filtered by tier', async () => {
      const useFeatures = await import('~/composables/useFeatures')
      const { loadFeatures, getByTier } = useFeatures.useFeatures()
      await loadFeatures()
      const freeFeatures = getByTier('free')
      freeFeatures.forEach(f => expect(f.min_tier).toBe('free'))
    })
  })
})
