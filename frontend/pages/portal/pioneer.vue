<template>
  <div class="space-y-6">
    <!-- Header with badge -->
    <div class="card bg-gradient-to-r from-brand-amber/20 to-primary-50 border-2 border-brand-amber/30">
      <div class="flex items-start gap-4">
        <div class="w-16 h-16 rounded-2xl bg-brand-amber/20 flex items-center justify-center flex-shrink-0">
          <span class="text-3xl">🏆</span>
        </div>
        
        <div class="flex-1">
          <div class="flex items-center gap-2 mb-2">
            <h1 class="font-display text-2xl font-bold text-gray-900">Roditelj Pionir</h1>
            <span class="px-3 py-1 rounded-full bg-brand-amber text-white text-xs font-bold">
              FOUNDING MEMBER
            </span>
          </div>
          
          <p v-if="isPioneer" class="text-brand-amber font-semibold mb-2">
            ✨ Vi ste jedan od 50 osnivača Šarena Sfere!
          </p>
          <p v-else class="text-gray-600 mb-3">
            Postanite jedan od 50 osnivača platforme i ostvarite ekskluzivne pogodnosti.
          </p>
          
          <!-- Slots counter -->
          <div v-if="!isPioneer" class="flex items-center gap-3 mb-4">
            <div class="flex-1 h-3 bg-gray-200 rounded-full overflow-hidden">
              <div
                class="h-full bg-gradient-to-r from-brand-amber to-primary-500 transition-all"
                :style="{ width: `${(pioneerCount / 50) * 100}%` }"
              />
            </div>
            <span class="text-sm font-semibold text-gray-700 whitespace-nowrap">
              {{ 50 - pioneerCount }} preostalo
            </span>
          </div>
          
          <NuxtLink v-if="!isPioneer && slotsAvailable" to="/auth/register? Pioneer=true" class="btn-primary">
            Postanite Pionir
          </NuxtLink>
        </div>
      </div>
    </div>

    <!-- Benefits grid -->
    <div class="grid md:grid-cols-2 gap-4">
      <div class="card p-5">
        <div class="flex items-start gap-3">
          <div class="w-10 h-10 rounded-xl bg-brand-green/20 flex items-center justify-center flex-shrink-0">
            <span class="text-xl">💰</span>
          </div>
          <div>
            <h3 class="font-bold text-gray-900 mb-1">Doživotna cijena</h3>
            <p class="text-sm text-gray-600">
              <span class="font-semibold text-brand-green">10 KM/mj</span> za Paid tier (umjesto 15 KM)
              <br />
              <span class="font-semibold text-brand-green">20 KM/mj</span> za Premium (umjesto 30 KM)
            </p>
          </div>
        </div>
      </div>
      
      <div class="card p-5">
        <div class="flex items-start gap-3">
          <div class="w-10 h-10 rounded-xl bg-primary-100 flex items-center justify-center flex-shrink-0">
            <span class="text-xl">🎖️</span>
          </div>
          <div>
            <h3 class="font-bold text-gray-900 mb-1">Ekskluzivni badge</h3>
            <p class="text-sm text-gray-600">
              "Roditelj Pionir" badge na vašem profilu i u zajednici
            </p>
          </div>
        </div>
      </div>
      
      <div class="card p-5">
        <div class="flex items-start gap-3">
          <div class="w-10 h-10 rounded-xl bg-brand-amber/20 flex items-center justify-center flex-shrink-0">
            <span class="text-xl">⭐</span>
          </div>
          <div>
            <h3 class="font-bold text-gray-900 mb-1">Prioritetni pristup</h3>
            <p class="text-sm text-gray-600">
              Prioritetna prijava na radionice i ekskluzivne događaje
            </p>
          </div>
        </div>
      </div>
      
      <div class="card p-5">
        <div class="flex items-start gap-3">
          <div class="w-10 h-10 rounded-xl bg-brand-pink/20 flex items-center justify-center flex-shrink-0">
            <span class="text-xl">📜</span>
          </div>
          <div>
            <h3 class="font-bold text-gray-900 mb-1">Zid Pionira</h3>
            <p class="text-sm text-gray-600">
              Vaše ime na javnom Zidu Pionira kao zahvalnost za rano povjerenje
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Pioneer Wall -->
    <div class="card">
      <h2 class="font-display font-bold text-lg text-gray-900 mb-4 flex items-center gap-2">
        <span class="text-xl">🌟</span>
        Zid Pionira
      </h2>
      
      <div v-if="pioneers && pioneers.length > 0" class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-3">
        <div
          v-for="pioneer in pioneers"
          :key="pioneer.id"
          class="p-3 rounded-xl bg-gradient-to-br from-brand-amber/10 to-primary-50 text-center border border-brand-amber/20"
        >
          <div class="text-2xl mb-1">🏆</div>
          <p class="font-semibold text-gray-900 text-sm truncate">{{ pioneer.display_name }}</p>
          <p class="text-xs text-gray-500">#{{ pioneer.slot_number }}</p>
          <p class="text-xs text-gray-400 mt-1">{{ formatJoinDate(pioneer.joined_at) }}</p>
        </div>
      </div>
      
      <div v-else class="text-center py-8 text-gray-400">
        <p class="text-sm">Prvi pioniri će se uskoro pojaviti ovdje!</p>
      </div>
    </div>

    <!-- How to become a pioneer -->
    <div v-if="!isPioneer && slotsAvailable" class="card bg-gray-50">
      <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Kako postati Pionir?</h2>
      <ol class="space-y-3">
        <li class="flex gap-3">
          <span class="w-6 h-6 rounded-full bg-brand-amber text-white flex items-center justify-center text-xs font-bold flex-shrink-0">1</span>
          <p class="text-sm text-gray-600">Registrujte se na Šarena Sfera platformu putem pionirskog linka</p>
        </li>
        <li class="flex gap-3">
          <span class="w-6 h-6 rounded-full bg-brand-amber text-white flex items-center justify-center text-xs font-bold flex-shrink-0">2</span>
          <p class="text-sm text-gray-600">Odaberite Paid ili Premium tier pretplatu</p>
        </li>
        <li class="flex gap-3">
          <span class="w-6 h-6 rounded-full bg-brand-amber text-white flex items-center justify-center text-xs font-bold flex-shrink-0">3</span>
          <p class="text-sm text-gray-600">Automatski dobijate Pionir status i doživotnu cijenu</p>
        </li>
      </ol>
      
      <div class="mt-6 flex justify-center">
        <NuxtLink to="/auth/register? Pioneer=true" class="btn-primary text-lg px-8 py-3">
          Postanite Pionir Danas
        </NuxtLink>
      </div>
    </div>

    <!-- FAQ -->
    <div class="card">
      <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Često postavljana pitanja</h2>
      
      <div class="space-y-4">
        <div>
          <h3 class="font-semibold text-gray-900 mb-1">Šta ako se cijene promijene?</h3>
          <p class="text-sm text-gray-600">Kao Pionir, vaša cijena je zaključana za uvijek. Bez obzira na buduće promjene cijena, vi plaćate pionirsku cijenu.</p>
        </div>
        
        <div>
          <h3 class="font-semibold text-gray-900 mb-1">Mogu li nadograditi tier kasnije?</h3>
          <p class="text-sm text-gray-600">Da! Možete nadograditi s Paid na Premium uz zadržavanje pionirske cijene.</p>
        </div>
        
        <div>
          <h3 class="font-semibold text-gray-900 mb-1">Šta se dešava ako pauziram pretplatu?</h3>
          <p class="text-sm text-gray-600">Vaš Pionir status ostaje sačuvan. Kada se ponovo pretplatite, i dalje imate pravo na pionirsku cijenu.</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })
useSeoMeta({ title: 'Roditelji Pioniri — Šarena Sfera' })

const supabase = useSupabase()
const { user } = useAuth()

const isPioneer = ref(false)
const pioneerCount = ref(0)
const slotsAvailable = ref(true)
const pioneers = ref<any[]>([])

onMounted(async () => {
  // Fetch pioneer wall data
  const { data: pioneerData } = await supabase
    .from('pioneer_wall')
    .select('id, display_name, city, slot_number, joined_at, is_visible')
    .eq('is_visible', true)
    .order('slot_number', { ascending: true })
  
  pioneers.value = pioneerData ?? []
  pioneerCount.value = pioneers.value.length
  slotsAvailable.value = pioneerCount.value < 50
  
  // Check if current user is a pioneer
  if (user.value) {
    const { data: userPioneer } = await supabase
      .from('pioneer_wall')
      .select('id')
      .eq('user_id', user.value.id)
      .maybeSingle()
    
    isPioneer.value = !!userPioneer
  }
})

function formatJoinDate(iso: string): string {
  const date = new Date(iso)
  return date.toLocaleDateString('bs-BA', { month: 'short', year: 'numeric' })
}
</script>
