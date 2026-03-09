# Security Best Practices — Šarena Sfera Platforma

**Version:** 1.0  
**Last Updated:** 2026-03-09  
**Status:** 🔒 CRITICAL

---

## 🚨 Security Incidents Response

If you discover a security vulnerability:

1. **DO NOT** disclose publicly
2. Email: security@sarenasfera.com
3. Include: description, steps to reproduce, potential impact
4. Response time: Within 24 hours

---

## 🔐 Authentication & Passwords

### Password Requirements

```typescript
// Minimum requirements
const passwordPolicy = {
  minLength: 8,
  requireUppercase: true,
  requireNumber: true,
  requireSpecial: false, // Balance security vs UX
}

// Enforce on registration
function validatePassword(password: string): boolean {
  if (password.length < 8) return false
  if (!/[A-Z]/.test(password)) return false
  if (!/[0-9]/.test(password)) return false
  return true
}
```

### Session Management

```typescript
// Session expiry
const sessionConfig = {
  accessTokenExpiry: 3600, // 1 hour
  refreshTokenExpiry: 604800, // 7 days
  absoluteExpiry: 2592000, // 30 days
}

// Logout on all devices
async function logoutEverywhere(userId: string) {
  await supabase
    .from('user_sessions')
    .update({ is_active: false })
    .eq('user_id', userId)
}
```

### Brute Force Protection

```sql
-- Implemented in migration 026
-- Lock account after 5 failed attempts in 15 minutes
SELECT is_account_locked('user@example.com');

-- Track failed attempts
SELECT track_failed_login('user@example.com', '192.168.1.1'::inet);
```

---

## 🛡️ Input Validation

### Client-Side Validation

```typescript
// Use Zod for schema validation
import { z } from 'zod'

const childSchema = z.object({
  full_name: z.string().min(2).max(100),
  date_of_birth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  gender: z.enum(['male', 'female', 'other']).optional(),
  allergies: z.string().max(500).optional(),
})

// Validate before submitting
function validateChildData(data: unknown) {
  const result = childSchema.safeParse(data)
  if (!result.success) {
    throw new Error(`Validation failed: ${result.error.message}`)
  }
  return result.data
}
```

### Server-Side Validation

```python
# FastAPI endpoint with validation
from pydantic import BaseModel, EmailStr, validator

class RegistrationData(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    
    @validator('password')
    def password_strength(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain uppercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain a number')
        return v

@app.post('/api/auth/register')
async def register(data: RegistrationData):
    # Additional server-side checks
    if await is_account_locked(data.email):
        raise HTTPException(429, 'Too many failed attempts')
    
    # ... registration logic
```

### SQL Injection Prevention

```typescript
// ❌ BAD - String concatenation
const query = `SELECT * FROM children WHERE full_name = '${userInput}'`

// ✅ GOOD - Parameterized query
const { data } = await supabase
  .from('children')
  .select('*')
  .eq('full_name', userInput)

// ✅ GOOD - Raw SQL with parameters
const { data } = await supabase.rpc('get_child', { 
  child_name: userInput 
})
```

---

## 🔒 Data Protection

### PII (Personally Identifiable Information)

```typescript
// Mask sensitive data before logging
function sanitizeForLog(data: any): any {
  return {
    ...data,
    email: maskEmail(data.email),
    phone: maskPhone(data.phone),
    // Never log these:
    // - passwords
    // - tokens
    // - full credit card numbers
  }
}

// Masking functions (from migration 026)
SELECT mask_email('user@example.com'); -- Returns: us***@ex***.com
SELECT mask_phone('+387611234567'); -- Returns: *******4567
```

### Data Encryption

```typescript
// Supabase encrypts data at rest by default
// For extra-sensitive data, encrypt client-side:

import { AES, enc } from 'crypto-js'

function encryptSensitiveData(data: string, key: string): string {
  return AES.encrypt(data, key).toString()
}

function decryptSensitiveData(encrypted: string, key: string): string {
  return AES.decrypt(encrypted, key).toString(enc.Utf8)
}
```

### GDPR Compliance

```typescript
// Right to data export
async function exportUserData(userId: string) {
  const tables = ['profiles', 'children', 'observations', 'attendance']
  const exportData = {}
  
  for (const table of tables) {
    const { data } = await supabase
      .from(table)
      .select('*')
      .eq('user_id', userId)
    exportData[table] = data
  }
  
  // Log the export
  await supabase.from('data_exports').insert({
    user_id: userId,
    export_type: 'full_export',
    status: 'completed',
  })
  
  return exportData
}

// Right to deletion
async function deleteUserData(userId: string) {
  // Soft delete first (30-day grace period)
  await supabase
    .from('profiles')
    .update({ 
      is_active: false,
      deleted_at: new Date().toISOString()
    })
    .eq('id', userId)
}
```

---

## 🚫 Access Control

### RLS Policies

```sql
-- Parents can only see their own children
CREATE POLICY "parents_see_own_children"
ON children FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM parent_children
    WHERE parent_children.child_id = children.id
    AND parent_children.parent_id = auth.uid()
  )
);

-- Staff can see children in their groups
CREATE POLICY "staff_see_group_children"
ON children FOR SELECT
USING (
  auth.jwt()->'app_metadata'->>'role' IN ('staff', 'admin')
  AND EXISTS (
    SELECT 1 FROM group_staff
    WHERE group_staff.staff_id = auth.uid()
  )
);

-- No one can delete children except admin
CREATE POLICY "admin_delete_children"
ON children FOR DELETE
USING (auth.jwt()->'app_metadata'->>'role' = 'admin');
```

### API Authorization

```typescript
// Middleware for role-based access
export default defineEventHandler((event) => {
  const user = event.context.user
  
  if (!user) {
    throw createError({ statusCode: 401, message: 'Unauthorized' })
  }
  
  const role = user.app_metadata.role
  
  // Admin-only endpoints
  if (event.path.startsWith('/api/admin') && role !== 'admin') {
    throw createError({ statusCode: 403, message: 'Forbidden' })
  }
  
  // Staff-only endpoints
  if (event.path.startsWith('/api/staff') && !['staff', 'admin'].includes(role)) {
    throw createError({ statusCode: 403, message: 'Forbidden' })
  }
})
```

---

## 📁 File Upload Security

### Validation

```typescript
async function validateAndUpload(file: File, bucket: string) {
  // 1. Validate file type (whitelist)
  const allowedTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf'
  ]
  
  if (!allowedTypes.includes(file.type)) {
    throw new Error('Invalid file type')
  }
  
  // 2. Validate file size
  const maxSize = 5 * 1024 * 1024 // 5MB
  if (file.size > maxSize) {
    throw new Error('File too large')
  }
  
  // 3. Generate safe filename
  const ext = file.name.split('.').pop()
  const safeName = `${crypto.randomUUID()}.${ext}`
  
  // 4. Upload
  const { data, error } = await supabase.storage
    .from(bucket)
    .upload(safeName, file, {
      cacheControl: '3600',
      upsert: false
    })
  
  if (error) throw error
  return data
}
```

### Storage RLS

```sql
-- Users can only upload to their own folder
CREATE POLICY "users_upload_own"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'user-uploads'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can only see their own files
CREATE POLICY "users_see_own"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'user-uploads'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

---

## 📊 Logging & Monitoring

### What to Log

```typescript
// ✅ DO Log:
- Login/logout events
- Failed authentication attempts
- Data exports
- Admin actions
- API errors (without PII)
- Performance metrics

// ❌ DON'T Log:
- Passwords
- Full credit card numbers
- Session tokens
- Personal emails/phones
- Full request bodies with PII
```

### Implementation

```typescript
// Audit logging
async function logAuditEvent(action: string, metadata: any = {}) {
  const { user } = useAuth()
  
  await supabase.from('audit_logs').insert({
    user_id: user?.id,
    action,
    metadata: sanitizeForLog(metadata),
    ip_address: await getClientIP(),
    user_agent: navigator.userAgent,
  })
}

// Usage
await logAuditEvent('child_created', { child_id: newChild.id })
await logAuditEvent('data_exported', { export_type: 'full' })
```

---

## 🔐 Environment Variables

### Never Commit Secrets

```bash
# .gitignore
.env
.env.production
.env.local
*.local

# Pre-commit hook to check for secrets
#!/bin/bash
if grep -r "sk-[a-zA-Z0-9]" --include="*.ts" --include="*.vue" .; then
  echo "❌ Potential API key found in code!"
  exit 1
fi
```

### Production Checklist

```bash
# Before deploying to production:

# 1. Verify no secrets in code
git grep -i "password\|secret\|key" -- "*.ts" "*.vue"

# 2. Check .env file is not committed
git ls-files | grep ".env"

# 3. Verify environment variables are set
echo $SUPABASE_SERVICE_KEY | grep -q "^eyJ" && echo "✓ Service key set"

# 4. Rotate all secrets from staging
# Generate new JWT_SECRET, POSTGRES_PASSWORD, etc.
```

---

## 🚨 Incident Response

### If You Suspect a Breach

1. **Immediate Actions** (within 1 hour)
   - Change all admin passwords
   - Rotate service role keys
   - Enable enhanced logging
   - Document what you know

2. **Investigation** (within 24 hours)
   - Review audit logs
   - Check for unusual activity
   - Identify scope of breach
   - Preserve evidence

3. **Remediation** (within 72 hours)
   - Patch vulnerability
   - Notify affected users
   - Report to authorities (if required)
   - Update security measures

4. **Post-Mortem** (within 1 week)
   - Document what happened
   - Identify root cause
   - Implement preventive measures
   - Update this document

---

## 📚 Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Supabase Security Guide](https://supabase.com/docs/guides/database/security)
- [Vue.js Security](https://vuejs.org/guide/best-practices/security.html)
- [Nuxt Security](https://nuxt.com/docs/guide/concepts/security)

---

**Remember:** Security is not a feature, it's a requirement. Every developer is responsible for security.
