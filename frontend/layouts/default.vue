<template>
  <div class="min-h-screen flex flex-col">
    <!-- Public Navigation -->
    <header class="bg-white border-b border-gray-200 sticky top-0 z-50">
      <nav class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16 items-center">
          <NuxtLink to="/" class="flex items-center">
            <img :src="logoImage" alt="Šarena Sfera" class="h-10 w-auto">
          </NuxtLink>

          <!-- Desktop nav -->
          <div class="hidden md:flex items-center gap-6">
            <NuxtLink to="/program" class="text-gray-600 hover:text-primary-600 text-sm font-medium">
              Program
            </NuxtLink>
            <NuxtLink to="/events" class="text-gray-600 hover:text-primary-600 text-sm font-medium">
              Radionice
            </NuxtLink>
            <NuxtLink to="/quiz" class="text-gray-600 hover:text-primary-600 text-sm font-medium">
              Kviz
            </NuxtLink>
            <NuxtLink to="/pricing" class="text-gray-600 hover:text-primary-600 text-sm font-medium">
              Cjenovnik
            </NuxtLink>
            <NuxtLink to="/blog" class="text-gray-600 hover:text-primary-600 text-sm font-medium">
              Blog
            </NuxtLink>
            <NuxtLink to="/bazar" class="text-gray-600 hover:text-primary-600 text-sm font-medium">
              Bazar
            </NuxtLink>
            <NuxtLink to="/#o-nama" class="text-gray-600 hover:text-primary-600 text-sm font-medium">
              O nama
            </NuxtLink>
            <NuxtLink to="/contact" class="text-gray-600 hover:text-primary-600 text-sm font-medium">
              Kontakt
            </NuxtLink>
          </div>

          <div class="hidden md:flex items-center gap-3">
            <NuxtLink to="/auth/login" class="btn-secondary text-sm">
              Prijava
            </NuxtLink>
            <NuxtLink to="/auth/register" class="btn-primary text-sm">
              Registracija
            </NuxtLink>
          </div>

          <!-- Mobile menu button -->
          <button
            class="md:hidden p-2 rounded-lg text-gray-600 hover:bg-gray-100"
            @click="mobileMenuOpen = !mobileMenuOpen"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                v-if="!mobileMenuOpen"
                stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M4 6h16M4 12h16M4 18h16"
              />
              <path
                v-else
                stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <!-- Mobile menu -->
        <div v-if="mobileMenuOpen" class="md:hidden pb-4 space-y-2">
          <NuxtLink to="/program" class="block px-3 py-2 rounded-lg text-gray-600 hover:bg-gray-100">
            Program
          </NuxtLink>
          <NuxtLink to="/events" class="block px-3 py-2 rounded-lg text-gray-600 hover:bg-gray-100">
            Radionice
          </NuxtLink>
          <NuxtLink to="/quiz" class="block px-3 py-2 rounded-lg text-gray-600 hover:bg-gray-100">
            Kviz
          </NuxtLink>
          <NuxtLink to="/pricing" class="block px-3 py-2 rounded-lg text-gray-600 hover:bg-gray-100">
            Cjenovnik
          </NuxtLink>
          <NuxtLink to="/blog" class="block px-3 py-2 rounded-lg text-gray-600 hover:bg-gray-100">
            Blog
          </NuxtLink>
          <NuxtLink to="/bazar" class="block px-3 py-2 rounded-lg text-gray-600 hover:bg-gray-100">
            Bazar
          </NuxtLink>
          <NuxtLink to="/#o-nama" class="block px-3 py-2 rounded-lg text-gray-600 hover:bg-gray-100">
            O nama
          </NuxtLink>
          <NuxtLink to="/contact" class="block px-3 py-2 rounded-lg text-gray-600 hover:bg-gray-100">
            Kontakt
          </NuxtLink>
          <div class="flex gap-2 pt-2">
            <NuxtLink to="/auth/login" class="btn-secondary text-sm flex-1 text-center">
              Prijava
            </NuxtLink>
            <NuxtLink to="/auth/register" class="btn-primary text-sm flex-1 text-center">
              Registracija
            </NuxtLink>
          </div>
        </div>
      </nav>
    </header>

    <!-- Main content -->
    <main class="flex-1">
      <slot />
    </main>

    <!-- Footer -->
    <footer class="bg-gray-900 text-gray-400 py-12 mt-auto">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
          <!-- Brand -->
          <div class="md:col-span-2">
            <div class="flex items-center mb-3">
              <img :src="logoImage" alt="Šarena Sfera" class="h-8 w-auto">
            </div>
            <p class="text-sm text-gray-400 mb-4">
              Dječija knjižara, kreativno-edukativni kutak i roditeljski portal za razvoj, radionice i zajednicu.
            </p>
            <p class="text-sm text-gray-500 mb-4">
              Operativno poslovanje kroz <a href="https://technetis.net" target="_blank" rel="noreferrer" class="hover:text-white underline">Technetis s.p.</a>
            </p>
            <div class="flex gap-3">
              <a href="https://www.facebook.com/sharer/sharer.php?u=sarenasfera.com/" target="_blank" rel="noreferrer" class="text-gray-400 hover:text-white transition-colors">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
              </a>
              <a href="mailto:info@sarenasfera.com" class="text-gray-400 hover:text-white transition-colors">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/></svg>
              </a>
              <a href="https://www.instagram.com/sarenasfera" target="_blank" rel="noreferrer" class="text-gray-400 hover:text-white transition-colors">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 0C8.74 0 8.333.015 7.053.072 5.775.132 4.905.333 4.14.63c-.789.306-1.459.717-2.126 1.384S.935 3.35.63 4.14C.333 4.905.131 5.775.072 7.053.012 8.333 0 8.74 0 12s.015 3.667.072 4.947c.06 1.277.261 2.148.558 2.913.306.788.717 1.459 1.384 2.126.667.666 1.336 1.079 2.126 1.384.766.296 1.636.499 2.913.558C8.333 23.988 8.74 24 12 24s3.667-.015 4.947-.072c1.277-.06 2.148-.262 2.913-.558.788-.306 1.459-.718 2.126-1.384.666-.667 1.079-1.335 1.384-2.126.296-.765.499-1.636.558-2.913.06-1.28.072-1.687.072-4.947s-.015-3.667-.072-4.947c-.06-1.277-.262-2.149-.558-2.913-.306-.789-.718-1.459-1.384-2.126C21.31 1.347 20.651.935 19.86.63c-.765-.297-1.636-.499-2.913-.558C15.667.012 15.26 0 12 0zm0 2.16c3.203 0 3.585.016 4.85.071 1.17.055 1.805.249 2.227.415.562.217.96.477 1.382.896.419.42.679.819.896 1.381.164.422.36 1.057.413 2.227.057 1.266.07 1.646.07 4.85s-.015 3.585-.074 4.85c-.061 1.17-.256 1.805-.421 2.227-.224.562-.479.96-.899 1.382-.419.419-.824.679-1.38.896-.42.164-1.065.36-2.235.413-1.274.057-1.649.07-4.859.07-3.211 0-3.586-.015-4.859-.074-1.171-.061-1.816-.256-2.236-.421-.569-.224-.96-.479-1.379-.899-.421-.419-.69-.824-.9-1.38-.165-.42-.359-1.065-.42-2.235-.045-1.26-.061-1.649-.061-4.844 0-3.196.016-3.586.061-4.861.061-1.17.255-1.814.42-2.234.21-.57.479-.96.9-1.381.419-.419.81-.689 1.379-.898.42-.166 1.051-.361 2.221-.421 1.275-.045 1.65-.06 4.859-.06l.045.03zm0 3.678c-3.405 0-6.162 2.76-6.162 6.162 0 3.405 2.76 6.162 6.162 6.162 3.405 0 6.162-2.76 6.162-6.162 0-3.405-2.76-6.162-6.162-6.162zM12 16c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4zm7.846-10.405c0 .795-.646 1.44-1.44 1.44-.795 0-1.44-.646-1.44-1.44 0-.794.646-1.439 1.44-1.439.793-.001 1.44.645 1.44 1.439z"/></svg>
              </a>
            </div>
          </div>

          <!-- Quick Links -->
          <div>
            <h3 class="text-white font-semibold mb-3">Linkovi</h3>
            <ul class="space-y-2 text-sm">
              <li><NuxtLink to="/program" class="hover:text-white transition-colors">Program</NuxtLink></li>
              <li><NuxtLink to="/events" class="hover:text-white transition-colors">Radionice</NuxtLink></li>
              <li><NuxtLink to="/pricing" class="hover:text-white transition-colors">Cjenovnik</NuxtLink></li>
              <li><NuxtLink to="/quiz" class="hover:text-white transition-colors">Kviz</NuxtLink></li>
              <li><NuxtLink to="/blog" class="hover:text-white transition-colors">Blog</NuxtLink></li>
              <li><NuxtLink to="/bazar" class="hover:text-white transition-colors">Bazar</NuxtLink></li>
              <li><NuxtLink to="/#o-nama" class="hover:text-white transition-colors">O nama</NuxtLink></li>
            </ul>
          </div>

          <!-- Contact -->
          <div>
            <h3 class="text-white font-semibold mb-3">Kontakt</h3>
            <ul class="space-y-2 text-sm">
              <li class="text-gray-400">Bulevar vojvode Stepe Stepanovića 177, Banja Luka</li>
              <li><a href="mailto:info@sarenasfera.com" class="hover:text-white transition-colors">info@sarenasfera.com</a></li>
              <li class="text-gray-400">Pon - Pet: 8:30 - 16:30</li>
              <li><NuxtLink to="/contact" class="hover:text-white transition-colors">Kontakt forma</NuxtLink></li>
              <li><NuxtLink to="/referrals" class="hover:text-white transition-colors">Preporuči prijatelja</NuxtLink></li>
            </ul>
          </div>
        </div>

        <div class="border-t border-gray-800 mt-8 pt-8 text-sm text-center text-gray-500">
          &copy; {{ new Date().getFullYear() }} Šarena Sfera. Sva prava zadržana.
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
const logoImage = '/logo.webp'

const mobileMenuOpen = ref(false)

// Close mobile menu on route change
const route = useRoute()
watch(() => route.path, () => {
  mobileMenuOpen.value = false
})
</script>
