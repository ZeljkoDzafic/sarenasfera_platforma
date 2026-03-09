import type { UserRole } from '~/composables/useAuth'

export default defineNuxtRouteMiddleware(async (to) => {
  const { isAuthenticated, loading, init, role } = useAuth()

  if (loading.value) {
    await init()
  }

  if (!isAuthenticated.value) {
    return navigateTo('/auth/login')
  }

  // Check route-specific role requirements
  const path = to.path

  if (path.startsWith('/portal') && role.value !== 'parent' && role.value !== 'admin') {
    return navigateTo('/admin')
  }

  if (path.startsWith('/admin') && role.value !== 'staff' && role.value !== 'admin') {
    return navigateTo('/portal')
  }
})
