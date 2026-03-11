<template>
  <AdminBlogEditor />
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
</script>
