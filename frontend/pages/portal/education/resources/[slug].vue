<template>
  <div class="space-y-6">
    <!-- Loading -->
    <div v-if="pending" class="space-y-4">
      <div class="card animate-pulse h-64" />
      <div class="card animate-pulse h-48" />
    </div>

    <!-- Not found -->
    <div v-else-if="!resource" class="card text-center py-16">
      <div class="text-5xl mb-4">📚</div>
      <h3 class="font-display font-bold text-xl text-gray-900 mb-2">Resurs nije pronađen</h3>
      <NuxtLink to="/portal/education/resources" class="btn-primary">Nazad na biblioteku</NuxtLink>
    </div>

    <div v-else class="space-y-6">
      <!-- Header -->
      <div class="card">
        <div class="flex items-start justify-between gap-4">
          <div class="flex items-start gap-4 flex-1">
            <!-- Type icon -->
            <div
              class="w-20 h-20 rounded-xl flex items-center justify-center text-4xl flex-shrink-0"
              :class="getTypeBgClass(resource.resource_type)"
            >
              {{ getTypeIcon(resource.resource_type) }}
            </div>

            <!-- Info -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-2">
                <TierBadge :tier="resource.required_tier" />
                <span
                  v-if="resource.domain"
                  class="px-3 py-1 rounded-full text-xs font-semibold"
                  :style="{ backgroundColor: getDomainColor(resource.domain) + '20', color: getDomainColor(resource.domain) }"
                >
                  {{ getDomainName(resource.domain) }}
                </span>
              </div>

              <h1 class="font-display text-2xl font-bold text-gray-900 mb-2">{{ resource.title }}</h1>
              <p class="text-gray-600">{{ resource.description }}</p>

              <div class="flex flex-wrap items-center gap-4 text-sm text-gray-500 mt-3">
                <span class="flex items-center gap-1">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                  {{ resource.view_count || 0 }} pregleda
                </span>
                <span class="flex items-center gap-1">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                  </svg>
                  {{ resource.download_count || 0 }} preuzimanja
                </span>
              </div>
            </div>
          </div>

          <!-- Download button -->
          <div class="text-right">
            <button
              v-if="canDownload"
              class="btn-primary"
              @click="download"
              :disabled="downloading"
            >
              {{ downloading ? 'Preuzimam...' : `Preuzmi ${getDownloadLabel(resource.resource_type)}` }}
            </button>
            <button
              v-else
              class="btn-secondary"
              disabled
            >
              🔒 Potrebna nadogradnja
            </button>
          </div>
        </div>
      </div>

      <!-- Content based on type -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Main content -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Article content -->
          <article v-if="resource.resource_type === 'article' && resource.content_html" class="card prose max-w-none">
            <div v-html="sanitizedResourceHtml" />
          </article>

          <!-- Video player -->
          <div v-if="resource.resource_type === 'video' && safeVideoUrl" class="card">
            <div class="aspect-video rounded-xl bg-gray-900 overflow-hidden">
              <iframe
                v-if="safeVideoUrl.includes('youtube') || safeVideoUrl.includes('vimeo')"
                :src="safeVideoUrl"
                class="w-full h-full"
                frameborder="0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen
              />
              <video v-else :src="safeVideoUrl" controls class="w-full h-full" />
            </div>
          </div>

          <!-- Materials/Attachments -->
          <div v-if="materials && materials.length > 0" class="card">
            <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Priloženi Materijali</h2>
            <div class="space-y-3">
              <div
                v-for="material in materials"
                :key="material.id"
                class="flex items-center justify-between p-4 rounded-xl bg-gray-50"
              >
                <div class="flex items-center gap-3">
                  <div class="text-2xl">{{ getFileIcon(material.file_type) }}</div>
                  <div>
                    <p class="font-semibold text-gray-900">{{ material.title }}</p>
                    <p class="text-xs text-gray-500">{{ formatFileSize(material.file_size_bytes) }}</p>
                  </div>
                </div>
                <a
                  v-if="material.is_downloadable"
                  :href="sanitizeUrl(material.file_url, false)"
                  download
                  class="btn-secondary text-sm"
                >
                  Preuzmi
                </a>
              </div>
            </div>
          </div>
        </div>

        <!-- Sidebar -->
        <div class="space-y-4">
          <!-- Related resources -->
          <div class="card">
            <h3 class="font-display font-bold text-sm text-gray-900 mb-3">Slični Resursi</h3>
            <div class="space-y-3">
              <NuxtLink
                v-for="related in relatedResources"
                :key="related.id"
                :to="`/portal/education/resources/${related.slug}`"
                class="flex items-start gap-3 p-3 rounded-xl hover:bg-gray-50 transition-colors"
              >
                <div class="text-xl">{{ getTypeIcon(related.resource_type) }}</div>
                <div class="flex-1 min-w-0">
                  <p class="font-semibold text-gray-900 text-sm line-clamp-2">{{ related.title }}</p>
                  <p class="text-xs text-gray-500 mt-1">{{ getDomainName(related.domain) }}</p>
                </div>
              </NuxtLink>
            </div>
          </div>

          <!-- Info box -->
          <div class="card bg-primary-50 border-primary-200">
            <h3 class="font-bold text-gray-900 mb-2">ℹ️ O ovom resursu</h3>
            <ul class="space-y-2 text-sm text-gray-700">
              <li class="flex items-center gap-2">
                <span class="w-1.5 h-1.5 rounded-full bg-primary-500" />
                Tip: {{ getTypeLabel(resource.resource_type) }}
              </li>
              <li v-if="resource.domain" class="flex items-center gap-2">
                <span class="w-1.5 h-1.5 rounded-full bg-primary-500" />
                Domena: {{ getDomainName(resource.domain) }}
              </li>
              <li v-if="resource.age_min && resource.age_max" class="flex items-center gap-2">
                <span class="w-1.5 h-1.5 rounded-full bg-primary-500" />
                Uzrast: {{ resource.age_min }}-{{ resource.age_max }} godina
              </li>
              <li class="flex items-center gap-2">
                <span class="w-1.5 h-1.5 rounded-full bg-primary-500" />
                Objavljeno: {{ formatDate(resource.created_at) }}
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { sanitizeHtml, sanitizeUrl } from '~/utils/sanitizeHtml'

definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })

const route = useRoute()
const supabase = useSupabase()
const { user } = useAuth()
const { tierName } = useTier()

const resourceSlug = route.params.slug as string
const downloading = ref(false)
const sanitizedResourceHtml = computed(() => sanitizeHtml(resource.value?.content_html))
const safeVideoUrl = computed(() => sanitizeUrl(resource.value?.metadata?.video_url ?? '', false))

const { data: resource, pending } = await useAsyncData(`resource-${resourceSlug}`, async () => {
  const { data } = await supabase
    .from('educational_content')
    .select(`
      *,
      resource_materials(
        id, file_url, file_type, file_size_bytes, title, description, is_downloadable
      )
    `)
    .eq('slug', resourceSlug)
    .eq('content_type', 'resource')
    .single()

  // Increment view count
  if (data) {
    await supabase
      .from('educational_content')
      .update({ view_count: data.view_count + 1 })
      .eq('id', data.id)
  }

  return data
})

const { data: materials } = await useAsyncData(`resource-materials-${resourceSlug}`, async () => {
  if (!resource.value) return []

  const { data } = await supabase
    .from('resource_materials')
    .select('*')
    .eq('content_id', resource.value.id)
    .order('created_at')

  return data ?? []
})

const { data: relatedResources } = await useAsyncData(`related-resources-${resourceSlug}`, async () => {
  if (!resource.value) return []

  const { data } = await supabase
    .from('educational_content')
    .select('*')
    .eq('content_type', 'resource')
    .eq('status', 'published')
    .neq('id', resource.value.id)
    .eq('domain', resource.value.domain)
    .limit(4)

  return (data ?? []).map(r => ({
    ...r,
    resource_type: r.resource_materials?.[0]?.file_type || 'article',
  }))
})

// Check download limits
const downloadLimits: Record<string, number> = {
  free: 5,
  paid: 20,
  premium: 9999,
}

const { data: downloadCount } = await useAsyncData('monthly-downloads', async () => {
  if (!user.value) return 0

  const startOfMonth = new Date()
  startOfMonth.setDate(1)
  startOfMonth.setHours(0, 0, 0, 0)

  const { count } = await supabase
    .from('content_registrations')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user.value.id)
    .gte('created_at', startOfMonth.toISOString())

  return count || 0
})

const canDownload = computed(() => {
  if (!resource.value) return false
  if (resource.value.required_tier === 'free') return true

  const limit = downloadLimits[tierName.value] || 5
  return (downloadCount.value || 0) < limit
})

async function download() {
  if (!resource.value || !canDownload.value) return

  downloading.value = true

  try {
    // Track download
    await supabase.from('content_registrations').insert({
      user_id: user.value!.id,
      content_id: resource.value.id,
      status: 'attended',
    })

    // Trigger actual download from first material
    const material = materials.value?.[0]
    if (material?.file_url) {
      const a = document.createElement('a')
      a.href = material.file_url
      a.download = ''
      a.target = '_blank'
      a.click()
    }

    await refreshNuxtData('monthly-downloads')
  } catch (err) {
    console.error('Download failed:', err)
  } finally {
    downloading.value = false
  }
}

function getTypeIcon(type: string): string {
  const map: Record<string, string> = {
    article: '📄',
    pdf: '📕',
    video: '🎬',
    worksheet: '📝',
  }
  return map[type] || '📄'
}

function getTypeBgClass(type: string): string {
  const map: Record<string, string> = {
    article: 'bg-gray-100',
    pdf: 'bg-brand-red/10',
    video: 'bg-brand-pink/10',
    worksheet: 'bg-primary-100',
  }
  return map[type] || 'bg-gray-100'
}

function getTypeLabel(type: string): string {
  const map: Record<string, string> = {
    article: 'Članak',
    pdf: 'PDF Dokument',
    video: 'Video',
    worksheet: 'Radni list',
  }
  return map[type] || 'Resurs'
}

function getDownloadLabel(type: string): string {
  if (type === 'pdf') return 'PDF'
  if (type === 'video') return 'Video'
  if (type === 'worksheet') return 'Radni list'
  return 'Resurs'
}

function getFileIcon(type: string): string {
  const map: Record<string, string> = {
    pdf: '📕',
    image: '🖼️',
    video: '🎬',
    audio: '🎵',
    document: '📄',
    worksheet: '📝',
  }
  return map[type] || '📄'
}

function getDomainColor(domain: string): string {
  const colors: Record<string, string> = {
    emotional: '#cf2e2e',
    social: '#fcb900',
    creative: '#9b51e0',
    cognitive: '#0693e3',
    motor: '#00d084',
    language: '#f78da7',
  }
  return colors[domain] || '#9b51e0'
}

function getDomainName(domain: string): string {
  const names: Record<string, string> = {
    emotional: 'Emocionalni',
    social: 'Socijalni',
    creative: 'Kreativni',
    cognitive: 'Kognitivni',
    motor: 'Motorički',
    language: 'Jezički',
  }
  return names[domain] || domain
}

function formatFileSize(bytes: number): string {
  if (!bytes) return ''
  const kb = bytes / 1024
  if (kb < 1024) return `${Math.round(kb)} KB`
  return `${(kb / 1024).toFixed(1)} MB`
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short', year: 'numeric' })
}
</script>
