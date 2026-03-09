<template>
  <div class="space-y-6">
    <!-- Back + Title -->
    <div class="flex items-center gap-3">
      <NuxtLink to="/portal/community" class="p-2 rounded-xl hover:bg-gray-100 text-gray-500 hover:text-gray-700 transition-colors">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </NuxtLink>
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">{{ topic?.title }}</h1>
        <div class="flex items-center gap-2 text-sm text-gray-500">
          <span>{{ topic?.forum_categories?.name }}</span>
          <span>•</span>
          <span>{{ topic?.view_count }} pregleda</span>
          <span>•</span>
          <span>{{ topic?.reply_count }} odgovora</span>
        </div>
      </div>
    </div>

    <!-- Original Post -->
    <div v-if="topic" class="card">
      <div class="flex items-start gap-4">
        <!-- Author -->
        <div class="text-center">
          <div class="w-16 h-16 rounded-full bg-primary-100 flex items-center justify-center text-primary-600 font-bold text-xl mb-2">
            {{ topic.profiles?.full_name?.[0] || 'U' }}
          </div>
          <p class="font-semibold text-gray-900 text-sm">{{ topic.profiles?.full_name }}</p>
          <p class="text-xs text-gray-500">{{ formatDateTime(topic.created_at) }}</p>
        </div>

        <!-- Content -->
        <div class="flex-1">
          <div class="prose max-w-none">
            <p class="text-gray-700 whitespace-pre-line">{{ topic.content }}</p>
          </div>

          <!-- Tags -->
          <div v-if="topic.tags && topic.tags.length > 0" class="flex gap-2 mt-4">
            <span
              v-for="tag in topic.tags"
              :key="tag"
              class="text-xs px-3 py-1 rounded-full bg-gray-100 text-gray-600 font-semibold"
            >
              #{{ tag }}
            </span>
          </div>

          <!-- Actions -->
          <div class="flex items-center gap-4 mt-6 pt-4 border-t border-gray-100">
            <button class="flex items-center gap-2 text-sm text-gray-500 hover:text-brand-red transition-colors">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
              </svg>
              {{ topic.like_count || 0 }}
            </button>
            <button class="text-sm text-gray-500 hover:text-primary-600 transition-colors">
              Prijavi
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Replies -->
    <section>
      <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Odgovori ({{ replies.length }})</h2>

      <div v-if="replies && replies.length > 0" class="space-y-3">
        <div
          v-for="reply in replies"
          :key="reply.id"
          class="card"
          :class="reply.is_answer ? 'border-2 border-brand-green' : ''"
        >
          <div class="flex items-start gap-4">
            <!-- Author -->
            <div class="text-center">
              <div class="w-12 h-12 rounded-full bg-primary-100 flex items-center justify-center text-primary-600 font-bold mb-2">
                {{ reply.profiles?.full_name?.[0] || 'U' }}
              </div>
              <p class="font-semibold text-gray-900 text-sm">{{ reply.profiles?.full_name }}</p>
              <p class="text-xs text-gray-500">{{ formatDateTime(reply.created_at) }}</p>
            </div>

            <!-- Content -->
            <div class="flex-1">
              <p class="text-gray-700 whitespace-pre-line">{{ reply.content }}</p>

              <!-- Answer badge -->
              <div v-if="reply.is_answer" class="flex items-center gap-2 mt-3 text-brand-green text-sm font-semibold">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                Najbolji odgovor
              </div>

              <!-- Actions -->
              <div class="flex items-center gap-4 mt-4 pt-3 border-t border-gray-100">
                <button class="flex items-center gap-2 text-sm text-gray-500 hover:text-brand-red transition-colors">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" />
                  </svg>
                  {{ reply.like_count || 0 }}
                </button>
                <button
                  v-if="reply.author_id === user?.id || userRole === 'admin'"
                  class="text-sm text-gray-500 hover:text-primary-600 transition-colors"
                  @click="editReply(reply)"
                >
                  Uredi
                </button>
                <button
                  v-if="userRole === 'admin'"
                  class="text-sm text-brand-green hover:text-brand-green-dark transition-colors"
                  @click="markAsAnswer(reply)"
                >
                  ✓ Označi kao najbolji
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="card text-center py-8">
        <div class="text-4xl mb-3">💭</div>
        <p class="text-gray-600 text-sm">Još nema odgovora. Budi prvi!</p>
      </div>
    </section>

    <!-- Reply Form -->
    <section class="card">
      <h3 class="font-display font-bold text-lg text-gray-900 mb-4">Tvoj odgovor</h3>
      <form @submit.prevent="submitReply">
        <textarea
          v-model="replyContent"
          class="input min-h-[120px]"
          placeholder="Podijeli svoje mišljenje ili iskustvo..."
          required
        />
        <div class="flex items-center justify-between mt-4">
          <p class="text-xs text-gray-500">
            Budi ljubazan i poštuj pravila zajednice.
          </p>
          <button type="submit" class="btn-primary" :disabled="submitting">
            {{ submitting ? 'Objavljujem...' : 'Objavi odgovor' }}
          </button>
        </div>
      </form>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })

const route = useRoute()
const supabase = useSupabase()
const { user } = useAuth()
const userRole = computed(() => user.value?.app_metadata?.role as string || '')

const topicSlug = route.params.slug as string
const replyContent = ref('')
const submitting = ref(false)

// Load topic
const { data: topic } = await useAsyncData(`forum-topic-${topicSlug}`, async () => {
  const { data } = await supabase
    .from('forum_topics')
    .select(`
      *,
      profiles(full_name, avatar_url),
      forum_categories(name, color)
    `)
    .eq('slug', topicSlug)
    .single()

  // Increment view count
  if (data) {
    await supabase
      .from('forum_topics')
      .update({ view_count: data.view_count + 1 })
      .eq('id', data.id)
  }

  return data
})

// Load replies
const { data: replies, refresh } = await useAsyncData(`forum-replies-${topicSlug}`, async () => {
  if (!topic.value) return []

  const { data } = await supabase
    .from('forum_posts')
    .select(`
      *,
      profiles(full_name)
    `)
    .eq('topic_id', topic.value.id)
    .order('created_at', { ascending: true })

  return data ?? []
})

async function submitReply() {
  if (!topic.value || !user.value) return

  submitting.value = true

  try {
    const { error } = await supabase
      .from('forum_posts')
      .insert({
        topic_id: topic.value.id,
        author_id: user.value.id,
        content: replyContent.value,
      })

    if (error) throw error

    replyContent.value = ''
    await refresh()
  } catch (err) {
    console.error('Failed to post reply:', err)
  } finally {
    submitting.value = false
  }
}

async function markAsAnswer(reply: any) {
  if (!topic.value) return

  // Unmark current answer
  await supabase
    .from('forum_posts')
    .update({ is_answer: false })
    .eq('topic_id', topic.value.id)

  // Mark new answer
  await supabase
    .from('forum_posts')
    .update({ is_answer: true })
    .eq('id', reply.id)

  await refresh()
}

function editReply(reply: any) {
  replyContent.value = reply.content
  // TODO: Implement edit functionality
}

function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', {
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit'
  })
}
</script>
