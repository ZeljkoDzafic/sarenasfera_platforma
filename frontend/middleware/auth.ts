export default defineNuxtRouteMiddleware(async () => {
  const { isAuthenticated, loading, init } = useAuth()

  // Initialize auth if not done yet
  if (loading.value) {
    await init()
  }

  if (!isAuthenticated.value) {
    return navigateTo('/auth/login')
  }
})
