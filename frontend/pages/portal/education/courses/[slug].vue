<template>
  <div class="space-y-6">
    <!-- Loading -->
    <div v-if="pending" class="space-y-4">
      <div class="card animate-pulse h-64" />
      <div class="card animate-pulse h-48" />
    </div>

    <!-- Not found -->
    <div v-else-if="!course" class="card text-center py-16">
      <div class="text-5xl mb-4">📚</div>
      <h3 class="font-display font-bold text-xl text-gray-900 mb-2">Kurs nije pronađen</h3>
      <NuxtLink to="/portal/education/courses" class="btn-primary">Nazad na kurseve</NuxtLink>
    </div>

    <div v-else class="space-y-6">
      <!-- Header with cover -->
      <div class="card overflow-hidden p-0">
        <div
          v-if="course.cover_image_url"
          class="h-64 bg-cover bg-center"
          :style="{ backgroundImage: `url(${course.cover_image_url})` }"
        />
        <div v-else class="h-64 bg-gradient-to-br from-primary-500 to-brand-pink flex items-center justify-center">
          <span class="text-6xl">📚</span>
        </div>

        <div class="p-6">
          <div class="flex items-center gap-2 mb-3">
            <TierBadge :tier="course.required_tier" />
            <span
              v-if="course.domain"
              class="px-3 py-1 rounded-full text-xs font-semibold"
              :style="{ backgroundColor: getDomainColor(course.domain) + '20', color: getDomainColor(course.domain) }"
            >
              {{ getDomainName(course.domain) }}
            </span>
          </div>

          <h1 class="font-display text-2xl font-bold text-gray-900 mb-2">{{ course.title }}</h1>
          <p class="text-gray-600 mb-4">{{ course.description }}</p>

          <div class="flex flex-wrap items-center gap-4 text-sm text-gray-500 mb-4">
            <span class="flex items-center gap-1">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              {{ course.duration_minutes || 0 }} min
            </span>
            <span class="flex items-center gap-1">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              {{ modules.length }} modula
            </span>
            <span class="flex items-center gap-1">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
              </svg>
              {{ course.view_count || 0 }} pregleda
            </span>
          </div>

          <!-- Enroll / Continue button -->
          <div class="flex gap-3">
            <button
              v-if="isEnrolled"
              class="btn-primary"
              @click="continueLearning"
            >
              {{ progress > 0 ? 'Nastavi učenje' : 'Započni kurs' }}
            </button>
            <button
              v-else
              class="btn-primary"
              @click="enroll"
              :disabled="enrolling"
            >
              {{ enrolling ? 'Upisujem...' : 'Upiši se besplatno' }}
            </button>
            <button class="btn-secondary">
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
              </svg>
              Sačuvaj
            </button>
          </div>
        </div>
      </div>

      <!-- Progress (if enrolled) -->
      <div v-if="isEnrolled && progress > 0" class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Tvoj Napredak</h2>
        <div class="flex items-center gap-4">
          <div class="flex-1">
            <div class="h-3 bg-gray-200 rounded-full overflow-hidden">
              <div
                class="h-full bg-primary-500 rounded-full transition-all"
                :style="{ width: `${progress}%` }"
              />
            </div>
          </div>
          <span class="text-lg font-bold text-primary-600">{{ progress }}%</span>
        </div>
        <p class="text-sm text-gray-500 mt-2">
          {{ completedLessons }} od {{ totalLessons }} lekcija završeno
        </p>
      </div>

      <!-- Syllabus / Modules -->
      <section>
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Program Kursa</h2>

        <div class="space-y-4">
          <div
            v-for="(module, index) in modules"
            :key="module.id"
            class="card"
          >
            <div class="flex items-center gap-3 mb-4">
              <div class="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center text-primary-600 font-bold text-sm">
                {{ index + 1 }}
              </div>
              <h3 class="font-bold text-gray-900">{{ module.title }}</h3>
            </div>

            <div class="space-y-2 ml-11">
              <div
                v-for="lesson in module.lessons"
                :key="lesson.id"
                class="flex items-center justify-between p-3 rounded-xl hover:bg-gray-50 transition-colors cursor-pointer"
                @click="openLesson(lesson)"
              >
                <div class="flex items-center gap-3 flex-1 min-w-0">
                  <!-- Lesson type icon -->
                  <div
                    class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
                    :class="getLessonTypeClass(lesson.lesson_type)"
                  >
                    {{ getLessonTypeIcon(lesson.lesson_type) }}
                  </div>

                  <!-- Lesson info -->
                  <div class="flex-1 min-w-0">
                    <h4 class="font-semibold text-gray-900 text-sm truncate">{{ lesson.title }}</h4>
                    <div class="flex items-center gap-2 text-xs text-gray-500">
                      <span v-if="lesson.video_duration">{{ formatDuration(lesson.video_duration) }}</span>
                      <span v-if="lesson.lesson_type !== 'content'">• {{ getLessonTypeLabel(lesson.lesson_type) }}</span>
                    </div>
                  </div>

                  <!-- Status -->
                  <div v-if="isEnrolled" class="flex-shrink-0">
                    <span
                      v-if="completedLessonsList.includes(lesson.id)"
                      class="text-brand-green text-sm font-semibold"
                    >
                      ✓ Završeno
                    </span>
                    <span v-else-if="lesson.is_preview" class="text-primary-600 text-xs font-semibold">
                      🔓 Preview
                    </span>
                    <span v-else class="text-gray-400 text-xs">
                      🔒 Zaključano
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- Instructor / About -->
      <section class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">O Kursu</h2>
        <div class="prose max-w-none text-gray-700">
          <p>{{ course.description }}</p>
        </div>

        <div class="mt-4 flex items-center gap-3">
          <div class="w-12 h-12 rounded-full bg-primary-100 flex items-center justify-center text-primary-600 font-bold">
            {{ (course.created_by || 'A')[0] }}
          </div>
          <div>
            <p class="font-semibold text-gray-900">Šarena Sfera Tim</p>
            <p class="text-sm text-gray-500">Autor</p>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })

const route = useRoute()
const supabase = useSupabase()
const { user } = useAuth()

const courseSlug = route.params.slug as string

const { data: course, pending } = await useAsyncData(`course-${courseSlug}`, async () => {
  const { data } = await supabase
    .from('educational_content')
    .select('*')
    .eq('slug', courseSlug)
    .eq('content_type', 'course')
    .single()

  return data
})

// Load modules and lessons
const { data: modulesData } = await useAsyncData(`course-modules-${courseSlug}`, async () => {
  if (!course.value) return []

  const { data } = await supabase
    .from('course_modules')
    .select(`
      *,
      course_lessons(
        id, title, slug, lesson_type, video_duration, is_preview, sort_order
      )
    `)
    .eq('course_id', course.value.id)
    .order('sort_order')

  return (data ?? []).map(m => ({
    ...m,
    lessons: (m.course_lessons || []).sort((a, b) => a.sort_order - b.sort_order),
  }))
})

const modules = computed(() => modulesData.value || [])

const totalLessons = computed(() =>
  modules.value.reduce((sum, m) => sum + m.lessons.length, 0)
)

// Check enrollment
const { data: enrollment } = await useAsyncData('course-enrollment', async () => {
  if (!user.value || !course.value) return null

  const { data } = await supabase
    .from('course_enrollments')
    .select('*')
    .eq('user_id', user.value.id)
    .eq('course_id', course.value.id)
    .single()

  return data
})

const isEnrolled = computed(() => !!enrollment.value)
const progress = computed(() => enrollment.value?.progress_percent || 0)
const completedLessons = computed(() => enrollment.value?.completed_lessons?.length || 0)
const completedLessonsList = computed(() => enrollment.value?.completed_lessons || [])

const enrolling = ref(false)

async function enroll() {
  if (!user.value || !course.value) return

  enrolling.value = true

  try {
    // Check if user has access based on tier
    const { data: canAccess } = await supabase.rpc('can_access_content', {
      content_id: course.value.id,
    })

    if (!canAccess) {
      navigateTo('/pricing')
      return
    }

    // Create enrollment
    await supabase.from('course_enrollments').insert({
      user_id: user.value.id,
      course_id: course.value.id,
      status: 'active',
    })

    // Refresh
    await refreshNuxtData('course-enrollment')
  } catch (err) {
    console.error('Failed to enroll:', err)
  } finally {
    enrolling.value = false
  }
}

function continueLearning() {
  // Find first incomplete lesson
  const allLessons = modules.value.flatMap(m => m.lessons)
  const nextLesson = allLessons.find(l => !completedLessonsList.value.includes(l.id))

  if (nextLesson) {
    openLesson(nextLesson)
  }
}

function openLesson(lesson: any) {
  navigateTo(`/portal/education/courses/${courseSlug}/lessons/${lesson.slug}`)
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

function getLessonTypeClass(type: string): string {
  const map: Record<string, string> = {
    content: 'bg-primary-100 text-primary-600',
    quiz: 'bg-brand-amber/20 text-brand-amber',
    assignment: 'bg-brand-pink/20 text-brand-pink',
    discussion: 'bg-brand-green/20 text-brand-green',
  }
  return map[type] || 'bg-gray-100 text-gray-600'
}

function getLessonTypeIcon(type: string): string {
  const map: Record<string, string> = {
    content: '📖',
    quiz: '📝',
    assignment: '📋',
    discussion: '💬',
  }
  return map[type] || '📄'
}

function getLessonTypeLabel(type: string): string {
  const map: Record<string, string> = {
    content: 'Lekcija',
    quiz: 'Kviz',
    assignment: 'Zadatak',
    discussion: 'Diskusija',
  }
  return map[type] || 'Lekcija'
}

function formatDuration(seconds: number): string {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins}:${secs.toString().padStart(2, '0')}`
}
</script>
