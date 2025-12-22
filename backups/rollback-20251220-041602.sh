#!/bin/bash
# Auto-generated rollback script
BACKUP_TAG="dd9856a4d9dcb1fc9beb949669fc30d437a732da"
BACKUP_FILE="backups/deployments/deployment-20251220-041602-dd9856a4d9dcb1fc9beb949669fc30d437a732da.yaml"

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
