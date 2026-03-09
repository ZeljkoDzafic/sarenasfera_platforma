<template>
  <div class="space-y-6">
    <NuxtLink to="/portal/education/resources" class="inline-flex items-center gap-2 text-sm font-semibold text-primary-600 hover:text-primary-700">
      ← Nazad na biblioteku
    </NuxtLink>

    <div v-if="pending" class="space-y-4">
      <div class="card h-32 animate-pulse" />
      <div class="card h-80 animate-pulse" />
    </div>

    <div v-else-if="!resource" class="card py-14 text-center">
      <div class="mb-4 text-5xl">📄</div>
      <h1 class="font-display text-xl font-bold text-gray-900">Resurs nije pronađen</h1>
      <p class="mt-2 text-sm text-gray-500">Provjerite link ili se vratite na biblioteku resursa.</p>
    </div>

    <template v-else>
      <section class="card">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <div class="flex flex-wrap gap-2">
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :style="{ backgroundColor: `${resource.domainColor}20`, color: resource.domainColor }">
                {{ resource.domainLabel }}
              </span>
              <span class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-semibold text-gray-600">
                {{ resource.typeLabel }}
              </span>
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="resource.tierClass">
                {{ resource.tierLabel }}
              </span>
            </div>

            <h1 class="mt-4 text-3xl font-bold text-gray-900">{{ resource.title }}</h1>
            <p class="mt-3 max-w-3xl text-sm leading-6 text-gray-600">{{ resource.description }}</p>
          </div>

          <div class="rounded-3xl px-5 py-4 text-center" :style="{ backgroundColor: `${resource.domainColor}15` }">
            <div class="text-4xl">{{ resource.icon }}</div>
            <p class="mt-2 text-sm font-semibold text-gray-900">Uzrast {{ resource.ageLabel }}</p>
            <p class="text-xs text-gray-500">{{ resource.materials.length }} materijala</p>
          </div>
        </div>
      </section>

      <section class="grid gap-4 xl:grid-cols-[1.2fr_0.8fr]">
        <div class="card">
          <h2 class="text-lg font-bold text-gray-900">Sadržaj i preporuka</h2>
          <div class="prose prose-sm mt-4 max-w-none text-gray-700">
            <div v-if="resource.articleHtml" v-html="resource.articleHtml" />
            <template v-else>
              <p>{{ resource.description }}</p>
              <p>Ovaj resurs je namijenjen roditeljima koji žele praktične smjernice za rad kod kuće i bolje razumijevanje razvoja po domenama.</p>
              <p>Preporuka: pregledajte materijal prije aktivnosti s djetetom i fokusirajte se na jednu malu rutinu koju možete zadržati svake sedmice.</p>
            </template>
          </div>

          <div v-if="resource.videoUrl" class="mt-6">
            <h3 class="text-base font-bold text-gray-900">Video lekcija</h3>
            <div v-if="resource.embedVideoUrl" class="mt-3 overflow-hidden rounded-3xl bg-gray-950 shadow-lg">
              <iframe
                :src="resource.embedVideoUrl"
                title="Video resurs"
                class="aspect-video w-full"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen
              />
            </div>
            <video v-else-if="resource.videoUrl.endsWith('.mp4') || resource.videoUrl.endsWith('.webm')" class="mt-3 w-full rounded-3xl bg-black" controls>
              <source :src="resource.videoUrl" />
            </video>
            <a v-else :href="resource.videoUrl" target="_blank" rel="noopener noreferrer" class="mt-3 inline-flex text-sm font-semibold text-primary-600 hover:text-primary-700">
              Otvori video →
            </a>
          </div>
        </div>

        <div class="card">
          <h2 class="text-lg font-bold text-gray-900">Materijali</h2>
          <div v-if="resource.materials.length > 0" class="mt-4 space-y-3">
            <article v-for="material in resource.materials" :key="material.id" class="rounded-2xl bg-gray-50 p-4">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <p class="font-semibold text-gray-900">{{ material.title }}</p>
                  <p class="mt-1 text-sm text-gray-600">{{ fileTypeLabel(material.fileType) }}</p>
                  <p class="mt-1 text-xs text-gray-500">Preuzeto {{ material.downloadCount }} puta</p>
                </div>
                <button
                  v-if="material.fileUrl"
                  type="button"
                  class="btn-secondary text-sm"
                  @click="openMaterial(material)"
                >
                  Otvori
                </button>
              </div>
            </article>
          </div>
          <p v-else class="mt-4 text-sm text-gray-500">Ovaj resurs još nema priložene materijale.</p>
        </div>
      </section>
    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })

const route = useRoute()
const supabase = useSupabase()
const slug = route.params.slug as string

const domains = {
  emotional: { label: 'Emocionalni', color: '#cf2e2e', icon: '❤️' },
  social: { label: 'Socijalni', color: '#fcb900', icon: '🤝' },
  creative: { label: 'Kreativni', color: '#9b51e0', icon: '🎨' },
  cognitive: { label: 'Kognitivni', color: '#0693e3', icon: '🧠' },
  motor: { label: 'Motorički', color: '#00d084', icon: '🏃' },
  language: { label: 'Jezički', color: '#f78da7', icon: '💬' },
} as const

const { data: resource, pending } = await useAsyncData(`portal-resource-${slug}`, async () => {
  const { data } = await supabase
    .from('educational_content')
    .select(`
      id,
      title,
      slug,
      description,
      domain,
      age_min,
      age_max,
      required_tier,
      resource_materials (
        id,
        title,
        file_url,
        file_type,
        download_count,
        content_html,
        video_url
      )
    `)
    .eq('slug', slug)
    .eq('content_type', 'resource')
    .eq('status', 'published')
    .maybeSingle()

  if (!data) return null

  const domain = domains[(data.domain as keyof typeof domains) ?? 'creative'] ?? domains.creative
  const materials = (data.resource_materials ?? []).map((item: Record<string, any>) => ({
    id: item.id as string,
    title: item.title as string,
    fileUrl: item.file_url as string,
    fileType: item.file_type as string,
    downloadCount: Number(item.download_count ?? 0),
    contentHtml: item.content_html as string | null,
    videoUrl: item.video_url as string | null,
  }))

  const articleMaterial = materials.find((item) => item.fileType === 'article' && item.contentHtml)
  const videoMaterial = materials.find((item) => item.videoUrl || item.fileType === 'video')
  const videoUrl = videoMaterial?.videoUrl || videoMaterial?.fileUrl || null

  return {
    id: data.id as string,
    title: data.title as string,
    slug: data.slug as string,
    description: (data.description as string | null) ?? 'Edukativni materijal za roditelje i dijete.',
    domainLabel: domain.label,
    domainColor: domain.color,
    icon: domain.icon,
    ageLabel: `${data.age_min ?? 2}-${data.age_max ?? 6}`,
    tierLabel: data.required_tier === 'premium' ? 'Premium' : data.required_tier === 'paid' ? 'Paid' : 'Free',
    tierClass: data.required_tier === 'premium' ? 'bg-primary-100 text-primary-700' : data.required_tier === 'paid' ? 'bg-brand-green/15 text-brand-green' : 'bg-gray-100 text-gray-600',
    typeLabel: materials.some((item) => item.fileType === 'video' || item.videoUrl) ? 'Video resurs' : materials.some((item) => item.fileType === 'pdf') ? 'PDF resurs' : 'Članak / vodič',
    articleHtml: articleMaterial?.contentHtml ?? null,
    videoUrl,
    embedVideoUrl: toEmbedUrl(videoUrl),
    materials,
  }
})

async function trackDownload(materialId: string) {
  if (!resource.value) return
  const material = resource.value.materials.find((item) => item.id === materialId)
  if (!material) return

  await supabase
    .from('resource_materials')
    .update({ download_count: material.downloadCount + 1 })
    .eq('id', materialId)

  material.downloadCount += 1
}

async function openMaterial(material: { id: string; fileUrl: string }) {
  await trackDownload(material.id)
  window.open(material.fileUrl, '_blank', 'noopener,noreferrer')
}

function toEmbedUrl(url: string | null) {
  if (!url) return null
  const youtubeMatch = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&?/]+)/)
  if (youtubeMatch) return `https://www.youtube.com/embed/${youtubeMatch[1]}`
  const vimeoMatch = url.match(/vimeo\.com\/(\d+)/)
  if (vimeoMatch) return `https://player.vimeo.com/video/${vimeoMatch[1]}`
  return null
}

function fileTypeLabel(type: string) {
  const labels: Record<string, string> = {
    article: 'Članak',
    pdf: 'PDF materijal',
    image: 'Galerija / slika',
    video: 'Video lekcija',
    audio: 'Audio zapis',
    document: 'Dokument',
    worksheet: 'Radni list',
  }
  return labels[type] ?? 'Materijal'
}
</script>
