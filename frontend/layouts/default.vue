<template>
  <div class="min-h-screen flex flex-col">
    <!-- Public Navigation -->
    <header class="bg-white border-b border-gray-200">
      <nav class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16 items-center">
          <NuxtLink to="/" class="flex items-center gap-2">
            <div class="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
              <span class="text-white font-bold text-sm">ŠS</span>
            </div>
            <span class="text-xl font-bold text-gray-900">Šarena Sfera</span>
          </NuxtLink>

          <!-- Desktop nav -->
          <div class="hidden md:flex items-center gap-6">
            <NuxtLink to="/program" class="text-gray-600 hover:text-primary-600 text-sm font-medium">
              Program
            </NuxtLink>
            <NuxtLink to="/blog" class="text-gray-600 hover:text-primary-600 text-sm font-medium">
              Blog
            </NuxtLink>
            <NuxtLink to="/resources" class="text-gray-600 hover:text-primary-600 text-sm font-medium">
              Resursi
            </NuxtLink>
            <NuxtLink to="/contact" class="text-gray-600 hover:text-primary-600 text-sm font-medium">
              Kontakt
            </NuxtLink>
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
          <NuxtLink to="/blog" class="block px-3 py-2 rounded-lg text-gray-600 hover:bg-gray-100">
            Blog
          </NuxtLink>
          <NuxtLink to="/resources" class="block px-3 py-2 rounded-lg text-gray-600 hover:bg-gray-100">
            Resursi
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
    <footer class="bg-gray-900 text-gray-400 py-12">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div>
            <h3 class="text-white font-semibold mb-3">Šarena Sfera</h3>
            <p class="text-sm">Platforma za praćenje dječijeg razvoja kroz edukativne radionice.</p>
          </div>
          <div>
            <h3 class="text-white font-semibold mb-3">Linkovi</h3>
            <ul class="space-y-2 text-sm">
              <li><NuxtLink to="/program" class="hover:text-white">Program</NuxtLink></li>
              <li><NuxtLink to="/blog" class="hover:text-white">Blog</NuxtLink></li>
              <li><NuxtLink to="/contact" class="hover:text-white">Kontakt</NuxtLink></li>
            </ul>
          </div>
          <div>
            <h3 class="text-white font-semibold mb-3">Kontakt</h3>
            <p class="text-sm">info@sarenasfera.com</p>
          </div>
        </div>
        <div class="border-t border-gray-800 mt-8 pt-8 text-sm text-center">
          &copy; {{ new Date().getFullYear() }} Šarena Sfera. Sva prava zadržana.
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
const mobileMenuOpen = ref(false)

// Close mobile menu on route change
const route = useRoute()
watch(() => route.path, () => {
  mobileMenuOpen.value = false
})
</script>
