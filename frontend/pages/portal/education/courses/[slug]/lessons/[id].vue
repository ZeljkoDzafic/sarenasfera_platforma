<template>
  <div class="space-y-6">
    <NuxtLink :to="`/portal/education/courses/${slug}`" class="inline-flex items-center gap-2 text-sm font-semibold text-primary-600 hover:text-primary-700">
      ← Nazad na kurs
    </NuxtLink>

    <div v-if="pending" class="space-y-4">
      <div class="card h-32 animate-pulse" />
      <div class="card h-96 animate-pulse" />
    </div>

    <div v-else-if="!lessonView" class="card py-14 text-center">
      <div class="mb-4 text-5xl">📘</div>
      <h1 class="font-display text-xl font-bold text-gray-900">Lekcija nije pronađena</h1>
    </div>

    <template v-else>
      <section class="card">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <div class="flex flex-wrap gap-2">
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :style="{ backgroundColor: `${lessonView.domainColor}20`, color: lessonView.domainColor }">
                {{ lessonView.domainLabel }}
              </span>
              <span class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-semibold text-gray-600">
                {{ lessonView.accessLabel }}
              </span>
            </div>
            <h1 class="mt-4 text-3xl font-bold text-gray-900">{{ lessonView.lesson.title }}</h1>
            <p class="mt-2 text-sm text-gray-600">{{ lessonView.course.title }}</p>
          </div>

          <div class="flex gap-3">
            <button
              v-if="lessonView.canTrack"
              type="button"
              class="btn-primary"
              :disabled="saving"
              @click="markComplete"
            >
              {{ saving ? 'Čuvam...' : 'Označi završeno' }}
            </button>
            <NuxtLink v-else-if="lessonView.requiresEnrollment" :to="`/portal/education/courses/${slug}`" class="btn-primary">
              Upiši kurs
            </NuxtLink>
          </div>
        </div>
      </section>

      <section class="grid gap-4 xl:grid-cols-[1.2fr_0.8fr]">
        <div class="space-y-4">
          <div class="card">
            <div v-if="lessonView.lesson.videoUrl" class="mb-4 overflow-hidden rounded-2xl bg-black/5">
              <iframe
                :src="lessonView.lesson.videoUrl"
                class="aspect-video w-full"
                title="Video lekcija"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen
              />
            </div>

            <div v-if="lessonView.lesson.contentHtml" class="prose prose-sm max-w-none" v-html="lessonView.lesson.contentHtml" />
            <div v-else class="prose prose-sm max-w-none text-gray-700">
              <p>{{ lessonView.lesson.description || 'Lekcija je dostupna kroz video i priložene materijale.' }}</p>
            </div>
          </div>

          <div v-if="lessonView.lesson.attachments.length > 0" class="card">
            <h2 class="text-lg font-bold text-gray-900">Prilozi</h2>
            <div class="mt-4 space-y-2">
              <a
                v-for="attachment in lessonView.lesson.attachments"
                :key="attachment"
                :href="attachment"
                target="_blank"
                rel="noopener noreferrer"
                class="btn-secondary block w-full text-center"
              >
                Otvori prilog
              </a>
            </div>
          </div>
        </div>

        <div class="space-y-4">
          <div class="card">
            <h2 class="text-lg font-bold text-gray-900">Navigacija</h2>
            <div class="mt-4 grid gap-3">
              <NuxtLink v-if="lessonView.previousLessonId" :to="`/portal/education/courses/${slug}/lessons/${lessonView.previousLessonId}`" class="btn-secondary text-center">
                Prethodna lekcija
              </NuxtLink>
              <NuxtLink v-if="lessonView.nextLessonId" :to="`/portal/education/courses/${slug}/lessons/${lessonView.nextLessonId}`" class="btn-primary text-center">
                Sljedeća lekcija
              </NuxtLink>
            </div>
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
const lessonId = route.params.id as string
const saving = ref(false)

const domainMeta = {
  emotional: { label: 'Emocionalni', color: '#cf2e2e' },
  social: { label: 'Socijalni', color: '#fcb900' },
  creative: { label: 'Kreativni', color: '#9b51e0' },
  cognitive: { label: 'Kognitivni', color: '#0693e3' },
  motor: { label: 'Motorički', color: '#00d084' },
  language: { label: 'Jezički', color: '#f78da7' },
} as const

const { data: lessonView, pending, refresh } = await useAsyncData(`portal-course-lesson-${slug}-${lessonId}`, async () => {
  const { data: course } = await supabase
    .from('educational_content')
    .select(`
      id,
      title,
      slug,
      domain,
      required_tier,
      course_modules (
        id,
        sort_order,
        course_lessons (
          id,
          title,
          description,
          content_html,
          video_url,
          attachment_urls,
          sort_order,
          is_preview
        )
      )
    `)
    .eq('slug', slug)
    .eq('content_type', 'course')
    .eq('status', 'published')
    .maybeSingle()

  if (!course) return null

  const enrollment = user.value
    ? (await supabase
        .from('course_enrollments')
        .select('id, completed_lessons, progress_percent')
        .eq('user_id', user.value.id)
        .eq('course_id', course.id)
        .maybeSingle()).data
    : null

  const flattenedLessons = (course.course_modules ?? [])
    .sort((a: Record<string, any>, b: Record<string, any>) => Number(a.sort_order ?? 0) - Number(b.sort_order ?? 0))
    .flatMap((module: Record<string, any>) =>
      (module.course_lessons ?? [])
        .sort((a: Record<string, any>, b: Record<string, any>) => Number(a.sort_order ?? 0) - Number(b.sort_order ?? 0)),
    )

  const lesson = flattenedLessons.find((item: Record<string, any>) => item.id === lessonId)
  if (!lesson) return null

  const tierAllowed = hasAccess(course.required_tier as 'free' | 'paid' | 'premium')
  const requiresEnrollment = !lesson.is_preview && !enrollment
  const canTrack = Boolean(enrollment)
  const currentIndex = flattenedLessons.findIndex((item: Record<string, any>) => item.id === lessonId)
  const domain = domainMeta[(course.domain as keyof typeof domainMeta) ?? 'creative'] ?? domainMeta.creative

  return {
    course: {
      id: course.id as string,
      title: course.title as string,
    },
    lesson: {
      id: lesson.id as string,
      title: lesson.title as string,
      description: (lesson.description as string | null) ?? '',
      contentHtml: lesson.content_html as string | null,
      videoUrl: lesson.video_url as string | null,
      attachments: (lesson.attachment_urls as string[] | null) ?? [],
      isPreview: Boolean(lesson.is_preview),
    },
    enrollment,
    canTrack,
    requiresEnrollment: requiresEnrollment && tierAllowed,
    accessLabel: lesson.is_preview ? 'Preview' : enrollment ? 'Upisano' : tierAllowed ? 'Potreban upis' : 'Zaključano',
    previousLessonId: currentIndex > 0 ? flattenedLessons[currentIndex - 1].id as string : null,
    nextLessonId: currentIndex < flattenedLessons.length - 1 ? flattenedLessons[currentIndex + 1].id as string : null,
    domainLabel: domain.label,
    domainColor: domain.color,
  }
})

async function markComplete() {
  if (!lessonView.value?.enrollment?.id || !user.value) return
  saving.value = true
  try {
    await supabase.from('lesson_progress').upsert({
      user_id: user.value.id,
      lesson_id: lessonView.value.lesson.id,
      enrollment_id: lessonView.value.enrollment.id,
      status: 'completed',
      progress_percent: 100,
      completed_at: new Date().toISOString(),
    }, {
      onConflict: 'user_id,lesson_id',
    })

    const completedLessons = new Set((lessonView.value.enrollment.completed_lessons as string[] | null) ?? [])
    completedLessons.add(lessonView.value.lesson.id)

    await supabase
      .from('course_enrollments')
      .update({
        completed_lessons: [...completedLessons],
        last_accessed_at: new Date().toISOString(),
      })
      .eq('id', lessonView.value.enrollment.id)

    await refresh()
  } finally {
    saving.value = false
  }
}
</script>
