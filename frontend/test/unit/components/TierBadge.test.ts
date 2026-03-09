// test/unit/components/TierBadge.test.ts
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import TierBadge from '~/components/ui/TierBadge.vue'

describe('TierBadge', () => {
  it('should render free tier badge', () => {
    const wrapper = mount(TierBadge, {
      props: {
        tier: 'free',
        showIcon: true
      }
    })

    expect(wrapper.text()).toContain('Free')
    expect(wrapper.text()).toContain('🆓')
    expect(wrapper.classes()).toContain('bg-gray-100')
  })

  it('should render paid tier badge', () => {
    const wrapper = mount(TierBadge, {
      props: {
        tier: 'paid',
        showIcon: true
      }
    })

    expect(wrapper.text()).toContain('Paid')
    expect(wrapper.text()).toContain('⭐')
    expect(wrapper.classes()).toContain('bg-primary-100')
  })

  it('should render premium tier badge', () => {
    const wrapper = mount(TierBadge, {
      props: {
        tier: 'premium',
        showIcon: true
      }
    })

    expect(wrapper.text()).toContain('Premium')
    expect(wrapper.text()).toContain('👑')
    expect(wrapper.classes()).toContain('bg-gradient-to-r')
  })

  it('should hide icon when showIcon is false', () => {
    const wrapper = mount(TierBadge, {
      props: {
        tier: 'paid',
        showIcon: false
      }
    })

    expect(wrapper.text()).not.toContain('⭐')
    expect(wrapper.text()).toContain('Paid')
  })

  it('should use small size by default', () => {
    const wrapper = mount(TierBadge, {
      props: {
        tier: 'free'
      }
    })

    expect(wrapper.classes()).toContain('text-xs')
  })
})
