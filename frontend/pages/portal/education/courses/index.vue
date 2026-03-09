<template>
  <div class="space-y-6">
    <section class="card-featured">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <p class="text-sm font-semibold uppercase tracking-wide text-white/90">Portal edukacija</p>
          <h1 class="mt-2 text-2xl font-bold text-white">Online kursevi</h1>
          <p class="mt-2 text-sm text-white/90">Samostalni kursevi za roditelje, sa modulima, lekcijama i praćenjem napretka.</p>
        </div>

        <div class="grid gap-2 sm:grid-cols-3">
          <label class="text-xs font-semibold text-white/90">
            Domena
            <select v-model="domainFilter" class="input mt-1 min-h-11 py-2 text-gray-900">
              <option value="all">Sve domene</option>
              <option v-for="domain in domains" :key="domain.key" :value="domain.key">{{ domain.label }}</option>
            </select>
          </label>
          <label class="text-xs font-semibold text-white/90">
            Uzrast
            <select v-model="ageFilter" class="input mt-1 min-h-11 py-2 text-gray-900">
              <option value="all">Svi uzrasti</option>
              <option value="2-3">2-3</option>
              <option value="3-4">3-4</option>
              <option value="4-5">4-5</option>
              <option value="5-6">5-6</option>
            </select>
          </label>
          <label class="text-xs font-semibold text-white/90">
            Tier
            <select v-model="tierFilter" class="input mt-1 min-h-11 py-2 text-gray-900">
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
      <div v-for="i in 6" :key="i" class="card h-72 animate-pulse" />
    </div>

    <div v-else-if="filteredCourses.length === 0" class="card py-14 text-center">
      <div class="mb-4 text-5xl">🎓</div>
      <h2 class="font-display text-xl font-bold text-gray-900">Nema kurseva za odabrane filtere</h2>
      <p class="mt-2 text-sm text-gray-500">Promijenite filtere ili se vratite kasnije kada dodamo nove edukativne programe.</p>
    </div>

    <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
      <NuxtLink
        v-for="course in filteredCourses"
        :key="course.id"
        :to="`/portal/education/courses/${course.slug}`"
        class="card-hover block"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="inline-flex h-12 w-12 items-center justify-center rounded-2xl text-2xl" :style="{ backgroundColor: `${course.domainColor}20`, color: course.domainColor }">
            {{ course.domainIcon }}
          </div>
          <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="course.tierClass">
            {{ course.tierLabel }}
          </span>
        </div>

        <div class="mt-4 flex flex-wrap gap-2">
          <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :style="{ backgroundColor: `${course.domainColor}20`, color: course.domainColor }">
            {{ course.domainLabel }}
          </span>
          <span class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-semibold text-gray-600">
            {{ course.durationLabel }}
          </span>
        </div>

        <h2 class="mt-4 text-lg font-bold text-gray-900">{{ course.title }}</h2>
        <p class="mt-2 line-clamp-3 text-sm text-gray-600">{{ course.description }}</p>

        <div class="mt-5 grid grid-cols-2 gap-3 text-sm">
          <div class="rounded-2xl bg-gray-50 p-3">
            <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">Lekcije</p>
            <p class="mt-1 font-semibold text-gray-900">{{ course.lessonCount }}</p>
          </div>
          <div class="rounded-2xl bg-gray-50 p-3">
            <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">Napredak</p>
            <p class="mt-1 font-semibold text-gray-900">{{ course.progressLabel }}</p>
          </div>
        </div>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })

useSeoMeta({
  title: 'Online kursevi — Šarena Sfera',
  description: 'Katalog online kurseva za roditelje sa napretkom, modulima i lekcijama.',
})

type DomainKey = 'emotional' | 'social' | 'creative' | 'cognitive' | 'motor' | 'language'
type TierName = 'free' | 'paid' | 'premium'

const supabase = useSupabase()
const { user } = useAuth()

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

const { data: courses, pending } = await useAsyncData('portal-course-catalog', async () => {
  const { data: courseRows } = await supabase
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
      duration_minutes,
      course_modules (
        id,
        title,
        course_lessons (
          id,
          is_preview
        )
      )
    `)
    .eq('content_type', 'course')
    .eq('status', 'published')
    .order('published_at', { ascending: false })

  const enrollments = user.value
    ? (await supabase
        .from('course_enrollments')
        .select('course_id, progress_percent, status')
        .eq('user_id', user.value.id)).data ?? []
    : []

  const enrollmentMap = new Map(
    enrollments.map((item: Record<string, any>) => [
      item.course_id,
      {
        progressPercent: Number(item.progress_percent ?? 0),
        status: item.status as string,
      },
    ]),
  )

  return (courseRows ?? []).map((course: Record<string, any>) => {
    const modules = course.course_modules ?? []
    const lessonCount = modules.reduce((sum: number, module: Record<string, any>) => sum + (module.course_lessons?.length ?? 0), 0)
    const enrollment = enrollmentMap.get(course.id)
    return {
      ...course,
      lessonCount,
      enrollment,
    }
  })
})

const filteredCourses = computed(() => {
  return (courses.value ?? []).filter((course: Record<string, any>) => {
    if (domainFilter.value !== 'all' && course.domain !== domainFilter.value) return false
    if (tierFilter.value !== 'all' && course.required_tier !== tierFilter.value) return false

    if (ageFilter.value !== 'all') {
      const [min, max] = ageFilter.value.split('-').map(Number)
      const overlaps = Number(course.age_min ?? 2) <= max && Number(course.age_max ?? 6) >= min
      if (!overlaps) return false
    }

    return true
  }).map((course: Record<string, any>) => {
    const domain = domains.find((entry) => entry.key === course.domain) ?? domains[2]
    const progressPercent = Number(course.enrollment?.progressPercent ?? 0)

    return {
      id: course.id as string,
      slug: course.slug as string,
      title: course.title as string,
      description: (course.description as string | null) ?? 'Online kurs za roditelje.',
      domainLabel: domain.label,
      domainColor: domain.color,
      domainIcon: domain.icon,
      durationLabel: `${course.duration_minutes ?? 60} min`,
      lessonCount: Number(course.lessonCount ?? 0),
      progressLabel: progressPercent > 0 ? `${progressPercent.toFixed(0)}%` : 'Nije upisano',
      tierLabel: course.required_tier === 'premium' ? 'Premium' : course.required_tier === 'paid' ? 'Paid' : 'Free',
      tierClass: course.required_tier === 'premium' ? 'bg-primary-100 text-primary-700' : course.required_tier === 'paid' ? 'bg-brand-green/15 text-brand-green' : 'bg-gray-100 text-gray-600',
      ageMin: Number(course.age_min ?? 2),
      ageMax: Number(course.age_max ?? 6),
    }
  })
})
</script>
