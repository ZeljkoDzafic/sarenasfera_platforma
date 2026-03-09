<template>
  <div class="space-y-6">
    <NuxtLink to="/portal/education/courses" class="inline-flex items-center gap-2 text-sm font-semibold text-primary-600 hover:text-primary-700">
      ← Nazad na kurseve
    </NuxtLink>

    <div v-if="pending" class="space-y-4">
      <div class="card h-40 animate-pulse" />
      <div class="card h-80 animate-pulse" />
    </div>

    <div v-else-if="!course" class="card py-14 text-center">
      <div class="mb-4 text-5xl">🎓</div>
      <h1 class="font-display text-xl font-bold text-gray-900">Kurs nije pronađen</h1>
    </div>

    <template v-else>
      <section class="card">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <div class="flex flex-wrap gap-2">
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :style="{ backgroundColor: `${course.domainColor}20`, color: course.domainColor }">
                {{ course.domainLabel }}
              </span>
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="course.tierClass">
                {{ course.tierLabel }}
              </span>
              <span class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-semibold text-gray-600">
                {{ course.lessonCount }} lekcija
              </span>
            </div>

            <h1 class="mt-4 text-3xl font-bold text-gray-900">{{ course.title }}</h1>
            <p class="mt-3 max-w-3xl text-sm leading-6 text-gray-600">{{ course.description }}</p>
          </div>

          <div class="rounded-3xl px-5 py-4 text-center" :style="{ backgroundColor: `${course.domainColor}15` }">
            <div class="text-4xl">{{ course.domainIcon }}</div>
            <p class="mt-2 text-sm font-semibold text-gray-900">{{ course.durationLabel }}</p>
            <p class="text-xs text-gray-500">{{ course.progressLabel }}</p>
          </div>
        </div>
      </section>

      <section class="grid gap-4 xl:grid-cols-[1.2fr_0.8fr]">
        <div class="card">
          <div class="flex items-center justify-between gap-3">
            <div>
              <h2 class="text-lg font-bold text-gray-900">Moduli i lekcije</h2>
              <p class="mt-1 text-sm text-gray-500">Prva preview lekcija je dostupna i bez upisa. Ostatak prati vaš plan pristupa.</p>
            </div>
            <span class="rounded-full bg-primary-50 px-2.5 py-1 text-xs font-semibold text-primary-700">
              {{ course.progressLabel }}
            </span>
          </div>

          <div class="mt-5 space-y-4">
            <article v-for="module in course.modules" :key="module.id" class="rounded-2xl border border-gray-100 p-4">
              <div class="flex items-center justify-between gap-3">
                <div>
                  <h3 class="font-semibold text-gray-900">{{ module.title }}</h3>
                  <p v-if="module.description" class="mt-1 text-sm text-gray-500">{{ module.description }}</p>
                </div>
                <span class="text-xs font-semibold text-gray-400">{{ module.lessons.length }} lekcija</span>
              </div>

              <div class="mt-4 space-y-2">
                <div
                  v-for="lesson in module.lessons"
                  :key="lesson.id"
                  class="flex items-center justify-between gap-3 rounded-2xl bg-gray-50 px-4 py-3"
                >
                  <div class="min-w-0">
                    <p class="text-sm font-semibold text-gray-900">{{ lesson.title }}</p>
                    <p class="mt-1 text-xs text-gray-500">
                      {{ lesson.isPreview ? 'Preview' : lesson.accessLabel }}
                    </p>
                  </div>
                  <NuxtLink
                    v-if="lesson.canOpen"
                    :to="`/portal/education/courses/${course.slug}/lessons/${lesson.id}`"
                    class="btn-secondary text-sm"
                  >
                    Otvori
                  </NuxtLink>
                  <span v-else class="rounded-full bg-gray-200 px-3 py-1 text-xs font-semibold text-gray-500">Zaključano</span>
                </div>
              </div>
            </article>
          </div>
        </div>

        <div class="space-y-4">
          <div class="card">
            <h2 class="text-lg font-bold text-gray-900">Akcije</h2>
            <div class="mt-4 space-y-3">
              <button
                v-if="canEnroll"
                type="button"
                class="btn-primary w-full"
                :disabled="enrolling"
                @click="enroll"
              >
                {{ enrolling ? 'Upisujem...' : 'Upiši kurs' }}
              </button>
              <NuxtLink
                v-else-if="primaryLessonHref"
                :to="primaryLessonHref"
                class="btn-primary block w-full text-center"
              >
                {{ course.enrollment ? 'Nastavi kurs' : 'Pogledaj preview' }}
              </NuxtLink>
              <NuxtLink to="/pricing" class="btn-secondary block w-full text-center">
                Pregled planova
              </NuxtLink>
            </div>
          </div>

          <div class="card">
            <h2 class="text-lg font-bold text-gray-900">Sažetak</h2>
            <dl class="mt-4 space-y-3 text-sm">
              <div class="flex items-center justify-between gap-3">
                <dt class="text-gray-500">Trajanje</dt>
                <dd class="font-semibold text-gray-900">{{ course.durationLabel }}</dd>
              </div>
              <div class="flex items-center justify-between gap-3">
                <dt class="text-gray-500">Tier</dt>
                <dd class="font-semibold text-gray-900">{{ course.tierLabel }}</dd>
              </div>
              <div class="flex items-center justify-between gap-3">
                <dt class="text-gray-500">Napredak</dt>
                <dd class="font-semibold text-gray-900">{{ course.progressLabel }}</dd>
              </div>
            </dl>
          </div>
        </div>
      </section>
    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })

const route = useRoute()
const supabase = useSupabase()
const { user } = useAuth()
const { hasAccess } = useTier()
const slug = route.params.slug as string
const enrolling = ref(false)

const domainMeta = {
  emotional: { label: 'Emocionalni', color: '#cf2e2e', icon: '❤️' },
  social: { label: 'Socijalni', color: '#fcb900', icon: '🤝' },
  creative: { label: 'Kreativni', color: '#9b51e0', icon: '🎨' },
  cognitive: { label: 'Kognitivni', color: '#0693e3', icon: '🧠' },
  motor: { label: 'Motorički', color: '#00d084', icon: '🏃' },
  language: { label: 'Jezički', color: '#f78da7', icon: '💬' },
} as const

const { data: course, pending, refresh } = await useAsyncData(`portal-course-${slug}`, async () => {
  const { data: courseRow } = await supabase
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
        description,
        sort_order,
        course_lessons (
          id,
          title,
          description,
          sort_order,
          is_preview
        )
      )
    `)
    .eq('slug', slug)
    .eq('content_type', 'course')
    .eq('status', 'published')
    .maybeSingle()

  if (!courseRow) return null

  const enrollment = user.value
    ? (await supabase
        .from('course_enrollments')
        .select('id, progress_percent, completed_lessons, status')
        .eq('user_id', user.value.id)
        .eq('course_id', courseRow.id)
        .maybeSingle()).data
    : null

  const completedLessons = new Set((enrollment?.completed_lessons as string[] | null) ?? [])
  const domain = domainMeta[(courseRow.domain as keyof typeof domainMeta) ?? 'creative'] ?? domainMeta.creative
  const tierAllowed = hasAccess(courseRow.required_tier as 'free' | 'paid' | 'premium')

  const modules = (courseRow.course_modules ?? [])
    .sort((a: Record<string, any>, b: Record<string, any>) => Number(a.sort_order ?? 0) - Number(b.sort_order ?? 0))
    .map((module: Record<string, any>) => ({
      id: module.id as string,
      title: module.title as string,
      description: (module.description as string | null) ?? '',
      lessons: (module.course_lessons ?? [])
        .sort((a: Record<string, any>, b: Record<string, any>) => Number(a.sort_order ?? 0) - Number(b.sort_order ?? 0))
        .map((lesson: Record<string, any>) => ({
          id: lesson.id as string,
          title: lesson.title as string,
          isPreview: Boolean(lesson.is_preview),
          canOpen: Boolean(lesson.is_preview) || Boolean(enrollment) || tierAllowed,
          accessLabel: completedLessons.has(lesson.id as string) ? 'Završeno' : tierAllowed ? 'Dostupno nakon upisa' : 'Zaključano po planu',
        })),
    }))

  const allLessons = modules.flatMap((module) => module.lessons)
  const previewLesson = allLessons.find((lesson) => lesson.isPreview) ?? allLessons[0] ?? null

  return {
    id: courseRow.id as string,
    slug: courseRow.slug as string,
    title: courseRow.title as string,
    description: (courseRow.description as string | null) ?? 'Online kurs za roditelje.',
    domainLabel: domain.label,
    domainColor: domain.color,
    domainIcon: domain.icon,
    durationLabel: `${courseRow.duration_minutes ?? 60} min`,
    lessonCount: allLessons.length,
    tierLabel: courseRow.required_tier === 'premium' ? 'Premium' : courseRow.required_tier === 'paid' ? 'Paid' : 'Free',
    tierClass: courseRow.required_tier === 'premium' ? 'bg-primary-100 text-primary-700' : courseRow.required_tier === 'paid' ? 'bg-brand-green/15 text-brand-green' : 'bg-gray-100 text-gray-600',
    enrollment,
    progressLabel: enrollment ? `${Number(enrollment.progress_percent ?? 0).toFixed(0)}%` : 'Nije upisano',
    modules,
    previewLesson,
    tierAllowed,
  }
})

const canEnroll = computed(() => {
  return Boolean(course.value && !course.value.enrollment && course.value.tierAllowed)
})

const primaryLessonHref = computed(() => {
  if (!course.value?.previewLesson) return null
  return `/portal/education/courses/${course.value.slug}/lessons/${course.value.previewLesson.id}`
})

async function enroll() {
  if (!course.value || !user.value) return
  enrolling.value = true
  try {
    await supabase.from('course_enrollments').insert({
      user_id: user.value.id,
      course_id: course.value.id,
      progress_percent: 0,
      status: 'active',
    })
    await refresh()
  } finally {
    enrolling.value = false
  }
}
</script>
