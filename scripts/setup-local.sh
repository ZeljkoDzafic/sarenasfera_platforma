#!/bin/bash
# Sarena Sfera - Local Development Setup
# Usage: bash scripts/setup-local.sh

set -e

echo "=== Sarena Sfera - Local Setup ==="

# 1. Copy env file if not exists
if [ ! -f .env ]; then
  cp .env.example .env
  echo "[OK] Created .env from .env.example"
  echo "     Edit .env with your secrets before running Docker!"
else
  echo "[OK] .env already exists"
fi

# 2. Copy frontend env
if [ ! -f frontend/.env ]; then
  cp frontend/.env.example frontend/.env
  echo "[OK] Created frontend/.env"
else
  echo "[OK] frontend/.env already exists"
fi

# 3. Install frontend dependencies
echo ""
echo "=== Installing frontend dependencies ==="
cd frontend
npm install
cd ..

# 4. Start Docker services
echo ""
echo "=== Starting Docker services ==="
docker compose up -d

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Services:"
echo "  Supabase API:    http://localhost:54321"
echo "  Supabase Studio: http://localhost:3001"
echo "  Python API:      http://localhost:8080"
echo "  Mailpit (email): http://localhost:8025"
echo "  PostgreSQL:      localhost:5432"
echo ""
echo "To start the frontend:"
echo "  cd frontend && npm run dev"
echo ""
echo "Frontend will be at: http://localhost:3000"
