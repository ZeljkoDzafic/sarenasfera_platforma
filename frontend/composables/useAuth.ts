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

let authSubscription: { unsubscribe: () => void } | null = null

export function useAuth() {
  const supabase = useSupabase()

  async function resolveRole(session: Session | null): Promise<UserRole | null> {
    const metadataRole = session?.user?.app_metadata?.role as UserRole | undefined
    if (metadataRole) return metadataRole

    if (!session?.user) return null

    const { data } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', session.user.id)
      .maybeSingle()

    return (data?.role as UserRole | undefined) ?? null
  }

  // Initialize auth state
  async function init() {
    authState.loading = true
    try {
      const { data } = await supabase.auth.getSession()
      authState.session = data.session
      authState.user = data.session?.user ?? null
      authState.role = await resolveRole(data.session)
    } finally {
      authState.loading = false
    }

    // Listen for auth changes
    if (!authSubscription) {
      const { data: listener } = supabase.auth.onAuthStateChange(async (_event, session) => {
        authState.session = session
        authState.user = session?.user ?? null
        authState.role = await resolveRole(session)
        authState.loading = false
      })
      authSubscription = listener.subscription
    }
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
    authState.session = null
    authState.user = null
    authState.role = null
    return navigateTo('/auth/login')
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
    logout: signOut,
    resetPassword,
    updatePassword,
    resolveRole,
  }
}
