<template>
  <div class="max-w-4xl space-y-6">
    <div class="flex items-center gap-3">
      <NuxtLink to="/portal/community" class="text-gray-500 hover:text-gray-700">←</NuxtLink>
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Nova diskusija</h1>
        <p class="text-sm text-gray-500">Pokrenite temu za roditelje i zajednicu.</p>
      </div>
    </div>

    <form class="card space-y-4" @submit.prevent="submitTopic">
      <input v-model="form.title" class="input" placeholder="Naslov teme" required />
      <select v-model="form.categoryId" class="input" required>
        <option value="">Odaberite kategoriju</option>
        <option v-for="category in categories" :key="category.id" :value="category.id">
          {{ category.name }}
        </option>
      </select>
      <input v-model="tagsInput" class="input" placeholder="Tagovi odvojeni zarezom" />
      <textarea v-model="form.content" class="input min-h-[220px]" rows="10" placeholder="Opišite pitanje, iskustvo ili temu..." required />

      <div class="flex justify-end">
        <button type="submit" class="btn-primary" :disabled="submitting">
          {{ submitting ? 'Objavljujem...' : 'Objavi diskusiju' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })
useSeoMeta({ title: 'Nova diskusija — Zajednica' })

const supabase = useSupabase()
const router = useRouter()
const { user } = useAuth()
const tagsInput = ref('')
const submitting = ref(false)

const form = reactive({
  title: '',
  categoryId: '',
  content: '',
})

const { data: categories } = await useAsyncData('forum-categories-new', async () => {
  const { data } = await supabase.from('forum_categories').select('id, name').eq('is_active', true).eq('is_locked', false).order('sort_order')
  return data ?? []
})

async function submitTopic() {
  if (!user.value) return
  submitting.value = true
  const slug = form.title.toLowerCase().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-').replace(/-+/g, '-').trim()

  try {
    const { error } = await supabase.from('forum_topics').insert({
      title: form.title,
      slug: `${slug}-${Date.now().toString().slice(-5)}`,
      content: form.content,
      author_id: user.value.id,
      category_id: form.categoryId,
      tags: tagsInput.value.split(',').map((tag) => tag.trim()).filter(Boolean),
      status: 'published',
    })

    if (error) throw error
    await router.push('/portal/community')
  } finally {
    submitting.value = false
  }
}
</script>
