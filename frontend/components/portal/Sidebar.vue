<template>
  <aside
    :class="[
      'fixed top-16 left-0 bottom-0 w-72 bg-white border-r border-primary-100 z-40 transition-transform duration-300 ease-out overflow-y-auto',
      isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0',
    ]"
    aria-label="Portal navigacija"
  >
    <nav class="p-4 space-y-1">
      <NuxtLink
        v-for="item in items"
        :key="item.to"
        :to="item.to"
        class="flex min-h-11 items-center gap-3 rounded-xl px-3 py-2 text-sm font-semibold transition-all"
        :class="isActive(item.to)
          ? 'bg-primary-50 text-primary-700 border-l-4 border-primary-500'
          : 'text-gray-700 hover:bg-primary-50/60 hover:text-primary-700'"
        @click="$emit('navigate')"
      >
        <span class="inline-flex h-8 w-8 items-center justify-center rounded-lg" :class="item.iconBgClass">
          <span class="h-5 w-5" v-html="item.icon" />
        </span>
        <span>{{ item.label }}</span>
      </NuxtLink>
    </nav>
  </aside>
</template>

<script setup lang="ts">
defineEmits<{ (event: 'navigate'): void }>()

interface NavItem {
  to: string
  label: string
  icon: string
  iconBgClass: string
}

const props = defineProps<{
  isOpen: boolean
  currentPath: string
  items: NavItem[]
}>()

const isActive = (path: string) => props.currentPath === path || props.currentPath.startsWith(`${path}/`)
</script>
