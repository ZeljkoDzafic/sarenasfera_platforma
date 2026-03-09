<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Top navigation -->
    <header class="bg-white border-b border-gray-200 fixed top-0 left-0 right-0 z-30">
      <div class="flex items-center justify-between h-16 px-4">
        <!-- Left: menu toggle + logo -->
        <div class="flex items-center gap-3">
          <button
            class="lg:hidden p-2 rounded-lg text-gray-600 hover:bg-gray-100"
            @click="sidebarOpen = !sidebarOpen"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
          <NuxtLink to="/portal" class="flex items-center gap-2">
            <div class="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
              <span class="text-white font-bold text-sm">ŠS</span>
            </div>
            <span class="text-lg font-bold text-gray-900 hidden sm:block">Šarena Sfera</span>
          </NuxtLink>
        </div>

        <!-- Right: notifications + user -->
        <div class="flex items-center gap-3">
          <button class="p-2 rounded-lg text-gray-600 hover:bg-gray-100 relative">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
          </button>
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
              <span class="text-primary-700 text-sm font-medium">
                {{ user?.email?.charAt(0).toUpperCase() }}
              </span>
            </div>
            <button @click="signOut" class="text-sm text-gray-600 hover:text-gray-900 hidden sm:block">
              Odjava
            </button>
          </div>
        </div>
      </div>
    </header>

    <!-- Sidebar overlay (mobile) -->
    <div
      v-if="sidebarOpen"
      class="fixed inset-0 bg-black/50 z-40 lg:hidden"
      @click="sidebarOpen = false"
    />

    <!-- Sidebar -->
    <aside
      :class="[
        'fixed top-16 left-0 bottom-0 w-64 bg-white border-r border-gray-200 z-40 transition-transform',
        sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
      ]"
    >
      <nav class="p-4 space-y-1">
        <NuxtLink
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors"
          :class="route.path === item.to || route.path.startsWith(item.to + '/')
            ? 'bg-primary-50 text-primary-700'
            : 'text-gray-600 hover:bg-gray-100'"
          @click="sidebarOpen = false"
        >
          <span v-html="item.icon" class="w-5 h-5" />
          {{ item.label }}
        </NuxtLink>
      </nav>
    </aside>

    <!-- Main content -->
    <main class="pt-16 lg:pl-64">
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
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>',
  },
  {
    to: '/portal/children',
    label: 'Moja Djeca',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>',
  },
  {
    to: '/portal/workshops',
    label: 'Radionice',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>',
  },
  {
    to: '/portal/activities',
    label: 'Aktivnosti',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/></svg>',
  },
  {
    to: '/portal/gallery',
    label: 'Galerija',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>',
  },
  {
    to: '/portal/profile',
    label: 'Profil',
    icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>',
  },
]

watch(() => route.path, () => {
  sidebarOpen.value = false
})
</script>
