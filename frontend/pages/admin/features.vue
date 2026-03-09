<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Feature Flags</h1>
      <p class="text-sm text-gray-500 mt-1">Upravljajte dostupnošću funkcija po sekcijama i tier-ovima</p>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-brand-green mb-1">{{ activeCount }}</div>
        <div class="text-xs text-gray-600">Aktivne</div>
      </div>
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-brand-amber mb-1">{{ comingSoonCount }}</div>
        <div class="text-xs text-gray-600">Uskoro</div>
      </div>
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-gray-400 mb-1">{{ hiddenCount }}</div>
        <div class="text-xs text-gray-600">Skrivene</div>
      </div>
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-primary-600 mb-1">{{ betaCount }}</div>
        <div class="text-xs text-gray-600">Beta</div>
      </div>
    </div>

    <!-- Filters -->
    <div class="card">
      <div class="flex flex-wrap gap-2">
        <button
          v-for="filter in filters"
          :key="filter.key"
          class="px-4 py-2 rounded-xl text-sm font-semibold transition-all border-2"
          :class="activeFilter === filter.key
            ? 'border-primary-500 bg-primary-50 text-primary-700'
            : 'border-gray-200 text-gray-600 hover:border-gray-300'"
          @click="activeFilter = filter.key"
        >
          {{ filter.label }}
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="pending" class="space-y-3">
      <div v-for="i in 10" :key="i" class="card h-20 animate-pulse" />
    </div>

    <!-- Features by section -->
    <div v-else class="space-y-6">
      <div v-for="(section, sectionKey) in groupedFeatures" :key="sectionKey" class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4 flex items-center gap-2">
          <span class="text-xl">{{ sectionIcons[sectionKey] }}</span>
          {{ sectionNames[sectionKey] }}
        </h2>

        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead class="bg-gray-50 border-b border-gray-100">
              <tr>
                <th class="text-left px-4 py-3 font-semibold text-gray-600">Funkcija</th>
                <th class="text-left px-4 py-3 font-semibold text-gray-600">Status</th>
                <th class="text-left px-4 py-3 font-semibold text-gray-600">Tier</th>
                <th class="text-left px-4 py-3 font-semibold text-gray-600">Interesi</th>
                <th class="text-right px-4 py-3 font-semibold text-gray-600">Akcije</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
              <tr
                v-for="feature in section"
                :key="feature.id"
                class="hover:bg-gray-50 transition-colors"
              >
                <td class="px-4 py-3">
                  <div>
                    <p class="font-semibold text-gray-900">{{ feature.name }}</p>
                    <p class="text-xs text-gray-500">{{ feature.key }}</p>
                  </div>
                </td>
                <td class="px-4 py-3">
                  <select
                    v-model="feature.status"
                    class="input text-xs py-1"
                    @change="updateFeature(feature)"
                  >
                    <option value="active">Aktivno</option>
                    <option value="coming_soon">Uskoro</option>
                    <option value="hidden">Skriveno</option>
                    <option value="beta">Beta</option>
                  </select>
                </td>
                <td class="px-4 py-3">
                  <select
                    v-model="feature.min_tier"
                    class="input text-xs py-1"
                    @change="updateFeature(feature)"
                  >
                    <option value="free">Free</option>
                    <option value="paid">Paid</option>
                    <option value="premium">Premium</option>
                  </select>
                </td>
                <td class="px-4 py-3">
                  <span v-if="feature.interest_count" class="text-xs font-semibold text-primary-600">
                    {{ feature.interest_count }} zainteresovanih
                  </span>
                  <span v-else class="text-xs text-gray-400">—</span>
                </td>
                <td class="px-4 py-3 text-right">
                  <button
                    class="text-xs text-primary-600 hover:text-primary-700 font-semibold"
                    @click="showInterestList(feature)"
                  >
                    Pogledaj listu
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Interest List Modal -->
    <Teleport to="body">
      <div v-if="showingInterestFor" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
        <div class="bg-white rounded-2xl w-full max-w-lg shadow-xl max-h-[80vh] overflow-y-auto">
          <div class="p-6 border-b border-gray-100">
            <h2 class="font-display font-bold text-lg text-gray-900">
              Zainteresovani za: {{ showingInterestFor.name }}
            </h2>
          </div>
          <div class="p-6">
            <div v-if="interestList.length > 0" class="space-y-2">
              <div
                v-for="interest in interestList"
                :key="interest.id"
                class="flex items-center justify-between p-3 bg-gray-50 rounded-xl"
              >
                <div>
                  <p class="font-semibold text-gray-900 text-sm">{{ interest.profiles?.full_name || 'Anoniman' }}</p>
                  <p class="text-xs text-gray-500">{{ interest.profiles?.email || '—' }}</p>
                </div>
                <span class="text-xs text-gray-400">{{ formatDate(interest.created_at) }}</span>
              </div>
            </div>
            <div v-else class="text-center py-8 text-gray-400">
              <p>Nema zainteresovanih korisnika.</p>
            </div>
            <button class="btn-ghost w-full mt-4" @click="showingInterestFor = null">
              Zatvori
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'] })
useSeoMeta({ title: 'Feature Flags — Admin' })

const supabase = useSupabase()
const { role } = useAuth()

// Verify admin role
if (role.value !== 'admin') {
  throw createError({ statusCode: 403, message: 'Samo admini mogu upravljati feature flagsovima' })
}

const activeFilter = ref('all')
const filters = [
  { key: 'all', label: 'Sve' },
  { key: 'active', label: 'Aktivne' },
  { key: 'coming_soon', label: 'Uskoro' },
  { key: 'hidden', label: 'Skrivene' },
  { key: 'beta', label: 'Beta' },
]

const sectionNames: Record<string, string> = {
  public: 'Javne stranice',
  auth: 'Autentifikacija',
  portal: 'Parent Portal',
  admin: 'Admin Panel',
}

const sectionIcons: Record<string, string> = {
  public: '🌐',
  auth: '🔐',
  portal: '👨‍👩‍👧‍👦',
  admin: '⚙️',
}

const { data: features, pending, refresh } = await useAsyncData('admin-features', async () => {
  const { data } = await supabase
    .from('feature_flags')
    .select(`
      *,
      feature_interests(feature_key)
    `)
    .order('key')

  // Add interest count
  return (data ?? []).map(f => ({
    ...f,
    interest_count: f.feature_interests?.length ?? 0,
  }))
})

// Group features by section
const groupedFeatures = computed(() => {
  const groups: Record<string, typeof features.value> = {
    public: [],
    auth: [],
    portal: [],
    admin: [],
  }

  features.value?.forEach(f => {
    const prefix = f.key.split('.')[0]
    if (groups[prefix]) {
      groups[prefix].push(f)
    }
  })

  // Filter by active filter
  if (activeFilter.value !== 'all') {
    Object.keys(groups).forEach(key => {
      groups[key] = groups[key].filter(f => f.status === activeFilter.value)
    })
  }

  return groups
})

const activeCount = computed(() => features.value?.filter(f => f.status === 'active').length ?? 0)
const comingSoonCount = computed(() => features.value?.filter(f => f.status === 'coming_soon').length ?? 0)
const hiddenCount = computed(() => features.value?.filter(f => f.status === 'hidden').length ?? 0)
const betaCount = computed(() => features.value?.filter(f => f.status === 'beta').length ?? 0)

const showingInterestFor = ref<typeof features.value[number] | null>(null)
const interestList = ref<any[]>([])

async function updateFeature(feature: any) {
  const { error } = await supabase
    .from('feature_flags')
    .update({
      status: feature.status,
      min_tier: feature.min_tier,
      updated_at: new Date().toISOString(),
    })
    .eq('id', feature.id)

  if (error) {
    console.error('Failed to update feature:', error)
    await refresh()
  }
}

async function showInterestList(feature: any) {
  showingInterestFor.value = feature

  const { data } = await supabase
    .from('feature_interests')
    .select(`
      id, created_at,
      profiles(full_name, email)
    `)
    .eq('feature_key', feature.key)
    .order('created_at', { ascending: false })

  interestList.value = data ?? []
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short' })
}
</script>
