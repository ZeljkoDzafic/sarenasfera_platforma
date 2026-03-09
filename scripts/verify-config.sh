#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

check_file() {
  local file="$1"
  if [ -f "$file" ]; then
    echo "ok    $file"
  else
    echo "miss  $file"
    return 1
  fi
}

check_file ".env.example"
check_file ".env.production.example"
check_file "frontend/.env.example"
check_file "api/.env.example"
check_file "frontend/Dockerfile.prod"
check_file "api/Dockerfile.prod"
check_file "docker/kong/kong.yml"
check_file "docker/kong/kong.prod.yml"
check_file "docker/nginx/nginx.conf"
check_file "docker/prometheus/prometheus.yml"

bash -n scripts/setup-local.sh
echo "ok    scripts/setup-local.sh syntax"

docker compose -f docker-compose.yml config >/tmp/sarenasfera-local-compose.txt
echo "ok    docker-compose.yml renders"

docker compose --env-file .env.production.example -f docker-compose.prod.yml config >/tmp/sarenasfera-prod-compose.txt
echo "ok    docker-compose.prod.yml renders"
