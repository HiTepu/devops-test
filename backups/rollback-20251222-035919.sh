#!/bin/bash
# Auto-generated rollback script
BACKUP_TAG="c332ad3482feb04cd31c71d959a5d8b5fde21cae"
BACKUP_FILE="backups/deployments/deployment-20251222-035919-c332ad3482feb04cd31c71d959a5d8b5fde21cae.yaml"

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
