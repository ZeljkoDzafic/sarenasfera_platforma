// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-01-01',

  devtools: { enabled: true },

  modules: ['@nuxtjs/tailwindcss'],

  ssr: true,

  typescript: {
    strict: true,
    typeCheck: true,
  },

  runtimeConfig: {
    // Server-only (not exposed to client)
    supabaseServiceKey: '',
    // Public (exposed to client)
    public: {
      supabaseUrl: 'http://localhost:54321',
      supabaseAnonKey: '',
      apiUrl: 'http://localhost:8080',
      appName: 'Šarena Sfera',
    },
  },

  app: {
    head: {
      title: 'Šarena Sfera - Platforma za praćenje dječijeg razvoja',
      charset: 'utf-8',
      viewport: 'width=device-width, initial-scale=1',
      meta: [
        {
          name: 'description',
          content:
            'Online platforma za praćenje razvoja djece kroz edukativne radionice. 6 razvojnih domena, dječiji pasoš, opservacije.',
        },
        { name: 'theme-color', content: '#6366f1' },
      ],
      htmlAttrs: {
        lang: 'bs',
      },
    },
  },

  routeRules: {
    // Public pages — SSR for SEO
    '/': { prerender: true },
    '/program': { prerender: true },
    '/blog/**': { isr: 3600 }, // revalidate every hour
    '/contact': { prerender: true },
    '/resources': { prerender: true },

    // Auth pages — SPA mode
    '/auth/**': { ssr: false },

    // Portal — SPA mode (auth required, no SEO needed)
    '/portal/**': { ssr: false },

    // Admin — SPA mode (auth required, no SEO needed)
    '/admin/**': { ssr: false },
  },
})
