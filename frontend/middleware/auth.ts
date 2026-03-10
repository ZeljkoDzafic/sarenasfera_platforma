export default defineNuxtRouteMiddleware(async (to) => {
  const { isAuthenticated, loading, init, role } = useAuth()

  // Initialize auth if not done yet
  if (loading.value) {
    await init()
  }

  if (!isAuthenticated.value) {
    return navigateTo('/auth/login')
  }

  if (to.path.startsWith('/portal') && role.value !== 'parent' && role.value !== 'admin') {
    return navigateTo('/admin')
  }

  if (to.path.startsWith('/admin') && role.value !== 'staff' && role.value !== 'admin') {
    return navigateTo('/portal')
  }
})
