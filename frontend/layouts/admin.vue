<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Top navigation -->
    <header class="bg-white border-b border-gray-200 fixed top-0 left-0 right-0 z-30">
      <div class="flex items-center justify-between h-16 px-4">
        <div class="flex items-center gap-3">
          <button
            class="lg:hidden p-2 rounded-lg text-gray-600 hover:bg-gray-100"
            @click="sidebarOpen = !sidebarOpen"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
          <NuxtLink to="/admin" class="flex items-center gap-2">
            <div class="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
              <span class="text-white font-bold text-sm">ŠS</span>
            </div>
            <span class="text-lg font-bold text-gray-900 hidden sm:block">Admin Panel</span>
          </NuxtLink>
        </div>

        <div class="flex items-center gap-3">
          <!-- Quick add -->
          <button
            class="btn-primary text-xs gap-1"
            @click="showQuickAdd = !showQuickAdd"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            <span class="hidden sm:inline">Brzi unos</span>
          </button>

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

    <!-- Sidebar overlay -->
    <div
      v-if="sidebarOpen"
      class="fixed inset-0 bg-black/50 z-40 lg:hidden"
      @click="sidebarOpen = false"
    />

    <!-- Sidebar -->
    <aside
      :class="[
        'fixed top-16 left-0 bottom-0 w-64 bg-white border-r border-gray-200 z-40 transition-transform overflow-y-auto',
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

    <!-- Quick add modal placeholder -->
    <div v-if="showQuickAdd" class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" @click.self="showQuickAdd = false">
      <div class="bg-white rounded-xl shadow-xl p-6 w-full max-w-md">
        <h3 class="text-lg font-semibold mb-4">Brzi unos</h3>
        <div class="grid grid-cols-2 gap-3">
          <NuxtLink to="/admin/observations" class="card text-center hover:border-primary-300" @click="showQuickAdd = false">
            <div class="text-2xl mb-1">📝</div>
            <div class="text-sm font-medium">Nova opservacija</div>
          </NuxtLink>
          <NuxtLink to="/admin/attendance" class="card text-center hover:border-primary-300" @click="showQuickAdd = false">
            <div class="text-2xl mb-1">✅</div>
            <div class="text-sm font-medium">Prisustvo</div>
          </NuxtLink>
        </div>
        <button class="btn-secondary w-full mt-4" @click="showQuickAdd = false">Zatvori</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'] })

const route = useRoute()
const { user, signOut } = useAuth()
const sidebarOpen = ref(false)
const showQuickAdd = ref(false)

const navItems = [
  { to: '/admin', label: 'Kontrolna Tabla', icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>' },
  { to: '/admin/children', label: 'Djeca', icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>' },
  { to: '/admin/groups', label: 'Grupe', icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>' },
  { to: '/admin/workshops', label: 'Radionice', icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>' },
  { to: '/admin/observations', label: 'Opservacije', icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>' },
  { to: '/admin/parent-observations', label: 'Parent review', icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 10h.01M12 10h.01M16 10h.01M9 16h6M7 4h10a2 2 0 012 2v12l-4-3H7a2 2 0 01-2-2V6a2 2 0 012-2z"/></svg>' },
  { to: '/admin/attendance', label: 'Prisustvo', icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/></svg>' },
  { to: '/admin/messages', label: 'Poruke', icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>' },
  { to: '/admin/education', label: 'Edukacija', icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l9-5-9-5-9 5 9 5z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l6.16-3.422A12.083 12.083 0 0112 20.055a12.083 12.083 0 01-6.16-9.477L12 14z"/></svg>' },
  { to: '/admin/users', label: 'Korisnici', icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>' },
  { to: '/admin/stats', label: 'Statistike', icon: '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>' },
]

watch(() => route.path, () => {
  sidebarOpen.value = false
})
</script>
