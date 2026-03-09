#!/bin/bash
set -e

# ════════════════════════════════════════════════════════════
# Multi-Cloud Deployment Script
# ════════════════════════════════════════════════════════════
# Usage: ./deploy.sh [provider] [environment]
# Providers: digitalocean, aws, azure, hostgator, all
# Environments: staging, production
# ════════════════════════════════════════════════════════════

PROVIDER=${1:-digitalocean}
ENVIRONMENT=${2:-production}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Load environment variables
load_env() {
    if [ -f ".env.$ENVIRONMENT" ]; then
        log_info "Loading environment from .env.$ENVIRONMENT"
        export $(cat .env.$ENVIRONMENT | grep -v '^#' | xargs)
    elif [ -f ".env.production" ]; then
        log_warning ".env.$ENVIRONMENT not found, using .env.production"
        export $(cat .env.production | grep -v '^#' | xargs)
    else
        log_error "No environment file found"
        exit 1
    fi
}

# DigitalOcean deployment
deploy_digitalocean() {
    log_info "Deploying to DigitalOcean..."
    
    if command -v doctl &> /dev/null; then
        # App Platform deployment
        if [ -f ".do/app.yaml" ]; then
            log_info "Deploying to App Platform..."
            doctl apps create --spec .do/app.yaml --wait || \
            doctl apps update $DIGITALOCEAN_APP_ID --spec .do/app.yaml --wait
            log_success "App Platform deployment complete"
        fi
    else
        log_warning "doctl not found, using Docker Compose deployment"
        deploy_docker_compose
    fi
}

# AWS deployment
deploy_aws() {
    log_info "Deploying to AWS..."
    
    if command -v aws &> /dev/null; then
        # ECR login
        log_info "Logging in to ECR..."
        aws ecr get-login-password --region eu-central-1 | \
            docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com
        
        # Push images
        log_info "Pushing Frontend to ECR..."
        docker tag sarenasfera-frontend:latest \
            $AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/sarenasfera-frontend:latest
        docker push $AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/sarenasfera-frontend:latest
        
        log_info "Pushing API to ECR..."
        docker tag sarenasfera-api:latest \
            $AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/sarenasfera-api:latest
        docker push $AWS_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/sarenasfera-api:latest
        
        # ECS deployment
        log_info "Updating ECS services..."
        aws ecs update-service \
            --cluster sarenasfera-platforma \
            --service frontend-service \
            --force-new-deployment
        
        aws ecs update-service \
            --cluster sarenasfera-platforma \
            --service api-service \
            --force-new-deployment
        
        log_success "AWS deployment complete"
    else
        log_error "AWS CLI not found"
        exit 1
    fi
}

# Azure deployment
deploy_azure() {
    log_info "Deploying to Azure..."
    
    if command -v az &> /dev/null; then
        # ACR login
        log_info "Logging in to Azure Container Registry..."
        az acr login --name sarenasfera
        
        # Push images
        log_info "Pushing Frontend to ACR..."
        docker tag sarenasfera-frontend:latest \
            sarenasfera.azurecr.io/frontend:latest
        docker push sarenasfera.azurecr.io/frontend:latest
        
        log_info "Pushing API to ACR..."
        docker tag sarenasfera-api:latest \
            sarenasfera.azurecr.io/api:latest
        docker push sarenasfera.azurecr.io/api:latest
        
        # Container Apps deployment
        log_info "Updating Container Apps..."
        az containerapp revision copy \
            --name sarenasfera-frontend \
            --resource-group sarenasfera-rg \
            --source-revision-name $(az containerapp show -n sarenasfera-frontend -g sarenasfera-rg --query properties.latestRevisionName -o tsv)
        
        az containerapp revision copy \
            --name sarenasfera-api \
            --resource-group sarenasfera-rg \
            --source-revision-name $(az containerapp show -n sarenasfera-api -g sarenasfera-rg --query properties.latestRevisionName -o tsv)
        
        log_success "Azure deployment complete"
    else
        log_error "Azure CLI not found"
        exit 1
    fi
}

# HostGator deployment (FTP)
deploy_hostgator() {
    log_info "Deploying to HostGator..."
    
    if command -v lftp &> /dev/null; then
        # Build frontend
        log_info "Building frontend..."
        cd frontend
        npm ci
        npm run build
        cd ..
        
        # FTP upload
        log_info "Uploading via FTP..."
        lftp -c "
            set ftp:ssl-allow no;
            open -u $HOSTGATOR_FTP_USERNAME,$HOSTGATOR_FTP_PASSWORD $HOSTGATOR_FTP_SERVER;
            mirror -R ./frontend/dist ./public_html/platforma;
            bye
        "
        
        log_success "HostGator deployment complete"
    else
        log_warning "lftp not found, please install or use FileZilla for manual upload"
    fi
}

# Docker Compose deployment (universal fallback)
deploy_docker_compose() {
    log_info "Deploying via Docker Compose..."
    
    # Pull latest images
    docker compose -f docker-compose.prod.yml pull
    
    # Run migrations
    log_info "Running database migrations..."
    docker compose -f docker-compose.prod.yml run --rm db \
        psql -U postgres -d sarenasfera -f /docker-entrypoint-initdb.d/migrations/001_core.sql
    
    # Deploy
    log_info "Starting services..."
    docker compose -f docker-compose.prod.yml up -d --remove-orphans
    
    # Show status
    log_info "Service status:"
    docker compose -f docker-compose.prod.yml ps
    
    # Cleanup
    log_info "Cleaning up old images..."
    docker system prune -af --volumes
    
    log_success "Docker Compose deployment complete"
}

# Health check
health_check() {
    log_info "Running health checks..."
    
    # Frontend
    if curl -f -s https://platforma.sarenasfera.com > /dev/null; then
        log_success "Frontend is healthy"
    else
        log_error "Frontend health check failed"
    fi
    
    # API
    if curl -f -s https://platforma.sarenasfera.com/api/health > /dev/null; then
        log_success "API is healthy"
    else
        log_error "API health check failed"
    fi
}

# Main deployment logic
main() {
    log_info "Starting deployment to $PROVIDER ($ENVIRONMENT)"
    echo "=================================================="
    
    check_prerequisites
    load_env
    
    case $PROVIDER in
        digitalocean)
            deploy_digitalocean
            ;;
        aws)
            deploy_aws
            ;;
        azure)
            deploy_azure
            ;;
        hostgator)
            deploy_hostgator
            ;;
        all)
            deploy_digitalocean
            deploy_aws
            deploy_azure
            ;;
        *)
            log_error "Unknown provider: $PROVIDER"
            echo "Usage: $0 [digitalocean|aws|azure|hostgator|all] [staging|production]"
            exit 1
            ;;
    esac
    
    health_check
    
    echo "=================================================="
    log_success "Deployment to $PROVIDER completed successfully!"
    echo "URL: https://platforma.sarenasfera.com"
}

# Run main function
main "$@"
