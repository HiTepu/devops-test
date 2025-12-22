#!/bin/bash
# Auto-generated rollback script
BACKUP_TAG="03510c46093417238611339beb6bc964ee30e52d"
BACKUP_FILE="backups/deployments/deployment-20251222-021505-03510c46093417238611339beb6bc964ee30e52d.yaml"

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
