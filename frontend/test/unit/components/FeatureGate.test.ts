// test/unit/components/FeatureGate.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import FeatureGate from '~/components/portal/FeatureGate.vue'

describe('FeatureGate', () => {
  let mockTierName: any

  beforeEach(() => {
    vi.clearAllMocks()
    mockTierName = { ref: vi.fn(() => ({ value: 'paid' })) }

    vi.mock('~/composables/useTier', () => ({
      useTier: () => ({ tierName: mockTierName })
    }))
  })

  it('should show content when user has access', async () => {
    const FeatureGate = (await import('~/components/portal/FeatureGate.vue')).default
    const wrapper = mount(FeatureGate, {
      props: {
        requiredTier: 'free'
      },
      slots: {
        default: '<p>Protected Content</p>'
      }
    })

    expect(wrapper.text()).toContain('Protected Content')
  })

  it('should show locked state when user lacks access', async () => {
    const FeatureGate = (await import('~/components/portal/FeatureGate.vue')).default
    const wrapper = mount(FeatureGate, {
      props: {
        requiredTier: 'premium'
      },
      slots: {
        default: '<p>Protected Content</p>',
        locked: '<div>Locked Message</div>'
      }
    })

    expect(wrapper.text()).toContain('Locked Message')
    expect(wrapper.text()).not.toContain('Protected Content')
  })

  it('should show default locked message without custom slot', async () => {
    const FeatureGate = (await import('~/components/portal/FeatureGate.vue')).default
    const wrapper = mount(FeatureGate, {
      props: {
        requiredTier: 'premium',
        title: 'Custom Title'
      },
      slots: {
        default: '<p>Protected Content</p>'
      }
    })

    expect(wrapper.text()).toContain('Custom Title')
    expect(wrapper.text()).toContain('Premium')
  })

  it('should emit dismiss event', async () => {
    const FeatureGate = (await import('~/components/portal/FeatureGate.vue')).default
    const wrapper = mount(FeatureGate, {
      props: {
        requiredTier: 'premium'
      },
      slots: {
        default: '<p>Content</p>'
      }
    })

    await wrapper.find('button').trigger('click')
    expect(wrapper.emitted('dismiss')).toBeTruthy()
  })

  it('should allow paid tier to access free content', async () => {
    const FeatureGate = (await import('~/components/portal/FeatureGate.vue')).default
    const wrapper = mount(FeatureGate, {
      props: {
        requiredTier: 'free'
      },
      slots: {
        default: '<p>Free Content</p>'
      }
    })

    expect(wrapper.text()).toContain('Free Content')
  })

  it('should allow premium tier to access paid content', async () => {
    mockTierName.ref = vi.fn(() => ({ value: 'premium' }))
    
    const FeatureGate = (await import('~/components/portal/FeatureGate.vue')).default
    const wrapper = mount(FeatureGate, {
      props: {
        requiredTier: 'paid'
      },
      slots: {
        default: '<p>Paid Content</p>'
      }
    })

    expect(wrapper.text()).toContain('Paid Content')
  })

  it('should block free tier from accessing paid content', async () => {
    mockTierName.ref = vi.fn(() => ({ value: 'free' }))
    
    const FeatureGate = (await import('~/components/portal/FeatureGate.vue')).default
    const wrapper = mount(FeatureGate, {
      props: {
        requiredTier: 'paid'
      },
      slots: {
        default: '<p>Paid Content</p>',
        locked: '<div>Upgrade Required</div>'
      }
    })

    expect(wrapper.text()).toContain('Upgrade Required')
  })
})
