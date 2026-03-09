<template>
  <div>
    <!-- Header -->
    <section class="bg-gradient-to-br from-primary-500 to-brand-blue py-16 px-4 text-white text-center">
      <div class="max-w-3xl mx-auto">
        <h1 class="font-display text-4xl font-bold mb-3">Kontakt</h1>
        <p class="text-white/90 text-lg">
          Imate pitanje? Javite nam se — odgovaramo u roku od 24 sata.
        </p>
      </div>
    </section>

    <section class="py-16 px-4">
      <div class="max-w-5xl mx-auto grid grid-cols-1 lg:grid-cols-5 gap-12">

        <!-- Contact Info -->
        <div class="lg:col-span-2 space-y-6">
          <div class="card">
            <h2 class="font-display font-bold text-xl text-gray-900 mb-6">Pronađite nas</h2>
            <div class="space-y-4">
              <div class="flex items-start gap-3">
                <div class="w-10 h-10 rounded-xl bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                </div>
                <div>
                  <p class="font-semibold text-gray-900 text-sm">Email</p>
                  <a href="mailto:info@sarenasfera.com" class="text-primary-600 hover:underline">info@sarenasfera.com</a>
                </div>
              </div>

              <div class="flex items-start gap-3">
                <div class="w-10 h-10 rounded-xl bg-brand-green/10 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-brand-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                  </svg>
                </div>
                <div>
                  <p class="font-semibold text-gray-900 text-sm">Telefon / WhatsApp</p>
                  <a href="tel:+38761000000" class="text-gray-600">+387 61 000 000</a>
                </div>
              </div>

              <div class="flex items-start gap-3">
                <div class="w-10 h-10 rounded-xl bg-brand-amber/10 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-brand-amber" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </div>
                <div>
                  <p class="font-semibold text-gray-900 text-sm">Lokacija</p>
                  <p class="text-gray-600">Sarajevo, Bosna i Hercegovina</p>
                </div>
              </div>
            </div>
          </div>

          <div class="card">
            <h3 class="font-semibold text-gray-900 mb-3">Radno vrijeme</h3>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-gray-600">Pon – Pet</span>
                <span class="font-semibold">09:00 – 17:00</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600">Subota</span>
                <span class="font-semibold">09:00 – 13:00</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600">Nedjelja</span>
                <span class="text-gray-400">Zatvoreno</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Contact Form -->
        <div class="lg:col-span-3">
          <div class="card">
            <h2 class="font-display font-bold text-xl text-gray-900 mb-6">Pošaljite poruku</h2>

            <div v-if="submitted" class="text-center py-8">
              <div class="w-16 h-16 rounded-full bg-brand-green/10 flex items-center justify-center mx-auto mb-4">
                <svg class="w-8 h-8 text-brand-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <h3 class="font-bold text-xl text-gray-900 mb-2">Poruka je poslana!</h3>
              <p class="text-gray-600">Odgovorićemo vam u roku od 24 sata.</p>
              <button class="mt-4 btn-secondary" @click="submitted = false">Pošalji novu poruku</button>
            </div>

            <form v-else class="space-y-5" @submit.prevent="submitContact">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                <div>
                  <label class="label">Ime i prezime *</label>
                  <input v-model="form.name" type="text" class="input" placeholder="Vaše ime" required />
                </div>
                <div>
                  <label class="label">Email adresa *</label>
                  <input v-model="form.email" type="email" class="input" placeholder="vas@email.com" required />
                </div>
              </div>

              <div>
                <label class="label">Tema poruke</label>
                <select v-model="form.subject" class="input">
                  <option value="">Odaberite temu...</option>
                  <option value="info">Informacije o programu</option>
                  <option value="registration">Upis djeteta</option>
                  <option value="subscription">Pretplata i plaćanje</option>
                  <option value="technical">Tehnički problem</option>
                  <option value="other">Ostalo</option>
                </select>
              </div>

              <div>
                <label class="label">Poruka *</label>
                <textarea
                  v-model="form.message"
                  class="input"
                  rows="5"
                  placeholder="Vaša poruka..."
                  required
                />
              </div>

              <div class="flex items-start gap-2">
                <input
                  v-model="form.newsletter"
                  id="newsletter"
                  type="checkbox"
                  class="mt-1 rounded text-primary-500"
                />
                <label for="newsletter" class="text-sm text-gray-600 cursor-pointer">
                  Prijavite me na newsletter — savjeti o dječijem razvoju, vijesti o programu.
                </label>
              </div>

              <button type="submit" class="btn-primary w-full" :disabled="loading">
                <span v-if="loading">Šalje se...</span>
                <span v-else>Pošalji poruku</span>
              </button>

              <p v-if="error" class="text-brand-red text-sm text-center">{{ error }}</p>
            </form>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
useSeoMeta({
  title: 'Kontakt — Šarena Sfera',
  description: 'Kontaktirajte Šarenu Sferu. Odgovaramo u roku od 24 sata.',
})

const form = reactive({
  name: '',
  email: '',
  subject: '',
  message: '',
  newsletter: false,
})

const loading = ref(false)
const submitted = ref(false)
const error = ref('')

async function submitContact() {
  loading.value = true
  error.value = ''

  try {
    const supabase = useSupabase()
    await supabase.from('leads').insert({
      email: form.email,
      name: form.name,
      source: 'contact_form',
      metadata: {
        subject: form.subject,
        message: form.message,
        newsletter: form.newsletter,
      },
    })

    submitted.value = true
    Object.assign(form, { name: '', email: '', subject: '', message: '', newsletter: false })
  } catch (err) {
    error.value = 'Došlo je do greške. Pokušajte ponovo ili nas kontaktirajte direktno.'
  } finally {
    loading.value = false
  }
}
</script>
