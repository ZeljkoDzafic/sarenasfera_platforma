<template>
  <div class="space-y-6">
    <section class="card">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Biblioteka resursa</h1>
          <p class="mt-1 text-sm text-gray-600">Članci, PDF vodiči, video lekcije i radni listovi za roditelje.</p>
        </div>

        <div class="grid gap-2 sm:grid-cols-4">
          <label class="text-xs font-semibold text-gray-600">
            Tip
            <select v-model="typeFilter" class="input mt-1 min-h-11 py-2">
              <option value="all">Sve</option>
              <option value="article">Članci</option>
              <option value="pdf">PDF</option>
              <option value="video">Video</option>
              <option value="worksheet">Radni listovi</option>
            </select>
          </label>
          <label class="text-xs font-semibold text-gray-600">
            Domena
            <select v-model="domainFilter" class="input mt-1 min-h-11 py-2">
              <option value="all">Sve domene</option>
              <option v-for="domain in domains" :key="domain.key" :value="domain.key">{{ domain.label }}</option>
            </select>
          </label>
          <label class="text-xs font-semibold text-gray-600">
            Uzrast
            <select v-model="ageFilter" class="input mt-1 min-h-11 py-2">
              <option value="all">Svi</option>
              <option value="2-3">2-3</option>
              <option value="3-4">3-4</option>
              <option value="4-5">4-5</option>
              <option value="5-6">5-6</option>
            </select>
          </label>
          <label class="text-xs font-semibold text-gray-600">
            Tier
            <select v-model="tierFilter" class="input mt-1 min-h-11 py-2">
              <option value="all">Svi planovi</option>
              <option value="free">Free</option>
              <option value="paid">Paid</option>
              <option value="premium">Premium</option>
            </select>
          </label>
        </div>
      </div>
    </section>

    <div v-if="pending" class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
      <div v-for="i in 6" :key="i" class="card h-56 animate-pulse" />
    </div>

    <div v-else-if="filteredResources.length === 0" class="card py-14 text-center">
      <div class="mb-4 text-5xl">📚</div>
      <h2 class="font-display text-xl font-bold text-gray-900">Nema resursa za ovaj filter</h2>
      <p class="mt-2 text-sm text-gray-500">Probajte proširiti filtere ili se vratite kasnije kada dodamo nove materijale.</p>
    </div>

    <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
      <NuxtLink
        v-for="resource in filteredResources"
        :key="resource.id"
        :to="`/portal/education/resources/${resource.slug}`"
        class="card-hover block"
      >
        <div class="mb-4 flex items-start justify-between gap-3">
          <div class="inline-flex h-12 w-12 items-center justify-center rounded-2xl text-2xl" :style="{ backgroundColor: `${resource.domainColor}20`, color: resource.domainColor }">
            {{ resource.icon }}
          </div>
          <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="resource.tierClass">
            {{ resource.tierLabel }}
          </span>
        </div>

        <div class="flex flex-wrap gap-2">
          <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :style="{ backgroundColor: `${resource.domainColor}20`, color: resource.domainColor }">
            {{ resource.domainLabel }}
          </span>
          <span class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-semibold text-gray-600">
            {{ resource.typeLabel }}
          </span>
        </div>

        <h2 class="mt-4 text-lg font-bold text-gray-900">{{ resource.title }}</h2>
        <p class="mt-2 line-clamp-3 text-sm text-gray-600">{{ resource.description }}</p>

        <div class="mt-5 flex items-center justify-between text-sm text-gray-500">
          <span>Uzrast {{ resource.ageLabel }}</span>
          <span>{{ resource.materialCount }} materijala</span>
        </div>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })

useSeoMeta({
  title: 'Biblioteka resursa — Šarena Sfera',
  description: 'Portal biblioteka članaka, PDF-ova, video lekcija i radnih listova.',
})

type DomainKey = 'emotional' | 'social' | 'creative' | 'cognitive' | 'motor' | 'language'
type TierName = 'free' | 'paid' | 'premium'

const supabase = useSupabase()

const typeFilter = ref<'all' | 'article' | 'pdf' | 'video' | 'worksheet'>('all')
const domainFilter = ref<'all' | DomainKey>('all')
const ageFilter = ref<'all' | '2-3' | '3-4' | '4-5' | '5-6'>('all')
const tierFilter = ref<'all' | TierName>('all')

const domains: Array<{ key: DomainKey; label: string; color: string; icon: string }> = [
  { key: 'emotional', label: 'Emocionalni', color: '#cf2e2e', icon: '❤️' },
  { key: 'social', label: 'Socijalni', color: '#fcb900', icon: '🤝' },
  { key: 'creative', label: 'Kreativni', color: '#9b51e0', icon: '🎨' },
  { key: 'cognitive', label: 'Kognitivni', color: '#0693e3', icon: '🧠' },
  { key: 'motor', label: 'Motorički', color: '#00d084', icon: '🏃' },
  { key: 'language', label: 'Jezički', color: '#f78da7', icon: '💬' },
]

const { data: resources, pending } = await useAsyncData('portal-education-resources', async () => {
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
        file_type
      )
    `)
    .eq('content_type', 'resource')
    .eq('status', 'published')
    .order('published_at', { ascending: false })

  return data ?? []
})

const normalizedResources = computed(() => {
  return (resources.value ?? []).map((resource: Record<string, any>) => {
    const domain = domains.find((entry) => entry.key === resource.domain) ?? domains[2]
    const materialTypes = (resource.resource_materials ?? []).map((item: Record<string, any>) => item.file_type)
    const type = materialTypes.includes('video')
      ? 'video'
      : materialTypes.includes('pdf')
        ? 'pdf'
        : materialTypes.includes('worksheet')
          ? 'worksheet'
          : 'article'

    return {
      id: resource.id as string,
      slug: resource.slug as string,
      title: resource.title as string,
      description: (resource.description as string | null) ?? 'Edukativni materijal za roditelje i dijete.',
      domainKey: domain.key,
      domainLabel: domain.label,
      domainColor: domain.color,
      icon: domain.icon,
      ageLabel: `${resource.age_min ?? 2}-${resource.age_max ?? 6}`,
      ageMin: Number(resource.age_min ?? 2),
      ageMax: Number(resource.age_max ?? 6),
      tier: resource.required_tier as TierName,
      tierLabel: resource.required_tier === 'premium' ? 'Premium' : resource.required_tier === 'paid' ? 'Paid' : 'Free',
      tierClass: resource.required_tier === 'premium' ? 'bg-primary-100 text-primary-700' : resource.required_tier === 'paid' ? 'bg-brand-green/15 text-brand-green' : 'bg-gray-100 text-gray-600',
      type,
      typeLabel: type === 'video' ? 'Video' : type === 'pdf' ? 'PDF' : type === 'worksheet' ? 'Radni list' : 'Članak',
      materialCount: (resource.resource_materials ?? []).length,
    }
  })
})

const filteredResources = computed(() => {
  return normalizedResources.value.filter((resource) => {
    if (typeFilter.value !== 'all' && resource.type !== typeFilter.value) return false
    if (domainFilter.value !== 'all' && resource.domainKey !== domainFilter.value) return false
    if (tierFilter.value !== 'all' && resource.tier !== tierFilter.value) return false

    if (ageFilter.value !== 'all') {
      const [min, max] = ageFilter.value.split('-').map(Number)
      const overlaps = resource.ageMin <= max && resource.ageMax >= min
      if (!overlaps) return false
    }

    return true
  })
})
</script>
