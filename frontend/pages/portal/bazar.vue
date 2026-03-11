<template>
  <div class="space-y-6">
    <div class="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-4">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Dječiji bazar</h1>
        <p class="text-sm text-gray-500">Razmjena, prodaja i poklanjanje opreme, igračaka i knjiga među roditeljima.</p>
      </div>
      <button class="btn-primary" @click="showCreate = !showCreate">{{ showCreate ? 'Zatvori formu' : '+ Dodaj oglas' }}</button>
    </div>

    <section v-if="showCreate" class="card space-y-4">
      <h2 class="font-display text-lg font-bold text-gray-900">Novi oglas</h2>
      <div class="grid gap-4 md:grid-cols-2">
        <input v-model="form.title" class="input md:col-span-2" placeholder="Naslov oglasa" />
        <select v-model="form.item_type" class="input">
          <option value="gift">Poklanjam</option>
          <option value="exchange">Mijenjam</option>
          <option value="sale">Prodajem</option>
        </select>
        <input v-model="form.category" class="input" placeholder="Kategorija" />
        <input v-model="form.age_group_label" class="input" placeholder="Uzrast, npr. 0-1 god" />
        <input v-model="form.location_label" class="input" placeholder="Lokacija" />
        <input v-model.number="form.price" type="number" min="0" step="0.01" class="input" placeholder="Cijena u BAM" />
        <input v-model="form.contact_phone" class="input" placeholder="Telefon (opcionalno)" />
        <input v-model="form.contact_email" class="input" placeholder="Kontakt email (opcionalno)" />
        <input v-model="imageUrl" class="input md:col-span-2" placeholder="URL slike (opcionalno)" />
        <textarea v-model="form.description" class="input md:col-span-2" rows="4" placeholder="Opis predmeta" />
      </div>
      <div class="flex justify-end">
        <button class="btn-primary" :disabled="saving" @click="createItem">{{ saving ? 'Objavljujem...' : 'Objavi oglas' }}</button>
      </div>
    </section>

    <section class="card">
      <div class="grid gap-3 md:grid-cols-4">
        <input v-model="filters.search" class="input md:col-span-2" placeholder="Pretraži bazar" />
        <select v-model="filters.itemType" class="input">
          <option value="all">Svi tipovi</option>
          <option value="gift">Poklanjam</option>
          <option value="exchange">Mijenjam</option>
          <option value="sale">Prodajem</option>
        </select>
        <input v-model="filters.location" class="input" placeholder="Lokacija" />
      </div>
    </section>

    <div v-if="filteredItems.length > 0" class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
      <article v-for="item in filteredItems" :key="item.id" class="card space-y-4">
        <div class="aspect-[4/3] rounded-2xl overflow-hidden bg-primary-50">
          <img v-if="item.image_urls?.[0]" :src="item.image_urls[0]" :alt="item.title" class="w-full h-full object-cover" />
          <div v-else class="w-full h-full flex items-center justify-center text-5xl">🧸</div>
        </div>
        <div class="flex flex-wrap gap-2">
          <span class="badge badge-paid">{{ typeLabel(item.item_type) }}</span>
          <span class="badge badge-free">{{ item.category }}</span>
          <span v-if="item.age_group_label" class="badge badge-premium">{{ item.age_group_label }}</span>
        </div>
        <div>
          <h2 class="font-semibold text-gray-900">{{ item.title }}</h2>
          <p class="mt-2 text-sm text-gray-600 line-clamp-3">{{ item.description }}</p>
        </div>
        <div class="flex items-center justify-between text-sm">
          <span class="font-semibold text-primary-700">{{ priceLabel(item) }}</span>
          <span class="text-gray-500">{{ item.location_label || 'Bez lokacije' }}</span>
        </div>
        <div class="text-xs text-gray-500">
          <div>{{ ownerName(item.owner) }}</div>
          <div v-if="item.contact_email || item.contact_phone">{{ item.contact_email || item.contact_phone }}</div>
        </div>
      </article>
    </div>

    <div v-else class="card text-center py-12 text-gray-500">Još nema oglasa u bazaru.</div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'portal' })
useSeoMeta({ title: 'Dječiji bazar — Portal' })

const supabase = useSupabase()
const { user } = useAuth()
const showCreate = ref(false)
const saving = ref(false)
const imageUrl = ref('')

const form = reactive({
  title: '',
  description: '',
  item_type: 'gift',
  category: '',
  age_group_label: '',
  location_label: '',
  price: null as number | null,
  contact_phone: '',
  contact_email: '',
})

const filters = reactive({
  search: '',
  itemType: 'all',
  location: '',
})

const { data: items, refresh } = await useAsyncData('marketplace-items', async () => {
  const { data } = await supabase
    .from('marketplace_items')
    .select('id, title, description, item_type, category, age_group_label, location_label, price, currency, image_urls, contact_email, contact_phone, status, created_at, owner:profiles!marketplace_items_owner_id_fkey(full_name)')
    .order('created_at', { ascending: false })

  return data ?? []
})

const filteredItems = computed(() => {
  const term = filters.search.trim().toLowerCase()
  const location = filters.location.trim().toLowerCase()
  return (items.value ?? []).filter((item) => {
    const termMatch = !term || [item.title, item.description, item.category, item.age_group_label].some((value) => (value ?? '').toLowerCase().includes(term))
    const typeMatch = filters.itemType === 'all' || item.item_type === filters.itemType
    const locationMatch = !location || (item.location_label ?? '').toLowerCase().includes(location)
    return termMatch && typeMatch && locationMatch
  })
})

async function createItem() {
  if (!user.value || !form.title || !form.category) return
  saving.value = true
  try {
    const { error } = await supabase.from('marketplace_items').insert({
      owner_id: user.value.id,
      title: form.title,
      description: form.description || null,
      item_type: form.item_type,
      category: form.category,
      age_group_label: form.age_group_label || null,
      location_label: form.location_label || null,
      price: form.item_type === 'sale' ? form.price : null,
      image_urls: imageUrl.value ? [imageUrl.value] : [],
      contact_email: form.contact_email || user.value.email || null,
      contact_phone: form.contact_phone || null,
    })

    if (error) throw error

    Object.assign(form, {
      title: '',
      description: '',
      item_type: 'gift',
      category: '',
      age_group_label: '',
      location_label: '',
      price: null,
      contact_phone: '',
      contact_email: '',
    })
    imageUrl.value = ''
    showCreate.value = false
    await refresh()
  } finally {
    saving.value = false
  }
}

function typeLabel(type: string): string {
  return type === 'sale' ? 'Prodaja' : type === 'exchange' ? 'Razmjena' : 'Poklon'
}

function priceLabel(item: { item_type: string; price: number | null; currency: string }): string {
  if (item.item_type !== 'sale') return typeLabel(item.item_type)
  return item.price ? `${item.price.toFixed(2)} ${item.currency}` : `0 ${item.currency}`
}

function ownerName(owner: Array<{ full_name?: string | null }> | null | undefined): string {
  return owner?.[0]?.full_name ?? 'Član zajednice'
}
</script>
