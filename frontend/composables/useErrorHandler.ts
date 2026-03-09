// composable/useErrorHandler.ts
// Centralized error handling with user-friendly messages

export type ErrorType = 'auth' | 'validation' | 'network' | 'permission' | 'unknown'

interface UserFriendlyError {
  type: ErrorType
  title: string
  message: string
  action?: string
  retryable?: boolean
}

const errorMessages: Record<string, UserFriendlyError> = {
  // Auth errors
  'Invalid login credentials': {
    type: 'auth',
    title: 'Pogrešna prijava',
    message: 'Provjerite email i lozinku.',
    retryable: true,
  },
  'Email not confirmed': {
    type: 'auth',
    title: 'Email nije potvrđen',
    message: 'Provjerite inbox i potvrdite email adresu.',
    action: 'Pošalji ponovo',
  },
  'User already registered': {
    type: 'auth',
    title: 'Email već postoji',
    message: 'Ova email adresa je već registrovana.',
    action: 'Prijavi se',
  },
  
  // Permission errors
  'permission_denied': {
    type: 'permission',
    title: 'Nemate pristup',
    message: 'Nemate dozvolu za ovu akciju.',
  },
  'JWT expired': {
    type: 'permission',
    title: 'Sesija istekla',
    message: 'Prijavite se ponovo.',
    action: 'Prijava',
    retryable: true,
  },
  
  // Network errors
  'NetworkError': {
    type: 'network',
    title: 'Problem sa konekcijom',
    message: 'Provjerite internet konekciju.',
    retryable: true,
  },
  'timeout': {
    type: 'network',
    title: 'Zahtjev istekao',
    message: 'Server ne odgovara. Pokušajte ponovo.',
    retryable: true,
  },
  
  // Validation errors
  'violates_not_null_constraint': {
    type: 'validation',
    title: 'Nedostaju podaci',
    message: 'Popunite sva obavezna polja.',
  },
  'violates_unique_constraint': {
    type: 'validation',
    title: 'Duplikat',
    message: 'Ova vrijednost već postoji.',
  },
  'violates_foreign_key_constraint': {
    type: 'validation',
    title: 'Nevažeći podatak',
    message: 'Referencirani podatak ne postoji.',
  },
  'violates_check_constraint': {
    type: 'validation',
    title: 'Nevažeći unos',
    message: 'Unesena vrijednost nije validna.',
  },
}

export function useErrorHandler() {
  const toast = useToast()

  function getSupabaseErrorCode(error: any): string {
    return error?.code || error?.message || 'unknown'
  }

  function getUserFriendlyError(error: any): UserFriendlyError {
    const code = getSupabaseErrorCode(error)
    
    // Check if we have a predefined message
    if (errorMessages[code]) {
      return errorMessages[code]
    }
    
    // Check for partial matches
    for (const [key, value] of Object.entries(errorMessages)) {
      if (code.toLowerCase().includes(key.toLowerCase())) {
        return value
      }
    }
    
    // Default unknown error
    return {
      type: 'unknown',
      title: 'Greška',
      message: 'Došlo je do neočekivane greške. Pokušajte ponovo.',
      retryable: true,
    }
  }

  function handleError(error: any, context?: string) {
    const friendlyError = getUserFriendlyError(error)
    
    // Log to console (in development)
    if (import.meta.dev) {
      console.error(`[${context || 'Error'}]`, error)
    }
    
    // Log to audit trail (for security-related errors)
    if (friendlyError.type === 'permission' || friendlyError.type === 'auth') {
      logErrorToAudit(error, context)
    }
    
    // Show user-friendly toast
    toast.add({
      title: friendlyError.title,
      description: friendlyError.message,
      icon: 'i-heroicons-exclamation-circle',
      color: 'red',
      duration: 5000,
      actions: friendlyError.action ? [{
        label: friendlyError.action,
        click: () => {
          // Handle action
        }
      }] : undefined,
    })
    
    return friendlyError
  }

  async function logErrorToAudit(error: any, context?: string) {
    if (!import.meta.client) return
    
    const supabase = useSupabase()
    const { user } = useAuth()
    
    try {
      await supabase.from('audit_logs').insert({
        user_id: user?.id,
        action: 'error',
        metadata: {
          context,
          error_code: error?.code,
          error_message: error?.message,
          timestamp: new Date().toISOString(),
        },
      })
    } catch {
      // Ignore logging errors
    }
  }

  function wrapRequest<T>(
    fn: () => Promise<T>,
    context?: string
  ): Promise<T> {
    return fn().catch((error) => {
      handleError(error, context)
      throw error // Re-throw for caller to handle
    })
  }

  return {
    handleError,
    getUserFriendlyError,
    wrapRequest,
    logErrorToAudit,
  }
}
