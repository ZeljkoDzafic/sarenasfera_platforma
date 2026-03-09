<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Preporuči Prijatelja</h1>
      <p class="text-sm text-gray-500 mt-1">Zaradite besplatan pristup preporučivanjem Šarena Sfere prijateljima</p>
    </div>

    <!-- Your referral link -->
    <div class="card bg-gradient-to-r from-primary-50 to-brand-pink/10 border-2 border-primary-200">
      <div class="flex items-start gap-4">
        <div class="w-12 h-12 rounded-xl bg-primary-100 flex items-center justify-center flex-shrink-0">
          <svg class="w-6 h-6 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
          </svg>
        </div>
        
        <div class="flex-1 min-w-0">
          <h3 class="font-display font-bold text-gray-900 mb-2">Vaš jedinstveni link</h3>
          
          <div class="flex gap-2 mb-3">
            <input
              :value="referralLink"
              readonly
              class="input flex-1 text-sm bg-white"
            />
            <button
              class="btn-primary text-sm whitespace-nowrap"
              @click="copyLink"
              :disabled="copying"
            >
              {{ copying ? 'Kopirano...' : 'Kopiraj' }}
            </button>
          </div>
          
          <!-- Share buttons -->
          <div class="flex flex-wrap gap-2">
            <button
              class="btn-secondary text-sm flex items-center gap-2"
              @click="share('whatsapp')"
            >
              <span class="text-lg">📱</span> WhatsApp
            </button>
            <button
              class="btn-secondary text-sm flex items-center gap-2"
              @click="share('viber')"
            >
              <span class="text-lg">📞</span> Viber
            </button>
            <button
              class="btn-secondary text-sm flex items-center gap-2"
              @click="share('facebook')"
            >
              <span class="text-lg">📘</span> Facebook
            </button>
            <button
              class="btn-secondary text-sm flex items-center gap-2"
              @click="share('email')"
            >
              <span class="text-lg">📧</span> Email
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div class="card text-center p-4">
        <div class="text-2xl font-bold text-primary-600 mb-1">{{ stats.invitesSent }}</div>
        <div class="text-xs text-gray-600">Poslanih poziva</div>
      </div>
      <div class="card text-center p-4">
        <div class="text-2xl font-bold text-brand-amber mb-1">{{ stats.registered }}</div>
        <div class="text-xs text-gray-600">Registrovanih</div>
      </div>
      <div class="card text-center p-4">
        <div class="text-2xl font-bold text-brand-green mb-1">{{ stats.paid }}</div>
        <div class="text-xs text-gray-600">Aktiviranih</div>
      </div>
      <div class="card text-center p-4">
        <div class="text-2xl font-bold text-brand-green mb-1">{{ stats.rewardsEarned }}</div>
        <div class="text-xs text-gray-600">Nagrada</div>
      </div>
    </div>

    <!-- Rewards summary -->
    <div class="card">
      <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Vaše nagrade</h2>
      
      <div v-if="referrals && referrals.length > 0" class="space-y-3">
        <div
          v-for="ref in referrals"
          :key="ref.id"
          class="p-4 rounded-xl border border-gray-100 flex items-center justify-between"
        >
          <div class="flex items-center gap-3">
            <div
              class="w-10 h-10 rounded-xl flex items-center justify-center"
              :class="getStatusBg(ref.status)"
            >
              {{ getStatusIcon(ref.status) }}
            </div>
            <div>
              <p class="font-semibold text-gray-900">{{ ref.referred_email || 'Prijatelj' }}</p>
              <p class="text-xs text-gray-500">{{ formatDate(ref.created_at) }}</p>
            </div>
          </div>
          
          <div class="text-right">
            <span
              class="text-xs font-semibold px-2 py-1 rounded-full"
              :class="getStatusBadgeClass(ref.status)"
            >
              {{ getStatusLabel(ref.status) }}
            </span>
            <p v-if="ref.reward_type" class="text-xs text-brand-green font-semibold mt-1">
              + {{ ref.reward_type }}
            </p>
          </div>
        </div>
      </div>
      
      <div v-else class="text-center py-8 text-gray-400">
        <div class="text-4xl mb-3">🎁</div>
        <p class="text-sm">Još nemate preporuka. Podijelite svoj link!</p>
      </div>
    </div>

    <!-- How it works -->
    <div class="card bg-gray-50">
      <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Kako funkcioniše?</h2>
      <ol class="space-y-3">
        <li class="flex gap-3">
          <span class="w-6 h-6 rounded-full bg-primary-100 text-primary-600 flex items-center justify-center text-xs font-bold flex-shrink-0">1</span>
          <p class="text-sm text-gray-600">Podijelite svoj jedinstveni referral link s prijateljima</p>
        </li>
        <li class="flex gap-3">
          <span class="w-6 h-6 rounded-full bg-primary-100 text-primary-600 flex items-center justify-center text-xs font-bold flex-shrink-0">2</span>
          <p class="text-sm text-gray-600">Prijatelj se registruje putem vašeg linka</p>
        </li>
        <li class="flex gap-3">
          <span class="w-6 h-6 rounded-full bg-primary-100 text-primary-600 flex items-center justify-center text-xs font-bold flex-shrink-0">3</span>
          <p class="text-sm text-gray-600">Kada prijatelj aktivira Paid tier, oboje dobijate 1 mjesec besplatno</p>
        </li>
      </ol>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })
useSeoMeta({ title: 'Preporuči Prijatelja — Šarena Sfera' })

const supabase = useSupabase()
const { user } = useAuth()

const referralLink = ref('')
const copying = ref(false)
const referrals = ref<any[]>([])

const stats = ref({
  invitesSent: 0,
  registered: 0,
  paid: 0,
  rewardsEarned: 0,
})

// Generate referral link on mount
onMounted(async () => {
  if (!user.value) return
  
  // Generate or fetch referral code
  const { data: existingReferral } = await supabase
    .from('referrals')
    .select('referral_code')
    .eq('referrer_id', user.value.id)
    .order('created_at', { ascending: true })
    .limit(1)
    .maybeSingle()
  
  let code = existingReferral?.referral_code
  
  if (!code) {
    // Generate new code
    code = 'REF-' + Math.random().toString(36).substring(2, 8).toUpperCase()
    
    await supabase.from('referrals').insert({
      referrer_id: user.value.id,
      referral_code: code,
      status: 'pending',
    })
  }
  
  referralLink.value = `${window.location.origin}/auth/register?ref=${code}`
  
  // Fetch referrals
  await fetchReferrals()
})

async function fetchReferrals() {
  if (!user.value) return
  
  const { data } = await supabase
    .from('referrals')
    .select('id, referral_code, referred_email, status, reward_type, created_at, converted_at')
    .eq('referrer_id', user.value.id)
    .order('created_at', { ascending: false })
  
  referrals.value = data ?? []
  
  // Calculate stats
  stats.value.invitesSent = referrals.value.length
  stats.value.registered = referrals.value.filter(r => r.status === 'registered').length
  stats.value.paid = referrals.value.filter(r => r.status === 'paid' || r.status === 'reward_granted').length
  stats.value.rewardsEarned = referrals.value.filter(r => r.reward_granted).length
}

function copyLink() {
  navigator.clipboard.writeText(referralLink.value)
  copying.value = true
  setTimeout(() => {
    copying.value = false
  }, 2000)
}

function share(platform: string) {
  const text = `Pridruži mi se na Šarena Sfera platformi i prati razvoj svog djeteta kroz 6 domena! Koristi moj link: ${referralLink.value}`
  
  const urls: Record<string, string> = {
    whatsapp: `https://wa.me/?text=${encodeURIComponent(text)}`,
    viber: `viber://forward?text=${encodeURIComponent(text)}`,
    facebook: `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(referralLink.value)}`,
    email: `mailto:?subject=Šarena Sfera - Preporuka&body=${encodeURIComponent(text)}`,
  }
  
  window.open(urls[platform], '_blank')
}

function getStatusBg(status: string): string {
  const map: Record<string, string> = {
    pending: 'bg-gray-100',
    registered: 'bg-brand-amber/20',
    paid: 'bg-brand-green/20',
    reward_granted: 'bg-brand-green/20',
    expired: 'bg-gray-100',
  }
  return map[status] || 'bg-gray-100'
}

function getStatusIcon(status: string): string {
  const icons: Record<string, string> = {
    pending: '⏳',
    registered: '📝',
    paid: '✓',
    reward_granted: '🎁',
    expired: '❌',
  }
  return icons[status] || '⏳'
}

function getStatusLabel(status: string): string {
  const labels: Record<string, string> = {
    pending: 'Na čekanju',
    registered: 'Registrovan',
    paid: 'Aktiviran',
    reward_granted: 'Nagrada dodijeljena',
    expired: 'Isteklo',
  }
  return labels[status] || 'Nepoznato'
}

function getStatusBadgeClass(status: string): string {
  const map: Record<string, string> = {
    pending: 'bg-gray-100 text-gray-600',
    registered: 'bg-brand-amber/10 text-brand-amber',
    paid: 'bg-brand-green/10 text-brand-green',
    reward_granted: 'bg-brand-green/10 text-brand-green',
    expired: 'bg-gray-100 text-gray-400',
  }
  return map[status] || 'bg-gray-100 text-gray-600'
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('bs-BA', { day: 'numeric', month: 'short' })
}
</script>
