<template>
  <div class="min-h-screen bg-gradient-to-b from-primary-50 to-white">
    <!-- Hero section -->
    <section class="container mx-auto px-4 py-16 text-center">
      <div class="max-w-3xl mx-auto">
        <h1 class="font-display text-4xl md:text-5xl font-bold text-gray-900 mb-4">
          Preporuči Prijatelja i Zaradite
        </h1>
        <p class="text-lg text-gray-600 mb-8">
          Pozovite prijatelje da se pridruže Šarena Sfera platformi i oboje dobijate 
          <span class="font-semibold text-primary-600">1 mjesec Paid tier-a besplatno</span>!
        </p>
        
        <!-- CTA buttons -->
        <div class="flex flex-col sm:flex-row gap-4 justify-center mb-12">
          <NuxtLink to="/auth/register" class="btn-primary text-lg px-8 py-3">
            Registrujte se
          </NuxtLink>
          <NuxtLink to="/auth/login" class="btn-secondary text-lg px-8 py-3">
            Prijavite se
          </NuxtLink>
        </div>
        
        <!-- Stats -->
        <div class="grid grid-cols-3 gap-6 mb-12">
          <div class="card p-4">
            <div class="text-3xl font-bold text-primary-600 mb-1">500+</div>
            <div class="text-sm text-gray-600">Preporuka</div>
          </div>
          <div class="card p-4">
            <div class="text-3xl font-bold text-brand-green mb-1">85%</div>
            <div class="text-sm text-gray-600">Uspješnost</div>
          </div>
          <div class="card p-4">
            <div class="text-3xl font-bold text-brand-amber mb-1">1 KM</div>
            <div class="text-sm text-gray-600">Po preporuci</div>
          </div>
        </div>
      </div>
    </section>

    <!-- How it works -->
    <section class="container mx-auto px-4 py-16">
      <h2 class="font-display text-3xl font-bold text-center text-gray-900 mb-12">
        Kako funkcioniše?
      </h2>
      
      <div class="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
        <!-- Step 1 -->
        <div class="card text-center p-6">
          <div class="w-16 h-16 mx-auto mb-4 rounded-2xl bg-primary-100 flex items-center justify-center">
            <span class="text-2xl font-bold text-primary-600">1</span>
          </div>
          <h3 class="font-display font-bold text-lg text-gray-900 mb-2">Podijelite svoj link</h3>
          <p class="text-gray-600 text-sm">
            Nakon prijave, dobićete jedinstveni referral link koji možete podijeliti s prijateljima.
          </p>
        </div>
        
        <!-- Step 2 -->
        <div class="card text-center p-6">
          <div class="w-16 h-16 mx-auto mb-4 rounded-2xl bg-brand-amber/20 flex items-center justify-center">
            <span class="text-2xl font-bold text-brand-amber">2</span>
          </div>
          <h3 class="font-display font-bold text-lg text-gray-900 mb-2">Prijatelj se registruje</h3>
          <p class="text-gray-600 text-sm">
            Vaš prijatelj se registruje putem vašeg linka i kreira nalog za praćenje djetetovog razvoja.
          </p>
        </div>
        
        <!-- Step 3 -->
        <div class="card text-center p-6">
          <div class="w-16 h-16 mx-auto mb-4 rounded-2xl bg-brand-green/20 flex items-center justify-center">
            <span class="text-2xl font-bold text-brand-green">3</span>
          </div>
          <h3 class="font-display font-bold text-lg text-gray-900 mb-2">Oboje dobijate nagradu</h3>
          <p class="text-gray-600 text-sm">
            Kada se prijatelj pretplati na Paid tier, oboje dobijate 1 mjesec besplatno!
          </p>
        </div>
      </div>
    </section>

    <!-- Benefits -->
    <section class="container mx-auto px-4 py-16 bg-primary-50 rounded-3xl my-8">
      <h2 class="font-display text-3xl font-bold text-center text-gray-900 mb-12">
        Zašto preporučiti Šarenu Sferu?
      </h2>
      
      <div class="grid md:grid-cols-2 gap-6 max-w-4xl mx-auto">
        <div class="flex gap-4">
          <div class="w-10 h-10 rounded-xl bg-brand-green/20 flex items-center justify-center flex-shrink-0">
            <svg class="w-5 h-5 text-brand-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <div>
            <h3 class="font-bold text-gray-900 mb-1">Praćenje razvoja djeteta</h3>
            <p class="text-sm text-gray-600">6 domena razvoja u jednom digitalnom pasošu</p>
          </div>
        </div>
        
        <div class="flex gap-4">
          <div class="w-10 h-10 rounded-xl bg-brand-green/20 flex items-center justify-center flex-shrink-0">
            <svg class="w-5 h-5 text-brand-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <div>
            <h3 class="font-bold text-gray-900 mb-1">Ekskluzivne radionice</h3>
            <p class="text-sm text-gray-600">96 radionica godišnje za sve uzraste</p>
          </div>
        </div>
        
        <div class="flex gap-4">
          <div class="w-10 h-10 rounded-xl bg-brand-green/20 flex items-center justify-center flex-shrink-0">
            <svg class="w-5 h-5 text-brand-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <div>
            <h3 class="font-bold text-gray-900 mb-1">Kućne aktivnosti</h3>
            <p class="text-sm text-gray-600">Biblioteka aktivnosti za rad kod kuće</p>
          </div>
        </div>
        
        <div class="flex gap-4">
          <div class="w-10 h-10 rounded-xl bg-brand-green/20 flex items-center justify-center flex-shrink-0">
            <svg class="w-5 h-5 text-brand-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <div>
            <h3 class="font-bold text-gray-900 mb-1">Zajednica roditelja</h3>
            <p class="text-sm text-gray-600">Forum i podrška drugih roditelja</p>
          </div>
        </div>
      </div>
    </section>

    <!-- FAQ -->
    <section class="container mx-auto px-4 py-16">
      <h2 class="font-display text-3xl font-bold text-center text-gray-900 mb-12">
        Često postavljana pitanja
      </h2>
      
      <div class="max-w-3xl mx-auto space-y-4">
        <div class="card p-6">
          <h3 class="font-bold text-gray-900 mb-2">Koliko prijatelja mogu preporučiti?</h3>
          <p class="text-gray-600 text-sm">Nema ograničenja! Svaki uspješno preporučeni prijatelj vam donosi 1 mjesec Paid tier-a besplatno.</p>
        </div>
        
        <div class="card p-6">
          <h3 class="font-bold text-gray-900 mb-2">Šta ako moj prijatelj već ima nalog?</h3>
          <p class="text-gray-600 text-sm">Referral nagrada se odnosi samo na nove korisnike koji se registruju putem vašeg linka.</p>
        </div>
        
        <div class="card p-6">
          <h3 class="font-bold text-gray-900 mb-2">Kada dobijam nagradu?</h3>
          <p class="text-gray-600 text-sm">Nagrada se dodjeljuje automatski kada se vaš prijatelj pretplati na Paid tier.</p>
        </div>
        
        <div class="card p-6">
          <h3 class="font-bold text-gray-900 mb-2">Mogu li kombinovati više nagrada?</h3>
          <p class="text-gray-600 text-sm">Da! Možete skupiti više mjeseci besplatnog Paid tier-a.</p>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
useSeoMeta({
  title: 'Preporuči Prijatelja — Šarena Sfera',
  description: 'Pozovite prijatelje i zaradite besplatan pristup Šarena Sfera platformi.',
})
</script>
