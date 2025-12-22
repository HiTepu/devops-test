#!/bin/bash
# Auto-generated rollback script
BACKUP_TAG="7c4749afcd2e225408195c924c3f67447ff69fb8"
BACKUP_FILE="backups/deployments/deployment-20251219-095405-7c4749afcd2e225408195c924c3f67447ff69fb8.yaml"

echo "🔄 Rolling back to version: $BACKUP_TAG"

if [ -f "$BACKUP_FILE" ]; then
  cp "$BACKUP_FILE" k8s-manifests/demo/deployment.yaml
  git add k8s-manifests/demo/deployment.yaml
  git commit -m "⏮️ Rollback to $BACKUP_TAG [skip ci]"
  git push
  echo "✅ Rollback completed"
else
  echo "❌ Backup file not found: $BACKUP_FILE"
  exit 1
fi
