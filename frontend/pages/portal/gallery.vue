<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-2xl font-bold text-gray-900">Galerija</h1>
        <p class="text-sm text-gray-500 mt-1">Fotografije s radionica</p>
      </div>
    </div>

    <!-- Child filter -->
    <div class="flex gap-2 overflow-x-auto pb-1">
      <button
        class="px-4 py-1.5 rounded-full text-sm font-semibold transition-all border-2 whitespace-nowrap"
        :class="activeChild === null ? 'border-primary-500 bg-primary-50 text-primary-700' : 'border-gray-200 text-gray-600'"
        @click="activeChild = null"
      >
        Sva djeca
      </button>
      <button
        v-for="child in children"
        :key="child.id"
        class="px-4 py-1.5 rounded-full text-sm font-semibold transition-all border-2 whitespace-nowrap"
        :class="activeChild === child.id ? 'border-primary-500 bg-primary-50 text-primary-700' : 'border-gray-200 text-gray-600'"
        @click="activeChild = child.id"
      >
        {{ child.full_name }}
      </button>
    </div>

    <!-- Loading -->
    <div v-if="pending" class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2">
      <div v-for="i in 12" :key="i" class="aspect-square bg-gray-100 rounded-xl animate-pulse" />
    </div>

    <!-- Photo grid -->
    <div v-else-if="photos.length > 0" class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2">
      <div
        v-for="photo in photos"
        :key="photo.id"
        class="aspect-square rounded-xl overflow-hidden cursor-pointer relative group"
        @click="openPhoto(photo)"
      >
        <img
          :src="photo.file_url"
          :alt="photo.caption ?? 'Slika s radionice'"
          class="w-full h-full object-cover transition-transform group-hover:scale-105"
        />
        <div class="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors" />
        <div v-if="photo.caption" class="absolute bottom-0 left-0 right-0 p-2 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity">
          <p class="text-white text-xs line-clamp-2">{{ photo.caption }}</p>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-else class="card text-center py-16">
      <div class="text-5xl mb-4">📷</div>
      <h3 class="font-display font-bold text-xl text-gray-900 mb-2">Nema fotografija</h3>
      <p class="text-gray-600 text-sm">Fotografije s radionica se pojavljuju ovdje nakon što ih voditelji objave.</p>
    </div>

    <!-- Lightbox -->
    <Teleport to="body">
      <div v-if="activePhoto" class="fixed inset-0 bg-black/90 flex items-center justify-center z-50 p-4" @click.self="activePhoto = null">
        <div class="max-w-2xl w-full">
          <img :src="activePhoto.file_url" :alt="activePhoto.caption ?? ''" class="w-full rounded-2xl max-h-[70vh] object-contain" />
          <div class="mt-4 flex items-center justify-between">
            <p v-if="activePhoto.caption" class="text-white/90 text-sm">{{ activePhoto.caption }}</p>
            <div class="flex gap-3 ml-auto">
              <a :href="activePhoto.file_url" target="_blank" download class="btn bg-white/10 text-white border border-white/20 text-sm hover:bg-white/20">
                ⬇ Preuzmi
              </a>
              <button class="btn bg-white/10 text-white border border-white/20 text-sm hover:bg-white/20" @click="activePhoto = null">
                ✕ Zatvori
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'portal' })
useSeoMeta({ title: 'Galerija — Šarena Sfera' })

const supabase = useSupabase()
const { user } = useAuth()

const activeChild = ref<string | null>(null)

const { data: children } = await useAsyncData('gallery-children', async () => {
  if (!user.value) return []
  const { data } = await supabase
    .from('children')
    .select('id, full_name, parent_children!inner(parent_id)')
    .eq('parent_children.parent_id', user.value.id)
    .eq('is_active', true)
  return data ?? []
})

const { data: photos, pending } = await useAsyncData('gallery-photos', async () => {
  if (!user.value) return []

  let query = supabase
    .from('observation_media')
    .select(`
      id, file_url, file_type, caption, created_at,
      observations!inner(child_id, is_visible_to_parent, children(full_name))
    `)
    .eq('file_type', 'photo')
    .eq('observations.is_visible_to_parent', true)
    .order('created_at', { ascending: false })
    .limit(48)

  if (activeChild.value) {
    query = query.eq('observations.child_id', activeChild.value)
  }

  const { data } = await query
  return data ?? []
}, { watch: [activeChild] })

const activePhoto = ref<{ file_url: string; caption?: string } | null>(null)
function openPhoto(photo: { file_url: string; caption?: string }) { activePhoto.value = photo }
</script>
