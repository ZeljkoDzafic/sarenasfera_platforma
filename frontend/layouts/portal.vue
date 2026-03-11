<template>
  <div class="min-h-screen bg-gray-50">
    <PortalTopNav
      :breadcrumbs="breadcrumbs"
      :initials="userInitials"
      :notification-count="3"
      @toggle-sidebar="sidebarOpen = !sidebarOpen"
      @sign-out="signOut"
    />

    <div
      v-if="sidebarOpen"
      class="fixed inset-0 z-20 bg-black/40 lg:hidden"
      @click="sidebarOpen = false"
    />

    <PortalSidebar
      :is-open="sidebarOpen"
      :current-path="route.path"
      :items="navItems"
      @navigate="sidebarOpen = false"
    />

    <main class="pt-16 lg:pl-72">
      <div class="p-4 sm:p-6 lg:p-8">
        <slot />
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'] })

const route = useRoute()
const { user, signOut } = useAuth()
const sidebarOpen = ref(false)

const navItems = [
  {
    to: '/portal',
    label: 'Kontrolna Tabla',
    iconBgClass: 'bg-primary-100 text-primary-700',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>',
  },
  {
    to: '/portal/children',
    label: 'Moja Djeca',
    iconBgClass: 'domain-bg-social text-domain-social',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>',
  },
  {
    to: '/portal/workshops',
    label: 'Radionice',
    iconBgClass: 'domain-bg-creative text-domain-creative',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>',
  },
  {
    to: '/portal/education/events',
    label: 'Edukacija',
    iconBgClass: 'bg-brand-blue/20 text-brand-blue',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l9-5-9-5-9 5 9 5z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l6.16-3.422A12.083 12.083 0 0112 20.055a12.083 12.083 0 01-6.16-9.477L12 14z"/></svg>',
  },
  {
    to: '/portal/activities',
    label: 'Aktivnosti',
    iconBgClass: 'domain-bg-cognitive text-domain-cognitive',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/></svg>',
  },
  {
    to: '/portal/progress',
    label: 'Moj Napredak',
    iconBgClass: 'bg-brand-green/20 text-brand-green',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>',
  },
  {
    to: '/portal/certificates',
    label: 'Sertifikati',
    iconBgClass: 'bg-brand-amber/20 text-brand-amber',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"/></svg>',
  },
  {
    to: '/portal/gallery',
    label: 'Galerija',
    iconBgClass: 'domain-bg-language text-domain-language',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>',
  },
  {
    to: '/portal/referrals',
    label: 'Preporuči',
    iconBgClass: 'bg-brand-amber/20 text-brand-amber',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z"/></svg>',
  },
  {
    to: '/portal/pioneer',
    label: 'Pioniri',
    iconBgClass: 'bg-gradient-to-br from-brand-amber/30 to-primary-100 text-brand-amber',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"/></svg>',
  },
  {
    to: '/portal/community',
    label: 'Zajednica',
    iconBgClass: 'bg-primary-100 text-primary-700',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8h2a2 2 0 012 2v8l-4-4H7a2 2 0 01-2-2v-2m12-4V6a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2h2l4 4v-4h4a2 2 0 002-2V8z"/></svg>',
  },
  {
    to: '/portal/bazar',
    label: 'Dječiji Bazar',
    iconBgClass: 'bg-brand-amber/20 text-brand-amber',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7l1.664 9.15A2 2 0 006.632 18h10.736a2 2 0 001.968-1.85L21 7M3 7h18M8 11h8M9 7V5a3 3 0 016 0v2"/></svg>',
  },
  {
    to: '/portal/settings',
    label: 'Postavke',
    iconBgClass: 'domain-bg-emotional text-domain-emotional',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>',
  },
]

const breadcrumbs = computed(() => {
  const segments = route.path.split('/').filter(Boolean)
  if (segments.length === 0) {
    return [{ label: 'Početna', path: '/portal' }]
  }

  const labelMap: Record<string, string> = {
    portal: 'Portal',
    children: 'Moja Djeca',
    workshops: 'Radionice',
    education: 'Edukacija',
    activities: 'Aktivnosti',
    community: 'Zajednica',
    bazar: 'Dječiji Bazar',
    gallery: 'Galerija',
    referrals: 'Preporuči',
    pioneer: 'Pioniri',
    settings: 'Postavke',
  }

  return segments.map((segment, index) => {
    const path = `/${segments.slice(0, index + 1).join('/')}`
    return {
      label: labelMap[segment] ?? segment,
      path,
    }
  })
})

const userInitials = computed(() => user.value?.email?.charAt(0).toUpperCase() ?? 'U')

watch(
  () => route.path,
  () => {
    sidebarOpen.value = false
  },
)
</script>
