#!/bin/bash
# Auto-generated rollback script
BACKUP_TAG="917113717efd61404f0c8275279e6638a5f60775"
BACKUP_FILE="backups/deployments/deployment-20251219-084508-917113717efd61404f0c8275279e6638a5f60775.yaml"

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
