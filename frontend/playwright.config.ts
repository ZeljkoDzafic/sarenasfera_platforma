import { defineConfig } from '@playwright/test'
import { loadWorkspaceEnv } from './test/e2e/support/env'

const workspaceEnv = loadWorkspaceEnv()
const baseURL = process.env.PLAYWRIGHT_BASE_URL ?? 'http://127.0.0.1:3008'

export default defineConfig({
  testDir: './test/e2e',
  fullyParallel: false,
  retries: 0,
  timeout: 90_000,
  expect: {
    timeout: 15_000,
  },
  use: {
    baseURL,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  webServer: {
    command: 'npm run dev -- --host 127.0.0.1 --port 3008',
    url: baseURL,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
    env: {
      ...process.env,
      NUXT_PUBLIC_SUPABASE_URL: process.env.NUXT_PUBLIC_SUPABASE_URL ?? 'http://127.0.0.1:54321',
      NUXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NUXT_PUBLIC_SUPABASE_ANON_KEY ?? workspaceEnv.ANON_KEY ?? '',
      NUXT_PUBLIC_API_URL: process.env.NUXT_PUBLIC_API_URL ?? 'http://127.0.0.1:8080',
    },
  },
})
