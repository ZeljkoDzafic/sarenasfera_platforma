import type { Config } from 'tailwindcss'

export default {
  content: [
    './components/**/*.{vue,ts}',
    './layouts/**/*.vue',
    './pages/**/*.vue',
    './composables/**/*.ts',
    './plugins/**/*.ts',
    './app.vue',
  ],
  theme: {
    extend: {
      colors: {
        // Brand colors from sarenasfera.com — "Šarena" = "Colorful"
        // Logo: use /public/logo.svg (or logo.png) from sarenasfera.com
        brand: {
          red: '#cf2e2e',        // vivid red — CTAs, alerts
          blue: '#0693e3',       // cyan-blue — links, info
          purple: '#9b51e0',     // vivid purple — premium, highlights
          pink: '#f78da7',       // pale pink — soft accents, badges
          amber: '#fcb900',      // luminous amber — warnings, stars
          green: '#00d084',      // vivid green-cyan — success, progress
        },
        // Primary action color (purple from brand)
        primary: {
          50: '#faf5ff',
          100: '#f3e8ff',
          200: '#e9d5ff',
          300: '#d8b4fe',
          400: '#c084fc',
          500: '#9b51e0', // brand purple — main action color
          600: '#7c3aed',
          700: '#6d28d9',
          800: '#5b21b6',
          900: '#4c1d95',
          950: '#2e1065',
        },
        // Development domains — vivid, "šarene" colors
        domain: {
          emotional: '#cf2e2e', // brand red — heart, emotions
          social: '#fcb900',    // brand amber — warmth, connection
          creative: '#9b51e0',  // brand purple — imagination
          cognitive: '#0693e3', // brand blue — thinking, logic
          motor: '#00d084',     // brand green — movement, energy
          language: '#f78da7',  // brand pink — expression, voice
        },
      },
      fontFamily: {
        sans: ['Nunito', 'Inter', 'system-ui', '-apple-system', 'sans-serif'],
        display: ['Baloo 2', 'Nunito', 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        'xl': '1rem',
        '2xl': '1.5rem',
        '3xl': '2rem',
      },
      boxShadow: {
        'soft': '0 2px 15px -3px rgba(0, 0, 0, 0.07), 0 10px 20px -2px rgba(0, 0, 0, 0.04)',
        'card': '0 4px 20px rgba(0, 0, 0, 0.08)',
        'colorful': '0 4px 15px rgba(155, 81, 224, 0.15)',
      },
    },
  },
  plugins: [],
} satisfies Config
