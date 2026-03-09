<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Pretplate</h1>
      <p class="text-sm text-gray-500 mt-1">Upravljajte korisničkim pretplatama i plaćanjima</p>
    </div>

    <!-- Stats Overview -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-gray-700 mb-1">{{ stats.free }}</div>
        <div class="text-xs text-gray-600">Free Tier</div>
      </div>
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-primary-600 mb-1">{{ stats.paid }}</div>
        <div class="text-xs text-gray-600">Paid Tier</div>
      </div>
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-brand-pink mb-1">{{ stats.premium }}</div>
        <div class="text-xs text-gray-600">Premium Tier</div>
      </div>
      <div class="card p-4 text-center">
        <div class="text-2xl font-bold text-brand-green mb-1">{{ stats.monthlyRevenue }}</div>
        <div class="text-xs text-gray-600">Mjesečni prihod (KM)</div>
      </div>
    </div>

    <!-- Filters -->
    <div class="card">
      <div class="flex flex-wrap gap-3">
        <select v-model="filterTier" class="input w-auto text-sm">
          <option value="">Svi tier-ovi</option>
          <option value="free">Free</option>
          <option value="paid">Paid</option>
          <option value="premium">Premium</option>
        </select>
        <select v-model="filterStatus" class="input w-auto text-sm">
          <option value="">Svi statusi</option>
          <option value="active">Aktivne</option>
          <option value="trial">Trial</option>
          <option value="cancelled">Kancelirane</option>
          <option value="expired">Istekle</option>
        </select>
        <input
          v-model="search"
          type="search"
          placeholder="Pretraži korisnike..."
          class="input flex-1 min-w-48 text-sm"
        />
      </div>
    </div>

    <!-- Loading -->
    <div v-if="pending" class="space-y-2">
      <div v-for="i in 10" :key="i" class="card h-20 animate-pulse" />
    </div>

    <!-- Subscriptions Table -->
    <div v-else-if="filteredSubscriptions.length > 0" class="card overflow-hidden p-0">
      <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-100">
          <tr>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Korisnik</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Trenutni Plan</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Status</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Period</th>
            <th class="text-left px-4 py-3 font-semibold text-gray-600">Plaćanje</th>
            <th class="text-right px-4 py-3 font-semibold text-gray-600">Akcije</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr
            v-for="sub in filteredSubscriptions"
            :key="sub.id"
            class="hover:bg-gray-50 transition-colors"
          >
            <td class="px-4 py-3">
              <div>
                <p class="font-semibold text-gray-900">{{ sub.profiles?.full_name || 'N/A' }}</p>
                <p class="text-xs text-gray-500">{{ sub.profiles?.email || '—' }}</p>
              </div>
            </td>
            <td class="px-4 py-3">
              <TierBadge :tier="sub.subscription_plans?.key" />
            </td>
            <td class="px-4 py-3">
              <span
                class="text-xs font-semibold px-2 py-0.5 rounded-full"
                :class="getStatusClass(sub.status)"
              >
                {{ getStatusLabel(sub.status) }}
              </span>
            </td>
            <td class="px-4 py-3 text-gray-500">
              <div v-if="sub.start_date">
                <p class="text-xs">{{ formatDate(sub.start_date) }}</p>
                <p v-if="sub.end_date" class="text-xs text-gray-400">do {{ formatDate(sub.end_date) }}</p>
              </div>
            </td>
            <td class="px-4 py-3">
              <div v-if="sub.payment_method">
                <p class="font-semibold text-gray-900">{{ sub.subscription_plans?.price_km || 0 }} KM</p>
                <p class="text-xs text-gray-500 capitalize">{{ sub.payment_method }}</p>
              </div>
              <span v-else class="text-xs text-gray-400">—</span>
            </td>
            <td class="px-4 py-3 text-right">
              <button
                class="text-xs font-semibold text-primary-600 hover:text-primary-700"
                @click="openManageModal(sub)"
              >
                Upravljaj
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Empty State -->
    <div v-else class="card text-center py-12">
      <div class="text-4xl mb-3">💳</div>
      <h3 class="font-display font-bold text-lg text-gray-900 mb-2">Nema pretplata</h3>
      <p class="text-gray-500 text-sm">Pronađene pretplate prema odabranim filterima.</p>
    </div>

    <!-- Manage Subscription Modal -->
    <Teleport to="body">
      <div v-if="managingSubscription" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
        <div class="bg-white rounded-2xl w-full max-w-lg shadow-xl max-h-[90vh] overflow-y-auto">
          <div class="p-6 border-b border-gray-100">
            <h2 class="font-display font-bold text-xl text-gray-900">Upravljanje pretplatom</h2>
          </div>
          <div class="p-6 space-y-4">
            <!-- User Info -->
            <div class="bg-gray-50 rounded-xl p-4">
              <p class="font-semibold text-gray-900">{{ managingSubscription.profiles?.full_name }}</p>
              <p class="text-sm text-gray-600">{{ managingSubscription.profiles?.email }}</p>
              <p class="text-xs text-gray-500 mt-1">Trenutni plan: {{ managingSubscription.subscription_plans?.name }}</p>
            </div>

            <!-- Change Plan -->
            <div>
              <label class="label">Promijeni plan</label>
              <select v-model="selectedPlanId" class="input">
                <option
                  v-for="plan in availablePlans"
                  :key="plan.id"
                  :value="plan.id"
                >
                  {{ plan.name }} ({{ plan.price_km }} KM)
                </option>
              </select>
            </div>

            <!-- Change Status -->
            <div>
              <label class="label">Status</label>
              <select v-model="selectedStatus" class="input">
                <option value="active">Aktivna</option>
                <option value="cancelled">Kancelirana</option>
                <option value="expired">Istekla</option>
                <option value="trial">Trial</option>
              </select>
            </div>

            <!-- Record Payment -->
            <div class="border-t pt-4">
              <h3 class="font-bold text-gray-900 mb-3">Zabilježi plaćanje</h3>
              <div class="grid grid-cols-2 gap-3">
                <div>
                  <label class="label text-xs">Iznos (KM)</label>
                  <input v-model="payment.amount" type="number" step="0.01" class="input text-sm" />
                </div>
                <div>
                  <label class="label text-xs">Metoda</label>
                  <select v-model="payment.method" class="input text-sm">
                    <option value="cash">Gotovina</option>
                    <option value="bank">Bankovni transfer</option>
                    <option value="card">Kartica</option>
                    <option value="paypal">PayPal</option>
                  </select>
                </div>
              </div>
              <div class="mt-3">
                <label class="label text-xs">Referenca</label>
                <input v-model="payment.reference" type="text" class="input text-sm" placeholder="Broj uplate, ID transakcije..." />
              </div>
              <div class="grid grid-cols-2 gap-3 mt-3">
                <div>
                  <label class="label text-xs">Period od</label>
                  <input v-model="payment.periodStart" type="date" class="input text-sm" />
                </div>
                <div>
                  <label class="label text-xs">Period do</label>
                  <input v-model="payment.periodEnd" type="date" class="input text-sm" />
                </div>
              </div>
            </div>

            <!-- Actions -->
            <div class="flex gap-3 pt-4">
              <button class="btn-primary flex-1" :disabled="saving" @click="saveChanges">
                {{ saving ? 'Čuva...' : 'Sačuvaj promjene' }}
              </button>
              <button class="btn-secondary flex-1" @click="managingSubscription = null">
                Zatvori
              </button>
            </div>

            <p v-if="error" class="text-brand-red text-sm text-center">{{ error }}</p>
            <p v-if="success" class="text-brand-green text-sm text-center">{{ success }}</p>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'] })
useSeoMeta({ title: 'Pretplate — Admin' })

const supabase = useSupabase()
const { role } = useAuth()

if (role.value !== 'admin') {
  throw createError({ statusCode: 403, message: 'Samo admini mogu upravljati pretplatama' })
}

const search = ref('')
const filterTier = ref('')
const filterStatus = ref('')

const { data: subscriptions, pending, refresh } = await useAsyncData('admin-subscriptions', async () => {
  const { data } = await supabase
    .from('subscriptions')
    .select(`
      *,
      subscription_plans(id, name, key, price_km),
      profiles(full_name, email, subscription_tier)
    `)
    .order('created_at', { ascending: false })

  return data ?? []
})

const { data: availablePlans } = await useAsyncData('subscription-plans', async () => {
  const { data } = await supabase
    .from('subscription_plans')
    .select('*')
    .eq('is_active', true)
    .order('tier_level')

  return data ?? []
})

const filteredSubscriptions = computed(() => {
  let list = subscriptions.value ?? []

  if (filterTier.value) {
    list = list.filter(s => s.subscription_plans?.key === filterTier.value)
  }

  if (filterStatus.value) {
    list = list.filter(s => s.status === filterStatus.value)
  }

  if (search.value) {
    const s = search.value.toLowerCase()
    list = list.filter(sub =>
      sub.profiles?.full_name?.toLowerCase().includes(s) ||
      sub.profiles?.email?.toLowerCase().includes(s)
    )
  }

  return list
})

const stats = computed(() => {
  const list = subscriptions.value ?? []
  return {
    free: list.filter(s => s.subscription_plans?.key === 'free').length,
    paid: list.filter(s => s.subscription_plans?.key === 'paid').length,
    premium: list.filter(s => s.subscription_plans?.key === 'premium').length,
    monthlyRevenue: list
      .filter(s => s.status === 'active')
      .reduce((sum, s) => sum + (s.subscription_plans?.price_km || 0), 0),
  }
})

const managingSubscription = ref<any>(null)
const selectedPlanId = ref('')
const selectedStatus = ref('active')
const payment = reactive({
  amount: 0,
  method: 'cash',
  reference: '',
  periodStart: '',
  periodEnd: '',
})

const saving = ref(false)
const error = ref('')
const success = ref('')

function getStatusClass(status: string): string {
  const map: Record<string, string> = {
    active: 'bg-brand-green/10 text-brand-green',
    trial: 'bg-primary-100 text-primary-700',
    cancelled: 'bg-gray-100 text-gray-500',
    expired: 'bg-brand-red/10 text-brand-red',
  }
  return map[status] || 'bg-gray-100 text-gray-500'
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = {
    active: 'Aktivna',
    trial: 'Trial',
    cancelled: 'Kancelirana',
    expired: 'Istekla',
  }
  return map[status] || status
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short', year: 'numeric' })
}

function openManageModal(sub: any) {
  managingSubscription.value = sub
  selectedPlanId.value = sub.plan_id
  selectedStatus.value = sub.status
  payment.amount = sub.subscription_plans?.price_km || 0
  payment.method = sub.payment_method || 'cash'
  payment.reference = sub.payment_ref || ''
  payment.periodStart = sub.start_date || ''
  payment.periodEnd = sub.end_date || ''
}

async function saveChanges() {
  if (!managingSubscription.value) return

  saving.value = true
  error.value = ''
  success.value = ''

  try {
    // Update subscription
    const { error: subError } = await supabase
      .from('subscriptions')
      .update({
        plan_id: selectedPlanId.value,
        status: selectedStatus.value,
        payment_method: payment.method,
        payment_ref: payment.reference,
        start_date: payment.periodStart,
        end_date: payment.periodEnd,
        updated_at: new Date().toISOString(),
      })
      .eq('id', managingSubscription.value.id)

    if (subError) throw subError

    // Record payment if amount > 0
    if (payment.amount > 0) {
      const { error: paymentError } = await supabase
        .from('payments')
        .insert({
          user_id: managingSubscription.value.user_id,
          subscription_id: managingSubscription.value.id,
          amount_km: payment.amount,
          payment_method: payment.method,
          payment_ref: payment.reference,
          period_start: payment.periodStart,
          period_end: payment.periodEnd,
        })

      if (paymentError) throw paymentError
    }

    success.value = 'Promjene su sačuvane!'
    await refresh()

    setTimeout(() => {
      managingSubscription.value = null
    }, 1500)
  } catch (err: unknown) {
    error.value = 'Greška pri čuvanju. Pokušajte ponovo.'
  } finally {
    saving.value = false
  }
}
</script>
