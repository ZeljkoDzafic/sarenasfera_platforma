<template>
  <section class="mx-auto max-w-4xl px-4 py-12">
    <div class="card space-y-6">
      <div>
        <p class="text-sm font-semibold uppercase tracking-[0.2em] text-primary-600">Pravni dokument</p>
        <h1 class="mt-2 text-3xl font-bold text-gray-900">Uslovi korištenja</h1>
      </div>

      <p class="text-sm leading-7 text-gray-600">
        Korištenjem platforme Šarena Sfera prihvatate pravila korištenja digitalnih sadržaja, komunikacije,
        registracije na događaje i zaštite podataka djece i roditelja.
      </p>

      <div class="grid gap-4 md:grid-cols-2">
        <div class="rounded-2xl bg-gray-50 p-4">
          <h2 class="font-semibold text-gray-900">Odgovorno korištenje</h2>
          <p class="mt-2 text-sm text-gray-600">Korisnici su odgovorni za tačnost dostavljenih podataka i za sigurno čuvanje pristupnih podataka.</p>
        </div>
        <div class="rounded-2xl bg-gray-50 p-4">
          <h2 class="font-semibold text-gray-900">Prava platforme</h2>
          <p class="mt-2 text-sm text-gray-600">Šarena Sfera zadržava pravo izmjene funkcionalnosti, cijena i uslova uz pravovremeno obavještavanje korisnika.</p>
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
  title: 'Uslovi korištenja — Šarena Sfera',
  description: 'Osnovni uslovi korištenja platforme Šarena Sfera.',
})
</script>
