# Backup Script for Šarena Sfera Platforma
# Usage: ./scripts/backup.sh

#!/bin/bash
set -e

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/backups/sarenasfera/$DATE"
RETENTION_DAYS=7

echo "🔄 Starting backup at $DATE..."

# Create backup directory
mkdir -p $BACKUP_DIR

# Database backup
echo "📊 Backing up database..."
docker exec sarenasfera-db pg_dump -U postgres sarenasfera > $BACKUP_DIR/db.sql
gzip $BACKUP_DIR/db.sql
echo "✓ Database backup complete"

# Storage backup (user uploads, photos, etc.)
echo "📁 Backing up storage..."
docker cp sarenasfera-storage:/var/lib/storage $BACKUP_DIR/storage
tar -czf $BACKUP_DIR/storage.tar.gz -C $BACKUP_DIR storage
rm -rf $BACKUP_DIR/storage
echo "✓ Storage backup complete"

# Environment backup
echo "⚙️ Backing up environment configuration..."
cp .env.production $BACKUP_DIR/.env.backup
echo "✓ Environment backup complete"

# Create manifest
cat > $BACKUP_DIR/manifest.json << EOF
{
  "backup_date": "$DATE",
  "backup_type": "full",
  "services": ["frontend", "api", "db", "storage"],
  "database": "sarenasfera",
  "retention_days": $RETENTION_DAYS
}
EOF

# Upload to cloud storage (S3 example)
if command -v aws &> /dev/null && [ -n "$AWS_BUCKET_NAME" ]; then
    echo "☁️ Uploading to S3..."
    aws s3 cp $BACKUP_DIR s3://$AWS_BUCKET_NAME/backups/$DATE/ --recursive
    echo "✓ S3 upload complete"
fi

# Upload to DigitalOcean Spaces (alternative)
if command -v s3cmd &> /dev/null && [ -n "$DO_SPACES_BUCKET" ]; then
    echo "☁️ Uploading to DigitalOcean Spaces..."
    s3cmd put --recursive $BACKUP_DIR s3://$DO_SPACES_BUCKET/backups/$DATE/
    echo "✓ Spaces upload complete"
fi

# Cleanup old backups
echo "🧹 Cleaning up old backups..."
find /backups/sarenasfera -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true
echo "✓ Cleanup complete"

# Summary
echo ""
echo "═══════════════════════════════════════"
echo "✅ Backup completed successfully!"
echo "═══════════════════════════════════════"
echo "Backup location: $BACKUP_DIR"
echo "Size: $(du -sh $BACKUP_DIR | cut -f1)"
echo "Retention: $RETENTION_DAYS days"
echo ""

# Send notification (Discord webhook example)
if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    curl -X POST $DISCORD_WEBHOOK_URL \
        -H "Content-Type: application/json" \
        -d "{
            \"content\": \"✅ Backup completed for platforma.sarenasfera.com\",
            \"embeds\": [{
                \"title\": \"Backup Summary\",
                \"color\": 65280,
                \"fields\": [
                    {\"name\": \"Date\", \"value\": \"$DATE\", \"inline\": true},
                    {\"name\": \"Size\", \"value\": \"$(du -sh $BACKUP_DIR | cut -f1)\", \"inline\": true},
                    {\"name\": \"Location\", \"value\": \"$BACKUP_DIR\", \"inline\": false}
                ]
            }]
        }" || true
fi
