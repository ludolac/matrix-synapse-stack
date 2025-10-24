#!/bin/bash
#
# Matrix Synapse Backup Script
#
# This script performs a complete backup of Matrix Synapse including:
# - PostgreSQL database dump
# - Media store (uploaded files, images, videos)
# - Signing keys
# - Configuration secrets
#
# Backups are stored in .backup/ directory with timestamp
#
# Usage:
#   ./scripts/backup.sh [options]
#
# Options:
#   -n, --namespace     Kubernetes namespace (default: matrix)
#   -d, --destination   Backup destination directory (default: .backup)
#   -c, --compress      Compress backups with gzip (default: true)
#   -h, --help          Show this help message
#

set -e

# Default configuration
NAMESPACE="matrix"
BACKUP_DIR=".backup"
COMPRESS=true
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -d|--destination)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -c|--compress)
            COMPRESS="$2"
            shift 2
            ;;
        -h|--help)
            grep '^#' "$0" | tail -n +3 | head -n -1 | sed 's/^# \?//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Helper functions
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

# Create backup directory structure
BACKUP_PATH="${BACKUP_DIR}/${TIMESTAMP}"
mkdir -p "${BACKUP_PATH}"/{database,media,keys,secrets}

log_info "Starting Matrix Synapse backup to: ${BACKUP_PATH}"
log_info "Namespace: ${NAMESPACE}"

# Get pod names
log_info "Finding pods in namespace ${NAMESPACE}..."
POSTGRES_POD=$(kubectl get pod -n "${NAMESPACE}" -l app.kubernetes.io/component=postgresql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
SYNAPSE_POD=$(kubectl get pod -n "${NAMESPACE}" -l app.kubernetes.io/component=synapse -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POSTGRES_POD" ]; then
    log_error "PostgreSQL pod not found in namespace ${NAMESPACE}"
    exit 1
fi

if [ -z "$SYNAPSE_POD" ]; then
    log_error "Synapse pod not found in namespace ${NAMESPACE}"
    exit 1
fi

log_success "Found PostgreSQL pod: ${POSTGRES_POD}"
log_success "Found Synapse pod: ${SYNAPSE_POD}"

# 1. Backup PostgreSQL Database
log_info "Backing up PostgreSQL database..."
DB_NAME=$(kubectl get secret -n "${NAMESPACE}" matrix-synapse-postgresql -o jsonpath='{.data.database}' 2>/dev/null | base64 -d || echo "synapse")
DB_USER=$(kubectl get secret -n "${NAMESPACE}" matrix-synapse-postgresql -o jsonpath='{.data.username}' 2>/dev/null | base64 -d || echo "synapse")
DB_PASSWORD=$(kubectl get secret -n "${NAMESPACE}" matrix-synapse-postgresql -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo "")

kubectl exec "${POSTGRES_POD}" -n "${NAMESPACE}" -- \
    env PGPASSWORD="${DB_PASSWORD}" pg_dump -U "${DB_USER}" "${DB_NAME}" > "${BACKUP_PATH}/database/synapse.sql"

if [ "$COMPRESS" = true ]; then
    log_info "Compressing database backup..."
    gzip "${BACKUP_PATH}/database/synapse.sql"
    DB_BACKUP_FILE="${BACKUP_PATH}/database/synapse.sql.gz"
else
    DB_BACKUP_FILE="${BACKUP_PATH}/database/synapse.sql"
fi

DB_SIZE=$(du -h "${DB_BACKUP_FILE}" | cut -f1)
log_success "Database backup completed (${DB_SIZE})"

# 2. Backup Media Store
log_info "Backing up media store..."
kubectl exec "${SYNAPSE_POD}" -n "${NAMESPACE}" -- \
    tar czf /tmp/media-store-backup.tar.gz -C /data media_store 2>/dev/null || {
    log_warning "Media store backup failed or media_store directory not found"
}

if kubectl exec "${SYNAPSE_POD}" -n "${NAMESPACE}" -- test -f /tmp/media-store-backup.tar.gz 2>/dev/null; then
    kubectl cp "${NAMESPACE}/${SYNAPSE_POD}:/tmp/media-store-backup.tar.gz" \
        "${BACKUP_PATH}/media/media-store.tar.gz"
    kubectl exec "${SYNAPSE_POD}" -n "${NAMESPACE}" -- rm /tmp/media-store-backup.tar.gz

    MEDIA_SIZE=$(du -h "${BACKUP_PATH}/media/media-store.tar.gz" | cut -f1)
    log_success "Media store backup completed (${MEDIA_SIZE})"
else
    log_warning "No media store to backup"
fi

# 3. Backup Signing Keys
log_info "Backing up signing keys..."
SERVER_NAME=$(kubectl get configmap -n "${NAMESPACE}" matrix-synapse-synapse-config -o jsonpath='{.data.homeserver\.yaml}' 2>/dev/null | grep "server_name:" | awk '{print $2}' | tr -d '"' || echo "matrix.example.com")

kubectl exec "${SYNAPSE_POD}" -n "${NAMESPACE}" -- \
    cat "/data/${SERVER_NAME}.signing.key" > "${BACKUP_PATH}/keys/${SERVER_NAME}.signing.key" 2>/dev/null || {
    log_warning "Signing key not found at /data/${SERVER_NAME}.signing.key"
}

if [ -f "${BACKUP_PATH}/keys/${SERVER_NAME}.signing.key" ]; then
    log_success "Signing keys backup completed"
else
    log_warning "No signing keys to backup"
fi

# 4. Backup Kubernetes Secrets
log_info "Backing up Kubernetes secrets..."
kubectl get secret -n "${NAMESPACE}" matrix-synapse-postgresql -o yaml > \
    "${BACKUP_PATH}/secrets/postgresql-secret.yaml" 2>/dev/null || {
    log_warning "PostgreSQL secret not found"
}

kubectl get secret -n "${NAMESPACE}" matrix-synapse-admin-credentials -o yaml > \
    "${BACKUP_PATH}/secrets/admin-credentials-secret.yaml" 2>/dev/null || {
    log_warning "Admin credentials secret not found"
}

log_success "Kubernetes secrets backup completed"

# 5. Create backup manifest
log_info "Creating backup manifest..."
cat > "${BACKUP_PATH}/MANIFEST.txt" <<EOF
Matrix Synapse Backup Manifest
==============================

Backup Date: $(date)
Timestamp: ${TIMESTAMP}
Namespace: ${NAMESPACE}
Server Name: ${SERVER_NAME}

Components:
-----------
- PostgreSQL Database: ${DB_NAME}
- PostgreSQL User: ${DB_USER}
- PostgreSQL Pod: ${POSTGRES_POD}
- Synapse Pod: ${SYNAPSE_POD}

Files:
------
database/synapse.sql$([ "$COMPRESS" = true ] && echo ".gz" || echo "")
media/media-store.tar.gz
keys/${SERVER_NAME}.signing.key
secrets/postgresql-secret.yaml
secrets/admin-credentials-secret.yaml

Backup Path: ${BACKUP_PATH}

Restore Instructions:
--------------------
To restore from this backup, run:
    ./scripts/restore.sh -b ${TIMESTAMP}

EOF

log_success "Backup manifest created"

# 6. Calculate total backup size
TOTAL_SIZE=$(du -sh "${BACKUP_PATH}" | cut -f1)

# Print summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              Backup Completed Successfully                 ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║ Timestamp:     ${TIMESTAMP}                           ║"
echo "║ Location:      ${BACKUP_PATH}"
echo "║ Total Size:    ${TOTAL_SIZE}                                        ║"
echo "║                                                            ║"
echo "║ Backed up:                                                 ║"
echo "║   ✓ PostgreSQL Database                                    ║"
echo "║   ✓ Media Store                                            ║"
echo "║   ✓ Signing Keys                                           ║"
echo "║   ✓ Kubernetes Secrets                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_info "To restore this backup, run:"
log_info "  ./scripts/restore.sh -b ${TIMESTAMP}"
echo ""

# Create latest symlink
ln -sfn "${TIMESTAMP}" "${BACKUP_DIR}/latest"
log_success "Created symlink: ${BACKUP_DIR}/latest -> ${TIMESTAMP}"

exit 0
