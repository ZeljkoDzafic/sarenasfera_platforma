// components/app/ErrorBoundary.vue
// Global error boundary component

<template>
  <div v-if="error" class="min-h-screen flex items-center justify-center bg-gray-50 p-4">
    <div class="max-w-md w-full bg-white rounded-2xl shadow-card p-8 text-center">
      <!-- Error Icon -->
      <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-brand-red/10 flex items-center justify-center">
        <svg class="w-8 h-8 text-brand-red" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>

      <!-- Error Message -->
      <h1 class="font-display text-xl font-bold text-gray-900 mb-2">
        {{ errorInfo.title }}
      </h1>
      <p class="text-gray-600 text-sm mb-6">
        {{ errorInfo.message }}
      </p>

      <!-- Error Code (for support) -->
      <div v-if="error?.code" class="bg-gray-50 rounded-lg p-3 mb-6">
        <p class="text-xs text-gray-500 font-mono">
          Error code: {{ error.code }}
        </p>
      </div>

      <!-- Actions -->
      <div class="flex flex-col gap-3">
        <button
          v-if="errorInfo.retryable"
          class="btn-primary w-full"
          @click="retry"
        >
          Pokušaj ponovo
        </button>
        
        <NuxtLink
          v-if="errorInfo.action === 'Prijava'"
          to="/auth/login"
          class="btn-primary w-full"
        >
          {{ errorInfo.action }}
        </NuxtLink>
        
        <NuxtLink
          to="/"
          class="btn-secondary w-full"
        >
          Nazad na početnu
        </NuxtLink>
      </div>

      <!-- Support Link -->
      <div class="mt-6 text-xs text-gray-500">
        <p>Treba li pomoć?</p>
        <a href="mailto:support@sarenasfera.com" class="text-primary-600 hover:underline">
          Kontaktirajte support
        </a>
      </div>
    </div>
  </div>

  <slot v-else />
</template>

<script setup lang="ts">
type CapturedErrorHandler = (err: unknown, vm: unknown, info: string) => void

interface BoundaryError {
  message?: string
  stack?: string
  code?: string
}

interface BoundaryErrorInfo {
  title: string
  message: string
  retryable: boolean
  action: string
}

const error = ref<BoundaryError | null>(null)
const errorInfo = ref<BoundaryErrorInfo>({
  title: 'Greška',
  message: 'Došlo je do neočekivane greške.',
  retryable: false,
  action: '',
})

function toBoundaryError(value: unknown): BoundaryError {
  if (value instanceof Error) {
    return {
      message: value.message,
      stack: value.stack,
    }
  }

  if (value && typeof value === 'object') {
    return value as BoundaryError
  }

  return {
    message: typeof value === 'string' ? value : 'Nepoznata greška',
  }
}

// Vue error handler
const errorHandler: CapturedErrorHandler = (err, _vm, info) => {
  console.error('Vue Error:', err, info)
  error.value = toBoundaryError(err)
  const message = error.value.message ?? ''
  
  // Determine error type
  if (message.includes('Authentication')) {
    errorInfo.value = {
      title: 'Problem sa prijavom',
      message: 'Vaša sesija je istekla. Prijavite se ponovo.',
      retryable: false,
      action: 'Prijava',
    }
  } else if (message.includes('Network')) {
    errorInfo.value = {
      title: 'Problem sa konekcijom',
      message: 'Provjerite internet konekciju i pokušajte ponovo.',
      retryable: true,
      action: '',
    }
  } else if (message.includes('Permission')) {
    errorInfo.value = {
      title: 'Nemate pristup',
      message: 'Nemate dozvolu za pristup ovoj stranici.',
      retryable: false,
      action: '',
    }
  }
}

// Set global error handler
onMounted(() => {
  window.addEventListener('error', (event) => {
    console.error('Global Error:', event.error)
    error.value = toBoundaryError(event.error)
    errorInfo.value = {
      title: 'Greška u aplikaciji',
      message: 'Došlo je do tehničkog problema.',
      retryable: true,
      action: '',
    }
  })

  window.addEventListener('unhandledrejection', (event) => {
    console.error('Unhandled Promise Rejection:', event.reason)
  })
})

async function retry() {
  error.value = null
  window.location.reload()
}

// Log error to backend
watch(error, async (newError) => {
  if (!newError || !import.meta.client) return
  
  const supabase = useSupabase()
  const { user } = useAuth()
  
  try {
    await supabase.from('audit_logs').insert({
      user_id: user.value?.id,
      action: 'frontend_error',
      metadata: {
        error_message: newError.message,
        error_stack: newError.stack,
        url: window.location.href,
        user_agent: navigator.userAgent,
        timestamp: new Date().toISOString(),
      },
    })
  } catch {
    // Ignore logging errors
  }
})

onMounted(() => {
  const vueApp = useNuxtApp().vueApp
  vueApp.config.errorHandler = errorHandler
})
</script>
