#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

copy_if_missing() {
  local source_file="$1"
  local target_file="$2"

  if [ -f "$target_file" ]; then
    echo "skip  $target_file already exists"
  else
    cp "$source_file" "$target_file"
    echo "create $target_file"
  fi
}

copy_if_missing "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
copy_if_missing "$ROOT_DIR/frontend/.env.example" "$ROOT_DIR/frontend/.env"
copy_if_missing "$ROOT_DIR/api/.env.example" "$ROOT_DIR/api/.env"

cat <<'EOF'

Local env files are ready.

Next:
1. Open .env, frontend/.env, and api/.env
2. In frontend/.env set:
   NUXT_PUBLIC_SUPABASE_URL=http://localhost:54321
   NUXT_PUBLIC_SUPABASE_ANON_KEY=<ANON_KEY from root .env>
   NUXT_PUBLIC_API_URL=http://localhost:8080
3. In api/.env set:
   SUPABASE_URL=http://localhost:54321
   SUPABASE_ANON_KEY=<ANON_KEY from root .env>
   SUPABASE_SERVICE_ROLE_KEY=<SERVICE_ROLE_KEY from root .env>
   INTERNAL_API_KEY=<shared key for internal API routes>
4. Run:
   npm run verify:config
   npm run install:all
   npm run dev:stack
   npm run dev:api
   npm run dev:frontend

EOF
