#!/bin/bash

# Script rollback deployment cho CI/CD pipeline
# Sử dụng: ./rollback.sh [tag_version]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEPLOYMENT_FILE="k8s-manifests/demo/deployment.yaml"
BACKUP_DIR="backups"
HARBOR_URL="harbor.lmsx.io.vn"
HARBOR_PROJECT="demo"
IMAGE_NAME="nginx"
NAMESPACE="demo"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Rollback deployment to a previous version

Options:
    -t, --tag TAG           Specific image tag to rollback to
    -l, --list             List available backup versions
    -p, --previous         Rollback to the immediate previous version
    -c, --current          Show current deployed version
    -h, --help             Show this help message

Examples:
    $0 --list                              # List available versions
    $0 --previous                          # Rollback to previous version
    $0 --tag abc123                        # Rollback to specific version
    $0 --tag abc123 --dry-run             # Preview changes without applying

EOF
}

get_current_version() {
    if [ ! -f "$DEPLOYMENT_FILE" ]; then
        log_error "Deployment file not found: $DEPLOYMENT_FILE"
        exit 1
    fi
    
    CURRENT_IMAGE=$(grep "image:" "$DEPLOYMENT_FILE" | head -1 | awk '{print $2}')
    CURRENT_TAG=$(echo "$CURRENT_IMAGE" | cut -d: -f2)
    echo "$CURRENT_TAG"
}

list_backups() {
    log_info "Available backup versions:"
    echo ""
    
    if [ -d "$BACKUP_DIR" ]; then
        ls -lt "$BACKUP_DIR" | grep "deployment-" | awk '{print $9}' | while read -r backup; do
            TAG=$(echo "$backup" | sed 's/deployment-.*-\(.*\)\.yaml/\1/')
            TIMESTAMP=$(echo "$backup" | sed 's/deployment-\(.*\)-.*\.yaml/\1/')
            echo "  📦 Tag: $TAG (Backup: $TIMESTAMP)"
        done
    else
        log_warn "No backup directory found"
    fi
    
    echo ""
    log_info "Git commit history (last 10 deployments):"
    git log --grep="Update image to" -n 10 --pretty=format:"  🔖 %h - %s (%ar)" | sed 's/Update image to /Tag: /g'
}

get_previous_version() {
    PREVIOUS_COMMIT=$(git log --grep="Update image to" -n 2 --pretty=format:"%H" | tail -1)
    
    if [ -z "$PREVIOUS_COMMIT" ]; then
        log_error "Could not find previous deployment in git history"
        exit 1
    fi
    
    git show "$PREVIOUS_COMMIT:$DEPLOYMENT_FILE" | grep "image:" | head -1 | awk '{print $2}' | cut -d: -f2
}

verify_image_exists() {
    local TAG=$1
    local IMAGE="${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${TAG}"
    
    log_info "Verifying image exists: $IMAGE"
    
    if command -v skopeo &> /dev/null; then
        if skopeo inspect "docker://${IMAGE}" &> /dev/null; then
            log_info "✅ Image verified: $IMAGE"
            return 0
        else
            log_error "❌ Image not found in Harbor: $IMAGE"
            return 1
        fi
    else
        log_warn "skopeo not installed, skipping image verification"
        log_warn "Install skopeo: sudo apt-get install skopeo"
        return 0
    fi
}

backup_current_state() {
    local CURRENT_TAG=$1
    local BACKUP_FILE="${BACKUP_DIR}/deployment-$(date +%Y%m%d-%H%M%S)-${CURRENT_TAG}.yaml"
    
    mkdir -p "$BACKUP_DIR"
    cp "$DEPLOYMENT_FILE" "$BACKUP_FILE"
    
    log_info "Current state backed up to: $BACKUP_FILE"
}

perform_rollback() {
    local TARGET_TAG=$1
    local DRY_RUN=$2
    
    CURRENT_TAG=$(get_current_version)
    log_info "Current version: $CURRENT_TAG"
    log_info "Target version: $TARGET_TAG"
    
    if [ "$CURRENT_TAG" == "$TARGET_TAG" ]; then
        log_warn "Target version is the same as current version"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Verify target image exists
    if ! verify_image_exists "$TARGET_TAG"; then
        log_error "Cannot rollback to non-existent image"
        exit 1
    fi
    
    # Backup current state
    backup_current_state "$CURRENT_TAG"
    
    # Prepare new image reference
    NEW_IMAGE="${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${TARGET_TAG}"
    
    if [ "$DRY_RUN" == "true" ]; then
        log_info "DRY RUN - Would update image to: $NEW_IMAGE"
        log_info "Current content:"
        grep "image:" "$DEPLOYMENT_FILE"
        echo ""
        log_info "Would become:"
        sed "s|image: ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:.*|image: $NEW_IMAGE|g" "$DEPLOYMENT_FILE" | grep "image:"
        return 0
    fi
    
    # Perform the rollback
    log_info "Updating deployment manifest..."
    sed -i "s|image: ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:.*|image: $NEW_IMAGE|g" "$DEPLOYMENT_FILE"
    
    log_info "Updated manifest:"
    grep "image:" "$DEPLOYMENT_FILE"
    
    # Commit and push
    git config user.name "Manual Rollback"
    git config user.email "ops@example.com"
    
    git add "$DEPLOYMENT_FILE"
    
    if git diff --staged --quiet; then
        log_warn "No changes to commit"
    else
        git commit -m "⏮️ Manual rollback to version $TARGET_TAG from $CURRENT_TAG [skip ci]"
        log_info "Pushing to repository..."
        git push
        log_info "✅ Rollback committed and pushed"
    fi
    
    # Wait for ArgoCD
    log_info "Waiting for ArgoCD to sync..."
    log_info "Monitor deployment: kubectl rollout status deployment/$IMAGE_NAME -n $NAMESPACE"
    
    # Optional: Verify deployment
    if command -v kubectl &> /dev/null; then
        log_info "Checking deployment status..."
        sleep 10
        kubectl rollout status deployment/"$IMAGE_NAME" -n "$NAMESPACE" --timeout=5m || {
            log_error "Deployment rollout failed!"
            log_error "Check status: kubectl get pods -n $NAMESPACE"
            exit 1
        }
        log_info "✅ Deployment rolled back successfully!"
    else
        log_warn "kubectl not available, cannot verify deployment"
        log_info "Monitor manually: kubectl rollout status deployment/$IMAGE_NAME -n $NAMESPACE"
    fi
    
    # Send metrics to Prometheus (if pushgateway is available)
    if command -v curl &> /dev/null; then
        cat <<EOF | curl --data-binary @- http://prometheus-pushgateway.monitoring.svc.cluster.local:9091/metrics/job/manual_rollback 2>/dev/null || true
# HELP manual_rollback_total Manual rollback operations
# TYPE manual_rollback_total counter
manual_rollback_total{from_tag="$CURRENT_TAG",to_tag="$TARGET_TAG",image="$IMAGE_NAME"} 1
EOF
    fi
}

# Parse arguments
DRY_RUN=false
TARGET_TAG=""
ACTION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -l|--list)
            ACTION="list"
            shift
            ;;
        -c|--current)
            ACTION="current"
            shift
            ;;
        -p|--previous)
            ACTION="previous"
            shift
            ;;
        -t|--tag)
            TARGET_TAG="$2"
            ACTION="rollback"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Execute action
case $ACTION in
    list)
        list_backups
        ;;
    current)
        CURRENT=$(get_current_version)
        log_info "Current deployed version: $CURRENT"
        ;;
    previous)
        PREVIOUS=$(get_previous_version)
        log_info "Previous version: $PREVIOUS"
        echo ""
        read -p "Rollback to $PREVIOUS? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            perform_rollback "$PREVIOUS" "$DRY_RUN"
        else
            log_info "Rollback cancelled"
        fi
        ;;
    rollback)
        if [ -z "$TARGET_TAG" ]; then
            log_error "Target tag not specified"
            show_usage
            exit 1
        fi
        perform_rollback "$TARGET_TAG" "$DRY_RUN"
        ;;
    *)
        log_error "No action specified"
        show_usage
        exit 1
        ;;
esac
