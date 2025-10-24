#!/bin/bash
#
# Matrix Synapse Restore Script
#
# This script performs a complete restore of Matrix Synapse from backup including:
# - PostgreSQL database
# - Media store
# - Signing keys
# - Configuration secrets
#
# Usage:
#   ./scripts/restore.sh [options]
#
# Options:
#   -b, --backup        Backup timestamp to restore (required)
#   -n, --namespace     Kubernetes namespace (default: matrix)
#   -d, --backup-dir    Backup directory (default: .backup)
#   -y, --yes           Skip confirmation prompts
#   -h, --help          Show this help message
#
# Examples:
#   ./scripts/restore.sh -b 20251024_120000
#   ./scripts/restore.sh -b latest -n matrix -y
#

set -e

# Default configuration
NAMESPACE="matrix"
BACKUP_DIR=".backup"
BACKUP_TIMESTAMP=""
SKIP_CONFIRM=false

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--backup)
            BACKUP_TIMESTAMP="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -d|--backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
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

# Validate required parameters
if [ -z "$BACKUP_TIMESTAMP" ]; then
    log_error "Backup timestamp is required. Use -b or --backup option."
    echo "Available backups:"
    ls -1 "${BACKUP_DIR}" 2>/dev/null | grep -v "^latest$" || echo "  No backups found"
    exit 1
fi

# Resolve backup path
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_TIMESTAMP}"
if [ ! -d "$BACKUP_PATH" ]; then
    log_error "Backup not found: ${BACKUP_PATH}"
    echo "Available backups:"
    ls -1 "${BACKUP_DIR}" 2>/dev/null | grep -v "^latest$" || echo "  No backups found"
    exit 1
fi

log_info "Restore configuration:"
log_info "  Backup: ${BACKUP_TIMESTAMP}"
log_info "  Path: ${BACKUP_PATH}"
log_info "  Namespace: ${NAMESPACE}"

# Confirmation prompt
if [ "$SKIP_CONFIRM" = false ]; then
    echo ""
    echo -e "${RED}WARNING: This will restore Matrix Synapse from backup!${NC}"
    echo -e "${RED}This operation will:${NC}"
    echo "  1. DROP and restore the PostgreSQL database"
    echo "  2. Replace all media files"
    echo "  3. Replace signing keys"
    echo "  4. Restore Kubernetes secrets"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Restore cancelled by user"
        exit 0
    fi
fi

# Read manifest
if [ -f "${BACKUP_PATH}/MANIFEST.txt" ]; then
    log_info "Backup manifest:"
    cat "${BACKUP_PATH}/MANIFEST.txt"
    echo ""
fi

# Get pod names
log_info "Finding pods in namespace ${NAMESPACE}..."
POSTGRES_POD=$(kubectl get pod -n "${NAMESPACE}" -l app.kubernetes.io/component=postgresql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
SYNAPSE_POD=$(kubectl get pod -n "${NAMESPACE}" -l app.kubernetes.io/component=synapse -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POSTGRES_POD" ]; then
    log_error "PostgreSQL pod not found in namespace ${NAMESPACE}"
    log_error "Please ensure Matrix Synapse is deployed before restoring"
    exit 1
fi

if [ -z "$SYNAPSE_POD" ]; then
    log_error "Synapse pod not found in namespace ${NAMESPACE}"
    log_error "Please ensure Matrix Synapse is deployed before restoring"
    exit 1
fi

log_success "Found PostgreSQL pod: ${POSTGRES_POD}"
log_success "Found Synapse pod: ${SYNAPSE_POD}"

# Get database credentials (use trust auth on localhost - no password needed)
DB_NAME="synapse_prod"  # Default database name for this chart
DB_USER="synapse"  # Database user

log_info "Database: ${DB_NAME}, User: ${DB_USER}"

# 1. Restore Kubernetes Secrets (admin credentials only)
# Note: We DO NOT restore the PostgreSQL secret because:
# - The database has already been created with new credentials
# - Restoring old credentials would cause authentication failures
# - The synapse user in the restored DB will work with new credentials

log_warning "Skipping PostgreSQL secret restore (using current credentials)"

if [ -f "${BACKUP_PATH}/secrets/admin-credentials-secret.yaml" ]; then
    log_info "Restoring admin credentials secret..."
    kubectl delete secret matrix-synapse-admin-credentials -n "${NAMESPACE}" 2>/dev/null || true
    kubectl apply -f "${BACKUP_PATH}/secrets/admin-credentials-secret.yaml"
    log_success "Admin credentials secret restored"
else
    log_warning "Admin credentials secret not found in backup, keeping current"
fi

# 2. Restore PostgreSQL Database
log_info "Restoring PostgreSQL database..."
log_warning "This will DROP all existing data in database: ${DB_NAME}"
sleep 2

# Find the database backup file
if [ -f "${BACKUP_PATH}/database/synapse.sql.gz" ]; then
    DB_BACKUP="${BACKUP_PATH}/database/synapse.sql.gz"
    COMPRESSED=true
elif [ -f "${BACKUP_PATH}/database/synapse.sql" ]; then
    DB_BACKUP="${BACKUP_PATH}/database/synapse.sql"
    COMPRESSED=false
else
    log_error "Database backup file not found"
    exit 1
fi

log_info "Using database backup: ${DB_BACKUP}"

# Copy backup to PostgreSQL pod
log_info "Copying database backup to PostgreSQL pod..."
if [ "$COMPRESSED" = true ]; then
    kubectl cp "${DB_BACKUP}" "${NAMESPACE}/${POSTGRES_POD}:/tmp/synapse-backup.sql.gz"
    kubectl exec "${POSTGRES_POD}" -n "${NAMESPACE}" -- gunzip -f /tmp/synapse-backup.sql.gz
else
    kubectl cp "${DB_BACKUP}" "${NAMESPACE}/${POSTGRES_POD}:/tmp/synapse-backup.sql"
fi

# Scale down Synapse to prevent new connections
log_info "Scaling down Synapse deployment..."
kubectl scale deployment -n "${NAMESPACE}" -l app.kubernetes.io/component=synapse --replicas=0
log_info "Waiting for Synapse pods to terminate..."
kubectl wait --for=delete pod -n "${NAMESPACE}" -l app.kubernetes.io/component=synapse --timeout=60s 2>/dev/null || true

# Terminate all remaining connections to the database
log_info "Terminating any remaining database connections..."
kubectl exec "${POSTGRES_POD}" -n "${NAMESPACE}" -- \
    psql -h 127.0.0.1 -U "${DB_USER}" postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}' AND pid <> pg_backend_pid();" || true

# Drop and recreate database using trust authentication
log_info "Dropping and recreating database..."
kubectl exec "${POSTGRES_POD}" -n "${NAMESPACE}" -- \
    psql -h 127.0.0.1 -U "${DB_USER}" postgres -c "DROP DATABASE IF EXISTS ${DB_NAME};"
kubectl exec "${POSTGRES_POD}" -n "${NAMESPACE}" -- \
    psql -h 127.0.0.1 -U "${DB_USER}" postgres -c "CREATE DATABASE ${DB_NAME};"

# Restore database
log_info "Restoring database (this may take a while)..."
kubectl exec "${POSTGRES_POD}" -n "${NAMESPACE}" -- \
    psql -h 127.0.0.1 -U "${DB_USER}" "${DB_NAME}" -f /tmp/synapse-backup.sql

# Cleanup
kubectl exec "${POSTGRES_POD}" -n "${NAMESPACE}" -- rm /tmp/synapse-backup.sql

log_success "Database restored successfully"

# 3. Scale Synapse back up (before restoring media/keys)
log_info "Scaling Synapse back up..."
kubectl scale deployment -n "${NAMESPACE}" -l app.kubernetes.io/component=synapse --replicas=1

log_info "Waiting for Synapse to be ready..."
kubectl wait --for=condition=ready pod -n "${NAMESPACE}" -l app.kubernetes.io/component=synapse --timeout=300s

# Get the new Synapse pod name
SYNAPSE_POD=$(kubectl get pod -n "${NAMESPACE}" -l app.kubernetes.io/component=synapse -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$SYNAPSE_POD" ]; then
    log_error "Synapse pod not found after scaling up"
    exit 1
fi

log_success "Synapse started successfully: ${SYNAPSE_POD}"

# 4. Restore Media Store
if [ -f "${BACKUP_PATH}/media/media-store.tar.gz" ]; then
    log_info "Restoring media store..."

    # Copy media backup to Synapse pod
    kubectl cp "${BACKUP_PATH}/media/media-store.tar.gz" \
        "${NAMESPACE}/${SYNAPSE_POD}:/tmp/media-store-backup.tar.gz"

    # Remove old media store and extract backup
    kubectl exec "${SYNAPSE_POD}" -n "${NAMESPACE}" -- \
        bash -c "rm -rf /data/media_store && tar xzf /tmp/media-store-backup.tar.gz -C /data/"

    # Cleanup
    kubectl exec "${SYNAPSE_POD}" -n "${NAMESPACE}" -- rm /tmp/media-store-backup.tar.gz

    log_success "Media store restored successfully"
else
    log_warning "No media store backup found, skipping"
fi

# 5. Restore Signing Keys
SIGNING_KEY=$(ls "${BACKUP_PATH}/keys/"*.signing.key 2>/dev/null | head -n 1)
if [ -n "$SIGNING_KEY" ]; then
    log_info "Restoring signing keys..."
    KEY_FILENAME=$(basename "$SIGNING_KEY")

    kubectl cp "$SIGNING_KEY" "${NAMESPACE}/${SYNAPSE_POD}:/data/${KEY_FILENAME}"

    log_success "Signing keys restored: ${KEY_FILENAME}"
else
    log_warning "No signing keys found in backup, skipping"
fi

# 6. Restart Synapse to load restored files
log_info "Restarting Synapse to apply changes..."
kubectl rollout restart deployment -n "${NAMESPACE}" -l app.kubernetes.io/component=synapse

log_info "Waiting for Synapse to be ready..."
kubectl rollout status deployment -n "${NAMESPACE}" -l app.kubernetes.io/component=synapse --timeout=300s

log_success "Synapse restarted successfully"

# Print summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              Restore Completed Successfully                ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║ Backup:        ${BACKUP_TIMESTAMP}                           ║"
echo "║ Namespace:     ${NAMESPACE}                                       ║"
echo "║                                                            ║"
echo "║ Restored:                                                  ║"
echo "║   ✓ PostgreSQL Database                                    ║"
echo "║   ✓ Media Store                                            ║"
echo "║   ✓ Signing Keys                                           ║"
echo "║   ✓ Kubernetes Secrets                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_info "Matrix Synapse has been restored from backup: ${BACKUP_TIMESTAMP}"
log_info "Please verify the restoration by:"
log_info "  1. Logging into Element Web"
log_info "  2. Checking messages and rooms"
log_info "  3. Testing media uploads"
echo ""

exit 0
