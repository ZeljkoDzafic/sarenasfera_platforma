<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Poruke</h1>
        <p class="text-sm text-gray-500 mt-1">Komunikacija s roditeljima</p>
      </div>
      <button class="btn-primary text-sm" @click="showCompose = true">+ Nova poruka</button>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Inbox list -->
      <div class="lg:col-span-1 space-y-2">
        <div class="flex gap-1 border-b border-gray-100 mb-3">
          <button
            v-for="tab in ['inbox', 'sent']"
            :key="tab"
            class="px-3 py-2 text-sm font-semibold border-b-2 -mb-px transition-colors capitalize"
            :class="activeTab === tab ? 'border-primary-500 text-primary-700' : 'border-transparent text-gray-500'"
            @click="activeTab = tab"
          >
            {{ tab === 'inbox' ? 'Primljeno' : 'Poslano' }}
            <span v-if="tab === 'inbox' && unreadCount > 0" class="ml-1 bg-primary-500 text-white text-xs font-bold rounded-full px-1.5 py-0.5">{{ unreadCount }}</span>
          </button>
        </div>

        <div v-if="pending" class="space-y-2">
          <div v-for="i in 5" :key="i" class="h-16 bg-gray-100 rounded-xl animate-pulse" />
        </div>

        <div v-else-if="currentMessages.length > 0" class="space-y-1">
          <button
            v-for="msg in currentMessages"
            :key="msg.id"
            class="w-full text-left p-3 rounded-xl hover:bg-gray-50 transition-colors border-2"
            :class="selectedMsg?.id === msg.id ? 'border-primary-200 bg-primary-50' : 'border-transparent'"
            @click="selectMessage(msg)"
          >
            <div class="flex items-start gap-2">
              <div class="w-7 h-7 rounded-lg bg-primary-100 flex items-center justify-center font-bold text-primary-600 text-xs flex-shrink-0 mt-0.5">
                {{ getSenderName(msg)[0] }}
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center justify-between">
                  <p class="text-xs font-bold text-gray-900 truncate">{{ getSenderName(msg) }}</p>
                  <span class="text-xs text-gray-400 ml-2 whitespace-nowrap">{{ timeAgo(msg.created_at) }}</span>
                </div>
                <p class="text-xs font-semibold text-gray-700 truncate">{{ msg.subject }}</p>
                <p class="text-xs text-gray-400 truncate">{{ msg.body?.slice(0, 50) }}</p>
              </div>
              <div v-if="!msg.is_read && activeTab === 'inbox'" class="w-2 h-2 rounded-full bg-primary-500 flex-shrink-0 mt-2" />
            </div>
          </button>
        </div>

        <div v-else class="text-center py-8 text-gray-400 text-sm">
          {{ activeTab === 'inbox' ? 'Nema primljenih poruka.' : 'Nema poslanih poruka.' }}
        </div>
      </div>

      <!-- Message detail -->
      <div class="lg:col-span-2">
        <div v-if="selectedMsg" class="card space-y-4">
          <div class="border-b border-gray-100 pb-4">
            <h2 class="font-display font-bold text-xl text-gray-900">{{ selectedMsg.subject }}</h2>
            <p class="text-sm text-gray-500 mt-1">
              Od: {{ getSenderName(selectedMsg) }} •
              {{ formatDateTime(selectedMsg.created_at) }}
            </p>
          </div>
          <div class="prose prose-sm max-w-none text-gray-700 whitespace-pre-wrap">{{ selectedMsg.body }}</div>
          <div class="border-t border-gray-100 pt-4">
            <label class="label">Odgovori</label>
            <textarea v-model="replyBody" class="input" rows="4" placeholder="Napišite odgovor..." />
            <button class="btn-primary text-sm mt-3" :disabled="!replyBody.trim() || sending" @click="sendReply">
              {{ sending ? 'Šalje...' : 'Pošalji odgovor' }}
            </button>
          </div>
        </div>

        <div v-else class="card text-center py-20">
          <div class="text-4xl mb-3">💬</div>
          <p class="text-gray-400 text-sm">Odaberite poruku za prikaz.</p>
        </div>
      </div>
    </div>

    <!-- Compose modal -->
    <Teleport to="body">
      <div v-if="showCompose" class="fixed inset-0 bg-black/50 flex items-end md:items-center justify-center z-50 p-4">
        <div class="bg-white rounded-2xl w-full max-w-lg shadow-xl">
          <div class="p-6 border-b border-gray-100">
            <h2 class="font-display font-bold text-xl text-gray-900">Nova poruka</h2>
          </div>
          <form class="p-6 space-y-4" @submit.prevent="sendMessage">
            <div>
              <label class="label">Primatelj *</label>
              <select v-model="composeForm.recipient_id" class="input" required>
                <option value="">— odaberite korisnika —</option>
                <option v-for="u in users" :key="u.id" :value="u.id">
                  {{ u.full_name ?? u.email }} ({{ u.role }})
                </option>
              </select>
            </div>
            <div>
              <label class="label">Naslov *</label>
              <input v-model="composeForm.subject" type="text" class="input" required placeholder="Naslov poruke..." />
            </div>
            <div>
              <label class="label">Poruka *</label>
              <textarea v-model="composeForm.body" class="input" rows="6" required placeholder="Tekst poruke..." />
            </div>
            <div class="flex gap-3">
              <button type="button" class="btn-secondary flex-1" @click="showCompose = false">Otkaži</button>
              <button type="submit" class="btn-primary flex-1" :disabled="sending">
                {{ sending ? 'Šalje...' : 'Pošalji' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Poruke — Admin' })

const supabase = useSupabase()
const { user } = useAuth()

const activeTab = ref('inbox')
const showCompose = ref(false)
const selectedMsg = ref<Record<string, unknown> | null>(null)
const replyBody = ref('')
const sending = ref(false)

const composeForm = reactive({ recipient_id: '', subject: '', body: '' })

const { data: inbox, pending, refresh } = await useAsyncData('admin-messages', async () => {
  const { data } = await supabase
    .from('messages')
    .select('id, subject, body, is_read, created_at, sender_id, recipient_id, sender:profiles!messages_sender_id_fkey(full_name, email), recipient:profiles!messages_recipient_id_fkey(full_name, email)')
    .or(`recipient_id.eq.${user.value?.id},sender_id.eq.${user.value?.id}`)
    .order('created_at', { ascending: false })
  return data ?? []
})

const { data: users } = await useAsyncData('admin-msg-users', async () => {
  const { data } = await supabase.from('profiles').select('id, full_name, email, role').order('full_name')
  return data ?? []
})

const currentMessages = computed(() => {
  const msgs = inbox.value ?? []
  if (activeTab.value === 'inbox') return msgs.filter((m: Record<string, unknown>) => m.recipient_id === user.value?.id)
  return msgs.filter((m: Record<string, unknown>) => m.sender_id === user.value?.id)
})

const unreadCount = computed(() =>
  (inbox.value ?? []).filter((m: Record<string, unknown>) => m.recipient_id === user.value?.id && !m.is_read).length
)

function getSenderName(msg: Record<string, unknown>): string {
  if (msg.sender_id === user.value?.id) return 'Vi'
  const sender = msg.sender as { full_name?: string; email?: string } | null
  return sender?.full_name ?? sender?.email ?? 'Nepoznat'
}

async function selectMessage(msg: Record<string, unknown>) {
  selectedMsg.value = msg
  replyBody.value = ''
  if (!msg.is_read && msg.recipient_id === user.value?.id) {
    await supabase.from('messages').update({ is_read: true }).eq('id', msg.id)
    await refresh()
  }
}

async function sendReply() {
  if (!selectedMsg.value || !replyBody.value.trim()) return
  sending.value = true
  await supabase.from('messages').insert({
    sender_id: user.value?.id,
    recipient_id: selectedMsg.value.sender_id === user.value?.id ? selectedMsg.value.recipient_id : selectedMsg.value.sender_id,
    subject: `Re: ${selectedMsg.value.subject}`,
    body: replyBody.value,
  })
  replyBody.value = ''
  sending.value = false
  await refresh()
}

async function sendMessage() {
  if (!composeForm.recipient_id || !composeForm.subject || !composeForm.body) return
  sending.value = true
  await supabase.from('messages').insert({
    sender_id: user.value?.id,
    recipient_id: composeForm.recipient_id,
    subject: composeForm.subject,
    body: composeForm.body,
  })
  showCompose.value = false
  sending.value = false
  Object.assign(composeForm, { recipient_id: '', subject: '', body: '' })
  await refresh()
}

function timeAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 60) return `${mins}m`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h`
  return `${Math.floor(hrs / 24)}d`
}

function formatDateTime(value: unknown): string {
  if (typeof value !== 'string') return '—'
  return new Date(value).toLocaleString('bs-BA')
}
</script>
