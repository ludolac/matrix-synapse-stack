#!/bin/bash
# Matrix Synapse User Creation Script
# Creates additional Matrix users on an existing Synapse deployment

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
USERS_DIR="${SECRETS_DIR}/users"

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

generate_password() { openssl rand -base64 32 | tr -d "=+/" | cut -c1-32; }

show_usage() {
    cat << EOF
Matrix Synapse User Creation

Usage: $0 [options]

Options:
    -u, --username USERNAME     Username (required, without @ or :domain)
    -p, --password PASSWORD     Password (optional, auto-generated if not provided)
    -e, --email EMAIL          Email address (optional)
    -a, --admin                Make user a server admin (default: false)
    -d, --display-name NAME    Display name (optional)
    -h, --help                 Show this help

Environment:
    NAMESPACE=${NAMESPACE}
    RELEASE_NAME=${RELEASE_NAME}

Examples:
    # Create regular user with auto-generated password
    $0 -u john -e john@example.com

    # Create admin user with custom password
    $0 -u alice -p MySecretPass123 -e alice@example.com -a

    # Create user with display name
    $0 -u bob -d "Bob Smith" -e bob@example.com

EOF
}

# Parse arguments
USERNAME=""
PASSWORD=""
EMAIL=""
IS_ADMIN=false
DISPLAY_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -a|--admin)
            IS_ADMIN=true
            shift
            ;;
        -d|--display-name)
            DISPLAY_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$USERNAME" ]; then
    print_error "Username is required!"
    show_usage
    exit 1
fi

# Generate password if not provided
if [ -z "$PASSWORD" ]; then
    PASSWORD=$(generate_password)
    print_info "Generated password for user '$USERNAME'"
fi

# Get server name from ConfigMap
SERVER_NAME=$(kubectl get configmap ${RELEASE_NAME}-synapse-config -n ${NAMESPACE} -o jsonpath='{.data.homeserver-override\.yaml}' 2>/dev/null | grep "^server_name:" | awk '{print $2}' | tr -d '"')

if [ -z "$SERVER_NAME" ]; then
    print_warning "Could not determine server name from ConfigMap, using default"
    SERVER_NAME="matrix.waadoo.ovh"
fi

print_info "Server name: ${SERVER_NAME}"

FULL_USERNAME="@${USERNAME}:${SERVER_NAME}"

print_info "Creating Matrix user..."
echo ""
echo "=========================================="
echo "  User Information"
echo "=========================================="
echo "Username: ${FULL_USERNAME}"
echo "Password: [Will be shown after creation]"
echo "Email: ${EMAIL:-<not set>}"
echo "Admin: ${IS_ADMIN}"
echo "Display Name: ${DISPLAY_NAME:-<not set>}"
echo "=========================================="
echo ""

# Check if user already exists
print_info "Checking if user already exists..."
HTTP_CODE=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
    curl -s -o /dev/null -w "%{http_code}" \
    http://localhost:8008/_synapse/admin/v2/users/${FULL_USERNAME} 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    print_error "User ${FULL_USERNAME} already exists!"
    exit 1
fi

# Get registration shared secret
print_info "Retrieving registration secret..."
REGISTRATION_SECRET=$(kubectl get secret ${RELEASE_NAME}-admin-credentials -n ${NAMESPACE} -o jsonpath='{.data.registration-secret}' | base64 -d)

if [ -z "$REGISTRATION_SECRET" ]; then
    print_error "Could not retrieve registration secret!"
    exit 1
fi

# Create user using register_new_matrix_user
print_info "Creating user via Synapse registration API..."

ADMIN_FLAG=""
if [ "$IS_ADMIN" = true ]; then
    ADMIN_FLAG="--admin"
else
    ADMIN_FLAG="--no-admin"
fi

# Create config file for register_new_matrix_user
kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- bash -c "
cat > /tmp/user-registration.yaml << 'EOF'
server_name: ${SERVER_NAME}
registration_shared_secret: ${REGISTRATION_SECRET}
EOF

/usr/local/bin/register_new_matrix_user \
  -c /tmp/user-registration.yaml \
  http://localhost:8008 \
  -u ${USERNAME} \
  -p '${PASSWORD}' \
  ${ADMIN_FLAG}

rm -f /tmp/user-registration.yaml
" 2>&1

if [ $? -eq 0 ]; then
    print_success "User created successfully!"

    # Save credentials to file
    mkdir -p "${USERS_DIR}"
    USER_FILE="${USERS_DIR}/${USERNAME}.txt"

    cat > "$USER_FILE" << EOF
Matrix User Credentials
========================
Created: $(date)

Username: ${USERNAME}
Full User ID: ${FULL_USERNAME}
Password: ${PASSWORD}
Email: ${EMAIL:-<not set>}
Admin: ${IS_ADMIN}
Display Name: ${DISPLAY_NAME:-<not set>}

Server: ${SERVER_NAME}
Element Web: https://element.waadoo.ovh

========================
EOF

    print_success "Credentials saved to: ${USER_FILE}"

    echo ""
    echo "=========================================="
    echo "  User Created Successfully!"
    echo "=========================================="
    echo -e "${GREEN}Username:${NC} ${FULL_USERNAME}"
    echo -e "${GREEN}Password:${NC} ${PASSWORD}"
    if [ -n "$EMAIL" ]; then
        echo -e "${GREEN}Email:${NC} ${EMAIL}"
    fi
    echo -e "${GREEN}Admin:${NC} ${IS_ADMIN}"
    if [ -n "$DISPLAY_NAME" ]; then
        echo -e "${GREEN}Display Name:${NC} ${DISPLAY_NAME}"
    fi
    echo "=========================================="
    echo ""
    print_info "The user can now log in at: https://element.waadoo.ovh"
    echo ""
else
    print_error "Failed to create user!"
    exit 1
fi
