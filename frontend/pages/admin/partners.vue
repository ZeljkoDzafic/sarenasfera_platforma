<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Partner Program</h1>
      <p class="text-sm text-gray-500 mt-1">Upravljajte partnerima i affiliate programom</p>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-primary-600 mb-1">{{ stats.partners }}</div>
        <div class="text-xs text-gray-600">Partnera</div>
      </div>
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-brand-green mb-1">{{ stats.referrals }}</div>
        <div class="text-xs text-gray-600">Preporuka</div>
      </div>
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-brand-amber mb-1">{{ stats.conversions }}</div>
        <div class="text-xs text-gray-600">Konverzija</div>
      </div>
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-brand-pink mb-1">{{ stats.totalCommission }} KM</div>
        <div class="text-xs text-gray-600">Ukupna provizija</div>
      </div>
    </div>

    <!-- Tabs -->
    <div class="flex gap-1 bg-gray-100 rounded-xl p-1">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        class="flex-1 py-2 px-3 rounded-lg text-sm font-semibold transition-all"
        :class="activeTab === tab.key ? 'bg-white shadow-sm text-gray-900' : 'text-gray-500 hover:text-gray-700'"
        @click="activeTab = tab.key"
      >
        {{ tab.label }}
      </button>
    </div>

    <!-- Partners List -->
    <div v-if="activeTab === 'partners'" class="space-y-4">
      <div class="flex items-center justify-between">
        <div class="flex gap-2">
          <select v-model="filterType" class="input w-auto text-sm">
            <option value="">Svi tipovi</option>
            <option value="kindergarten">Vrtić</option>
            <option value="school">Škola</option>
            <option value="pediatrician">Pedijatar</option>
            <option value="organization">Organizacija</option>
            <option value="influencer">Influencer</option>
          </select>
        </div>
        <button class="btn-primary text-sm" @click="showAddPartner = true">
          + Dodaj partnera
        </button>
      </div>

      <div v-if="partners && partners.length > 0" class="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div
          v-for="partner in filteredPartners"
          :key="partner.id"
          class="card hover:shadow-md transition-shadow cursor-pointer"
          @click="openPartnerDetail(partner)"
        >
          <div class="flex items-start gap-4">
            <!-- Logo -->
            <div v-if="partner.logo_url" class="w-16 h-16 rounded-xl bg-cover bg-center" :style="{ backgroundImage: `url(${partner.logo_url})` }" />
            <div v-else class="w-16 h-16 rounded-xl bg-primary-100 flex items-center justify-center text-primary-600 font-bold text-xl">
              {{ partner.name[0] }}
            </div>

            <!-- Info -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-1">
                <h3 class="font-bold text-gray-900 truncate">{{ partner.name }}</h3>
                <span v-if="partner.is_verified" class="text-brand-green text-xs">✓ Verifikovan</span>
              </div>
              <p class="text-xs text-gray-500 mb-2 capitalize">{{ partner.partner_type }}</p>
              <div class="flex items-center gap-3 text-xs text-gray-500">
                <span>{{ partner.referral_count }} preporuka</span>
                <span>{{ partner.conversion_count }} konverzija</span>
                <span class="font-semibold text-brand-green">{{ partner.total_commission }} KM</span>
              </div>
            </div>

            <!-- Commission rate -->
            <div class="text-right">
              <p class="text-sm font-bold text-primary-600">{{ partner.commission_rate }}%</p>
              <p class="text-xs text-gray-500">provizija</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Referrals List -->
    <div v-if="activeTab === 'referrals'" class="card overflow-hidden p-0">
      <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-100">
          <tr>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Partner</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Korisnik</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Status</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Provizija</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Datum</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr
            v-for="referral in referrals"
            :key="referral.id"
            class="hover:bg-gray-50 transition-colors"
          >
            <td class="px-4 py-3">
              <p class="font-semibold text-gray-900">{{ referral.partners?.name }}</p>
            </td>
            <td class="px-4 py-3">
              <p class="text-gray-900">{{ referral.user_email || '—' }}</p>
            </td>
            <td class="px-4 py-3">
              <span
                class="text-xs font-semibold px-2 py-0.5 rounded-full"
                :class="getStatusClass(referral.status)"
              >
                {{ getStatusLabel(referral.status) }}
              </span>
            </td>
            <td class="px-4 py-3">
              <p class="font-semibold text-gray-900">{{ referral.commission_earned }} KM</p>
            </td>
            <td class="px-4 py-3 text-gray-500">
              {{ formatDate(referral.created_at) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Payouts List -->
    <div v-if="activeTab === 'payouts'" class="card overflow-hidden p-0">
      <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-100">
          <tr>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Partner</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Iznos</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Period</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Status</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Akcije</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr
            v-for="payout in payouts"
            :key="payout.id"
            class="hover:bg-gray-50 transition-colors"
          >
            <td class="px-4 py-3">
              <p class="font-semibold text-gray-900">{{ payout.partners?.name }}</p>
            </td>
            <td class="px-4 py-3">
              <p class="font-bold text-gray-900">{{ payout.amount }} KM</p>
            </td>
            <td class="px-4 py-3 text-gray-500">
              {{ formatDate(payout.period_start) }} - {{ formatDate(payout.period_end) }}
            </td>
            <td class="px-4 py-3">
              <span
                class="text-xs font-semibold px-2 py-0.5 rounded-full"
                :class="getPayoutStatusClass(payout.status)"
              >
                {{ getPayoutStatusLabel(payout.status) }}
              </span>
            </td>
            <td class="px-4 py-3">
              <button
                v-if="payout.status === 'pending'"
                class="text-xs font-semibold text-brand-green hover:text-brand-green-dark"
                @click="markAsPaid(payout)"
              >
                ✓ Označi plaćenim
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Add Partner Modal -->
    <Teleport to="body">
      <div v-if="showAddPartner" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
        <div class="bg-white rounded-2xl w-full max-w-lg shadow-xl">
          <div class="p-6 border-b border-gray-100">
            <h2 class="font-display font-bold text-xl text-gray-900">Dodaj Partnera</h2>
          </div>
          <form class="p-6 space-y-4" @submit.prevent="addPartner">
            <div>
              <label class="label">Naziv *</label>
              <input v-model="newPartner.name" type="text" class="input" required />
            </div>
            <div>
              <label class="label">Tip *</label>
              <select v-model="newPartner.type" class="input" required>
                <option value="">Odaberite...</option>
                <option value="kindergarten">Vrtić</option>
                <option value="school">Škola</option>
                <option value="pediatrician">Pedijatar</option>
                <option value="organization">Organizacija</option>
                <option value="influencer">Influencer</option>
                <option value="other">Ostalo</option>
              </select>
            </div>
            <div>
              <label class="label">Email</label>
              <input v-model="newPartner.email" type="email" class="input" />
            </div>
            <div>
              <label class="label">Stopa provizije (%)</label>
              <input v-model="newPartner.commission" type="number" class="input" />
            </div>
            <div class="flex gap-3">
              <button type="button" class="btn-secondary flex-1" @click="showAddPartner = false">Otkaži</button>
              <button type="submit" class="btn-primary flex-1" :disabled="adding">
                {{ adding ? 'Dodaje...' : 'Dodaj' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'] })
useSeoMeta({ title: 'Partner Program — Admin' })

const supabase = useSupabase()
const { role } = useAuth()

if (role.value !== 'admin') {
  throw createError({ statusCode: 403, message: 'Samo admini mogu upravljati partnerima' })
}

const activeTab = ref('partners')
const tabs = [
  { key: 'partners', label: 'Partneri' },
  { key: 'referrals', label: 'Preporuke' },
  { key: 'payouts', label: 'Isplate' },
]

const filterType = ref('')
const showAddPartner = ref(false)
const adding = ref(false)

const newPartner = reactive({
  name: '',
  type: '',
  email: '',
  commission: 20,
})

// Load partners
const { data: partners, refresh: refreshPartners } = await useAsyncData('admin-partners', async () => {
  const { data } = await supabase
    .from('partners')
    .select('*')
    .order('created_at', { ascending: false })

  return data ?? []
})

// Load referrals
const { data: referrals } = await useAsyncData('admin-partner-referrals', async () => {
  const { data } = await supabase
    .from('partner_referrals')
    .select(`
      *,
      partners(name)
    `)
    .order('created_at', { ascending: false })
    .limit(50)

  return data ?? []
})

// Load payouts
const { data: payouts, refresh: refreshPayouts } = await useAsyncData('admin-partner-payouts', async () => {
  const { data } = await supabase
    .from('partner_payouts')
    .select(`
      *,
      partners(name)
    `)
    .order('created_at', { ascending: false })
    .limit(50)

  return data ?? []
})

const filteredPartners = computed(() => {
  if (!filterType.value) return partners.value
  return partners.value?.filter(p => p.partner_type === filterType.value)
})

const stats = computed(() => ({
  partners: partners.value?.length ?? 0,
  referrals: referrals.value?.length ?? 0,
  conversions: referrals.value?.filter(r => r.status === 'paid').length ?? 0,
  totalCommission: partners.value?.reduce((sum, p) => sum + (p.total_commission || 0), 0) ?? 0,
}))

async function addPartner() {
  adding.value = true

  try {
    const affiliateCode = 'PARTNER-' + Math.random().toString(36).substring(2, 8).toUpperCase()

    const { error } = await supabase
      .from('partners')
      .insert({
        name: newPartner.name,
        partner_type: newPartner.type,
        contact_email: newPartner.email,
        commission_rate: newPartner.commission,
        affiliate_code: affiliateCode,
        is_verified: false,
      })

    if (error) throw error

    showAddPartner.value = false
    Object.assign(newPartner, { name: '', type: '', email: '', commission: 20 })
    await refreshPartners()
  } catch (err) {
    console.error('Failed to add partner:', err)
  } finally {
    adding.value = false
  }
}

function openPartnerDetail(partner: any) {
  navigateTo(`/admin/partners/${partner.id}`)
}

function getStatusClass(status: string): string {
  const map: Record<string, string> = {
    registered: 'bg-gray-100 text-gray-600',
    trial: 'bg-primary-100 text-primary-700',
    paid: 'bg-brand-green/10 text-brand-green',
    expired: 'bg-brand-red/10 text-brand-red',
  }
  return map[status] || 'bg-gray-100 text-gray-600'
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = {
    registered: 'Registrovan',
    trial: 'Trial',
    paid: 'Plaćen',
    expired: 'Istekao',
  }
  return map[status] || status
}

function getPayoutStatusClass(status: string): string {
  const map: Record<string, string> = {
    pending: 'bg-brand-amber/10 text-brand-amber',
    processing: 'bg-primary-100 text-primary-700',
    paid: 'bg-brand-green/10 text-brand-green',
    cancelled: 'bg-gray-100 text-gray-500',
  }
  return map[status] || 'bg-gray-100 text-gray-600'
}

function getPayoutStatusLabel(status: string): string {
  const map: Record<string, string> = {
    pending: 'Na čekanju',
    processing: 'U obradi',
    paid: 'Plaćeno',
    cancelled: 'Otkazano',
  }
  return map[status] || status
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short', year: 'numeric' })
}

async function markAsPaid(payout: any) {
  const { error } = await supabase
    .from('partner_payouts')
    .update({
      status: 'paid',
      payment_date: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', payout.id)

  if (error) {
    console.error('Failed to mark payout as paid:', error)
    return
  }

  await refreshPayouts()
}
</script>
