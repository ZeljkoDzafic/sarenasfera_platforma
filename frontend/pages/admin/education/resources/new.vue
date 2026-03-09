<template>
  <div class="max-w-6xl space-y-6">
    <div>
      <NuxtLink to="/admin/education" class="text-sm text-gray-500 hover:text-gray-700">← Nazad na edukaciju</NuxtLink>
      <h1 class="mt-2 font-display text-2xl font-bold text-gray-900">{{ isEditing ? 'Uredi resurs' : 'Novi resurs' }}</h1>
    </div>

    <form class="grid gap-6 xl:grid-cols-[1.1fr_0.9fr]" @submit.prevent="saveResource">
      <div class="space-y-6">
        <section class="card space-y-4">
          <h2 class="font-display font-bold text-lg text-gray-900">Osnovno</h2>
          <input v-model="form.title" class="input" placeholder="Naslov resursa" required />
          <input v-model="form.slug" class="input" placeholder="Slug" required />
          <textarea v-model="form.description" class="input" rows="4" placeholder="Opis resursa" />
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
            <select v-model="form.material_type" class="input">
              <option value="article">Članak</option>
              <option value="pdf">PDF</option>
              <option value="video">Video</option>
              <option value="worksheet">Radni list</option>
              <option value="document">Dokument</option>
            </select>
            <select v-model="form.status" class="input">
              <option value="draft">Draft</option>
              <option value="published">Published</option>
              <option value="archived">Archived</option>
            </select>
          </div>
        </section>

        <section class="card space-y-4">
          <h2 class="font-display font-bold text-lg text-gray-900">Sadržaj</h2>
          <textarea v-if="form.material_type === 'article'" v-model="form.content_html" class="input" rows="10" placeholder="HTML / rich text sadržaj članka" />
          <input v-if="form.material_type === 'video'" v-model="form.video_url" class="input" placeholder="Video URL" />
          <div v-if="['pdf', 'worksheet', 'document', 'video'].includes(form.material_type)" class="space-y-2">
            <input type="file" class="input" @change="onFileSelected" />
            <p v-if="selectedFileName" class="text-xs text-primary-600">Odabrano: {{ selectedFileName }}</p>
          </div>
        </section>
      </div>

      <div class="space-y-6">
        <section class="card">
          <h2 class="font-display font-bold text-lg text-gray-900">Preview</h2>
          <div class="mt-4 rounded-2xl bg-gray-50 p-4">
            <h3 class="font-semibold text-gray-900">{{ form.title || 'Naslov resursa' }}</h3>
            <p class="mt-2 text-sm text-gray-600">{{ form.description || 'Opis resursa.' }}</p>
            <p class="mt-3 text-xs text-gray-500">{{ form.material_type }} • {{ form.required_tier }}</p>
          </div>
          <NuxtLink
            v-if="form.slug"
            :to="`/portal/education/resources/${form.slug}`"
            target="_blank"
            class="btn-secondary mt-4 block w-full text-center"
          >
            Otvori preview
          </NuxtLink>
        </section>
        <section class="card">
          <button type="submit" class="btn-primary w-full" :disabled="saving">
            {{ saving ? 'Čuvam...' : (isEditing ? 'Sačuvaj izmjene' : 'Kreiraj resurs') }}
          </button>
        </section>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Resource creator — Admin' })

const route = useRoute()
const router = useRouter()
const supabase = useSupabase()

const editId = computed(() => route.query.edit as string | undefined)
const sourceId = computed(() => (route.query.from as string | undefined) ?? editId.value)
const isEditing = computed(() => Boolean(editId.value))
const saving = ref(false)
const selectedFile = ref<File | null>(null)

const form = reactive({
  title: '',
  slug: '',
  description: '',
  domain: 'creative',
  required_tier: 'free',
  material_type: 'article',
  content_html: '',
  video_url: '',
  status: 'draft',
})

if (sourceId.value) {
  const { data } = await useAsyncData(`admin-resource-source-${sourceId.value}`, async () => {
    const { data } = await supabase
      .from('educational_content')
      .select(`
        id,
        title,
        slug,
        description,
        domain,
        required_tier,
        status,
        resource_materials (
          id,
          file_type,
          title,
          file_url,
          content_html,
          video_url
        )
      `)
      .eq('id', sourceId.value)
      .maybeSingle()
    return data
  })
  if (data.value) {
    const material = data.value.resource_materials?.[0]
    Object.assign(form, {
      title: editId.value ? data.value.title : `${data.value.title} kopija`,
      slug: editId.value ? data.value.slug : `${data.value.slug}-copy`,
      description: data.value.description ?? '',
      domain: data.value.domain ?? 'creative',
      required_tier: data.value.required_tier ?? 'free',
      material_type: material?.file_type ?? 'article',
      content_html: material?.content_html ?? '',
      video_url: material?.video_url ?? '',
      status: editId.value ? data.value.status : 'draft',
    })
  }
}

watch(() => form.title, (value) => {
  if (!isEditing.value && !route.query.from) {
    form.slug = value.toLowerCase().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-').replace(/-+/g, '-').trim()
  }
})

const selectedFileName = computed(() => selectedFile.value?.name ?? '')

function onFileSelected(event: Event) {
  const input = event.target as HTMLInputElement
  selectedFile.value = input.files?.[0] ?? null
}

async function saveResource() {
  saving.value = true
  try {
    let contentId = editId.value

    if (editId.value) {
      await supabase.from('educational_content').update({
        title: form.title,
        slug: form.slug,
        description: form.description,
        domain: form.domain,
        required_tier: form.required_tier,
        status: form.status,
        content_type: 'resource',
      }).eq('id', editId.value)

      await supabase.from('resource_materials').delete().eq('content_id', editId.value)
    } else {
      const { data, error } = await supabase.from('educational_content').insert({
        title: form.title,
        slug: form.slug,
        description: form.description,
        domain: form.domain,
        required_tier: form.required_tier,
        status: form.status,
        content_type: 'resource',
      }).select('id').single()
      if (error) throw error
      contentId = data.id
    }

    let fileUrl: string | null = null
    if (selectedFile.value) {
      const extension = selectedFile.value.name.split('.').pop() || 'bin'
      const path = `${contentId}/${Date.now()}.${extension}`
      const { error: uploadError } = await supabase.storage.from('education-content').upload(path, selectedFile.value, { upsert: false })
      if (uploadError) throw uploadError
      fileUrl = supabase.storage.from('education-content').getPublicUrl(path).data.publicUrl
    }

    await supabase.from('resource_materials').insert({
      content_id: contentId,
      file_type: form.material_type,
      title: form.title,
      description: form.description || null,
      file_url: fileUrl ?? '',
      content_html: form.material_type === 'article' ? form.content_html || null : null,
      video_url: form.material_type === 'video' ? form.video_url || fileUrl || null : null,
    })

    await router.push('/admin/education')
  } finally {
    saving.value = false
  }
}
</script>
