import { expect, test, type Page } from '@playwright/test'
import { createClient } from '@supabase/supabase-js'
import { loadWorkspaceEnv } from './support/env'

const workspaceEnv = loadWorkspaceEnv()

const appBaseUrl = process.env.PLAYWRIGHT_BASE_URL ?? 'http://127.0.0.1:3005'
const supabaseUrl = process.env.NUXT_PUBLIC_SUPABASE_URL ?? 'http://127.0.0.1:54321'
const anonKey = process.env.NUXT_PUBLIC_SUPABASE_ANON_KEY ?? workspaceEnv.ANON_KEY ?? ''
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY ?? workspaceEnv.SERVICE_ROLE_KEY ?? ''
const mailpitUrl = process.env.MAILPIT_URL ?? 'http://127.0.0.1:8025'

if (!anonKey) {
  throw new Error('Missing local Supabase anon key for Playwright auth tests')
}

if (!serviceRoleKey) {
  throw new Error('Missing local Supabase service role key for Playwright auth tests')
}

const adminClient = createClient(supabaseUrl, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
})

const stamp = Date.now()
const parentEmail = `auth-parent-${stamp}@example.test`
const parentPassword = 'ParentPass!123'
const parentNewPassword = 'ParentPass!456'
const staffEmail = `auth-staff-${stamp}@example.test`
const staffPassword = 'StaffPass!123'
const adminEmail = `auth-admin-${stamp}@example.test`
const adminPassword = 'AdminPass!123'

const createdUserIds = new Set<string>()

async function createRoleUser(role: 'staff' | 'admin', email: string, password: string, fullName: string) {
  const { data, error } = await adminClient.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName },
    app_metadata: { role },
  })

  if (error) {
    throw error
  }

  if (!data.user) {
    throw new Error(`Expected ${role} user to be created`)
  }

  createdUserIds.add(data.user.id)

  const { error: profileError } = await adminClient
    .from('profiles')
    .update({ role, full_name: fullName })
    .eq('id', data.user.id)

  if (profileError) {
    throw profileError
  }

  return data.user
}

async function findProfileByEmail(email: string) {
  const { data, error } = await adminClient
    .from('profiles')
    .select('id, email, full_name, role')
    .eq('email', email)
    .maybeSingle()

  if (error) {
    throw error
  }

  return data
}

async function findParentChildData(parentId: string) {
  const { data, error } = await adminClient
    .from('parent_children')
    .select('parent_id, child_id, relationship')
    .eq('parent_id', parentId)
    .maybeSingle()

  if (error) {
    throw error
  }

  return data
}

async function findChildById(childId: string) {
  const { data, error } = await adminClient
    .from('children')
    .select('id, full_name, date_of_birth')
    .eq('id', childId)
    .maybeSingle()

  if (error) {
    throw error
  }

  return data
}

async function login(page: Page, email: string, password: string) {
  await page.goto('/auth/login')
  await page.locator('#email').fill(email)
  await page.locator('#password').fill(password)
  await page.getByRole('button', { name: /prijavite se/i }).click()
}

async function logout(page: Page) {
  await page.getByRole('button', { name: /odjava/i }).click()
  await expect(page).toHaveURL(/\/auth\/login/)
}

async function pollForResetLink(email: string) {
  const deadline = Date.now() + 30_000

  while (Date.now() < deadline) {
    const response = await fetch(`${mailpitUrl}/api/v1/messages`)
    const list = await response.json() as {
      messages?: Array<{ ID?: string; id?: string; To?: unknown; to?: unknown }>
    }

    const match = (list.messages ?? []).find((message) =>
      JSON.stringify(message.To ?? message.to ?? '').includes(email),
    )

    if (match) {
      const messageId = match.ID ?? match.id
      if (!messageId) break

      const detail = await fetch(`${mailpitUrl}/api/v1/message/${messageId}`).then((res) => res.json()) as {
        HTML?: string
        Text?: string
      }
      const htmlLinkMatch = detail.HTML?.match(/href="([^"]+)"/)
      const textLinkMatch = detail.Text?.match(/https?:\/\/[^\s"'<>]+/)
      const rawLink = htmlLinkMatch?.[1]?.replaceAll('&amp;', '&') ?? textLinkMatch?.[0]

      if (rawLink) {
        const resetLink = new URL(rawLink)
        const localGateway = new URL(supabaseUrl)

        if (
          ['127.0.0.1', 'localhost'].includes(resetLink.hostname)
          && !resetLink.port
        ) {
          resetLink.protocol = localGateway.protocol
          resetLink.host = localGateway.host
        }

        const redirectTo = resetLink.searchParams.get('redirect_to')
        if (!redirectTo || redirectTo === 'http://localhost:3000') {
          resetLink.searchParams.set('redirect_to', `${appBaseUrl}/auth/reset-password`)
        }

        return resetLink.toString()
      }
    }

    await new Promise((resolve) => setTimeout(resolve, 1000))
  }

  throw new Error(`No reset email found in Mailpit for ${email}`)
}

test.describe.serial('Auth E2E Checklist', () => {
  test.beforeAll(async () => {
    await createRoleUser('staff', staffEmail, staffPassword, 'Auth E2E Staff')
    await createRoleUser('admin', adminEmail, adminPassword, 'Auth E2E Admin')
  })

  test.afterAll(async () => {
    const parentProfile = await findProfileByEmail(parentEmail)
    if (parentProfile?.id) {
      createdUserIds.add(parentProfile.id)
    }

    for (const userId of createdUserIds) {
      await adminClient.auth.admin.deleteUser(userId)
    }
  })

  test('parent registration creates account, profile and first child onboarding', async ({ page }) => {
    await page.goto('/auth/register')
    await page.locator('#full-name').fill('Auth E2E Parent')
    await page.locator('#email').fill(parentEmail)
    await page.locator('#phone').fill('+38761111222')
    await page.locator('#password').fill(parentPassword)
    await page.locator('#password-confirm').fill(parentPassword)
    await page.getByRole('button', { name: /^Dodaj$/ }).click()
    await page.locator('#child-name').fill('Test Dijete')
    await page.locator('#child-dob').fill('2022-05-15')
    await page.locator('input[type="checkbox"]').first().check()
    await page.getByRole('button', { name: /kreiraj nalog/i }).click()

    await expect(page).toHaveURL(/\/portal/)

    const profile = await findProfileByEmail(parentEmail)
    expect(profile?.role).toBe('parent')
    expect(profile?.full_name).toBe('Auth E2E Parent')

    const relation = await findParentChildData(profile!.id)
    expect(relation?.relationship).toBe('parent')

    const child = await findChildById(relation!.child_id)
    expect(child?.full_name).toBe('Test Dijete')
    expect(child?.date_of_birth).toContain('2022-05-15')
  })

  test('parent login redirects to portal, session persists after refresh, logout returns to login', async ({ page }) => {
    await login(page, parentEmail, parentPassword)
    await expect(page).toHaveURL(/\/portal/)

    await page.reload()
    await expect(page).toHaveURL(/\/portal/)

    await logout(page)
  })

  test('password recovery resets password and allows login with the new password', async ({ page, browser }) => {
    await page.goto('/auth/forgot-password')
    await page.locator('#email').fill(parentEmail)
    await page.getByRole('button', { name: /pošalji reset link/i }).click()
    await expect(page.getByText(/link za reset je poslan/i)).toBeVisible()

    const resetLink = await pollForResetLink(parentEmail)

    await page.goto(resetLink)
    await page.locator('#password').fill(parentNewPassword)
    await page.locator('#confirm-password').fill(parentNewPassword)
    const passwordUpdate = page.waitForResponse((response) =>
      response.url().includes('/auth/v1/user') && response.request().method() === 'PUT' && response.status() === 200,
    )
    await page.getByRole('button', { name: /sačuvaj novu lozinku/i }).click()
    await passwordUpdate

    const freshContext = await browser.newContext()
    const freshPage = await freshContext.newPage()

    await login(freshPage, parentEmail, parentNewPassword)
    await expect(freshPage).toHaveURL(/\/portal/)

    await freshContext.close()
  })

  test('role routing sends staff to admin area', async ({ page }) => {
    await login(page, staffEmail, staffPassword)
    await expect(page).toHaveURL(/\/admin/)
    await expect(page.getByRole('heading', { name: /admin panel/i })).toBeVisible()

    await page.goto('/portal')
    await expect(page).toHaveURL(/\/admin/)
  })

  test('admin login routes to admin and admin pages render', async ({ browser }) => {
    const adminContext = await browser.newContext()
    const adminPage = await adminContext.newPage()

    await login(adminPage, adminEmail, adminPassword)
    await expect(adminPage).toHaveURL(/\/admin/)
    await expect(adminPage.getByRole('heading', { name: /admin panel/i })).toBeVisible()
    await adminPage.goto('/admin/users')
    await expect(adminPage).toHaveURL(/\/admin\/users/)

    await adminContext.close()
  })

  test('negative cases show expected routing and errors', async ({ page, browser }) => {
    await page.goto('/auth/login')
    await page.locator('#email').fill(parentEmail)
    await page.locator('#password').fill('WrongPass!123')
    await page.getByRole('button', { name: /prijavite se/i }).click()
    await expect(page.locator('.text-brand-red')).toBeVisible()

    await page.goto('/auth/register')
    await page.locator('#full-name').fill('Duplicate Parent')
    await page.locator('#email').fill(parentEmail)
    await page.locator('#password').fill(parentNewPassword)
    await page.locator('#password-confirm').fill(parentNewPassword)
    await page.locator('input[type="checkbox"]').first().check()
    await page.getByRole('button', { name: /kreiraj nalog/i }).click()
    await expect(page.locator('.text-brand-red')).toBeVisible()

    const guestContext = await browser.newContext()
    const guestPage = await guestContext.newPage()

    await guestPage.goto(`${appBaseUrl}/portal`)
    await expect(guestPage).toHaveURL(/\/auth\/login/)

    await guestPage.goto(`${appBaseUrl}/admin`)
    await expect(guestPage).toHaveURL(/\/auth\/login/)

    await guestContext.close()

    await login(page, parentEmail, parentNewPassword)
    await expect(page).toHaveURL(/\/portal/)
    await page.goto('/admin')
    await expect(page).toHaveURL(/\/portal/)
  })
})
