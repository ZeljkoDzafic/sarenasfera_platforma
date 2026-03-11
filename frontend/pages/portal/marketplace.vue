<template>
  <div />
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })
await navigateTo('/portal/bazar', { replace: true })
</script>
