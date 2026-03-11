<template>
  <div class="max-w-6xl space-y-6">
    <div>
      <NuxtLink to="/admin/blog" class="text-sm text-gray-500 hover:text-gray-700">← Nazad na blog</NuxtLink>
      <h1 class="mt-2 font-display text-2xl font-bold text-gray-900">{{ isEditing ? 'Uredi blog post' : 'Novi blog post' }}</h1>
    </div>

    <form class="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]" @submit.prevent="savePost">
      <div class="space-y-6">
        <section class="card space-y-4">
          <h2 class="font-display font-bold text-lg text-gray-900">Osnovno</h2>
          <input v-model="form.title" class="input" placeholder="Naslov posta" required />
          <input v-model="form.slug" class="input" placeholder="Slug" required />
          <textarea v-model="form.excerpt" class="input" rows="3" placeholder="Kratki uvod / excerpt" />
          <textarea v-model="form.content" class="input min-h-[320px]" rows="14" placeholder="HTML ili rich text sadržaj" />
        </section>

        <section class="card space-y-4">
          <h2 class="font-display font-bold text-lg text-gray-900">Meta podaci</h2>
          <div class="grid gap-4 sm:grid-cols-2">
            <input v-model="form.author_name" class="input" placeholder="Autor" />
            <input v-model="form.category" class="input" placeholder="Kategorija" />
            <input v-model="form.cover_image_url" class="input sm:col-span-2" placeholder="Cover image URL" />
            <input v-model="tagsInput" class="input sm:col-span-2" placeholder="Tagovi odvojeni zarezom" />
            <input v-model="form.seo_title" class="input sm:col-span-2" placeholder="SEO naslov" />
            <textarea v-model="form.seo_description" class="input sm:col-span-2" rows="3" placeholder="SEO opis" />
          </div>
        </section>
      </div>

      <div class="space-y-6">
        <section class="card space-y-4">
          <h2 class="font-display font-bold text-lg text-gray-900">Objava</h2>
          <div class="grid gap-4">
            <input v-model.number="form.read_time_minutes" type="number" min="1" class="input" placeholder="Vrijeme čitanja (min)" />
            <input v-model="form.published_at" type="datetime-local" class="input" />
            <label class="flex items-center gap-3 text-sm font-semibold text-gray-700">
              <input v-model="form.is_published" type="checkbox" class="rounded" />
              Objavi post
            </label>
            <label class="flex items-center gap-3 text-sm font-semibold text-gray-700">
              <input v-model="form.is_featured" type="checkbox" class="rounded" />
              Označi kao istaknuti
            </label>
          </div>
        </section>

        <section class="card">
          <h2 class="font-display font-bold text-lg text-gray-900">Preview</h2>
          <div class="mt-4 rounded-2xl bg-gray-50 p-4">
            <p class="text-xs font-semibold uppercase tracking-wide text-primary-600">{{ form.category || 'Blog' }}</p>
            <h3 class="mt-2 font-bold text-gray-900">{{ form.title || 'Naslov posta' }}</h3>
            <p class="mt-2 text-sm text-gray-600">{{ form.excerpt || previewExcerpt }}</p>
          </div>
        </section>

        <section class="card">
          <button type="submit" class="btn-primary w-full" :disabled="saving">
            {{ saving ? 'Čuvam...' : (isEditing ? 'Sačuvaj izmjene' : 'Kreiraj post') }}
          </button>
        </section>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
const route = useRoute()
const router = useRouter()
const supabase = useSupabase()
const { getPostById } = useBlogAdmin()

const postId = computed(() => route.params.id as string | undefined)
const isEditing = computed(() => Boolean(postId.value))
const saving = ref(false)
const tagsInput = ref('')

const form = reactive({
  title: '',
  slug: '',
  excerpt: '',
  content: '',
  cover_image_url: '',
  author_name: '',
  category: '',
  read_time_minutes: 4,
  is_published: false,
  is_featured: false,
  seo_title: '',
  seo_description: '',
  published_at: '',
})

if (postId.value) {
  const { data } = await useAsyncData(`admin-blog-post-${postId.value}`, () => getPostById(postId.value!))
  if (data.value) {
    Object.assign(form, {
      title: data.value.title,
      slug: data.value.slug,
      excerpt: data.value.excerpt ?? '',
      content: data.value.content ?? '',
      cover_image_url: data.value.cover_image_url ?? '',
      author_name: data.value.author_name ?? '',
      category: data.value.category ?? '',
      read_time_minutes: data.value.read_time_minutes ?? 4,
      is_published: Boolean(data.value.is_published),
      is_featured: Boolean(data.value.is_featured),
      seo_title: data.value.seo_title ?? '',
      seo_description: data.value.seo_description ?? '',
      published_at: toDateTimeLocal(data.value.published_at),
    })
    tagsInput.value = (data.value.tags ?? []).join(', ')
  }
}

watch(() => form.title, (value) => {
  if (!isEditing.value) {
    form.slug = value.toLowerCase().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-').replace(/-+/g, '-').trim()
  }
})

const previewExcerpt = computed(() => (form.content || '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 150))

async function savePost() {
  saving.value = true
  const payload = {
    title: form.title,
    slug: form.slug,
    excerpt: form.excerpt || null,
    content: form.content || null,
    cover_image_url: form.cover_image_url || null,
    author_name: form.author_name || null,
    category: form.category || null,
    tags: tagsInput.value.split(',').map((tag) => tag.trim()).filter(Boolean),
    read_time_minutes: form.read_time_minutes || null,
    is_published: form.is_published,
    is_featured: form.is_featured,
    seo_title: form.seo_title || null,
    seo_description: form.seo_description || null,
    published_at: form.is_published ? (form.published_at ? new Date(form.published_at).toISOString() : new Date().toISOString()) : null,
  }

  try {
    if (postId.value) {
      const { error } = await supabase.from('blog_posts').update(payload).eq('id', postId.value)
      if (error) throw error
    } else {
      const { error } = await supabase.from('blog_posts').insert(payload)
      if (error) throw error
    }

    await router.push('/admin/blog')
  } finally {
    saving.value = false
  }
}

function toDateTimeLocal(value: string | null): string {
  if (!value) return ''
  const date = new Date(value)
  const pad = (n: number) => n.toString().padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
}
</script>
