<template>
  <div>
    <section class="bg-gradient-to-br from-brand-green to-primary-500 px-4 py-16 text-white">
      <div class="mx-auto max-w-5xl text-center">
        <p class="text-sm font-semibold uppercase tracking-[0.18em] text-white/80">Besplatno za roditelje</p>
        <h1 class="mt-3 font-display text-4xl font-bold">Dječiji bazar i zajednica na jednom mjestu</h1>
        <p class="mx-auto mt-4 max-w-3xl text-lg text-white/90">
          Bazar je javno predstavljen ovdje, a nakon registracije dobijaš pristup besplatnom roditeljskom bazaru i zajednici za razmjenu iskustava, pitanja i preporuka.
        </p>
        <div class="mt-8 flex flex-col justify-center gap-3 sm:flex-row">
          <NuxtLink to="/auth/register?redirect=/portal/bazar" class="btn bg-white font-bold text-gray-950 hover:bg-gray-100">
            Registruj se besplatno
          </NuxtLink>
          <NuxtLink to="/auth/login?redirect=/portal/bazar" class="btn border-2 border-white/20 bg-white/10 font-bold text-white hover:bg-white/15">
            Prijava u portal
          </NuxtLink>
        </div>
        <p class="mt-4 text-sm text-white/80">
          Registracija je besplatna. Bazar i community ne traže dodatnu pretplatu.
        </p>
      </div>
    </section>

    <section class="px-4 py-16 sm:px-6 lg:px-8">
      <div class="mx-auto grid max-w-6xl gap-4 md:grid-cols-3">
        <article class="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-gray-100">
          <div class="text-3xl">🧸</div>
          <h2 class="mt-4 text-lg font-bold text-gray-900">Objavi oglas za minut</h2>
          <p class="mt-2 text-sm leading-6 text-gray-600">
            Dodaj naslov, opis, lokaciju i kontakt. Podržani su oglasi za prodaju, razmjenu i poklanjanje.
          </p>
        </article>
        <article class="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-gray-100">
          <div class="text-3xl">💬</div>
          <h2 class="mt-4 text-lg font-bold text-gray-900">Besplatna zajednica roditelja</h2>
          <p class="mt-2 text-sm leading-6 text-gray-600">
            Nakon registracije dobijaš pristup i community dijelu portala gdje roditelji dijele iskustva, savjete i preporuke.
          </p>
        </article>
        <article class="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-gray-100">
          <div class="text-3xl">📍</div>
          <h2 class="mt-4 text-lg font-bold text-gray-900">Lokalno i pregledno</h2>
          <p class="mt-2 text-sm leading-6 text-gray-600">
            Filtriraj oglase po lokaciji i brzo pronađi opremu u Banjoj Luci i okolini bez rasutih grupa i nepreglednih chatova.
          </p>
        </article>
      </div>
    </section>

    <section class="px-4 pb-16 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-6xl rounded-[32px] bg-white p-8 shadow-sm ring-1 ring-gray-100 sm:p-10">
        <div class="grid gap-6 lg:grid-cols-2">
          <div>
            <p class="text-sm font-semibold uppercase tracking-[0.18em] text-primary-600">Zašto se registrovati</p>
            <h2 class="mt-2 font-display text-3xl font-bold text-gray-900">Javni pregled, privatna akcija.</h2>
            <p class="mt-4 text-sm leading-7 text-gray-600">
              Javno možeš vidjeti šta je Bazar i zašto postoji. Registracijom otključavaš objavu oglasa, direktan kontakt, community diskusije i praktične alate unutar portala.
            </p>
          </div>
          <div class="grid gap-3 sm:grid-cols-2">
            <div class="rounded-2xl bg-primary-50 p-4 text-sm text-gray-700">Objava oglasa za prodaju, razmjenu i poklanjanje</div>
            <div class="rounded-2xl bg-brand-green/10 p-4 text-sm text-gray-700">Pregled oglasa drugih roditelja iz zajednice</div>
            <div class="rounded-2xl bg-brand-amber/15 p-4 text-sm text-gray-700">Community diskusije, savjeti i preporuke</div>
            <div class="rounded-2xl bg-brand-pink/10 p-4 text-sm text-gray-700">Sve bez dodatne naplate za bazar i zajednicu</div>
          </div>
        </div>
      </div>
    </section>

    <section class="px-4 pb-16 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-6xl rounded-[32px] bg-gray-950 px-6 py-10 text-white sm:px-10">
        <div class="grid gap-8 lg:grid-cols-[1fr_0.9fr] lg:items-center">
          <div>
            <p class="text-sm font-semibold uppercase tracking-[0.18em] text-white/60">Kako radi</p>
            <h2 class="mt-2 font-display text-3xl font-bold">Jednostavan tok bez viška administracije.</h2>
            <div class="mt-6 space-y-4 text-sm text-white/80">
              <p>1. Registruješ se besplatno i ulaziš u portal.</p>
              <p>2. Objaviš oglas ili otvoriš community diskusiju sa osnovnim informacijama.</p>
              <p>3. Drugi roditelji pregledaju sadržaj i javljaju ti se direktno.</p>
            </div>
          </div>
          <div class="rounded-3xl bg-white/5 p-6 ring-1 ring-white/10">
            <h3 class="text-lg font-bold">Šta ide u bazar</h3>
            <div class="mt-4 grid gap-3 sm:grid-cols-2">
              <div class="rounded-2xl bg-white/5 p-4">Knjige i slikovnice</div>
              <div class="rounded-2xl bg-white/5 p-4">Igračke i didaktika</div>
              <div class="rounded-2xl bg-white/5 p-4">Oprema za bebe</div>
              <div class="rounded-2xl bg-white/5 p-4">Odjeća i obuća</div>
            </div>
            <p class="mt-4 text-xs text-white/60">
              Kontakt i preuzimanje dogovaraju roditelji međusobno. Platforma služi kao oglasni i community prostor unutar Šarene Sfere.
            </p>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
useSeoMeta({
  title: 'Dječiji bazar — Šarena Sfera',
  description: 'Javna info stranica za Dječiji bazar i zajednicu: besplatan prostor za razmjenu, poklanjanje, prodaju i povezivanje roditelja.',
  ogTitle: 'Dječiji bazar — Šarena Sfera',
})
</script>
