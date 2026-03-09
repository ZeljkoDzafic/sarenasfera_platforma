import type { User, Session } from '@supabase/supabase-js'

export type UserRole = 'parent' | 'staff' | 'admin' | 'expert'

interface AuthState {
  user: User | null
  session: Session | null
  role: UserRole | null
  loading: boolean
}

const authState = reactive<AuthState>({
  user: null,
  session: null,
  role: null,
  loading: true,
})

export function useAuth() {
  const supabase = useSupabase()

  // Initialize auth state
  async function init() {
    authState.loading = true
    try {
      const { data } = await supabase.auth.getSession()
      authState.session = data.session
      authState.user = data.session?.user ?? null
      authState.role = (data.session?.user?.app_metadata?.role as UserRole) ?? null
    } finally {
      authState.loading = false
    }

    // Listen for auth changes
    supabase.auth.onAuthStateChange((_event, session) => {
      authState.session = session
      authState.user = session?.user ?? null
      authState.role = (session?.user?.app_metadata?.role as UserRole) ?? null
    })
  }

  async function signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    if (error) throw error
    return data
  }

  async function signUp(email: string, password: string, metadata?: Record<string, unknown>) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: metadata },
    })
    if (error) throw error
    return data
  }

  async function signOut() {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
    navigateTo('/auth/login')
  }

  async function resetPassword(email: string) {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/reset-password`,
    })
    if (error) throw error
  }

  async function updatePassword(password: string) {
    const { error } = await supabase.auth.updateUser({ password })
    if (error) throw error
  }

  const isAuthenticated = computed(() => !!authState.session)
  const isParent = computed(() => authState.role === 'parent')
  const isStaff = computed(() => authState.role === 'staff' || authState.role === 'admin')
  const isAdmin = computed(() => authState.role === 'admin')

  return {
    ...toRefs(authState),
    isAuthenticated,
    isParent,
    isStaff,
    isAdmin,
    init,
    signIn,
    signUp,
    signOut,
    resetPassword,
    updatePassword,
  }
}
