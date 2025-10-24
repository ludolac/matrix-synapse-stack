#!/bin/bash
# Unified Matrix Synapse Secrets Management Script
# Generates and manages all required secrets for Matrix Synapse deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Defaults
NAMESPACE="${NAMESPACE:-matrix}"
RELEASE_NAME="${RELEASE_NAME:-matrix-synapse}"
SECRETS_DIR=".secrets"

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

generate_password() { openssl rand -base64 32 | tr -d "=+/" | cut -c1-32; }
generate_hex_secret() { openssl rand -hex 32; }

show_usage() {
    cat << EOF
Matrix Synapse Secrets Management

Usage: $0 [command]

Commands:
    all         Generate all secrets (PostgreSQL + Admin)
    postgres    Generate PostgreSQL credentials only
    admin       Generate admin user credentials only  
    list        List all existing secrets
    verify      Verify required secrets exist
    export      Export secrets to files
    delete      Delete all secrets
    help        Show this help

Environment:
    NAMESPACE=${NAMESPACE}
    RELEASE_NAME=${RELEASE_NAME}
EOF
}

ensure_namespace() {
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        print_info "Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
    fi
}

generate_postgres_secret() {
    local secret_name="${RELEASE_NAME}-postgresql"
    print_info "Generating PostgreSQL credentials..."

    if kubectl get secret "$secret_name" -n "$NAMESPACE" &> /dev/null; then
        print_warning "Secret exists: $secret_name"
        read -p "Recreate? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
        kubectl delete secret "$secret_name" -n "$NAMESPACE"
    fi

    local pg_password=$(generate_hex_secret)

    kubectl create secret generic "$secret_name" \
        --from-literal=postgres-password="$pg_password" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | \
    kubectl label --local -f - \
        app.kubernetes.io/managed-by=Helm \
        app.kubernetes.io/name=matrix-synapse \
        app.kubernetes.io/instance="$RELEASE_NAME" \
        --dry-run=client -o yaml | \
    kubectl annotate --local -f - \
        meta.helm.sh/release-name="$RELEASE_NAME" \
        meta.helm.sh/release-namespace="$NAMESPACE" \
        --dry-run=client -o yaml | \
    kubectl apply -f -

    print_success "PostgreSQL secret created"

    mkdir -p "$SECRETS_DIR"
    cat > "$SECRETS_DIR/postgresql-credentials.txt" << EOF
PostgreSQL Credentials
======================
Generated: $(date)
Password: $pg_password

Retrieve: kubectl get secret $secret_name -n $NAMESPACE -o jsonpath='{.data.postgres-password}' | base64 -d
EOF
    print_info "Saved to: $SECRETS_DIR/postgresql-credentials.txt"
}

generate_admin_secret() {
    local secret_name="${RELEASE_NAME}-admin-credentials"
    local username="${ADMIN_USERNAME:-admin}"
    
    print_info "Generating admin credentials..."

    if kubectl get secret "$secret_name" -n "$NAMESPACE" &> /dev/null; then
        print_warning "Secret exists: $secret_name"
        read -p "Recreate? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
        kubectl delete secret "$secret_name" -n "$NAMESPACE"
    fi

    local admin_password=$(generate_password)
    local registration_secret=$(generate_hex_secret)

    kubectl create secret generic "$secret_name" \
        --from-literal=username="$username" \
        --from-literal=password="$admin_password" \
        --from-literal=registration-secret="$registration_secret" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | \
    kubectl label --local -f - \
        app.kubernetes.io/managed-by=Helm \
        app.kubernetes.io/name=matrix-synapse \
        app.kubernetes.io/instance="$RELEASE_NAME" \
        --dry-run=client -o yaml | \
    kubectl annotate --local -f - \
        meta.helm.sh/release-name="$RELEASE_NAME" \
        meta.helm.sh/release-namespace="$NAMESPACE" \
        --dry-run=client -o yaml | \
    kubectl apply -f -

    print_success "Admin credentials created"

    mkdir -p "$SECRETS_DIR"
    cat > "$SECRETS_DIR/admin-credentials.txt" << EOF
Admin Credentials
=================
Generated: $(date)

Username: $username
Password: $admin_password
Registration Secret: $registration_secret

Retrieve:
  kubectl get secret $secret_name -n $NAMESPACE -o jsonpath='{.data.username}' | base64 -d
  kubectl get secret $secret_name -n $NAMESPACE -o jsonpath='{.data.password}' | base64 -d
  kubectl get secret $secret_name -n $NAMESPACE -o jsonpath='{.data.registration-secret}' | base64 -d
EOF
    chmod 600 "$SECRETS_DIR/admin-credentials.txt"

    echo ""
    echo "=========================================="
    echo "  Admin Credentials"
    echo "=========================================="
    echo -e "${GREEN}Username:${NC} $username"
    echo -e "${GREEN}Password:${NC} $admin_password"
    echo -e "${BLUE}Registration Secret:${NC} $registration_secret"
    echo "=========================================="
    echo ""
    print_info "Saved to: $SECRETS_DIR/admin-credentials.txt"
}

list_secrets() {
    kubectl get secrets -n "$NAMESPACE" -l app.kubernetes.io/name=matrix-synapse
}

verify_secrets() {
    local all_exist=true
    
    if kubectl get secret "${RELEASE_NAME}-postgresql" -n "$NAMESPACE" &> /dev/null; then
        print_success "PostgreSQL secret exists"
    else
        print_error "PostgreSQL secret missing"
        all_exist=false
    fi

    if kubectl get secret "${RELEASE_NAME}-admin-credentials" -n "$NAMESPACE" &> /dev/null; then
        print_success "Admin credentials exist"
    else
        print_warning "Admin credentials missing (optional)"
    fi

    [ "$all_exist" = true ]
}

export_secrets() {
    mkdir -p "$SECRETS_DIR"
    
    if kubectl get secret "${RELEASE_NAME}-postgresql" -n "$NAMESPACE" &> /dev/null; then
        kubectl get secret "${RELEASE_NAME}-postgresql" -n "$NAMESPACE" -o jsonpath='{.data.postgres-password}' | base64 -d > "$SECRETS_DIR/postgres-password.txt"
        print_success "PostgreSQL password exported"
    fi

    if kubectl get secret "${RELEASE_NAME}-admin-credentials" -n "$NAMESPACE" &> /dev/null; then
        echo "Username: $(kubectl get secret "${RELEASE_NAME}-admin-credentials" -n "$NAMESPACE" -o jsonpath='{.data.username}' | base64 -d)" > "$SECRETS_DIR/admin-export.txt"
        echo "Password: $(kubectl get secret "${RELEASE_NAME}-admin-credentials" -n "$NAMESPACE" -o jsonpath='{.data.password}' | base64 -d)" >> "$SECRETS_DIR/admin-export.txt"
        chmod 600 "$SECRETS_DIR/admin-export.txt"
        print_success "Admin credentials exported"
    fi
}

delete_secrets() {
    print_warning "Delete ALL Matrix secrets?"
    read -p "Type 'yes': " confirm
    [ "$confirm" != "yes" ] && return
    
    kubectl delete secrets -n "$NAMESPACE" -l app.kubernetes.io/name=matrix-synapse || true
    print_success "Secrets deleted"
}

case "${1:-help}" in
    all)
        ensure_namespace
        generate_postgres_secret
        echo ""
        generate_admin_secret
        ;;
    postgres) ensure_namespace; generate_postgres_secret ;;
    admin) ensure_namespace; generate_admin_secret ;;
    list) list_secrets ;;
    verify) verify_secrets ;;
    export) export_secrets ;;
    delete) delete_secrets ;;
    *) show_usage ;;
esac
