#!/bin/bash
# Matrix Synapse + Authelia SSO Setup Script
# This script helps configure Authelia as SSO provider for Matrix Synapse

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

echo ""
echo "=========================================="
echo "  Matrix Synapse + Authelia SSO Setup"
echo "=========================================="
echo ""

# Step 1: Generate client secret
print_info "Step 1: Generating OIDC client secret..."
CLIENT_SECRET=$(openssl rand -hex 32)
print_success "Client secret generated!"
echo ""
echo "  ${GREEN}Plain Secret (for Matrix):${NC}"
echo "  ${CLIENT_SECRET}"
echo ""

# Step 2: Get Authelia pod for hashing
print_info "Step 2: Getting Authelia pod..."
AUTHELIA_POD=$(kubectl get pod -n authentif -l app.kubernetes.io/name=authelia -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$AUTHELIA_POD" ]; then
    print_error "Authelia pod not found in 'authentif' namespace"
    print_info "Please ensure Authelia is running: kubectl get pods -n authentif"
    exit 1
fi

print_success "Found Authelia pod: $AUTHELIA_POD"
echo ""

# Step 3: Hash the secret for Authelia
print_info "Step 3: Hashing secret for Authelia..."
print_info "This may take a few seconds..."

HASHED_SECRET=$(kubectl exec -n authentif $AUTHELIA_POD -- \
    authelia crypto hash generate pbkdf2 --password "$CLIENT_SECRET" 2>/dev/null | grep "^Digest:" | awk '{print $2}')

if [ -z "$HASHED_SECRET" ]; then
    print_error "Failed to hash secret"
    print_info "You can manually hash it later with:"
    echo "  kubectl exec -n authentif $AUTHELIA_POD -- authelia crypto hash generate pbkdf2 --password '$CLIENT_SECRET'"
    exit 1
fi

print_success "Secret hashed successfully!"
echo ""
echo "  ${GREEN}Hashed Secret (for Authelia):${NC}"
echo "  ${HASHED_SECRET}"
echo ""

# Step 4: Create Authelia client configuration
print_info "Step 4: Creating Authelia client configuration..."

AUTHELIA_CONFIG=$(cat <<EOF
# Add this to your Authelia configuration
# (identity_providers.oidc.clients section)

      - id: matrix
        description: Matrix Synapse Homeserver
        secret: '${HASHED_SECRET}'
        public: false
        authorization_policy: one_factor  # Change to 'one_factor' if no 2FA
        redirect_uris:
          - https://matrix.waadoo.ovh/_synapse/client/oidc/callback
        scopes:
          - openid
          - profile
          - email
          - groups
        userinfo_signing_algorithm: none
        token_endpoint_auth_method: client_secret_post
EOF
)

# Save to file
echo "$AUTHELIA_CONFIG" > /tmp/authelia-matrix-client.yaml

print_success "Authelia configuration saved to: /tmp/authelia-matrix-client.yaml"
echo ""
echo "$AUTHELIA_CONFIG"
echo ""

# Step 5: Update values-prod.yaml
print_info "Step 5: Updating values-prod.yaml..."

VALUES_FILE="values-prod.yaml"

if [ ! -f "$VALUES_FILE" ]; then
    print_error "values-prod.yaml not found!"
    print_info "Please run this script from the chart directory"
    exit 1
fi

# Check if SSO is already configured
if grep -q "client_secret: \"CHANGE_ME_MATRIX_CLIENT_SECRET\"" "$VALUES_FILE"; then
    # Replace the placeholder
    sed -i.bak "s/CHANGE_ME_MATRIX_CLIENT_SECRET/${CLIENT_SECRET}/" "$VALUES_FILE"
    print_success "Updated client_secret in values-prod.yaml"
    print_info "Backup saved to: values-prod.yaml.bak"
else
    print_warning "client_secret already configured or SSO section not found"
    print_info "Please manually update values-prod.yaml with:"
    echo "  client_secret: \"${CLIENT_SECRET}\""
fi

echo ""

# Step 6: Instructions
print_info "=========================================="
print_info "  Next Steps"
print_info "=========================================="
echo ""
echo "1. ${BLUE}Add the Matrix client to Authelia:${NC}"
echo "   kubectl edit configmap authelia -n authentif"
echo ""
echo "   Add the configuration from: /tmp/authelia-matrix-client.yaml"
echo ""
echo "2. ${BLUE}Restart Authelia:${NC}"
echo "   kubectl rollout restart deployment/authelia -n authentif"
echo ""
echo "3. ${BLUE}Wait for Authelia to be ready:${NC}"
echo "   kubectl rollout status deployment/authelia -n authentif"
echo ""
echo "4. ${BLUE}Apply Matrix configuration:${NC}"
echo "   helm upgrade matrix-synapse . --namespace matrix --values values-prod.yaml"
echo ""
echo "5. ${BLUE}Test SSO login:${NC}"
echo "   Open https://element.waadoo.ovh and click 'Sign in with SSO'"
echo ""
echo "=========================================="
echo ""

# Save credentials
CREDS_FILE=".secrets/authelia-sso-credentials.txt"
mkdir -p .secrets

cat > "$CREDS_FILE" << EOF
Matrix Synapse + Authelia SSO Credentials
==========================================
Generated: $(date)

Client ID: matrix

Plain Secret (for Matrix):
${CLIENT_SECRET}

Hashed Secret (for Authelia):
${HASHED_SECRET}

Issuer URL:
https://authelia.waadoo.ovh

Redirect URI:
https://matrix.waadoo.ovh/_synapse/client/oidc/callback

==========================================

IMPORTANT: Keep this file secure!
This file has been saved with restricted permissions (600).
EOF

chmod 600 "$CREDS_FILE"

print_success "Credentials saved to: $CREDS_FILE"
echo ""
print_info "Setup script completed!"
print_info "Follow the 'Next Steps' above to complete the configuration."
echo ""
