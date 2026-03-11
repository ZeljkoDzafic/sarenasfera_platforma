import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'http://localhost:54321'
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic2FyZW5hc2ZlcmEtbG9jYWwiLCJpYXQiOjE3MDAwMDAwMDAsImV4cCI6MjA5OTk5OTk5OX0.aek88IZjaoZGK1K_KnmW6Kr12FHVi34xK_uJfRo7FLE'

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

const demoAccounts = [
  {
    email: 'demo-admin@sarenasfera.com',
    password: 'demo123',
    role: 'admin',
    tier: 'premium',
    full_name: 'Demo Admin'
  },
  {
    email: 'demo-staff@sarenasfera.com',
    password: 'demo123',
    role: 'staff',
    tier: 'free',
    full_name: 'Demo Edukator'
  },
  {
    email: 'demo-parent-free@sarenasfera.com',
    password: 'demo123',
    role: 'parent',
    tier: 'free',
    full_name: 'Demo Roditelj (Free)'
  },
  {
    email: 'demo-parent-paid@sarenasfera.com',
    password: 'demo123',
    role: 'parent',
    tier: 'paid',
    full_name: 'Demo Roditelj (Paid)'
  },
  {
    email: 'demo-parent-premium@sarenasfera.com',
    password: 'demo123',
    role: 'parent',
    tier: 'premium',
    full_name: 'Demo Roditelj (Premium)'
  }
]

async function createDemoAccounts() {
  console.log('🚀 Creating demo accounts...\n')

  for (const account of demoAccounts) {
    try {
      // Check if user already exists
      const { data: existingUsers } = await supabase.auth.admin.listUsers()
      const userExists = existingUsers.users.some(u => u.email === account.email)

      if (userExists) {
        console.log(`⏭️  ${account.email} already exists, skipping...`)
        continue
      }

      // Create user using admin API
      const { data: user, error: signUpError } = await supabase.auth.admin.createUser({
        email: account.email,
        password: account.password,
        email_confirm: true,
        user_metadata: {
          full_name: account.full_name
        }
      })

      if (signUpError) {
        console.error(`❌ Error creating ${account.email}:`, signUpError.message)
        continue
      }

      console.log(`✅ User created: ${account.email}`)

      // Update profile to set role and tier
      const { error: updateError } = await supabase
        .from('profiles')
        .update({
          role: account.role,
          subscription_tier: account.tier,
          onboarding_completed: true,
          full_name: account.full_name
        })
        .eq('id', user.user.id)

      if (updateError) {
        console.error(`❌ Error updating profile for ${account.email}:`, updateError.message)
        continue
      }

      console.log(`   Role: ${account.role}, Tier: ${account.tier}`)
      console.log(`   Password: ${account.password}\n`)

    } catch (err) {
      console.error(`❌ Error processing ${account.email}:`, err.message)
    }
  }

  console.log('\n✨ Demo accounts created successfully!')
  console.log('\nDemo credentials:')
  console.log('━'.repeat(60))
  demoAccounts.forEach(acc => {
    console.log(`${acc.full_name.padEnd(30)} | ${acc.email}`)
  })
  console.log('Password for all accounts: demo123')
  console.log('━'.repeat(60))
  console.log('\nYou can login at: http://localhost:3000/auth/login')
}

createDemoAccounts()
