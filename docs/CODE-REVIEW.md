# Code Review Guidelines — Šarena Sfera Platforma

**Version:** 1.0  
**Last Updated:** 2026-03-09

---

## 📋 Code Review Checklist

### Security Review (CRITICAL)

- [ ] **No hardcoded secrets** (API keys, passwords, tokens)
- [ ] **SQL injection prevention** (parameterized queries, no string concatenation)
- [ ] **XSS prevention** (escape user input, use `.textContent` not `.innerHTML`)
- [ ] **CSRF protection** (tokens on state-changing operations)
- [ ] **Authentication checks** (user is logged in before accessing data)
- [ ] **Authorization checks** (user has permission for this action)
- [ ] **Input validation** (all user input validated on client AND server)
- [ ] **Error messages** (no sensitive data in error messages)
- [ ] **Logging** (sensitive actions logged, but no PII in logs)

### Code Quality

- [ ] **TypeScript types** (no `any` in critical paths, proper interfaces)
- [ ] **Function length** (< 50 lines ideally, extract helpers)
- [ ] **Component size** (< 300 lines, split into smaller components)
- [ ] **Naming** (descriptive names, consistent conventions)
- [ ] **Comments** (why, not what; remove commented-out code)
- [ ] **DRY** (no code duplication, extract composables)
- [ ] **Error handling** (try/catch on async, user-friendly messages)

### Performance

- [ ] **N+1 queries** (use joins, batch loading)
- [ ] **Unnecessary re-renders** (use `computed`, `memoize`)
- [ ] **Large lists** (virtual scrolling for > 100 items)
- [ ] **Image optimization** (WebP, lazy loading, proper sizes)
- [ ] **Bundle size** (code splitting, tree shaking)

### Testing

- [ ] **Unit tests** for composables and utilities
- [ ] **E2E tests** for critical user flows
- [ ] **Edge cases** covered (empty states, errors, loading)

---

## 🔒 Security Best Practices

### 1. Database Queries

```typescript
// ❌ BAD - SQL injection risk
const { data } = await supabase
  .from('children')
  .select('*')
  .eq('full_name', userInput) // userInput could be malicious

// ✅ GOOD - Parameterized
const { data } = await supabase
  .from('children')
  .select('*')
  .eq('full_name', sanitizeInput(userInput))
```

### 2. User Input

```typescript
// ❌ BAD - Direct HTML rendering
<div v-html="userComment"></div>

// ✅ GOOD - Escaped
<div>{{ userComment }}</div>

// ✅ GOOD - Sanitized if HTML needed
<div v-html="sanitizeHtml(userComment)"></div>
```

### 3. Authentication

```typescript
// ❌ BAD - No auth check
async function getChildData(childId: string) {
  return await supabase.from('children').select('*').eq('id', childId)
}

// ✅ GOOD - Auth + RLS
async function getChildData(childId: string) {
  const { user } = useAuth()
  if (!user) throw new Error('Unauthorized')
  
  // RLS will also check if user can access this child
  return await supabase.from('children').select('*').eq('id', childId)
}
```

### 4. API Keys & Secrets

```typescript
// ❌ BAD - Hardcoded
const API_KEY = 'sk-1234567890abcdef'

// ✅ GOOD - Environment variable
const API_KEY = useRuntimeConfig().public.apiKey

// ✅ GOOD - Server-side only (not exposed to client)
const SERVICE_KEY = useRuntimeConfig().supabaseServiceKey
```

### 5. File Uploads

```typescript
// ❌ BAD - No validation
async function uploadFile(file: File) {
  return await supabase.storage.from('uploads').upload(file.name, file)
}

// ✅ GOOD - Validate type and size
async function uploadFile(file: File) {
  const allowedTypes = ['image/jpeg', 'image/png', 'image/webp']
  const maxSize = 5 * 1024 * 1024 // 5MB
  
  if (!allowedTypes.includes(file.type)) {
    throw new Error('Invalid file type')
  }
  
  if (file.size > maxSize) {
    throw new Error('File too large')
  }
  
  const safeName = `${crypto.randomUUID()}.${file.name.split('.').pop()}`
  return await supabase.storage.from('uploads').upload(safeName, file)
}
```

---

## 📝 Common Code Review Comments

### Security Issues (Block Merge)

```
🔒 SECURITY ISSUE: Potential SQL injection
Location: Line 42
Issue: User input directly concatenated into query
Fix: Use parameterized queries
```

```
🔒 SECURITY ISSUE: Missing authentication
Location: `pages/api/children.ts`
Issue: No check if user is logged in
Fix: Add `const { user } = useAuth()` and check before accessing data
```

```
🔒 SECURITY ISSUE: Sensitive data in logs
Location: Line 78
Issue: Logging full user object including email
Fix: Log only user ID or mask sensitive fields
```

### Performance Issues

```
⚡ PERFORMANCE: N+1 query detected
Location: Line 55-60
Issue: Querying database inside loop
Fix: Use batch loading or join
```

```
⚡ PERFORMANCE: Large list rendering
Location: `pages/admin/children/index.vue`
Issue: Rendering 500+ rows without virtualization
Fix: Add virtual scrolling or pagination
```

### Code Quality Issues

```
📝 CODE QUALITY: Function too long
Location: `composables/useChildren.ts:150`
Issue: Function is 200 lines
Fix: Extract helper functions
```

```
📝 CODE QUALITY: Using `any` type
Location: Line 34
Issue: `data: any` loses type safety
Fix: Define proper interface
```

---

## 🎯 Pre-Merge Checklist

Before merging any PR:

- [ ] All security checks pass
- [ ] No console errors in browser
- [ ] All tests pass
- [ ] Code follows style guide
- [ ] Documentation updated (if needed)
- [ ] Reviewed by at least 1 team member
- [ ] Deployed to staging and tested

---

## 🚨 Critical Files Requiring Extra Review

These files need security review before EVERY merge:

1. **Authentication & Authorization**
   - `composables/useAuth.ts`
   - `middleware/auth.ts`
   - `pages/auth/*.vue`

2. **API Routes**
   - `server/api/**/*.ts`
   - `api/app/**/*.py`

3. **Database Schema**
   - `supabase/migrations/*.sql`
   - Any file with RLS policies

4. **Environment & Config**
   - `.env*` files
   - `nuxt.config.ts`
   - `docker-compose*.yml`

---

## 📚 Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Vue.js Security Guide](https://vuejs.org/guide/best-practices/security.html)
- [Supabase Security](https://supabase.com/docs/guides/database/security)
- [Nuxt Security](https://nuxt.com/docs/guide/concepts/security)

---

**Remember:** If you see something, say something. Security is everyone's responsibility!
