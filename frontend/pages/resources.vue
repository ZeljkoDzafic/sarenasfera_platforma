<template>
  <div>
    <!-- Header -->
    <section class="bg-gradient-to-br from-brand-amber to-brand-red py-16 px-4 text-white text-center">
      <div class="max-w-3xl mx-auto">
        <h1 class="font-display text-4xl font-bold mb-3">Besplatni Resursi</h1>
        <p class="text-white/90 text-lg">
          PDF vodiči, radni listovi i edukativni materijali za roditelje i djecu.
          Preuzmite besplatno!
        </p>
      </div>
    </section>

    <!-- Resources Grid -->
    <section class="py-16 px-4">
      <div class="max-w-6xl mx-auto">

        <!-- Category Filter -->
        <div class="flex flex-wrap gap-2 mb-8 justify-center">
          <button
            v-for="cat in categories"
            :key="cat.key"
            class="px-4 py-2 rounded-xl text-sm font-semibold transition-all"
            :class="activeCategory === cat.key
              ? 'bg-primary-500 text-white shadow-colorful'
              : 'bg-white text-gray-600 hover:bg-primary-50 border border-gray-200'"
            @click="activeCategory = cat.key"
          >
            {{ cat.icon }} {{ cat.label }}
          </button>
        </div>

        <!-- Resource Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div
            v-for="resource in filteredResources"
            :key="resource.id"
            class="card-hover group"
          >
            <!-- Preview image area -->
            <div
              class="h-32 rounded-xl mb-4 flex items-center justify-center text-5xl"
              :style="{ backgroundColor: resource.color + '20' }"
            >
              {{ resource.icon }}
            </div>

            <div class="flex items-center gap-2 mb-2">
              <span class="text-xs font-semibold px-2 py-1 rounded-full" :style="{ backgroundColor: resource.color + '20', color: resource.color }">
                {{ resource.category }}
              </span>
              <span class="text-xs text-gray-400">{{ resource.pages }} stranica</span>
            </div>

            <h3 class="font-bold text-gray-900 mb-2">{{ resource.title }}</h3>
            <p class="text-gray-600 text-sm mb-4">{{ resource.description }}</p>

            <button
              class="btn-secondary w-full text-sm group-hover:btn-primary transition-all"
              @click="openDownload(resource)"
            >
              <svg class="w-4 h-4 mr-2 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              Preuzmi besplatno
            </button>
          </div>
        </div>
      </div>
    </section>

    <!-- Download Modal (email capture) -->
    <div
      v-if="selectedResource"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
      @click.self="selectedResource = null"
    >
      <div class="bg-white rounded-2xl shadow-xl w-full max-w-md p-6">
        <div class="text-center mb-6">
          <div class="text-4xl mb-3">{{ selectedResource.icon }}</div>
          <h3 class="font-display font-bold text-xl text-gray-900 mb-2">{{ selectedResource.title }}</h3>
          <p class="text-gray-600 text-sm">
            Unesite email adresu i PDF će vam biti poslan odmah.
          </p>
        </div>

        <div v-if="downloadSuccess" class="text-center py-4">
          <div class="w-12 h-12 rounded-full bg-brand-green/10 flex items-center justify-center mx-auto mb-3">
            <svg class="w-6 h-6 text-brand-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <p class="font-semibold text-gray-900">Poslan! Provjerite inbox.</p>
          <button class="mt-3 btn-secondary text-sm" @click="selectedResource = null">Zatvori</button>
        </div>

        <form v-else class="space-y-4" @submit.prevent="downloadResource">
          <div>
            <label class="label">Vaše ime</label>
            <input v-model="downloadForm.name" type="text" class="input" placeholder="Ime i prezime" required />
          </div>
          <div>
            <label class="label">Email adresa</label>
            <input v-model="downloadForm.email" type="email" class="input" placeholder="vas@email.com" required />
          </div>
          <div class="flex items-start gap-2">
            <input v-model="downloadForm.newsletter" id="dl-newsletter" type="checkbox" class="mt-1 rounded" />
            <label for="dl-newsletter" class="text-xs text-gray-500 cursor-pointer">
              Slažem se da primam newsletter sa savjetima o dječijem razvoju (možete se odjaviti u bilo kom trenutku).
            </label>
          </div>
          <div class="flex gap-3">
            <button type="button" class="btn-ghost flex-1" @click="selectedResource = null">Odustani</button>
            <button type="submit" class="btn-primary flex-1" :disabled="downloadLoading">
              {{ downloadLoading ? 'Šalje...' : 'Pošalji PDF' }}
            </button>
          </div>
          <p v-if="downloadError" class="text-brand-red text-xs text-center">{{ downloadError }}</p>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
useSeoMeta({
  title: 'Besplatni resursi — Šarena Sfera',
  description: 'Preuzmite besplatne PDF vodiče i radne listove za poticanje razvoja vašeg djeteta.',
})

const activeCategory = ref('all')

const categories = [
  { key: 'all', icon: '📚', label: 'Svi resursi' },
  { key: 'guide', icon: '📘', label: 'Vodiči za roditelje' },
  { key: 'activity', icon: '🎨', label: 'Aktivnosti' },
  { key: 'worksheet', icon: '📝', label: 'Radni listovi' },
]

const resources = [
  {
    id: 1,
    title: 'Vodič za emocionalni razvoj (2-4 god.)',
    description: 'Kako razgovarati s djetetom o emocijama, knjige koje možete čitati i aktivnosti za svaki dan.',
    icon: '❤️',
    color: '#cf2e2e',
    category: 'Vodič',
    categoryKey: 'guide',
    pages: 12,
  },
  {
    id: 2,
    title: '20 kreativnih aktivnosti za kišne dane',
    description: 'Aktivnosti s materijalima koji se nalaze u svakom domu. Bez posebnih priprema — samo igra i kreativnost.',
    icon: '🎨',
    color: '#9b51e0',
    category: 'Aktivnosti',
    categoryKey: 'activity',
    pages: 8,
  },
  {
    id: 3,
    title: 'Motorički razvoj kroz igru (4-6 god.)',
    description: 'Vježbe fine i grube motorike koje izgledaju kao igra. Sa slikovitim uputama.',
    icon: '🏃',
    color: '#00d084',
    category: 'Aktivnosti',
    categoryKey: 'activity',
    pages: 10,
  },
  {
    id: 4,
    title: 'Radni listovi: Matematika kroz igru',
    description: 'Printabilni radni listovi za uvod u brojeve, oblike i prostorne odnose.',
    icon: '🔢',
    color: '#0693e3',
    category: 'Radni list',
    categoryKey: 'worksheet',
    pages: 15,
  },
  {
    id: 5,
    title: 'Vodič: Priprema za vrtić',
    description: 'Šta dijete treba znati i umjeti prije polaska u vrtić. Checklista i savjeti.',
    icon: '🏫',
    color: '#fcb900',
    category: 'Vodič',
    categoryKey: 'guide',
    pages: 6,
  },
  {
    id: 6,
    title: 'Jezički razvoj: Priče i igre',
    description: '15 jezičkih igara za razvoj vokabulara i komunikacijskih vještina kod djece 3-5 god.',
    icon: '💬',
    color: '#f78da7',
    category: 'Aktivnosti',
    categoryKey: 'activity',
    pages: 9,
  },
]

const filteredResources = computed(() =>
  activeCategory.value === 'all'
    ? resources
    : resources.filter(r => r.categoryKey === activeCategory.value)
)

interface Resource {
  id: number
  title: string
  icon: string
  color: string
  category: string
  categoryKey: string
  pages: number
  description: string
}

const selectedResource = ref<Resource | null>(null)
const downloadForm = reactive({ name: '', email: '', newsletter: true })
const downloadLoading = ref(false)
const downloadSuccess = ref(false)
const downloadError = ref('')

function openDownload(resource: Resource) {
  selectedResource.value = resource
  downloadSuccess.value = false
  downloadError.value = ''
  Object.assign(downloadForm, { name: '', email: '', newsletter: true })
}

async function downloadResource() {
  downloadLoading.value = true
  downloadError.value = ''

  try {
    const supabase = useSupabase()
    await supabase.from('leads').insert({
      email: downloadForm.email,
      name: downloadForm.name,
      source: 'resource_download',
      metadata: {
        resource_id: selectedResource.value?.id,
        resource_title: selectedResource.value?.title,
        newsletter: downloadForm.newsletter,
      },
    })

    downloadSuccess.value = true
  } catch (err) {
    downloadError.value = 'Greška. Pokušajte ponovo.'
  } finally {
    downloadLoading.value = false
  }
}
</script>
