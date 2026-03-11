import { expect, test, type Page } from '@playwright/test'
import { createClient } from '@supabase/supabase-js'
import { loadWorkspaceEnv } from './support/env'

const workspaceEnv = loadWorkspaceEnv()

const appBaseUrl = process.env.PLAYWRIGHT_BASE_URL ?? 'http://127.0.0.1:3008'
const supabaseUrl = process.env.NUXT_PUBLIC_SUPABASE_URL ?? 'http://127.0.0.1:54321'
const anonKey = process.env.NUXT_PUBLIC_SUPABASE_ANON_KEY ?? workspaceEnv.ANON_KEY ?? ''
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.NUXT_SUPABASE_SERVICE_KEY ?? workspaceEnv.SERVICE_ROLE_KEY ?? ''

if (!anonKey) {
  throw new Error('Missing local Supabase anon key for content/marketplace tests')
}

if (!serviceRoleKey) {
  throw new Error('Missing local Supabase service role key for content/marketplace tests')
}

const adminClient = createClient(supabaseUrl, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
})

const stamp = Date.now()
const adminEmail = `content-admin-${stamp}@example.test`
const adminPassword = 'AdminPass!123'
const parentEmail = `content-parent-${stamp}@example.test`
const parentPassword = 'ParentPass!123'
const blogTitle = `Playwright blog post ${stamp}`
const blogSlug = `playwright-blog-post-${stamp}`
const blogExcerpt = 'Playwright testira admin blog workflow i javni prikaz.'
const bazarTitle = `Playwright bazar oglas ${stamp}`

const createdUserIds = new Set<string>()

async function createRoleUser(role: 'admin' | 'parent', email: string, password: string, fullName: string) {
  const { data, error } = await adminClient.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName },
    app_metadata: { role },
  })

  if (error) throw error
  if (!data.user) throw new Error(`Expected ${role} user to be created`)

  createdUserIds.add(data.user.id)

  const { error: profileError } = await adminClient
    .from('profiles')
    .update({ role, full_name: fullName, email })
    .eq('id', data.user.id)

  if (profileError) throw profileError

  return data.user
}

async function login(page: Page, email: string, password: string) {
  await page.goto('/auth/login')
  await page.locator('#email').fill(email)
  await page.locator('#password').fill(password)
  await page.getByRole('button', { name: /prijavite se/i }).click()
}

test.describe.serial('Blog and Marketplace E2E', () => {
  test.beforeAll(async () => {
    await createRoleUser('admin', adminEmail, adminPassword, 'Content Admin')
    await createRoleUser('parent', parentEmail, parentPassword, 'Content Parent')
  })

  test.afterAll(async () => {
    await adminClient.from('blog_posts').delete().eq('slug', blogSlug)
    await adminClient.from('marketplace_items').delete().eq('title', bazarTitle)

    for (const userId of createdUserIds) {
      await adminClient.auth.admin.deleteUser(userId)
    }
  })

  test('public header includes bazar entry point', async ({ page }) => {
    await page.goto('/')

    const desktopBazarLink = page.locator('header').getByRole('link', { name: 'Bazar' }).first()
    await expect(desktopBazarLink).toHaveAttribute('href', '/auth/login?redirect=/portal/bazar')
  })

  test('admin can create a blog post and it appears publicly', async ({ page }) => {
    await login(page, adminEmail, adminPassword)
    await expect(page).toHaveURL(/\/admin/)

    await page.goto('/admin/blog/new')
    await page.getByPlaceholder('Naslov posta').fill(blogTitle)
    await page.getByPlaceholder('Kratki uvod / excerpt').fill(blogExcerpt)
    await page.getByPlaceholder('HTML ili rich text sadržaj').fill('<p>Ovo je testni blog sadržaj iz Playwright scenarija.</p>')
    await page.getByPlaceholder('Autor').fill('Playwright Admin')
    await page.getByPlaceholder('Kategorija').fill('Test kategorija')
    await page.getByPlaceholder('Tagovi odvojeni zarezom').fill('playwright, test')
    await page.getByLabel(/objavi post/i).check()
    await page.getByRole('button', { name: /kreiraj post/i }).click()

    await expect(page).toHaveURL(/\/admin\/blog$/)
    await expect(page.getByText(blogTitle)).toBeVisible()

    const { data: blogRow, error } = await adminClient
      .from('blog_posts')
      .select('slug, title, is_published, excerpt')
      .eq('slug', blogSlug)
      .maybeSingle()

    if (error) throw error

    expect(blogRow?.title).toBe(blogTitle)
    expect(blogRow?.is_published).toBe(true)
    expect(blogRow?.excerpt).toBe(blogExcerpt)

    await page.goto('/blog')
    await expect(page.getByText(blogTitle)).toBeVisible()
    await page.getByRole('link', { name: blogTitle }).click()
    await expect(page).toHaveURL(new RegExp(`/blog/${blogSlug}$`))
    await expect(page.getByText('Ovo je testni blog sadržaj iz Playwright scenarija.')).toBeVisible()
  })

  test('parent can create a bazar listing and it persists in backend', async ({ page }) => {
    await login(page, parentEmail, parentPassword)
    await expect(page).toHaveURL(/\/portal/)

    await page.goto('/portal/bazar')
    await page.getByRole('button', { name: /\+ dodaj oglas/i }).click()
    await page.getByPlaceholder('Naslov oglasa').fill(bazarTitle)
    await page.getByPlaceholder('Kategorija').fill('Igračke')
    await page.getByPlaceholder('Uzrast, npr. 0-1 god').fill('0-1 god')
    await page.getByPlaceholder('Lokacija').fill('Banja Luka')
    await page.getByPlaceholder('Cijena u BAM').fill('15')
    await page.getByPlaceholder('Kontakt email (opcionalno)').fill(parentEmail)
    await page.getByPlaceholder('Opis predmeta').fill('Testni bazar oglas kreiran kroz Playwright.')
    await page.getByRole('button', { name: /objavi oglas/i }).click()

    await expect(page.getByText(bazarTitle)).toBeVisible()
    await expect(page.getByText('Banja Luka')).toBeVisible()

    const { data: itemRow, error } = await adminClient
      .from('marketplace_items')
      .select('title, category, location_label, age_group_label, price')
      .eq('title', bazarTitle)
      .maybeSingle()

    if (error) throw error

    expect(itemRow?.category).toBe('Igračke')
    expect(itemRow?.location_label).toBe('Banja Luka')
    expect(itemRow?.age_group_label).toBe('0-1 god')
    expect(Number(itemRow?.price)).toBe(15)

    await page.reload()
    await expect(page.getByText(bazarTitle)).toBeVisible()
  })
})
