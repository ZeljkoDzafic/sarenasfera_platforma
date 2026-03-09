<template>
  <div class="bg-[linear-gradient(180deg,#fff7fb_0%,#ffffff_42%,#f7fbff_100%)] text-gray-900">
    <section class="relative overflow-hidden px-4 pb-20 pt-16 sm:px-6 lg:px-8">
      <div class="absolute inset-x-0 top-0 -z-10 h-72 bg-[radial-gradient(circle_at_top,#f78da733,transparent_55%),radial-gradient(circle_at_top_right,#0693e322,transparent_35%),radial-gradient(circle_at_left,#9b51e01f,transparent_40%)]" />
      <div class="mx-auto grid max-w-6xl gap-10 lg:grid-cols-[1.15fr_0.85fr] lg:items-center">
        <div>
          <p class="inline-flex rounded-full bg-white/90 px-4 py-1 text-sm font-semibold text-primary-700 shadow-sm ring-1 ring-primary-100">
            Razvojni pasoš, radionice i podrška za roditelje
          </p>
          <h1 class="mt-6 font-display text-4xl font-bold tracking-tight text-gray-950 sm:text-5xl">
            Jedna platforma za praćenje razvoja djeteta od prve radionice do školskog polaska.
          </h1>
          <p class="mt-5 max-w-2xl text-lg leading-8 text-gray-600">
            Šarena Sfera spaja opservacije stručnog tima, razvojne domene, edukativne resurse i kućne aktivnosti u jasan roditeljski portal.
          </p>
          <div class="mt-8 flex flex-col gap-3 sm:flex-row">
            <NuxtLink to="/auth/register" class="btn-primary px-6 py-3 text-base">
              Kreiraj roditeljski račun
            </NuxtLink>
            <NuxtLink to="/events" class="btn-secondary px-6 py-3 text-base">
              Pogledaj radionice
            </NuxtLink>
          </div>
          <div class="mt-8 grid max-w-xl grid-cols-3 gap-3 text-sm">
            <div class="rounded-2xl bg-white p-4 shadow-sm ring-1 ring-gray-100">
              <div class="text-2xl font-bold text-primary-600">6</div>
              <div class="mt-1 text-gray-500">razvojnih domena</div>
            </div>
            <div class="rounded-2xl bg-white p-4 shadow-sm ring-1 ring-gray-100">
              <div class="text-2xl font-bold text-brand-green">1</div>
              <div class="mt-1 text-gray-500">dječiji pasoš</div>
            </div>
            <div class="rounded-2xl bg-white p-4 shadow-sm ring-1 ring-gray-100">
              <div class="text-2xl font-bold text-brand-amber">24/7</div>
              <div class="mt-1 text-gray-500">portal za roditelje</div>
            </div>
          </div>
        </div>

        <div class="grid gap-4">
          <div class="rounded-[28px] bg-gray-950 p-5 text-white shadow-2xl shadow-primary-200/50">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-xs uppercase tracking-[0.18em] text-white/60">Parent Portal</p>
                <h2 class="mt-1 text-xl font-bold">Razvojni pregled</h2>
              </div>
              <span class="rounded-full bg-white/10 px-3 py-1 text-xs font-semibold text-white/80">Premium UX</span>
            </div>
            <div class="mt-5 space-y-3">
              <div class="rounded-2xl bg-white/5 p-4">
                <div class="flex items-center justify-between text-sm">
                  <span class="text-white/70">Socijalni razvoj</span>
                  <span class="font-semibold text-brand-amber">napreduje</span>
                </div>
                <div class="mt-3 h-2 rounded-full bg-white/10">
                  <div class="h-2 w-[76%] rounded-full bg-brand-amber" />
                </div>
              </div>
              <div class="rounded-2xl bg-white/5 p-4">
                <div class="flex items-center justify-between text-sm">
                  <span class="text-white/70">Kućne aktivnosti</span>
                  <span class="font-semibold text-brand-green">2 nove</span>
                </div>
                <p class="mt-2 text-sm text-white/70">Preporuke nakon radionice i potvrda završetka od roditelja.</p>
              </div>
              <div class="rounded-2xl bg-gradient-to-r from-primary-500 to-brand-pink p-4">
                <p class="text-sm font-semibold">Sljedeća radionica</p>
                <p class="mt-1 text-lg font-bold">Motorički izazovi kroz igru</p>
                <p class="mt-1 text-sm text-white/85">Subota u 11:00 • Sarajevo</p>
              </div>
            </div>
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <div class="rounded-3xl bg-white p-5 shadow-sm ring-1 ring-gray-100">
              <p class="text-sm font-semibold text-primary-700">Za roditelje</p>
              <p class="mt-2 text-sm text-gray-600">Timeline napretka, verificirane opservacije i jasne preporuke za kuću.</p>
            </div>
            <div class="rounded-3xl bg-white p-5 shadow-sm ring-1 ring-gray-100">
              <p class="text-sm font-semibold text-primary-700">Za tim</p>
              <p class="mt-2 text-sm text-gray-600">Admin, attendance, milestone tracking i sadržaj za edukaciju na jednom mjestu.</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="px-4 py-16 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-6xl">
        <div class="mb-8 flex items-end justify-between gap-4">
          <div>
            <p class="text-sm font-semibold uppercase tracking-[0.18em] text-primary-600">Zašto radi</p>
            <h2 class="mt-2 font-display text-3xl font-bold">Brzina za tim, jasnoća za roditelja.</h2>
          </div>
          <NuxtLink to="/pricing" class="text-sm font-semibold text-primary-600 hover:text-primary-700">
            Pogledaj pakete
          </NuxtLink>
        </div>

        <div class="grid gap-4 md:grid-cols-3">
          <article class="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-gray-100">
            <div class="text-3xl">🧠</div>
            <h3 class="mt-4 text-lg font-bold">Razvojni pasoš</h3>
            <p class="mt-2 text-sm leading-6 text-gray-600">Sve opservacije, milestone-i i domeni razvoja sabrani u jedan pregled po djetetu.</p>
          </article>
          <article class="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-gray-100">
            <div class="text-3xl">🎨</div>
            <h3 class="mt-4 text-lg font-bold">Radionice i edukacija</h3>
            <p class="mt-2 text-sm leading-6 text-gray-600">Online i offline događaji, kursevi, resursi i preporuke povezani s razvojnim potrebama.</p>
          </article>
          <article class="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-gray-100">
            <div class="text-3xl">🤝</div>
            <h3 class="mt-4 text-lg font-bold">Moderirana saradnja</h3>
            <p class="mt-2 text-sm leading-6 text-gray-600">Roditelji šalju kućne opservacije, tim validira i uključuje ih u zvanični razvojni trag.</p>
          </article>
        </div>
      </div>
    </section>

    <section class="px-4 pb-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-6xl rounded-[32px] bg-gray-950 px-6 py-10 text-white sm:px-10">
        <div class="flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
          <div class="max-w-2xl">
            <p class="text-sm font-semibold uppercase tracking-[0.18em] text-white/60">Spremno za prvi korak</p>
            <h2 class="mt-2 font-display text-3xl font-bold">Registracija, kviz ili direktna prijava na događaj.</h2>
            <p class="mt-3 text-sm leading-6 text-white/75">Ako želiš najbrži put do onboardinga, kreni od besplatnog kviza ili otvori račun i dodaj prvo dijete.</p>
          </div>
          <div class="flex flex-col gap-3 sm:flex-row">
            <NuxtLink to="/quiz" class="btn bg-white text-gray-950 hover:bg-gray-100 font-bold">
              Uradi kviz
            </NuxtLink>
            <NuxtLink to="/auth/register" class="btn border-2 border-white/20 bg-white/10 text-white hover:bg-white/15 font-bold">
              Registracija
            </NuxtLink>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
useSeoMeta({
  title: 'Šarena Sfera — Platforma za razvoj djece i podršku roditeljima',
  description: 'Praćenje razvoja djece, radionice, edukacija za roditelje i razvojni pasoš na jednoj platformi.',
  ogTitle: 'Šarena Sfera',
  ogDescription: 'Platforma za praćenje razvoja djece, radionice i roditeljski portal.',
})
</script>
