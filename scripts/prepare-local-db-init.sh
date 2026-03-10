#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/supabase/migrations"
TARGET_DIR="$ROOT_DIR/.generated/local-db-init"
POST_INIT_SOURCE_DIR="$ROOT_DIR/supabase/local-post-init"
POST_INIT_TARGET_DIR="$ROOT_DIR/.generated/local-db-post-init"

rm -rf "$TARGET_DIR"
rm -rf "$POST_INIT_TARGET_DIR"
mkdir -p "$TARGET_DIR"
mkdir -p "$POST_INIT_TARGET_DIR"

for file in "$SOURCE_DIR"/*.sql; do
  target_file="$TARGET_DIR/$(basename "$file")"
  perl -0pe 's/^CREATE POLICY IF NOT EXISTS ("[^"]+")\s+ON\s+([^ \n;]+)(.*)$/DROP POLICY IF EXISTS $1 ON $2;\nCREATE POLICY $1 ON $2$3/gm' "$file" > "$target_file"
done

if [ -d "$POST_INIT_SOURCE_DIR" ]; then
  cp "$POST_INIT_SOURCE_DIR"/*.sql "$POST_INIT_TARGET_DIR"/ 2>/dev/null || true
fi

echo "Prepared local DB init directory at $TARGET_DIR"
echo "Prepared local DB post-init directory at $POST_INIT_TARGET_DIR"
