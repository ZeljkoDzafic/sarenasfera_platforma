// test/unit/components/ComingSoonBadge.test.ts
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ComingSoonBadge from '~/components/ui/ComingSoonBadge.vue'

describe('ComingSoonBadge', () => {
  it('should render coming soon badge by default', () => {
    const wrapper = mount(ComingSoonBadge, {
      props: {
        variant: 'coming_soon',
        visible: true
      }
    })

    expect(wrapper.text()).toContain('Uskoro')
    expect(wrapper.text()).toContain('🔜')
    expect(wrapper.classes()).toContain('bg-brand-amber/15')
  })

  it('should render beta badge', () => {
    const wrapper = mount(ComingSoonBadge, {
      props: {
        variant: 'beta',
        visible: true
      }
    })

    expect(wrapper.text()).toContain('Beta')
    expect(wrapper.text()).toContain('🧪')
    expect(wrapper.classes()).toContain('bg-primary-100')
  })

  it('should render locked badge', () => {
    const wrapper = mount(ComingSoonBadge, {
      props: {
        variant: 'locked',
        visible: true
      }
    })

    expect(wrapper.text()).toContain('Zaključano')
    expect(wrapper.text()).toContain('🔒')
    expect(wrapper.classes()).toContain('bg-gray-100')
  })

  it('should render new badge', () => {
    const wrapper = mount(ComingSoonBadge, {
      props: {
        variant: 'new',
        visible: true
      }
    })

    expect(wrapper.text()).toContain('Novo')
    expect(wrapper.classes()).toContain('bg-brand-green/15')
  })

  it('should render popular badge', () => {
    const wrapper = mount(ComingSoonBadge, {
      props: {
        variant: 'popular',
        visible: true
      }
    })

    expect(wrapper.text()).toContain('Popularno')
    expect(wrapper.classes()).toContain('bg-brand-pink/15')
  })

  it('should accept custom label', () => {
    const wrapper = mount(ComingSoonBadge, {
      props: {
        variant: 'coming_soon',
        label: 'Custom Label',
        visible: true
      }
    })

    expect(wrapper.text()).toContain('Custom Label')
  })

  it('should not render when visible is false', () => {
    const wrapper = mount(ComingSoonBadge, {
      props: {
        variant: 'coming_soon',
        visible: false
      }
    })

    expect(wrapper.element.style.display).toBe('none')
  })

  it('should render by default when visible is not provided', () => {
    const wrapper = mount(ComingSoonBadge, {
      props: {
        variant: 'coming_soon'
      }
    })

    expect(wrapper.isVisible()).toBe(true)
  })
})
