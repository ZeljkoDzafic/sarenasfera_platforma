import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database'

let client: SupabaseClient<Database> | null = null

export function useSupabase() {
  const config = useRuntimeConfig()

  if (!client) {
    client = createClient<Database>(
      config.public.supabaseUrl,
      config.public.supabaseAnonKey,
      {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true,
        },
      }
    )
  }

  return client
}
