# 04 - Authentication & Roles

## Auth System (Supabase GoTrue)

### Login Methods
1. **Email + Password** - primary method
2. **Google OAuth** - quick signup for parents
3. **Magic Link** - passwordless login (Phase 2)

### Registration Flow

```
[Landing Page]
     |
     v
[Click "Register" / "Registruj se"]
     |
     v
[Form: name, email, password]
     |
     v
[supabase.auth.signUp()] --> auto-creates profiles row (DB trigger)
     |
     v
[Email verification link sent]
     |
     v
[User clicks link -> redirected to /portal]
     |
     v
[Onboarding wizard (first login)]
  1. Add your child (name, date of birth)
  2. Select group/program (if available)
  3. Short questionnaire about expectations
     |
     v
[Dashboard - ready to use]
```

### Three Roles (RBAC)

| Role | Access | How assigned |
|------|--------|-------------|
| `parent` | Portal, child passport (own children), resources | Auto on signup |
| `staff` | Everything parent has + admin panel for observations, workshops | Admin manually sets |
| `admin` | Everything + user management, statistics, marketing | Initial user + manually |

### Custom JWT Claims (Optimized)

Instead of querying the profiles table on every page load, inject the role into the JWT:

```sql
-- This function runs on every token refresh
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event JSONB)
RETURNS JSONB LANGUAGE plpgsql STABLE AS $$
DECLARE
  claims JSONB;
  user_role TEXT;
BEGIN
  SELECT role INTO user_role FROM public.profiles WHERE id = (event->>'user_id')::UUID;
  claims := event->'claims';
  claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
  event := jsonb_set(event, '{claims}', claims);
  RETURN event;
END;
$$;
-- Configure this hook in Supabase Dashboard > Auth > Hooks
```

Now the role is available in the JWT without an extra DB query:

```typescript
// Read role directly from JWT
const { data: { session } } = await supabase.auth.getSession();
const role = session?.access_token
  ? JSON.parse(atob(session.access_token.split('.')[1])).user_role
  : null;
```

### Auth Guard (TypeScript)

```typescript
// src/auth.ts
import { supabase } from './supabase';

export async function requireAuth(allowedRoles?: string[]) {
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    window.location.href = '/prijava.html';
    return null;
  }

  if (allowedRoles) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    if (!profile || !allowedRoles.includes(profile.role)) {
      window.location.href = '/portal/index.html';
      return null;
    }
  }

  return user;
}

// Usage in any page's Alpine.js init():
// const user = await requireAuth();                    // any authenticated user
// const user = await requireAuth(['staff', 'admin']);   // staff or admin only
// const user = await requireAuth(['admin']);             // admin only
```

### Auth State Listener

```typescript
// src/main.ts - loaded on every page
import { supabase } from './supabase';

// Listen for auth changes globally
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_OUT') {
    // Redirect to login if on a protected page
    if (window.location.pathname.startsWith('/portal')
        || window.location.pathname.startsWith('/admin')) {
      window.location.href = '/prijava.html';
    }
  }
});
```

### Route Protection Map

```
Public routes (no auth):
  /index.html               -- landing page
  /program.html              -- program overview
  /blog.html                 -- blog posts
  /kontakt.html              -- contact form
  /registracija.html         -- signup
  /prijava.html              -- login
  /resursi.html              -- free resources
  /about.html                -- about us

Protected routes (any authenticated user):
  /portal/index.html         -- dashboard
  /portal/djeca.html         -- my children
  /portal/dijete.html        -- child passport
  /portal/radionice.html     -- workshop materials
  /portal/aktivnosti.html    -- home activities
  /portal/galerija.html      -- photos
  /portal/profil.html        -- my profile

Protected routes (staff + admin):
  /admin/index.html          -- admin dashboard
  /admin/djeca.html          -- all children
  /admin/dijete.html         -- child detail
  /admin/grupe.html          -- groups
  /admin/radionice.html      -- workshops
  /admin/opservacije.html    -- observations
  /admin/prisustvo.html      -- attendance
  /admin/poruke.html         -- messages

Protected routes (admin only):
  /admin/korisnici.html      -- user management
  /admin/statistike.html     -- analytics
  /admin/marketing.html      -- email campaigns
```

## Security Measures

1. **RLS on all tables** - users can NEVER access other people's data
2. **HTTPS required** - Let's Encrypt SSL certificates
3. **Rate limiting** - on auth endpoints (Supabase built-in)
4. **Input validation** - TypeScript types + RLS constraints
5. **Child photos** - private storage bucket, RLS on files
6. **GDPR compliance** - ability to delete all child data on request
7. **JWT expiry** - tokens auto-refresh, 1 hour expiry
8. **CORS** - Supabase configured to accept only sarenasfera.com origin
9. **No secrets in frontend** - only ANON key (safe to expose, RLS protects data)
