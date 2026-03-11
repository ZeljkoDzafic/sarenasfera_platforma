import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'http://localhost:54321'
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic2FyZW5hc2ZlcmEtbG9jYWwiLCJpYXQiOjE3MDAwMDAwMDAsImV4cCI6MjA5OTk5OTk5OX0.aek88IZjaoZGK1K_KnmW6Kr12FHVi34xK_uJfRo7FLE'

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

async function createAdminUser() {
  try {
    // Create user using admin API
    const { data: user, error: signUpError } = await supabase.auth.admin.createUser({
      email: 'admin@sarenasfera.com',
      password: 'admin123',
      email_confirm: true,
      user_metadata: {
        full_name: 'Admin User'
      }
    })

    if (signUpError) {
      console.error('Error creating user:', signUpError)
      return
    }

    console.log('✅ User created:', user.user.id)

    // Update profile to set role as admin
    const { error: updateError } = await supabase
      .from('profiles')
      .update({
        role: 'admin',
        onboarding_completed: true
      })
      .eq('id', user.user.id)

    if (updateError) {
      console.error('Error updating profile:', updateError)
      return
    }

    console.log('✅ Admin user created successfully!')
    console.log('   Email: admin@sarenasfera.com')
    console.log('   Password: admin123')
    console.log('\nYou can now login at http://localhost:3000/auth/login')
  } catch (err) {
    console.error('Error:', err)
  }
}

createAdminUser()
