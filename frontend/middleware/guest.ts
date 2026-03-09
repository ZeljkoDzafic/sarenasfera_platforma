export default defineNuxtRouteMiddleware(async () => {
  const { isAuthenticated, loading, init, role } = useAuth()

  if (loading.value) {
    await init()
  }

  if (isAuthenticated.value) {
    // Redirect to appropriate dashboard
    if (role.value === 'parent') {
      return navigateTo('/portal')
    }
    return navigateTo('/admin')
  }
})
