<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Online Kursevi</h1>
      <p class="text-sm text-gray-500 mt-1">Edukativni kursevi za roditelje i djecu</p>
    </div>

    <!-- Feature Gate -->
    <FeatureGate required-tier="paid">
      <template #locked>
        <div class="text-center py-12">
          <div class="text-5xl mb-4">🔒</div>
          <h3 class="font-display font-bold text-xl text-gray-900 mb-2">
            Kursevi su dostupni na Paid tieru
          </h3>
          <p class="text-gray-600 mb-6">
            Nadogradite na Paid tier za pristup online kursevima.
          </p>
          <NuxtLink to="/pricing" class="btn-primary">Pregledajte Planove</NuxtLink>
        </div>
      </template>

      <!-- Content -->
      <div class="space-y-6">
        <!-- Search & Filters -->
        <div class="card">
          <div class="flex flex-col md:flex-row gap-3 md:items-center md:justify-between">
            <div class="relative flex-1 max-w-md">
              <svg class="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input
                v-model="search"
                type="search"
                class="input pl-10"
                placeholder="Pretraži kurseve..."
              />
            </div>
            <div class="flex flex-wrap gap-2">
              <select v-model="filterDomain" class="input w-auto text-sm">
                <option value="">Sve domene</option>
                <option value="emotional">Emocionalni</option>
                <option value="social">Socijalni</option>
                <option value="creative">Kreativni</option>
                <option value="cognitive">Kognitivni</option>
                <option value="motor">Motorički</option>
                <option value="language">Jezički</option>
              </select>
              <select v-model="filterAge" class="input w-auto text-sm">
                <option value="">Svi uzrasti</option>
                <option value="2-3">2-3 godine</option>
                <option value="3-4">3-4 godine</option>
                <option value="4-5">4-5 godina</option>
                <option value="5-6">5-6 godina</option>
              </select>
            </div>
          </div>
        </div>

        <!-- My Courses -->
        <section v-if="enrolledCourses && enrolledCourses.length > 0">
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Moji Kursevi</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <NuxtLink
              v-for="course in enrolledCourses"
              :key="course.id"
              :to="`/portal/education/courses/${course.slug}`"
              class="card-hover block"
            >
              <!-- Cover image -->
              <div
                v-if="course.cover_image_url"
                class="h-40 rounded-xl bg-cover bg-center mb-4"
                :style="{ backgroundImage: `url(${course.cover_image_url})` }"
              />
              <div v-else class="h-40 rounded-xl bg-gradient-to-br from-primary-500 to-brand-pink mb-4 flex items-center justify-center">
                <span class="text-4xl">📚</span>
              </div>

              <div class="flex items-center gap-2 mb-2">
                <TierBadge :tier="course.required_tier" size="sm" />
                <span v-if="course.status === 'published'" class="text-xs text-brand-green font-semibold">Aktivan</span>
              </div>

              <h3 class="font-bold text-gray-900 mb-1">{{ course.title }}</h3>
              <p class="text-sm text-gray-600 line-clamp-2 mb-3">{{ course.description }}</p>

              <!-- Progress -->
              <div class="mb-2">
                <div class="flex justify-between text-xs text-gray-500 mb-1">
                  <span>Napredak</span>
                  <span>{{ course.progress_percent || 0 }}%</span>
                </div>
                <div class="h-2 bg-gray-200 rounded-full overflow-hidden">
                  <div
                    class="h-full bg-primary-500 rounded-full transition-all"
                    :style="{ width: `${course.progress_percent || 0}%` }"
                  />
                </div>
              </div>

              <!-- Meta -->
              <div class="flex items-center gap-3 text-xs text-gray-500">
                <span>{{ course.modules_count || 0 }} modula</span>
                <span>•</span>
                <span>{{ course.lessons_count || 0 }} lekcija</span>
                <span>•</span>
                <span>{{ course.duration_minutes || 0 }} min</span>
              </div>
            </NuxtLink>
          </div>
        </section>

        <!-- All Courses -->
        <section>
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Svi Kursevi</h2>

          <div v-if="filteredCourses && filteredCourses.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <NuxtLink
              v-for="course in filteredCourses"
              :key="course.id"
              :to="`/portal/education/courses/${course.slug}`"
              class="card-hover block"
            >
              <!-- Cover image -->
              <div
                v-if="course.cover_image_url"
                class="h-40 rounded-xl bg-cover bg-center mb-4"
                :style="{ backgroundImage: `url(${course.cover_image_url})` }"
              />
              <div v-else class="h-40 rounded-xl bg-gradient-to-br from-primary-500 to-brand-pink mb-4 flex items-center justify-center">
                <span class="text-4xl">📚</span>
              </div>

              <div class="flex items-center gap-2 mb-2">
                <TierBadge :tier="course.required_tier" size="sm" />
                <span v-if="course.status === 'published'" class="text-xs text-brand-green font-semibold">Aktivan</span>
              </div>

              <h3 class="font-bold text-gray-900 mb-1">{{ course.title }}</h3>
              <p class="text-sm text-gray-600 line-clamp-2 mb-3">{{ course.description }}</p>

              <!-- Meta -->
              <div class="flex items-center gap-3 text-xs text-gray-500">
                <span>{{ course.modules_count || 0 }} modula</span>
                <span>•</span>
                <span>{{ course.lessons_count || 0 }} lekcija</span>
                <span>•</span>
                <span>{{ course.duration_minutes || 0 }} min</span>
              </div>

              <div class="flex items-center gap-2 mt-3 text-xs text-gray-500">
                <span v-if="course.domain"
                  class="px-2 py-1 rounded-full"
                  :style="{ backgroundColor: getDomainColor(course.domain) + '20', color: getDomainColor(course.domain) }"
                >
                  {{ getDomainName(course.domain) }}
                </span>
                <span v-if="course.age_min && course.age_max">
                  {{ course.age_min }}-{{ course.age_max }} god
                </span>
              </div>
            </NuxtLink>
          </div>

          <div v-else class="card text-center py-12">
            <div class="text-4xl mb-3">📚</div>
            <p class="text-gray-600 text-sm">Nema pronađenih kurseva prema odabranim filterima.</p>
          </div>
        </section>
      </div>
    </FeatureGate>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })
useSeoMeta({ title: 'Online Kursevi — Šarena Sfera' })

const supabase = useSupabase()
const { user } = useAuth()
const { tierName } = useTier()

const search = ref('')
const filterDomain = ref('')
const filterAge = ref('')

// Load enrolled courses with progress
const { data: enrolledCourses } = await useAsyncData('my-courses', async () => {
  if (!user.value) return []

  const { data } = await supabase
    .from('course_enrollments')
    .select(`
      *,
      educational_content(
        id, title, slug, description, cover_image_url,
        required_tier, status, duration_minutes, domain, age_min, age_max,
        enrollment_count
      )
    `)
    .eq('user_id', user.value.id)
    .eq('status', 'active')
    .order('last_accessed_at', { ascending: false })

  return (data ?? []).map(e => ({
    ...e.educational_content,
    progress_percent: e.progress_percent,
    enrollment_id: e.id,
  }))
})

// Load all available courses
const { data: allCourses } = await useAsyncData('all-courses', async () => {
  const { data } = await supabase
    .from('educational_content')
    .select(`
      *,
      course_modules(count),
      course_lessons(count)
    `)
    .eq('content_type', 'course')
    .eq('status', 'published')
    .order('created_at', { ascending: false })

  return (data ?? []).map(c => ({
    ...c,
    modules_count: c.course_modules?.[0]?.count || 0,
    lessons_count: c.course_lessons?.[0]?.count || 0,
  }))
})

const filteredCourses = computed(() => {
  let courses = allCourses.value ?? []

  // Filter out enrolled courses from "all courses"
  const enrolledIds = enrolledCourses.value?.map(c => c.id) || []
  courses = courses.filter(c => !enrolledIds.includes(c.id))

  // Search filter
  if (search.value) {
    const s = search.value.toLowerCase()
    courses = courses.filter(c =>
      c.title.toLowerCase().includes(s) ||
      c.description?.toLowerCase().includes(s)
    )
  }

  // Domain filter
  if (filterDomain.value) {
    courses = courses.filter(c => c.domain === filterDomain.value)
  }

  // Age filter
  if (filterAge.value) {
    const [minAge, maxAge] = filterAge.value.split('-').map(Number)
    courses = courses.filter(c =>
      (!c.age_min || c.age_min <= maxAge) &&
      (!c.age_max || c.age_max >= minAge)
    )
  }

  return courses
})

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
</script>
