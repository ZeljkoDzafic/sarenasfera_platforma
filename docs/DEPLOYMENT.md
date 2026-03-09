# Multi-Cloud Deployment Guide — Šarena Sfera Platforma

**Domain:** `platforma.sarenasfera.com`  
**Last Updated:** 2026-03-09  
**Status:** Production Ready

---

## 📋 Sadržaj

1. [Arhitektura](#arhitektura)
2. [Podržani Provideri](#podržani-provideri)
3. [Brzi Start](#brzi-start)
4. [DigitalOcean Deployment](#digitalocean-deployment)
5. [AWS Deployment](#aws-deployment)
6. [Azure Deployment](#azure-deployment)
7. [HostGator Deployment](#hostgator-deployment)
8. [CI/CD Konfiguracija](#cicd-konfiguracija)
9. [DNS i SSL](#dns-i-ssl)
10. [Monitoring i Backup](#monitoring-i-backup)

---

## 🏗️ Arhitektura

```
┌─────────────────────────────────────────────────────────────┐
│                    platforma.sarenasfera.com                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Cloudflare    │  ← DNS + SSL + CDN
                    └─────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  DigitalOcean │   │     AWS       │   │    Azure      │
│  (Primary)    │   │  (Secondary)  │   │  (Secondary)  │
└───────────────┘   └───────────────┘   └───────────────┘
        │                     │                     │
        └─────────────────────┴─────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Supabase DB   │  ← Self-hosted
                    └─────────────────┘
```

---

## ☁️ Podržani Provideri

| Provider | Status | Tier | Estimated Cost/mj |
|----------|--------|------|-------------------|
| **DigitalOcean** | ✅ Production | Primary | $24-48 |
| **AWS** | ✅ Ready | Secondary | $30-60 |
| **Azure** | ✅ Ready | Secondary | $30-60 |
| **HostGator** | ⚠️ Limited | Dev/Test | $15-30 |

---

## 🚀 Brzi Start

### Pre-requisites

```bash
# Instalirani alati
- Docker & Docker Compose
- Git
- Provider CLI (opcionalno):
  - `doctl` (DigitalOcean)
  - `aws` (AWS)
  - `az` (Azure)
```

### 1. Clone i Setup

```bash
git clone <repo-url> sarenasfera_platforma
cd sarenasfera_platforma

# Kopiraj environment fajl
cp .env.example .env.production

# Generiši tajne
openssl rand -hex 32  # JWT_SECRET
openssl rand -hex 16  # POSTGRES_PASSWORD
```

### 2. Odabir Providera

```bash
# DigitalOcean (preporučeno)
./scripts/deploy.sh digitalocean

# AWS
./scripts/deploy.sh aws

# Azure
./scripts/deploy.sh azure

# HostGator (shared hosting)
./scripts/deploy.sh hostgator
```

---

## 🌊 DigitalOcean Deployment (Preporučeno)

### Opcija A: App Platform (Najlakše)

```bash
# 1. Kreiraj DigitalOcean account
# 2. Install doctl
doctl auth init

# 3. Deploy
doctl apps create --spec .do/app.yaml
```

**`.do/app.yaml`:**
```yaml
name: sarenasfera-platforma
region: fra
services:
- name: frontend
  github:
    repo: sarenasfera/platforma
    branch: main
  build_command: "cd frontend && npm install && npm run build"
  run_command: "cd frontend && npm run preview"
  environment_slug: node-js
  instance_size_slug: basic-xxs
  routes:
  - path: /
- name: api
  github:
    repo: sarenasfera/platforma
    branch: main
  build_command: "cd api && pip install -r requirements.txt"
  run_command: "uvicorn app.main:app --host 0.0.0.0 --port 8000"
  environment_slug: python
  instance_size_slug: basic-xxs
  routes:
  - path: /api
databases:
- engine: PG
  name: sarenasfera-db
  num_nodes: 1
  size: db-s-dev-database
```

### Opcija B: Droplet (Full Control)

```bash
# 1. Kreiraj Droplet (Ubuntu 22.04, 2GB RAM)
doctl compute droplet create sarenasfera-prod \
  --region fra1 \
  --size s-2vcpu-2gb \
  --image ubuntu-22-04-x64 \
  --ssh-keys <your-ssh-key-fingerprint>

# 2. SSH na server
ssh root@<droplet-ip>

# 3. Install Docker
curl -fsSL https://get.docker.com | sh

# 4. Clone i deploy
git clone <repo-url>
cd sarenasfera_platforma
docker compose -f docker-compose.prod.yml up -d
```

---

## 🅰️ AWS Deployment

### Opcija A: ECS Fargate (Serverless)

```bash
# 1. Install AWS CLI
aws configure

# 2. Login to ECR
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-central-1.amazonaws.com

# 3. Build i push
docker build -t sarenasfera-frontend ./frontend
docker tag sarenasfera-frontend:latest <account-id>.dkr.ecr.eu-central-1.amazonaws.com/sarenasfera-frontend:latest
docker push <account-id>.dkr.ecr.eu-central-1.amazonaws.com/sarenasfera-frontend:latest

# 4. Deploy s CloudFormation
aws cloudformation deploy \
  --template-file .aws/cloudformation.yml \
  --stack-name sarenasfera-platforma \
  --parameter-overrides \
    DomainName=platforma.sarenasfera.com \
    Environment=production \
  --capabilities CAPABILITY_NAMED_IAM
```

**`.aws/cloudformation.yml`:** (Full template u `.aws/` folderu)

### Opcija B: Lightsail (Budget)

```bash
# 1. Kreiraj Lightsail instance
aws lightsail create-instances \
  --instance-names sarenasfera-prod \
  --availability-zone eu-central-1a \
  --blueprint-id ubuntu-22-04 \
  --bundle-id medium_2_0

# 2. Connect i deploy
ssh -i ~/.ssh/lightsail-key ubuntu@<public-ip>
# ... isti process kao Droplet
```

---

## 🟦 Azure Deployment

### Opcija A: Azure Container Apps

```bash
# 1. Install Azure CLI
az login

# 2. Kreiraj resource group
az group create \
  --name sarenasfera-rg \
  --location westeurope

# 3. Deploy Container Apps
az containerapp app create \
  --name sarenasfera-frontend \
  --resource-group sarenasfera-rg \
  --environment sarenasfera-env \
  --image sarenasfera.azurecr.io/frontend:latest \
  --target-port 3000 \
  --ingress external \
  --cpu 0.5 \
  --memory 1.0
```

### Opcija B: VM (Full Control)

```bash
# 1. Kreiraj VM
az vm create \
  --resource-group sarenasfera-rg \
  --name sarenasfera-vm \
  --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts:latest \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys

# 2. Otvori portove
az vm open-port --port 80,443 --resource-group sarenasfera-rg --name sarenasfera-vm

# 3. Deploy
# ... isti process kao Droplet
```

---

## 🏠 HostGator Deployment (Shared Hosting)

### Ograničenja
- ❌ Nema Docker supporta
- ❌ Nema custom domaina na subdomain (samo addon domain)
- ⚠️ Node.js ograničen na shared runtime
- ⚠️ Self-hosted Supabase **nije moguć** - koristi Supabase Cloud

### Koraci

```bash
# 1. FTP upload
# Uploaduj frontend/dist na /public_html/platforma

# 2. Postgres setup
# Koristi HostGator MySQL umjesto Supabase

# 3. Node.js app (optional)
# Setup preko cPanel → Setup Node.js App

# 4. .htaccess za SPA routing
RewriteEngine On
RewriteBase /platforma/
RewriteRule ^index\.html$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /platforma/index.html [L]
```

---

## 🔁 CI/CD Konfiguracija

### GitHub Actions (Primary)

**`.github/workflows/deploy.yml`:**

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        provider: [digitalocean, aws, azure]
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Login to GitHub Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Build and Push Frontend
      uses: docker/build-push-action@v5
      with:
        context: ./frontend
        push: true
        tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/frontend:${{ github.sha }}
    
    - name: Build and Push API
      uses: docker/build-push-action@v5
      with:
        context: ./api
        push: true
        tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/api:${{ github.sha }}
    
    - name: Deploy to ${{ matrix.provider }}
      run: ./scripts/deploy.sh ${{ matrix.provider }}
      env:
        DIGITALOCEAN_TOKEN: ${{ secrets.DIGITALOCEAN_TOKEN }}
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
```

### Provider-Specific Scripts

**`scripts/deploy.sh`:**
```bash
#!/bin/bash
set -e

PROVIDER=$1

case $PROVIDER in
  digitalocean)
    echo "🌊 Deploying to DigitalOcean..."
    doctl apps create --spec .do/app.yaml --wait
    ;;
  
  aws)
    echo "🅰️ Deploying to AWS..."
    aws ecr get-login-password --region eu-central-1 | \
      docker login --username AWS --password-stdin $ECR_REGISTRY
    aws ecs update-service --cluster sarenasfera --service frontend --force-new-deployment
    ;;
  
  azure)
    echo "🟦 Deploying to Azure..."
    az containerapp revision copy \
      --name sarenasfera-frontend \
      --resource-group sarenasfera-rg \
      --source-revision-name $(az containerapp show -n sarenasfera-frontend -g sarenasfera-rg --query properties.latestRevisionName -o tsv)
    ;;
  
  hostgator)
    echo "🏠 Deploying to HostGator..."
    npm run build
    lftp -c "set ftp:ssl-allow no; open -u $FTP_USER,$FTP_PASS $FTP_HOST; mirror -R ./frontend/dist ./public_html/platforma; bye"
    ;;
  
  *)
    echo "❌ Unknown provider: $PROVIDER"
    exit 1
    ;;
esac

echo "✅ Deployment complete!"
```

---

## 🌐 DNS i SSL

### Cloudflare Setup (Preporučeno)

```
1. Dodaj domain na Cloudflare
2. Promijeni nameservere na Cloudflare-ove
3. Kreiraj DNS zapise:

Type    Name                      Content                 TTL     Proxy
A       platforma                 <DO Droplet IP>         Auto    ✅ (Orange)
CNAME   www.platforma             platforma.sarenasfera.com  Auto  ✅
TXT     @                         v=spf1 include:_spf.google.com ~all  Auto  ❌
```

### SSL Certifikat

**DigitalOcean/AWS/Azure (Docker):**
```bash
# Automatski preko Cloudflare Origin CA
# ili Let's Encrypt s Certbotom

docker run --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  certbot/certbot certonly \
  --standalone \
  -d platforma.sarenasfera.com \
  -d www.platforma.sarenasfera.com
```

---

## 📊 Monitoring i Backup

### Monitoring Stack

```yaml
# docker-compose.monitoring.yml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    ports:
      - "3001:3001"
    volumes:
      - uptime-kuma:/app/data
  
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3002:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    volumes:
      - grafana:/var/lib/grafana
  
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "3003:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
```

### Backup Strategy

```bash
#!/bin/bash
# scripts/backup.sh

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/backups/$DATE"

mkdir -p $BACKUP_DIR

# Database backup
docker exec sarenasfera-db pg_dump -U postgres sarenasfera > $BACKUP_DIR/db.sql

# Storage backup
docker cp sarenasfera-storage:/var/lib/storage $BACKUP_DIR/storage

# Upload to S3
aws s3 cp $BACKUP_DIR s3://sarenasfera-backups/$DATE/ --recursive

# Keep only last 7 backups
find /backups -type d -mtime +7 -exec rm -rf {} \;
```

**Cron za daily backup:**
```bash
0 2 * * * /path/to/scripts/backup.sh
```

---

## 💰 Troškovi po Provideru

### DigitalOcean (Primary Preporuka)
```
Droplet (2GB RAM, 2 vCPU):  $12/mj
Managed Database (optional): $15/mj
Spaces Storage (250GB):      $4/mj
─────────────────────────────────────
UKUPNO:                      $31/mj
```

### AWS
```
Lightsail (2GB):             $10/mj
RDS PostgreSQL (db.t3.micro): $15/mj
S3 Storage (250GB):          $6/mj
─────────────────────────────────────
UKUPNO:                      $31/mj
```

### Azure
```
VM B2s (2GB):                $10/mj
Azure Database PostgreSQL:   $15/mj
Blob Storage (250GB):        $6/mj
─────────────────────────────────────
UKUPNO:                      $31/mj
```

### HostGator
```
Shared Hosting (Business):   $14/mj
Supabase Cloud (Free tier):  $0/mj
─────────────────────────────────────
UKUPNO:                      $14/mj
```

---

## 🎯 Preporuke

### Za Launch (MVP)
1. **DigitalOcean App Platform** - Najbrži setup, minimalno održavanje
2. **Cloudflare** - Besplatan SSL + CDN
3. **Supabase Cloud Free Tier** - Izbjegni self-hosting na početku

### Za Growth (100+ korisnika)
1. **DigitalOcean Droplet** - Više kontrole, niža cijena
2. **Managed Database** - Automatski backup, HA
3. **Spaces CDN** - Brži assets

### Za Scale (1000+ korisnika)
1. **AWS ECS Fargate** - Auto-scaling
2. **RDS PostgreSQL** - Multi-AZ
3. **CloudFront** - Global CDN

---

## 📞 Support

Za pomoć oko deploya:
- 📧 Email: tech@sarenasfera.com
- 📚 Docs: `/docs/deployment/`
- 🐛 Issues: GitHub Issues

---

**Version:** 1.0  
**Maintained by:** Tech Team
