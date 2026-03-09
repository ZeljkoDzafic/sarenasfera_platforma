<template>
  <div class="space-y-6">
    <section class="card">
      <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Moja djeca</h1>
          <p class="text-sm text-gray-600">Pregled profila djece, grupa i brz pristup dječijem pasošu.</p>
        </div>
        <button class="btn-secondary">Dodaj dijete</button>
      </div>
    </section>

    <section class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
      <article v-for="child in children" :key="child.id" class="card-hover">
        <div class="mb-4 flex items-center gap-3">
          <div class="h-14 w-14 rounded-full border-2 border-primary-300 bg-primary-100" />
          <div>
            <h2 class="text-lg font-bold text-gray-900">{{ child.name }}</h2>
            <p class="text-sm text-gray-600">{{ child.age }} godina • {{ child.group }}</p>
          </div>
        </div>

        <div class="mb-4 flex flex-wrap gap-2">
          <span class="badge domain-bg-emotional text-domain-emotional">Emocionalni {{ child.snapshot.emotional }}</span>
          <span class="badge domain-bg-social text-domain-social">Socijalni {{ child.snapshot.social }}</span>
          <span class="badge domain-bg-language text-domain-language">Jezički {{ child.snapshot.language }}</span>
        </div>

        <NuxtLink :to="`/portal/children/${child.id}`" class="btn-primary w-full justify-center">Otvori profil</NuxtLink>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'portal' })

interface ChildSummary {
  id: string
  name: string
  age: number
  group: string
  snapshot: {
    emotional: string
    social: string
    language: string
  }
}

const children: ChildSummary[] = [
  {
    id: 'ana-1',
    name: 'Ana K.',
    age: 4,
    group: 'Srednja grupa',
    snapshot: { emotional: '4/5', social: '5/5', language: '5/5' },
  },
  {
    id: 'hamza-2',
    name: 'Hamza M.',
    age: 5,
    group: 'Velika grupa',
    snapshot: { emotional: '3/5', social: '4/5', language: '3/5' },
  },
]
</script>
