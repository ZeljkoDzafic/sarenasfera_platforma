// test/unit/composables/useErrorHandler.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest'

describe('useErrorHandler', () => {
  let mockToast: any
  let mockSupabase: any
  let mockUser: any

  beforeEach(() => {
    vi.clearAllMocks()
    
    mockUser = { ref: vi.fn(() => ({ value: { id: 'test-user' } })) }
    
    mockToast = {
      add: vi.fn()
    }

    mockSupabase = {
      from: vi.fn(() => ({
        insert: vi.fn(() => Promise.resolve({ error: null }))
      }))
    }

    vi.mock('~/composables/useSupabase', () => ({
      useSupabase: () => mockSupabase
    }))

    vi.mock('~/composables/useAuth', () => ({
      useAuth: () => ({ user: mockUser.ref })
    }))

    vi.mock('#app', () => ({
      useToast: () => mockToast
    }))
  })

  describe('getUserFriendlyError', () => {
    it('should return user-friendly message for auth errors', async () => {
      const useErrorHandler = await import('~/composables/useErrorHandler')
      const { getUserFriendlyError } = useErrorHandler.useErrorHandler()
      
      const error = { message: 'Invalid login credentials' }
      const friendly = getUserFriendlyError(error)
      
      expect(friendly.type).toBe('auth')
      expect(friendly.title).toBe('Pogrešna prijava')
      expect(friendly.retryable).toBe(true)
    })

    it('should return user-friendly message for permission errors', async () => {
      const useErrorHandler = await import('~/composables/useErrorHandler')
      const { getUserFriendlyError } = useErrorHandler.useErrorHandler()
      
      const error = { code: 'permission_denied' }
      const friendly = getUserFriendlyError(error)
      
      expect(friendly.type).toBe('permission')
      expect(friendly.title).toBe('Nemate pristup')
    })

    it('should return user-friendly message for network errors', async () => {
      const useErrorHandler = await import('~/composables/useErrorHandler')
      const { getUserFriendlyError } = useErrorHandler.useErrorHandler()
      
      const error = { message: 'NetworkError' }
      const friendly = getUserFriendlyError(error)
      
      expect(friendly.type).toBe('network')
      expect(friendly.title).toBe('Problem sa konekcijom')
      expect(friendly.retryable).toBe(true)
    })

    it('should return default message for unknown errors', async () => {
      const useErrorHandler = await import('~/composables/useErrorHandler')
      const { getUserFriendlyError } = useErrorHandler.useErrorHandler()
      
      const error = { message: 'Some random error' }
      const friendly = getUserFriendlyError(error)
      
      expect(friendly.type).toBe('unknown')
      expect(friendly.title).toBe('Greška')
      expect(friendly.retryable).toBe(true)
    })
  })

  describe('handleError', () => {
    it('should show toast notification', async () => {
      const useErrorHandler = await import('~/composables/useErrorHandler')
      const { handleError } = useErrorHandler.useErrorHandler()
      
      const error = { message: 'Invalid login credentials' }
      handleError(error, 'test_context')
      
      expect(mockToast.add).toHaveBeenCalled()
      expect(mockToast.add).toHaveBeenCalledWith(expect.objectContaining({
        color: 'red',
        duration: 5000
      }))
    })

    it('should log security errors to audit trail', async () => {
      const useErrorHandler = await import('~/composables/useErrorHandler')
      const { handleError } = useErrorHandler.useErrorHandler()
      
      const error = { code: 'permission_denied' }
      handleError(error, 'test_context')
      
      expect(mockSupabase.from).toHaveBeenCalledWith('audit_logs')
    })

    it('should not log non-security errors to audit trail', async () => {
      const useErrorHandler = await import('~/composables/useErrorHandler')
      const { handleError } = useErrorHandler.useErrorHandler()
      
      const error = { message: 'Some validation error' }
      handleError(error, 'test_context')
      
      // Should not call audit_logs for non-security errors
      const auditCalls = mockSupabase.from.mock.calls.filter(
        (call: any[]) => call[0] === 'audit_logs'
      )
      expect(auditCalls.length).toBe(0)
    })
  })

  describe('wrapRequest', () => {
    it('should return successful result', async () => {
      const useErrorHandler = await import('~/composables/useErrorHandler')
      const { wrapRequest } = useErrorHandler.useErrorHandler()
      
      const mockFn = vi.fn(() => Promise.resolve('success'))
      const result = await wrapRequest(mockFn, 'test')
      
      expect(result).toBe('success')
      expect(mockFn).toHaveBeenCalled()
    })

    it('should handle errors gracefully', async () => {
      const useErrorHandler = await import('~/composables/useErrorHandler')
      const { wrapRequest, handleError } = useErrorHandler.useErrorHandler()
      
      const mockFn = vi.fn(() => Promise.reject({ message: 'Error' }))
      
      await expect(wrapRequest(mockFn, 'test')).rejects.toThrow()
      expect(handleError).toHaveBeenCalled()
    })
  })

  describe('logErrorToAudit', () => {
    it('should log error with context', async () => {
      const useErrorHandler = await import('~/composables/useErrorHandler')
      const { logErrorToAudit } = useErrorHandler.useErrorHandler()
      
      const error = { code: 'test_code', message: 'Test error' }
      await logErrorToAudit(error, 'test_context')
      
      expect(mockSupabase.from).toHaveBeenCalledWith('audit_logs')
      expect(mockSupabase.from().insert).toHaveBeenCalledWith(expect.objectContaining({
        user_id: 'test-user',
        action: 'error',
      }))
    })

    it('should handle logging errors gracefully', async () => {
      const useErrorHandler = await import('~/composables/useErrorHandler')
      const { logErrorToAudit } = useErrorHandler.useErrorHandler()
      
      mockSupabase.from = vi.fn(() => ({
        insert: vi.fn(() => Promise.reject(new Error('Log failed')))
      }))
      
      const error = { message: 'Test error' }
      await logErrorToAudit(error, 'test_context')
      
      // Should not throw
      expect(true).toBe(true)
    })
  })
})
