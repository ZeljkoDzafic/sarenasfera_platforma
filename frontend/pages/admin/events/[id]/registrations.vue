<template>
  <div>
    <!-- Loading State -->
    <div v-if="loading" class="space-y-4">
      <div class="h-10 bg-gray-100 rounded-xl animate-pulse" />
      <div class="card h-64 bg-gray-100 animate-pulse" />
    </div>

    <!-- Registrations View -->
    <div v-else-if="event">
      <!-- Header -->
      <div class="mb-6">
        <NuxtLink :to="`/admin/events/${event.id}`" class="text-sm text-gray-500 hover:text-gray-700 mb-2 inline-block">
          ← Nazad na događaj
        </NuxtLink>
        <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
          <div>
            <h1 class="font-display text-2xl font-bold text-gray-900">Prijave za Događaj</h1>
            <p class="text-sm text-gray-500 mt-1">{{ event.title }}</p>
            <p class="text-xs text-gray-400 mt-1">
              📅 {{ formatDate(event.starts_at) }} • 📍 {{ event.location }}
            </p>
          </div>
          <div class="flex gap-2">
            <button @click="exportCSV" class="btn-secondary text-sm">
              📥 Exportuj CSV
            </button>
            <button @click="sendReminder" class="btn-secondary text-sm">
              ✉️ Pošalji podsjetnik
            </button>
          </div>
        </div>
      </div>

      <!-- Stats Cards -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div class="card text-center">
          <div class="text-3xl font-bold text-primary-600">{{ registrations.length }}</div>
          <div class="text-xs text-gray-500 mt-1">Ukupno prijava</div>
        </div>
        <div class="card text-center">
          <div class="text-3xl font-bold text-brand-green">
            {{ registrations.filter(r => r.status === 'confirmed').length }}
          </div>
          <div class="text-xs text-gray-500 mt-1">Potvrđeno</div>
        </div>
        <div class="card text-center">
          <div class="text-3xl font-bold text-brand-amber">
            {{ registrations.filter(r => r.status === 'pending').length }}
          </div>
          <div class="text-xs text-gray-500 mt-1">Na čekanju</div>
        </div>
        <div class="card text-center">
          <div class="text-3xl font-bold text-gray-400">
            {{ event.capacity - registrations.filter(r => r.status === 'confirmed').length }}
          </div>
          <div class="text-xs text-gray-500 mt-1">Slobodno</div>
        </div>
      </div>

      <!-- Registrations Table -->
      <div class="card overflow-x-auto">
        <table v-if="registrations.length > 0" class="w-full text-sm">
          <thead>
            <tr class="border-b-2 border-gray-200">
              <th class="text-left py-3 px-4 font-bold text-gray-900">Roditelj</th>
              <th class="text-left py-3 px-4 font-bold text-gray-900">Dijete</th>
              <th class="text-left py-3 px-4 font-bold text-gray-900">Kontakt</th>
              <th class="text-left py-3 px-4 font-bold text-gray-900">Napomene</th>
              <th class="text-center py-3 px-4 font-bold text-gray-900">Status</th>
              <th class="text-center py-3 px-4 font-bold text-gray-900">Akcije</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="reg in registrations"
              :key="reg.id"
              class="border-b border-gray-100 hover:bg-gray-50"
            >
              <td class="py-3 px-4">
                <div class="font-semibold text-gray-900">{{ reg.parent_name }}</div>
                <div v-if="reg.parent_email" class="text-xs text-gray-500">{{ reg.parent_email }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-gray-900">{{ reg.child_name }}</div>
                <div v-if="reg.child_dob" class="text-xs text-gray-500">
                  {{ calculateAge(reg.child_dob) }} god
                </div>
              </td>
              <td class="py-3 px-4">
                <div v-if="reg.parent_phone" class="text-sm text-gray-700">📞 {{ reg.parent_phone }}</div>
                <div v-if="reg.parent_email" class="text-xs text-gray-500">✉️ {{ reg.parent_email }}</div>
              </td>
              <td class="py-3 px-4">
                <div v-if="reg.notes" class="text-xs text-gray-600 max-w-xs truncate" :title="reg.notes">
                  {{ reg.notes }}
                </div>
                <span v-else class="text-xs text-gray-400">-</span>
              </td>
              <td class="text-center py-3 px-4">
                <span
                  :class="[
                    'badge text-xs px-2 py-1 rounded-full font-semibold',
                    reg.status === 'confirmed' ? 'badge-paid' :
                    reg.status === 'attended' ? 'badge-premium' :
                    reg.status === 'cancelled' ? 'badge-free' :
                    'bg-gray-100 text-gray-600'
                  ]"
                >
                  {{ statusLabel(reg.status) }}
                </span>
              </td>
              <td class="text-center py-3 px-4">
                <select
                  :value="reg.status"
                  @change="updateStatus(reg.id, ($event.target as HTMLSelectElement).value)"
                  class="text-xs border border-gray-300 rounded px-2 py-1"
                >
                  <option value="pending">Na čekanju</option>
                  <option value="confirmed">Potvrđeno</option>
                  <option value="cancelled">Otkazano</option>
                  <option value="attended">Prisustvovao</option>
                </select>
              </td>
            </tr>
          </tbody>
        </table>

        <!-- Empty State -->
        <div v-else class="text-center py-12">
          <div class="text-5xl mb-4">📋</div>
          <p class="text-gray-500">Nema prijava za ovaj događaj.</p>
        </div>
      </div>
    </div>

    <!-- Not Found -->
    <div v-else class="card text-center py-12">
      <p class="text-gray-500">Događaj nije pronađen.</p>
      <NuxtLink to="/admin/events" class="btn-primary mt-4 inline-block">
        Nazad na događaje
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
// T-832: Admin Events Management — Registrations Page
// View and manage event registrations

definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Prijave za Događaj — Admin — Šarena Sfera' })

const supabase = useSupabase()
const route = useRoute()

const eventId = route.params.id as string

const loading = ref(true)
const event = ref<any>(null)
const registrations = ref<any[]>([])

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function calculateAge(dob: string): number {
  const birthDate = new Date(dob)
  const today = new Date()
  let age = today.getFullYear() - birthDate.getFullYear()
  const monthDiff = today.getMonth() - birthDate.getMonth()
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
    age--
  }
  return age
}

function statusLabel(status: string): string {
  const labels: Record<string, string> = {
    pending: 'Na čekanju',
    confirmed: 'Potvrđeno',
    cancelled: 'Otkazano',
    attended: 'Prisustvovao',
  }
  return labels[status] || status
}

async function loadData() {
  loading.value = true
  try {
    // Load event
    const { data: eventData, error: eventError } = await supabase
      .from('events')
      .select('*')
      .eq('id', eventId)
      .single()

    if (eventError) throw eventError
    event.value = eventData

    // Load registrations
    const { data: regsData, error: regsError } = await supabase
      .from('event_registrations')
      .select('*')
      .eq('event_id', eventId)
      .order('created_at', { ascending: false })

    if (regsError) throw regsError
    registrations.value = regsData || []
  } catch (err) {
    console.error('Failed to load data:', err)
  } finally {
    loading.value = false
  }
}

async function updateStatus(registrationId: string, newStatus: string) {
  try {
    const { error } = await supabase
      .from('event_registrations')
      .update({ status: newStatus, updated_at: new Date().toISOString() })
      .eq('id', registrationId)

    if (error) throw error

    // Update local state
    const reg = registrations.value.find(r => r.id === registrationId)
    if (reg) reg.status = newStatus
  } catch (err) {
    console.error('Failed to update status:', err)
    alert('Greška pri ažuriranju statusa')
  }
}

function exportCSV() {
  if (registrations.value.length === 0) {
    alert('Nema prijava za export.')
    return
  }

  // Create CSV content
  const headers = ['Roditelj', 'Email', 'Telefon', 'Dijete', 'Datum rođenja', 'Uzrast', 'Napomene', 'Status', 'Datum prijave']
  const rows = registrations.value.map(reg => [
    reg.parent_name,
    reg.parent_email || '',
    reg.parent_phone || '',
    reg.child_name,
    reg.child_dob || '',
    reg.child_dob ? calculateAge(reg.child_dob).toString() : '',
    reg.notes || '',
    statusLabel(reg.status),
    new Date(reg.created_at).toLocaleDateString('bs-BA'),
  ])

  const csv = [
    headers.join(','),
    ...rows.map(row => row.map(cell => `"${cell}"`).join(',')),
  ].join('\n')

  // Download
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = `prijave-${event.value.slug}-${Date.now()}.csv`
  link.click()
}

function sendReminder() {
  // TODO: Implement email reminder functionality
  alert('Email podsjetnik funkcionalnost će biti implementirana uskoro.')
}

onMounted(() => {
  loadData()
})
</script>
