<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Sertifikati i Postignuća</h1>
      <p class="text-sm text-gray-500 mt-1">Pregled svih sertifikata i osvojenih badgeva</p>
    </div>

    <!-- Feature Gate -->
    <FeatureGate required-tier="premium">
      <template #locked>
        <div class="text-center py-12">
          <div class="text-5xl mb-4">🔒</div>
          <h3 class="font-display font-bold text-xl text-gray-900 mb-2">
            Sertifikati su Premium funkcija
          </h3>
          <p class="text-gray-600 mb-6">
            Nadogradite na Premium tier za pristup sertifikatima i postignućima.
          </p>
          <NuxtLink to="/pricing" class="btn-primary">Pregledajte Planove</NuxtLink>
        </div>
      </template>

      <!-- Content -->
      <div class="space-y-6">
        <!-- Badges Section -->
        <section>
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Vaša Postignuća</h2>

          <div v-if="userBadges && userBadges.length > 0" class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div
              v-for="badge in userBadges"
              :key="badge.id"
              class="card text-center p-4 hover:shadow-lg transition-shadow"
            >
              <div class="text-4xl mb-2">{{ badge.badges?.icon_url || '🏆' }}</div>
              <h3 class="font-bold text-gray-900 text-sm">{{ badge.badges?.name }}</h3>
              <p class="text-xs text-gray-500 mt-1">{{ badge.badges?.description }}</p>
              <p class="text-xs text-primary-600 font-semibold mt-2">
                Osvojeno: {{ formatDate(badge.earned_at) }}
              </p>
            </div>
          </div>
          <div v-else class="card text-center py-8">
            <div class="text-4xl mb-3">🎯</div>
            <p class="text-gray-600 text-sm">Još nemate osvojenih badgeva.</p>
            <p class="text-xs text-gray-500 mt-2">Budite aktivni i osvojite prve badgeve!</p>
          </div>
        </section>

        <!-- Certificates Section -->
        <section>
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Sertifikati Djece</h2>

          <div v-if="certificates && certificates.length > 0" class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div
              v-for="cert in certificates"
              :key="cert.id"
              class="card border-2 border-primary-200 hover:border-primary-400 transition-colors"
            >
              <div class="flex items-start gap-4">
                <!-- Certificate Icon -->
                <div class="w-16 h-16 rounded-xl bg-gradient-to-br from-primary-500 to-brand-pink flex items-center justify-center flex-shrink-0">
                  <span class="text-2xl">📜</span>
                </div>

                <div class="flex-1 min-w-0">
                  <h3 class="font-bold text-gray-900">{{ cert.title }}</h3>
                  <p class="text-sm text-gray-600 mt-1">{{ cert.children?.full_name }}</p>
                  <p class="text-xs text-gray-500 mt-1">{{ cert.description }}</p>

                  <div class="flex items-center gap-3 mt-3">
                    <span
                      class="text-xs font-semibold px-2 py-0.5 rounded-full"
                      :class="getTypeClass(cert.certificate_type)"
                    >
                      {{ getTypeLabel(cert.certificate_type) }}
                    </span>
                    <span class="text-xs text-gray-400">{{ formatDate(cert.issued_date) }}</span>
                  </div>
                </div>

                <a
                  v-if="cert.pdf_url"
                  :href="cert.pdf_url"
                  target="_blank"
                  class="btn-secondary text-sm"
                >
                  Preuzmi PDF
                </a>
              </div>
            </div>
          </div>
          <div v-else class="card text-center py-8">
            <div class="text-4xl mb-3">📋</div>
            <p class="text-gray-600 text-sm">Vaša djeca još nemaju sertifikata.</p>
            <p class="text-xs text-gray-500 mt-2">Sertifikati se dodjeljuju za završene programe i postignuća.</p>
          </div>
        </section>

        <!-- Available Badges -->
        <section>
          <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Dostupni Badgevi</h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div
              v-for="badge in availableBadges"
              :key="badge.id"
              class="card p-4"
              :class="userBadges?.some(b => b.badge_id === badge.id) ? 'border-2 border-brand-green' : ''"
            >
              <div class="flex items-start gap-3">
                <div class="text-3xl">{{ badge.icon_url || '🏆' }}</div>
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <h3 class="font-bold text-gray-900">{{ badge.name }}</h3>
                    <span v-if="userBadges?.some(b => b.badge_id === badge.id)" class="text-brand-green text-xs font-bold">
                      ✓ OSVOJENO
                    </span>
                  </div>
                  <p class="text-sm text-gray-600 mt-1">{{ badge.description }}</p>
                  <p v-if="badge.requirement_count" class="text-xs text-gray-500 mt-2">
                    Zahtjev: {{ badge.requirement_type }} {{ badge.requirement_count }}x
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </FeatureGate>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })
useSeoMeta({ title: 'Sertifikati — Šarena Sfera' })

const supabase = useSupabase()
const { user } = useAuth()
const { tierName } = useTier()

const { data: userBadges } = await useAsyncData('user-badges', async () => {
  if (!user.value) return []

  const { data } = await supabase
    .from('user_badges')
    .select(`
      *,
      badges(name, description, icon_url, badge_type)
    `)
    .eq('user_id', user.value.id)
    .order('earned_at', { ascending: false })

  return data ?? []
})

const { data: certificates } = await useAsyncData('user-certificates', async () => {
  if (!user.value) return []

  // Get user's children IDs
  const { data: parentChildren } = await supabase
    .from('parent_children')
    .select('child_id')
    .eq('parent_id', user.value.id)

  if (!parentChildren?.length) return []

  const childIds = parentChildren.map(pc => pc.child_id)

  const { data } = await supabase
    .from('certificates')
    .select(`
      *,
      children(full_name)
    `)
    .in('child_id', childIds)
    .order('issued_date', { ascending: false })

  return data ?? []
})

const { data: availableBadges } = await useAsyncData('all-badges', async () => {
  const { data } = await supabase
    .from('badges')
    .select('*')
    .eq('is_active', true)
    .order('badge_type')

  return data ?? []
})

function getTypeClass(type: string): string {
  const map: Record<string, string> = {
    program_completion: 'bg-brand-green/10 text-brand-green',
    domain_mastery: 'bg-primary-100 text-primary-700',
    attendance_milestone: 'bg-brand-amber/10 text-brand-amber',
  }
  return map[type] || 'bg-gray-100 text-gray-500'
}

function getTypeLabel(type: string): string {
  const map: Record<string, string> = {
    program_completion: 'Završen Program',
    domain_mastery: 'Mastery Domene',
    attendance_milestone: 'Prisustvo',
  }
  return map[type] || type
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short', year: 'numeric' })
}
</script>
