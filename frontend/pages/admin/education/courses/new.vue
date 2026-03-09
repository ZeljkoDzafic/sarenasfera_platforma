<template>
  <div class="max-w-6xl space-y-6">
    <div>
      <NuxtLink to="/admin/education" class="text-sm text-gray-500 hover:text-gray-700">← Nazad na edukaciju</NuxtLink>
      <h1 class="mt-2 font-display text-2xl font-bold text-gray-900">{{ isEditing ? 'Uredi kurs' : 'Novi kurs' }}</h1>
    </div>

    <form class="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]" @submit.prevent="saveCourse">
      <div class="space-y-6">
        <section class="card space-y-4">
          <h2 class="font-display font-bold text-lg text-gray-900">Osnovno</h2>
          <input v-model="form.title" class="input" placeholder="Naziv kursa" required />
          <input v-model="form.slug" class="input" placeholder="Slug" required />
          <textarea v-model="form.description" class="input" rows="5" placeholder="Opis kursa" />
          <div class="grid gap-4 sm:grid-cols-2">
            <select v-model="form.domain" class="input">
              <option value="emotional">Emocionalni</option>
              <option value="social">Socijalni</option>
              <option value="creative">Kreativni</option>
              <option value="cognitive">Kognitivni</option>
              <option value="motor">Motorički</option>
              <option value="language">Jezički</option>
            </select>
            <select v-model="form.required_tier" class="input">
              <option value="free">Free</option>
              <option value="paid">Paid</option>
              <option value="premium">Premium</option>
            </select>
            <input v-model.number="form.age_min" type="number" min="2" max="6" class="input" placeholder="Min uzrast" />
            <input v-model.number="form.age_max" type="number" min="2" max="6" class="input" placeholder="Max uzrast" />
            <input v-model.number="form.duration_minutes" type="number" min="10" class="input" placeholder="Trajanje (min)" />
            <select v-model="form.status" class="input">
              <option value="draft">Draft</option>
              <option value="published">Published</option>
              <option value="archived">Archived</option>
            </select>
          </div>
        </section>

        <section class="card space-y-4">
          <div class="flex items-center justify-between">
            <h2 class="font-display font-bold text-lg text-gray-900">Moduli i lekcije</h2>
            <button type="button" class="btn-secondary text-sm" @click="addModule">+ Modul</button>
          </div>

          <div v-if="modules.length > 0" class="space-y-4">
            <article v-for="(module, moduleIndex) in modules" :key="module.localId" class="rounded-2xl border border-gray-200 p-4">
              <div class="flex items-center justify-between gap-3">
                <input v-model="module.title" class="input" placeholder="Naziv modula" />
                <button type="button" class="btn-secondary text-sm" @click="removeModule(moduleIndex)">Obriši</button>
              </div>
              <textarea v-model="module.description" class="input mt-3" rows="2" placeholder="Opis modula" />

              <div class="mt-4 space-y-3">
                <div class="flex items-center justify-between">
                  <p class="text-sm font-semibold text-gray-700">Lekcije</p>
                  <button type="button" class="btn-secondary text-sm" @click="addLesson(moduleIndex)">+ Lekcija</button>
                </div>
                <div v-for="(lesson, lessonIndex) in module.lessons" :key="lesson.localId" class="rounded-2xl bg-gray-50 p-4">
                  <div class="grid gap-3">
                    <div class="flex items-center justify-between gap-3">
                      <input v-model="lesson.title" class="input" placeholder="Naziv lekcije" />
                      <button type="button" class="btn-secondary text-sm" @click="removeLesson(moduleIndex, lessonIndex)">Obriši</button>
                    </div>
                    <textarea v-model="lesson.description" class="input" rows="2" placeholder="Kratki opis lekcije" />
                    <textarea v-model="lesson.content_html" class="input" rows="5" placeholder="HTML / rich text sadržaj lekcije" />
                    <input v-model="lesson.video_url" class="input" placeholder="Video URL" />
                    <input v-model="lesson.attachments" class="input" placeholder="Attachment URL-ovi, odvojeni zarezom" />
                    <label class="flex items-center gap-2 text-sm font-semibold text-gray-700">
                      <input v-model="lesson.is_preview" type="checkbox" class="rounded" />
                      Preview lekcija
                    </label>
                  </div>
                </div>
              </div>
            </article>
          </div>
          <p v-else class="text-sm text-gray-500">Dodajte prvi modul i lekcije.</p>
        </section>
      </div>

      <div class="space-y-6">
        <section class="card">
          <h2 class="font-display font-bold text-lg text-gray-900">Preview</h2>
          <div class="mt-4 rounded-2xl bg-gray-50 p-4">
            <h3 class="font-semibold text-gray-900">{{ form.title || 'Naslov kursa' }}</h3>
            <p class="mt-2 text-sm text-gray-600">{{ form.description || 'Opis kursa će biti prikazan ovdje.' }}</p>
            <p class="mt-3 text-xs text-gray-500">{{ modules.length }} modula • {{ lessonCount }} lekcija</p>
          </div>
          <NuxtLink
            v-if="form.slug"
            :to="`/portal/education/courses/${form.slug}`"
            target="_blank"
            class="btn-secondary mt-4 block w-full text-center"
          >
            Otvori preview
          </NuxtLink>
        </section>

        <section class="card">
          <button type="submit" class="btn-primary w-full" :disabled="saving">
            {{ saving ? 'Čuvam...' : (isEditing ? 'Sačuvaj izmjene' : 'Kreiraj kurs') }}
          </button>
        </section>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Kurs creator — Admin' })

const route = useRoute()
const router = useRouter()
const supabase = useSupabase()

const editId = computed(() => route.query.edit as string | undefined)
const sourceId = computed(() => (route.query.from as string | undefined) ?? editId.value)
const isEditing = computed(() => Boolean(editId.value))
const saving = ref(false)

interface LessonDraft {
  localId: string
  title: string
  description: string
  content_html: string
  video_url: string
  attachments: string
  is_preview: boolean
}
interface ModuleDraft {
  localId: string
  title: string
  description: string
  lessons: LessonDraft[]
}

const form = reactive({
  title: '',
  slug: '',
  description: '',
  domain: 'creative',
  required_tier: 'free',
  age_min: 2,
  age_max: 6,
  duration_minutes: 60,
  status: 'draft',
})
const modules = ref<ModuleDraft[]>([])

if (sourceId.value) {
  const { data } = await useAsyncData(`admin-course-source-${sourceId.value}`, async () => {
    const { data } = await supabase
      .from('educational_content')
      .select(`
        id,
        title,
        slug,
        description,
        domain,
        required_tier,
        age_min,
        age_max,
        duration_minutes,
        status,
        course_modules (
          id,
          title,
          description,
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
      .eq('id', sourceId.value)
      .maybeSingle()
    return data
  })

  if (data.value) {
    Object.assign(form, {
      title: editId.value ? data.value.title : `${data.value.title} kopija`,
      slug: editId.value ? data.value.slug : `${data.value.slug}-copy`,
      description: data.value.description ?? '',
      domain: data.value.domain ?? 'creative',
      required_tier: data.value.required_tier ?? 'free',
      age_min: Number(data.value.age_min ?? 2),
      age_max: Number(data.value.age_max ?? 6),
      duration_minutes: Number(data.value.duration_minutes ?? 60),
      status: editId.value ? data.value.status : 'draft',
    })
    modules.value = (data.value.course_modules ?? []).map((module: Record<string, any>) => ({
      localId: crypto.randomUUID(),
      title: module.title ?? '',
      description: module.description ?? '',
      lessons: (module.course_lessons ?? []).map((lesson: Record<string, any>) => ({
        localId: crypto.randomUUID(),
        title: lesson.title ?? '',
        description: lesson.description ?? '',
        content_html: lesson.content_html ?? '',
        video_url: lesson.video_url ?? '',
        attachments: ((lesson.attachment_urls as string[] | null) ?? []).join(', '),
        is_preview: Boolean(lesson.is_preview),
      })),
    }))
  }
}

watch(() => form.title, (value) => {
  if (!isEditing.value && !route.query.from) {
    form.slug = value.toLowerCase().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-').replace(/-+/g, '-').trim()
  }
})

const lessonCount = computed(() => modules.value.reduce((sum, module) => sum + module.lessons.length, 0))

function addModule() {
  modules.value.push({ localId: crypto.randomUUID(), title: '', description: '', lessons: [] })
}
function removeModule(index: number) {
  modules.value.splice(index, 1)
}
function addLesson(moduleIndex: number) {
  const module = modules.value[moduleIndex]
  if (!module) return
  module.lessons.push({
    localId: crypto.randomUUID(),
    title: '',
    description: '',
    content_html: '',
    video_url: '',
    attachments: '',
    is_preview: false,
  })
}
function removeLesson(moduleIndex: number, lessonIndex: number) {
  const module = modules.value[moduleIndex]
  if (!module) return
  module.lessons.splice(lessonIndex, 1)
}

async function saveCourse() {
  saving.value = true
  try {
    let courseId = editId.value

    if (editId.value) {
      await supabase.from('educational_content').update({
        title: form.title,
        slug: form.slug,
        description: form.description,
        domain: form.domain,
        required_tier: form.required_tier,
        age_min: form.age_min,
        age_max: form.age_max,
        duration_minutes: form.duration_minutes,
        status: form.status,
      }).eq('id', editId.value)

      await supabase.from('course_modules').delete().eq('course_id', editId.value)
    } else {
      const { data, error } = await supabase.from('educational_content').insert({
        title: form.title,
        slug: form.slug,
        description: form.description,
        domain: form.domain,
        required_tier: form.required_tier,
        age_min: form.age_min,
        age_max: form.age_max,
        duration_minutes: form.duration_minutes,
        status: form.status,
        content_type: 'course',
      }).select('id').single()
      if (error) throw error
      courseId = data.id
    }

    for (const [moduleIndex, module] of modules.value.entries()) {
      const { data: moduleRow, error: moduleError } = await supabase
        .from('course_modules')
        .insert({
          course_id: courseId,
          title: module.title,
          description: module.description || null,
          sort_order: moduleIndex,
        })
        .select('id')
        .single()
      if (moduleError) throw moduleError

      for (const [lessonIndex, lesson] of module.lessons.entries()) {
        const { error: lessonError } = await supabase
          .from('course_lessons')
          .insert({
            module_id: moduleRow.id,
            title: lesson.title,
            slug: `${form.slug}-${moduleIndex + 1}-${lessonIndex + 1}`,
            description: lesson.description || null,
            content_html: lesson.content_html || null,
            video_url: lesson.video_url || null,
            attachment_urls: lesson.attachments ? lesson.attachments.split(',').map((item) => item.trim()).filter(Boolean) : [],
            sort_order: lessonIndex,
            is_preview: lesson.is_preview,
          })
        if (lessonError) throw lessonError
      }
    }

    await router.push('/admin/education')
  } finally {
    saving.value = false
  }
}
</script>
