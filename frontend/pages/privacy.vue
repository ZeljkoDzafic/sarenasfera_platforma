<template>
  <section class="mx-auto max-w-4xl px-4 py-12">
    <div class="card space-y-6">
      <div>
        <p class="text-sm font-semibold uppercase tracking-[0.2em] text-primary-600">Pravni dokument</p>
        <h1 class="mt-2 text-3xl font-bold text-gray-900">Politika privatnosti</h1>
      </div>

      <p class="text-sm leading-7 text-gray-600">
        Šarena Sfera obrađuje podatke roditelja i djece isključivo za potrebe registracije, organizacije radionica,
        komunikacije sa porodicama i pružanja digitalnih funkcionalnosti platforme.
      </p>

      <div class="grid gap-4 md:grid-cols-2">
        <div class="rounded-2xl bg-gray-50 p-4">
          <h2 class="font-semibold text-gray-900">Koje podatke prikupljamo</h2>
          <p class="mt-2 text-sm text-gray-600">Kontakt podatke, osnovne podatke o djetetu, razvojne zapise i operativne podatke vezane za radionice.</p>
        </div>
        <div class="rounded-2xl bg-gray-50 p-4">
          <h2 class="font-semibold text-gray-900">Zašto ih koristimo</h2>
          <p class="mt-2 text-sm text-gray-600">Za registraciju, obavijesti, planiranje aktivnosti, razvojne izvještaje i unapređenje usluge.</p>
        </div>
      </div>

      <div class="rounded-2xl border border-primary-100 bg-primary-50 p-4 text-sm text-primary-800">
        Finalna pravna verzija treba biti potvrđena prije javnog produkcijskog lansiranja.
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
useSeoMeta({
  title: 'Politika privatnosti — Šarena Sfera',
  description: 'Pregled načina na koji Šarena Sfera obrađuje podatke korisnika.',
})
</script>
