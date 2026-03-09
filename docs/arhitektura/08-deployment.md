# 08 - Deployment & Infrastructure

## Infrastructure Overview

```
┌──────────────────────────────────┐     ┌──────────────────────────────────────┐
│  ANY STATIC HOST                 │     │  DIGITALOCEAN DROPLET ($12-24/mo)    │
│                                  │     │                                      │
│  sarenasfera.com                 │     │  supabase.sarenasfera.com            │
│  ├── dist/index.html             │────>│  ├── Supabase (Docker Compose)       │
│  ├── dist/portal/*.html          │     │  │   ├── PostgreSQL                  │
│  ├── dist/admin/*.html           │     │  │   ├── PostgREST (auto API)        │
│  ├── dist/assets/*.js            │     │  │   ├── GoTrue (auth)               │
│  └── dist/assets/*.css           │     │  │   ├── Storage API                 │
│                                  │     │  │   ├── Realtime                    │
│  Built with: npm run build       │     │  │   └── Studio (admin UI :3000)     │
│  Deploy: upload dist/ folder     │     │  │                                    │
│                                  │     │  api.sarenasfera.com                 │
│  Options:                        │     │  └── Python FastAPI (Docker)          │
│  - HostGator (existing)          │     │      ├── PDF generation               │
│  - DigitalOcean (same droplet)   │     │      ├── Email service                │
│  - Netlify (free)                │     │      └── Cron jobs                    │
│  - Vercel (free)                 │     │                                      │
│  - GitHub Pages (free)           │     │  Nginx reverse proxy + SSL           │
│  - Any CDN                       │     └──────────────────────────────────────┘
└──────────────────────────────────┘
```

## Option A: Everything on DigitalOcean (Simplest)

One droplet runs everything: Supabase, Python API, AND serves the frontend.

```bash
# Nginx serves static frontend + proxies to Supabase + Python
# All on one $12/mo droplet
```

### Nginx Configuration

```nginx
# /etc/nginx/sites-available/sarenasfera
server {
    listen 443 ssl http2;
    server_name sarenasfera.com www.sarenasfera.com;

    ssl_certificate /etc/letsencrypt/live/sarenasfera.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sarenasfera.com/privkey.pem;

    # Serve static frontend files
    root /var/www/sarenasfera/dist;
    index index.html;

    # SPA-style: try file, then .html extension, then 404
    location / {
        try_files $uri $uri.html $uri/ =404;
    }

    # Cache static assets
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}

server {
    listen 443 ssl http2;
    server_name supabase.sarenasfera.com;

    ssl_certificate /etc/letsencrypt/live/supabase.sarenasfera.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/supabase.sarenasfera.com/privkey.pem;

    # Proxy to Supabase Kong gateway
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

server {
    listen 443 ssl http2;
    server_name api.sarenasfera.com;

    ssl_certificate /etc/letsencrypt/live/api.sarenasfera.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.sarenasfera.com/privkey.pem;

    # Proxy to Python FastAPI
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name sarenasfera.com www.sarenasfera.com supabase.sarenasfera.com api.sarenasfera.com;
    return 301 https://$host$request_uri;
}
```

## Option B: Split (Frontend on HostGator or Free CDN)

If you want to keep frontend separate:

### Deploy to HostGator (existing)
```bash
# Build locally
npm run build

# Upload dist/ folder via FTP or SSH
scp -r dist/* user@hostgator-server:~/public_html/
```

### Deploy to Netlify (free, automatic)
```bash
# Connect GitHub repo to Netlify
# Set build command: npm run build
# Set publish directory: dist
# Every push to main = auto-deploy
```

### Deploy to GitHub Pages (free)
```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci && npm run build
      - uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
```

## DigitalOcean Setup (Step by Step)

### 1. Create Droplet

| Setting | Value |
|---------|-------|
| Image | Ubuntu 24.04 LTS |
| Size | $12/mo (1 vCPU, 2GB RAM, 50GB SSD) |
| Region | Frankfurt (FRA1) - closest to BiH |
| Auth | SSH key |
| Hostname | sarenasfera |

### 2. Initial Server Setup

```bash
ssh root@your-droplet-ip

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh

# Install Nginx
apt install -y nginx certbot python3-certbot-nginx

# Install Node.js (for building frontend on server - optional)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
```

### 3. Self-hosted Supabase

```bash
# Clone Supabase docker setup
git clone --depth 1 https://github.com/supabase/supabase /opt/supabase
cd /opt/supabase/docker

# Configure
cp .env.example .env

# Generate secrets
JWT_SECRET=$(openssl rand -base64 32)
POSTGRES_PASSWORD=$(openssl rand -base64 24)
echo "Generated JWT_SECRET: $JWT_SECRET"
echo "Generated POSTGRES_PASSWORD: $POSTGRES_PASSWORD"

# Edit .env with your values:
# POSTGRES_PASSWORD=<generated>
# JWT_SECRET=<generated>
# SITE_URL=https://sarenasfera.com
# API_EXTERNAL_URL=https://supabase.sarenasfera.com
# SUPABASE_PUBLIC_URL=https://supabase.sarenasfera.com
# Generate ANON_KEY and SERVICE_ROLE_KEY from JWT_SECRET
# (use https://supabase.com/docs/guides/self-hosting#generate-api-keys)

# Start Supabase
docker compose up -d

# Verify
docker compose ps  # all services should be "Up"
```

### 4. Python API

```bash
# Clone your API repo
git clone https://github.com/your-user/sarena-sfera-api /opt/sarena-api
cd /opt/sarena-api

# Create .env
cat > .env << 'EOF'
SUPABASE_URL=http://localhost:8000
SUPABASE_SERVICE_KEY=your-service-role-key
RESEND_API_KEY=your-resend-key
EOF

# Docker Compose for Python API
cat > docker-compose.yml << 'EOF'
services:
  api:
    build: .
    ports:
      - "8080:8080"
    env_file: .env
    restart: unless-stopped
    volumes:
      - ./templates:/app/templates
EOF

docker compose up -d
```

### 5. SSL Certificates

```bash
# Get certificates for all domains
certbot --nginx -d sarenasfera.com -d www.sarenasfera.com
certbot --nginx -d supabase.sarenasfera.com
certbot --nginx -d api.sarenasfera.com

# Auto-renewal is configured automatically by certbot
```

### 6. Deploy Frontend

```bash
# On your local machine: build
npm run build

# Copy to server
scp -r dist/* root@your-droplet-ip:/var/www/sarenasfera/dist/

# Or: build on server
cd /opt/sarena-frontend
git pull
npm ci && npm run build
cp -r dist/* /var/www/sarenasfera/dist/
```

## DNS Configuration

| Record | Type | Value |
|--------|------|-------|
| sarenasfera.com | A | DigitalOcean droplet IP |
| www.sarenasfera.com | A | DigitalOcean droplet IP |
| supabase.sarenasfera.com | A | DigitalOcean droplet IP |
| api.sarenasfera.com | A | DigitalOcean droplet IP |

## Backup Strategy

```bash
#!/bin/bash
# /opt/scripts/backup.sh - run daily via cron
DATE=$(date +%Y%m%d_%H%M)

# Database backup
docker exec supabase-db pg_dump -U postgres -Fc > /opt/backups/db_${DATE}.dump

# Storage backup (optional - large files)
tar czf /opt/backups/storage_${DATE}.tar.gz /opt/supabase/docker/volumes/storage

# Keep last 30 days
find /opt/backups/ -mtime +30 -delete

# Optional: upload to DigitalOcean Spaces or external backup
```

```bash
# Add to crontab
crontab -e
# 0 3 * * * /opt/scripts/backup.sh
```

## Monitoring

| What | Tool | Cost |
|------|------|------|
| Server uptime | UptimeRobot | Free |
| Server resources | DigitalOcean built-in | Free |
| Application logs | `docker compose logs -f` | Free |
| SSL expiry | UptimeRobot | Free |

## Scaling Path

```
Phase 1 (MVP):     1 droplet ($12/mo) - everything
Phase 2 (200+ users): Upgrade to $24/mo (2 vCPU, 4GB RAM)
Phase 3 (1000+ users): Separate droplets for DB, API, and frontend on CDN
```
