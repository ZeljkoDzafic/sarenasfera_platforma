<template>
  <header class="fixed inset-x-0 top-0 z-30 border-b border-primary-100 bg-white/95 backdrop-blur">
    <div class="flex h-16 items-center justify-between px-4 sm:px-6 lg:px-8">
      <div class="flex items-center gap-3">
        <button
          class="inline-flex h-11 w-11 items-center justify-center rounded-xl text-gray-700 hover:bg-primary-50 lg:hidden"
          aria-label="Otvori navigaciju"
          @click="$emit('toggle-sidebar')"
        >
          <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>

        <NuxtLink to="/portal" class="flex items-center gap-2 text-gray-900">
          <img :src="logoImage" alt="Šarena Sfera" class="h-8 w-auto">
          <span class="hidden text-sm font-semibold text-gray-500 sm:block">Portal</span>
        </NuxtLink>

        <nav class="hidden items-center gap-2 text-sm text-gray-500 md:flex" aria-label="Breadcrumb">
          <span v-for="(crumb, index) in breadcrumbs" :key="crumb.path" class="inline-flex items-center gap-2">
            <span v-if="index > 0" aria-hidden="true">/</span>
            <NuxtLink
              v-if="index < breadcrumbs.length - 1"
              :to="crumb.path"
              class="hover:text-primary-600"
            >
              {{ crumb.label }}
            </NuxtLink>
            <span v-else class="font-semibold text-primary-700">{{ crumb.label }}</span>
          </span>
        </nav>
      </div>

      <div class="flex items-center gap-3">
        <button class="relative inline-flex h-11 w-11 items-center justify-center rounded-xl text-gray-700 hover:bg-primary-50" aria-label="Obavijesti">
          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
          </svg>
          <span
            v-if="notificationCount > 0"
            class="absolute -right-0.5 -top-0.5 inline-flex min-h-5 min-w-5 items-center justify-center rounded-full bg-brand-red px-1 text-xs font-bold text-white"
          >
            {{ notificationCount > 9 ? '9+' : notificationCount }}
          </span>
        </button>

        <div class="flex items-center gap-2 rounded-xl border border-primary-100 px-2 py-1">
          <span class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-primary-100 text-sm font-bold text-primary-700">
            {{ initials }}
          </span>
          <button class="hidden text-sm font-semibold text-gray-700 hover:text-primary-700 sm:block" @click="$emit('sign-out')">
            Odjava
          </button>
        </div>
      </div>
    </div>
  </header>
</template>

<script setup lang="ts">
interface BreadcrumbItem {
  label: string
  path: string
}

const logoImage = '/logo.webp'

defineEmits<{ (event: 'toggle-sidebar'): void; (event: 'sign-out'): void }>()

defineProps<{
  breadcrumbs: BreadcrumbItem[]
  initials: string
  notificationCount: number
}>()
</script>
