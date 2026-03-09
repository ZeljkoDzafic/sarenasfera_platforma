<template>
  <div class="space-y-6">
    <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Education sadržaj</h1>
        <p class="text-sm text-gray-500 mt-1">Kursevi, događaji, webinari i resursi na jednom mjestu.</p>
      </div>
      <div class="flex flex-wrap gap-3">
        <NuxtLink to="/admin/education/courses/new" class="btn-primary text-sm">+ Novi kurs</NuxtLink>
        <NuxtLink to="/admin/education/events/new" class="btn-secondary text-sm">+ Novi event</NuxtLink>
        <NuxtLink to="/admin/education/resources/new" class="btn-secondary text-sm">+ Novi resurs</NuxtLink>
      </div>
    </div>

    <div class="card">
      <div class="flex flex-wrap gap-3">
        <select v-model="typeFilter" class="input w-auto text-sm">
          <option value="all">Svi tipovi</option>
          <option value="course">Kursevi</option>
          <option value="event">Događaji</option>
          <option value="webinar">Webinari</option>
          <option value="resource">Resursi</option>
        </select>
        <select v-model="statusFilter" class="input w-auto text-sm">
          <option value="all">Svi statusi</option>
          <option value="draft">Draft</option>
          <option value="published">Published</option>
          <option value="archived">Archived</option>
        </select>
      </div>
    </div>

    <div v-if="pending" class="space-y-3">
      <div v-for="i in 5" :key="i" class="card h-20 animate-pulse" />
    </div>

    <div v-else-if="filteredItems.length > 0" class="space-y-3">
      <article v-for="item in filteredItems" :key="item.id" class="card">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div class="space-y-2">
            <div class="flex flex-wrap items-center gap-2">
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="typeClass(item.type)">{{ typeLabel(item.type) }}</span>
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="statusClass(item.status)">{{ item.status }}</span>
            </div>
            <div>
              <h2 class="text-lg font-bold text-gray-900">{{ item.title }}</h2>
              <p class="text-sm text-gray-500">{{ item.slug }}</p>
            </div>
            <p class="text-sm text-gray-600">{{ item.description }}</p>
            <div class="grid gap-2 sm:grid-cols-3 text-sm">
              <div class="rounded-xl bg-gray-50 p-3">
                <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">Views</p>
                <p class="mt-1 font-semibold text-gray-900">{{ item.views }}</p>
              </div>
              <div class="rounded-xl bg-gray-50 p-3">
                <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">Enroll / regs</p>
                <p class="mt-1 font-semibold text-gray-900">{{ item.enrollments }}</p>
              </div>
              <div class="rounded-xl bg-gray-50 p-3">
                <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">Completion</p>
                <p class="mt-1 font-semibold text-gray-900">{{ item.completion }}</p>
              </div>
            </div>
          </div>

          <div class="grid gap-2 sm:grid-cols-2 lg:w-64">
            <NuxtLink :to="editorLink(item)" class="btn-secondary text-center text-sm">
              Uredi
            </NuxtLink>
            <NuxtLink :to="duplicateLink(item)" class="btn-secondary text-center text-sm">
              Dupliraj
            </NuxtLink>
            <button type="button" class="btn-secondary text-sm" @click="toggleStatus(item)">
              {{ item.status === 'published' ? 'Vrati u draft' : 'Objavi' }}
            </button>
            <button type="button" class="btn-secondary text-sm" @click="archive(item)">
              Arhiviraj
            </button>
          </div>
        </div>
      </article>
    </div>

    <div v-else class="card py-14 text-center">
      <div class="mb-4 text-5xl">📚</div>
      <h2 class="font-display text-xl font-bold text-gray-900">Nema sadržaja za ove filtere</h2>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Education sadržaj — Admin' })

const supabase = useSupabase()
const typeFilter = ref<'all' | 'course' | 'event' | 'webinar' | 'resource'>('all')
const statusFilter = ref<'all' | 'draft' | 'published' | 'archived'>('all')

const { data: items, pending, refresh } = await useAsyncData('admin-education-content', async () => {
  const { data } = await supabase
    .from('educational_content')
    .select('id, title, slug, description, content_type, status, view_count, enrollment_count, completion_count')
    .order('created_at', { ascending: false })

  return data ?? []
})

const filteredItems = computed(() => {
  return (items.value ?? []).filter((item: Record<string, any>) => {
    if (typeFilter.value !== 'all' && item.content_type !== typeFilter.value) return false
    if (statusFilter.value !== 'all' && item.status !== statusFilter.value) return false
    return true
  }).map((item: Record<string, any>) => ({
    id: item.id as string,
    title: item.title as string,
    slug: item.slug as string,
    description: (item.description as string | null) ?? 'Bez opisa.',
    type: item.content_type as 'course' | 'event' | 'webinar' | 'resource',
    status: item.status as 'draft' | 'published' | 'archived',
    views: Number(item.view_count ?? 0),
    enrollments: Number(item.enrollment_count ?? 0),
    completion: Number(item.completion_count ?? 0),
  }))
})

function typeLabel(type: 'course' | 'event' | 'webinar' | 'resource') {
  return {
    course: 'Kurs',
    event: 'Događaj',
    webinar: 'Webinar',
    resource: 'Resurs',
  }[type]
}

function typeClass(type: 'course' | 'event' | 'webinar' | 'resource') {
  return {
    course: 'bg-primary-100 text-primary-700',
    event: 'bg-brand-amber/15 text-brand-amber',
    webinar: 'bg-brand-blue/15 text-brand-blue',
    resource: 'bg-brand-green/15 text-brand-green',
  }[type]
}

function statusClass(status: 'draft' | 'published' | 'archived') {
  return {
    draft: 'bg-gray-100 text-gray-600',
    published: 'bg-brand-green/15 text-brand-green',
    archived: 'bg-brand-red/15 text-brand-red',
  }[status]
}

function editorLink(item: { id: string; type: 'course' | 'event' | 'webinar' | 'resource' }) {
  if (item.type === 'course') return `/admin/education/courses/new?edit=${item.id}`
  if (item.type === 'resource') return `/admin/education/resources/new?edit=${item.id}`
  return `/admin/education/events/new?edit=${item.id}`
}

function duplicateLink(item: { id: string; type: 'course' | 'event' | 'webinar' | 'resource' }) {
  if (item.type === 'course') return `/admin/education/courses/new?from=${item.id}`
  if (item.type === 'resource') return `/admin/education/resources/new?from=${item.id}`
  return `/admin/education/events/new?from=${item.id}`
}

async function toggleStatus(item: { id: string; status: 'draft' | 'published' | 'archived' }) {
  const nextStatus = item.status === 'published' ? 'draft' : 'published'
  await supabase.from('educational_content').update({ status: nextStatus }).eq('id', item.id)
  await refresh()
}

async function archive(item: { id: string }) {
  await supabase.from('educational_content').update({ status: 'archived' }).eq('id', item.id)
  await refresh()
}
</script>
