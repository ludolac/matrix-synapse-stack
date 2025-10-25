#!/bin/bash
# Matrix Synapse Administration Script
# Manage users and rooms on Matrix Synapse

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
Matrix Synapse Administration Tool

Usage: $0 <command> [options]

User Management Commands:
    create              Create a new user
    list                List all users on the server
    info                Show detailed user information
    delete              Delete a user (permanently erase account and data)
    update-password     Update a user's password
    deactivate          Deactivate a user account (keeps data, prevents login)

Room Management Commands:
    room-list           List all rooms on the server
    room-info           Show detailed room information
    room-create         Create a new room
    room-delete         Delete a room

Create Options:
    -u, --username USERNAME     Username (required, without @ or :domain)
    -p, --password PASSWORD     Password (optional, auto-generated if not provided)
    -e, --email EMAIL          Email address (optional)
    -a, --admin                Make user a server admin (default: false)
    -d, --display-name NAME    Display name (optional)

Delete Options:
    -u, --username USERNAME     Username to delete (required, without @ or :domain)
    -y, --yes                  Skip confirmation prompt

Update Password Options:
    -u, --username USERNAME     Username (required, without @ or :domain)
    -p, --password PASSWORD     New password (optional, auto-generated if not provided)
    -y, --yes                  Skip confirmation prompt

Deactivate Options:
    -u, --username USERNAME     Username to deactivate (required, without @ or :domain)
    -y, --yes                  Skip confirmation prompt

User Info Options:
    -u, --username USERNAME     Username to query (required)

List Options:
    --guests               Show only guest users
    --admins               Show only admin users
    --deactivated          Show only deactivated users

Room List Options:
    --limit N              Limit results (default: 100)
    --order-by FIELD       Order by: name, joined_members (default: name)

Room Info Options:
    -r, --room ROOM_ID         Room ID (required)

Room Create Options:
    -n, --name NAME            Room name (required)
    -t, --topic TOPIC          Room topic (optional)
    -a, --alias ALIAS          Room alias (optional)
    --public                   Make room public (default: private)

Room Delete Options:
    -r, --room ROOM_ID         Room ID to delete (required)
    -y, --yes                  Skip confirmation
    --purge                    Purge room history

General Options:
    -h, --help                 Show this help

Environment:
    NAMESPACE=${NAMESPACE}
    RELEASE_NAME=${RELEASE_NAME}

Examples:
    # Create regular user with auto-generated password
    $0 create -u john -e john@example.com

    # Create admin user with custom password
    $0 create -u alice -p MySecretPass123 -e alice@example.com -a

    # List all users
    $0 list

    # List only admin users
    $0 list --admins

    # Update user password (auto-generated)
    $0 update-password -u john

    # Update user password (custom)
    $0 update-password -u john -p NewPassword123

    # Deactivate user (keeps data, prevents login)
    $0 deactivate -u john

    # Delete user (permanently erase all data)
    $0 delete -u john

    # Delete without confirmation
    $0 delete -u john -y

    # Show detailed user info
    $0 info -u john

    # List all rooms
    $0 room-list

    # Show room details
    $0 room-info -r '!abc123:matrix.waadoo.ovh'

    # Create a public room
    $0 room-create -n "General Chat" -a general --public

    # Delete room with history purge
    $0 room-delete -r '!abc123:matrix.waadoo.ovh' --purge -y

EOF
}

# List users function
list_users() {
    local FILTER=""
    local SHOW_GUESTS=false
    local SHOW_ADMINS=false
    local SHOW_DEACTIVATED=false

    # Parse list options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --guests)
                SHOW_GUESTS=true
                shift
                ;;
            --admins)
                SHOW_ADMINS=true
                shift
                ;;
            --deactivated)
                SHOW_DEACTIVATED=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option for list command: $1"
                exit 1
                ;;
        esac
    done

    print_info "Fetching users from Matrix Synapse..."

    # Get admin credentials for API access
    ADMIN_USER=$(kubectl get secret ${RELEASE_NAME}-admin-credentials -n ${NAMESPACE} -o jsonpath='{.data.username}' 2>/dev/null | base64 -d)
    ADMIN_PASS=$(kubectl get secret ${RELEASE_NAME}-admin-credentials -n ${NAMESPACE} -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)

    if [ -z "$ADMIN_USER" ] || [ -z "$ADMIN_PASS" ]; then
        print_error "Could not retrieve admin credentials!"
        exit 1
    fi

    # Get server name
    SERVER_NAME=$(kubectl get configmap ${RELEASE_NAME}-synapse-config -n ${NAMESPACE} -o jsonpath='{.data.homeserver-override\.yaml}' 2>/dev/null | grep "^server_name:" | awk '{print $2}' | tr -d '"')

    # Get access token
    print_info "Authenticating..."
    TOKEN_RESPONSE=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X POST http://localhost:8008/_matrix/client/r0/login \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"m.login.password\",\"user\":\"${ADMIN_USER}\",\"password\":\"${ADMIN_PASS}\"}" 2>/dev/null)

    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "Failed to authenticate. Check admin credentials."
        exit 1
    fi

    # Fetch users list
    USERS_JSON=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X GET "http://localhost:8008/_synapse/admin/v2/users?from=0&limit=1000" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" 2>/dev/null)

    # Parse and display users
    echo ""
    echo "=========================================="
    echo "  Matrix Synapse Users"
    echo "=========================================="
    printf "%-30s %-10s %-12s %-12s\n" "Username" "Admin" "Guest" "Status"
    echo "----------------------------------------"

    # Convert bash booleans to Python booleans
    local SHOW_ADMINS_PY="True"
    local SHOW_GUESTS_PY="True"
    local SHOW_DEACTIVATED_PY="True"
    [ "$SHOW_ADMINS" = "true" ] && SHOW_ADMINS_PY="True" || SHOW_ADMINS_PY="False"
    [ "$SHOW_GUESTS" = "true" ] && SHOW_GUESTS_PY="True" || SHOW_GUESTS_PY="False"
    [ "$SHOW_DEACTIVATED" = "true" ] && SHOW_DEACTIVATED_PY="True" || SHOW_DEACTIVATED_PY="False"

    # Use Python to parse JSON if available, otherwise use grep/sed
    if command -v python3 &> /dev/null; then
        echo "$USERS_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for user in data.get('users', []):
    username = user.get('name', '')
    is_admin = user.get('admin', False)
    is_guest = user.get('user_type', '') == 'guest'
    is_deactivated = user.get('deactivated', False)

    # Apply filters
    if $SHOW_ADMINS_PY and not is_admin:
        continue
    if $SHOW_GUESTS_PY and not is_guest:
        continue
    if $SHOW_DEACTIVATED_PY and not is_deactivated:
        continue

    status = 'Deactivated' if is_deactivated else 'Active'
    admin_str = 'Yes' if is_admin else 'No'
    guest_str = 'Yes' if is_guest else 'No'

    print(f'{username:<30} {admin_str:<10} {guest_str:<12} {status:<12}')
"
    else
        # Fallback to basic parsing
        echo "$USERS_JSON" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | while read -r username; do
            printf "%-30s %-10s %-12s %-12s\n" "$username" "?" "?" "?"
        done
        print_warning "Install python3 for detailed user information"
    fi

    echo "=========================================="
    echo ""

    # Count users
    TOTAL_USERS=$(echo "$USERS_JSON" | grep -o '"name"' | wc -l | tr -d ' ')
    print_success "Total users: ${TOTAL_USERS}"
}

# Delete user function
delete_user() {
    local USERNAME=""
    local SKIP_CONFIRM=false

    # Parse delete options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--username)
                USERNAME="$2"
                shift 2
                ;;
            -y|--yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option for delete command: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$USERNAME" ]; then
        print_error "Username is required for delete command!"
        show_usage
        exit 1
    fi

    # Get server name
    SERVER_NAME=$(kubectl get configmap ${RELEASE_NAME}-synapse-config -n ${NAMESPACE} -o jsonpath='{.data.homeserver-override\.yaml}' 2>/dev/null | grep "^server_name:" | awk '{print $2}' | tr -d '"')

    if [ -z "$SERVER_NAME" ]; then
        print_error "Could not determine server name!"
        exit 1
    fi

    FULL_USERNAME="@${USERNAME}:${SERVER_NAME}"

    # Confirmation prompt
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        print_warning "This will PERMANENTLY DELETE the user account: ${FULL_USERNAME}"
        print_warning "The user will be logged out and all their data will be erased."
        print_warning "The username will still be reserved and CANNOT be reused."
        print_warning "This action CANNOT be undone!"
        echo ""
        read -p "Are you sure you want to delete this user? (yes/no): " CONFIRM

        if [ "$CONFIRM" != "yes" ]; then
            print_info "Delete cancelled."
            exit 0
        fi
    fi

    # Get admin credentials
    ADMIN_USER=$(kubectl get secret ${RELEASE_NAME}-admin-credentials -n ${NAMESPACE} -o jsonpath='{.data.username}' 2>/dev/null | base64 -d)
    ADMIN_PASS=$(kubectl get secret ${RELEASE_NAME}-admin-credentials -n ${NAMESPACE} -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)

    if [ -z "$ADMIN_USER" ] || [ -z "$ADMIN_PASS" ]; then
        print_error "Could not retrieve admin credentials!"
        exit 1
    fi

    # Get access token
    print_info "Authenticating..."
    TOKEN_RESPONSE=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X POST http://localhost:8008/_matrix/client/r0/login \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"m.login.password\",\"user\":\"${ADMIN_USER}\",\"password\":\"${ADMIN_PASS}\"}" 2>/dev/null)

    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "Failed to authenticate. Check admin credentials."
        exit 1
    fi

    # Delete user (erase all data)
    print_info "Deleting user ${FULL_USERNAME} and erasing all data..."
    DELETE_RESPONSE=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X POST "http://localhost:8008/_synapse/admin/v1/deactivate/${FULL_USERNAME}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{"erase":true}' 2>/dev/null)

    # Check if successful
    if echo "$DELETE_RESPONSE" | grep -q '"id_server_unbind_result"'; then
        print_success "User ${FULL_USERNAME} has been deleted and all data erased!"

        # Remove local credential file if exists
        if [ -f "${USERS_DIR}/${USERNAME}.txt" ]; then
            rm -f "${USERS_DIR}/${USERNAME}.txt"
            print_info "Removed local credential file"
        fi

        echo ""
        echo "=========================================="
        echo "  User Deleted"
        echo "=========================================="
        echo "Username: ${FULL_USERNAME}"
        echo "Status: Deleted (data erased)"
        echo ""
        print_warning "Note: The username '${USERNAME}' is now reserved"
        print_warning "and CANNOT be reused for a new account."
        print_warning "This is a Matrix Synapse limitation."
        echo "=========================================="
        echo ""
    else
        print_error "Failed to delete user!"
        print_error "Response: ${DELETE_RESPONSE}"
        exit 1
    fi
}

# Update password function
update_password() {
    local USERNAME=""
    local PASSWORD=""
    local SKIP_CONFIRM=false

    # Parse options
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
            -y|--yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option for update-password command: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$USERNAME" ]; then
        print_error "Username is required for update-password command!"
        show_usage
        exit 1
    fi

    # Generate password if not provided
    if [ -z "$PASSWORD" ]; then
        PASSWORD=$(generate_password)
        print_info "Auto-generated password for user"
    fi

    # Get server name
    SERVER_NAME=$(kubectl get configmap ${RELEASE_NAME}-synapse-config -n ${NAMESPACE} -o jsonpath='{.data.homeserver-override\.yaml}' 2>/dev/null | grep "^server_name:" | awk '{print $2}' | tr -d '"')

    if [ -z "$SERVER_NAME" ]; then
        print_error "Could not determine server name!"
        exit 1
    fi

    FULL_USERNAME="@${USERNAME}:${SERVER_NAME}"

    # Confirmation prompt
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        print_warning "This will update the password for: ${FULL_USERNAME}"
        echo ""
        read -p "Are you sure you want to update this user's password? (yes/no): " CONFIRM

        if [ "$CONFIRM" != "yes" ]; then
            print_info "Update cancelled."
            exit 0
        fi
    fi

    # Get admin credentials
    ADMIN_USER=$(kubectl get secret ${RELEASE_NAME}-admin-credentials -n ${NAMESPACE} -o jsonpath='{.data.username}' 2>/dev/null | base64 -d)
    ADMIN_PASS=$(kubectl get secret ${RELEASE_NAME}-admin-credentials -n ${NAMESPACE} -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)

    if [ -z "$ADMIN_USER" ] || [ -z "$ADMIN_PASS" ]; then
        print_error "Could not retrieve admin credentials!"
        exit 1
    fi

    # Get access token
    print_info "Authenticating..."
    TOKEN_RESPONSE=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X POST http://localhost:8008/_matrix/client/r0/login \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"m.login.password\",\"user\":\"${ADMIN_USER}\",\"password\":\"${ADMIN_PASS}\"}" 2>/dev/null)

    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "Failed to authenticate. Check admin credentials."
        exit 1
    fi

    # Update password via Admin API
    print_info "Updating password for ${FULL_USERNAME}..."
    UPDATE_RESPONSE=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X PUT "http://localhost:8008/_synapse/admin/v2/users/${FULL_USERNAME}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"password\":\"${PASSWORD}\"}" 2>/dev/null)

    # Check if successful
    if echo "$UPDATE_RESPONSE" | grep -q '"name"'; then
        print_success "Password updated successfully for ${FULL_USERNAME}!"

        # Update local credential file if exists
        if [ -f "${USERS_DIR}/${USERNAME}.txt" ]; then
            # Read existing file to preserve other info
            EXISTING_CONTENT=$(cat "${USERS_DIR}/${USERNAME}.txt")

            # Update password line
            echo "$EXISTING_CONTENT" | sed "s/^Password:.*/Password: ${PASSWORD}/" > "${USERS_DIR}/${USERNAME}.txt"
            echo "Updated: $(date '+%Y-%m-%d %H:%M:%S')" >> "${USERS_DIR}/${USERNAME}.txt"
            print_info "Updated local credential file"
        else
            # Create new credential file
            mkdir -p "${USERS_DIR}"
            cat > "${USERS_DIR}/${USERNAME}.txt" << EOF
==========================================
  Matrix User Credentials (Password Updated)
==========================================
Username: ${USERNAME}
Full User ID: ${FULL_USERNAME}
Password: ${PASSWORD}
Updated: $(date '+%Y-%m-%d %H:%M:%S')
==========================================
EOF
            print_info "Created credential file: ${USERS_DIR}/${USERNAME}.txt"
        fi

        echo ""
        echo "=========================================="
        echo "  Password Updated"
        echo "=========================================="
        echo "Username: ${FULL_USERNAME}"
        echo "New Password: ${PASSWORD}"
        echo "=========================================="
        echo ""
        print_info "User must re-login with the new password"
    else
        print_error "Failed to update password!"
        print_error "Response: ${UPDATE_RESPONSE}"
        exit 1
    fi
}

# Deactivate user function (without erasing data)
deactivate_user() {
    local USERNAME=""
    local SKIP_CONFIRM=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--username)
                USERNAME="$2"
                shift 2
                ;;
            -y|--yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option for deactivate command: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$USERNAME" ]; then
        print_error "Username is required for deactivate command!"
        show_usage
        exit 1
    fi

    # Get server name
    SERVER_NAME=$(kubectl get configmap ${RELEASE_NAME}-synapse-config -n ${NAMESPACE} -o jsonpath='{.data.homeserver-override\.yaml}' 2>/dev/null | grep "^server_name:" | awk '{print $2}' | tr -d '"')

    if [ -z "$SERVER_NAME" ]; then
        print_error "Could not determine server name!"
        exit 1
    fi

    FULL_USERNAME="@${USERNAME}:${SERVER_NAME}"

    # Confirmation prompt
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        print_warning "This will DEACTIVATE the user account: ${FULL_USERNAME}"
        print_warning "The user will be logged out and cannot log in again."
        print_warning "User data will be PRESERVED (not deleted)."
        print_warning "This action CANNOT be undone!"
        echo ""
        read -p "Are you sure you want to deactivate this user? (yes/no): " CONFIRM

        if [ "$CONFIRM" != "yes" ]; then
            print_info "Deactivate cancelled."
            exit 0
        fi
    fi

    # Get admin credentials
    ADMIN_USER=$(kubectl get secret ${RELEASE_NAME}-admin-credentials -n ${NAMESPACE} -o jsonpath='{.data.username}' 2>/dev/null | base64 -d)
    ADMIN_PASS=$(kubectl get secret ${RELEASE_NAME}-admin-credentials -n ${NAMESPACE} -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)

    if [ -z "$ADMIN_USER" ] || [ -z "$ADMIN_PASS" ]; then
        print_error "Could not retrieve admin credentials!"
        exit 1
    fi

    # Get access token
    print_info "Authenticating..."
    TOKEN_RESPONSE=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X POST http://localhost:8008/_matrix/client/r0/login \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"m.login.password\",\"user\":\"${ADMIN_USER}\",\"password\":\"${ADMIN_PASS}\"}" 2>/dev/null)

    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "Failed to authenticate. Check admin credentials."
        exit 1
    fi

    # Deactivate user (erase: false to keep data)
    print_info "Deactivating user ${FULL_USERNAME} (keeping data)..."
    DEACTIVATE_RESPONSE=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X POST "http://localhost:8008/_synapse/admin/v1/deactivate/${FULL_USERNAME}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{"erase":false}' 2>/dev/null)

    # Check if successful
    if echo "$DEACTIVATE_RESPONSE" | grep -q '"id_server_unbind_result"'; then
        print_success "User ${FULL_USERNAME} has been deactivated!"

        # Keep local credential file but mark as deactivated
        if [ -f "${USERS_DIR}/${USERNAME}.txt" ]; then
            echo "" >> "${USERS_DIR}/${USERNAME}.txt"
            echo "DEACTIVATED: $(date '+%Y-%m-%d %H:%M:%S')" >> "${USERS_DIR}/${USERNAME}.txt"
            print_info "Marked local credential file as deactivated"
        fi

        echo ""
        echo "=========================================="
        echo "  User Deactivated"
        echo "=========================================="
        echo "Username: ${FULL_USERNAME}"
        echo "Status: Deactivated (data preserved)"
        echo ""
        print_info "Note: User data is preserved in database"
        print_info "The user cannot login but messages/rooms remain"
        echo "=========================================="
        echo ""
    else
        print_error "Failed to deactivate user!"
        print_error "Response: ${DEACTIVATE_RESPONSE}"
        exit 1
    fi
}

# Helper function to get admin access (reusable)
get_admin_access() {
    ADMIN_USER=$(kubectl get secret ${RELEASE_NAME}-admin-credentials -n ${NAMESPACE} -o jsonpath='{.data.username}' 2>/dev/null | base64 -d)
    ADMIN_PASS=$(kubectl get secret ${RELEASE_NAME}-admin-credentials -n ${NAMESPACE} -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)

    if [ -z "$ADMIN_USER" ] || [ -z "$ADMIN_PASS" ]; then
        print_error "Could not retrieve admin credentials!"
        exit 1
    fi

    TOKEN_RESPONSE=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X POST http://localhost:8008/_matrix/client/r0/login \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"m.login.password\",\"user\":\"${ADMIN_USER}\",\"password\":\"${ADMIN_PASS}\"}" 2>/dev/null)

    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "Failed to authenticate. Check admin credentials."
        exit 1
    fi
}

# User info function - shows detailed information
user_info() {
    local USERNAME=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--username)
                USERNAME="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option for info command: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$USERNAME" ]; then
        print_error "Username is required!"
        show_usage
        exit 1
    fi

    SERVER_NAME=$(kubectl get configmap ${RELEASE_NAME}-synapse-config -n ${NAMESPACE} -o jsonpath='{.data.homeserver-override\.yaml}' 2>/dev/null | grep "^server_name:" | awk '{print $2}' | tr -d '"')
    FULL_USERNAME="@${USERNAME}:${SERVER_NAME}"

    get_admin_access

    print_info "Fetching detailed information for ${FULL_USERNAME}..."

    USER_JSON=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X GET "http://localhost:8008/_synapse/admin/v2/users/${FULL_USERNAME}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" 2>/dev/null)

    if echo "$USER_JSON" | grep -q '"errcode"'; then
        print_error "User not found!"
        exit 1
    fi

    ROOMS_JSON=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X GET "http://localhost:8008/_synapse/admin/v1/users/${FULL_USERNAME}/joined_rooms" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" 2>/dev/null)

    echo ""
    echo "=========================================="
    echo "  User Details: ${USERNAME}"
    echo "=========================================="

    if command -v python3 &> /dev/null; then
        echo "$USER_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"Full User ID: {data.get('name', 'N/A')}\")
print(f\"Display Name: {data.get('displayname', '<not set>')}\")
print(f\"Admin: {'Yes' if data.get('admin', False) else 'No'}\")
print(f\"User Type: {data.get('user_type', 'regular')}\")
print(f\"Deactivated: {'Yes' if data.get('deactivated', False) else 'No'}\")
print(f\"Creation Time: {data.get('creation_ts', 'N/A')}\")
"
        ROOM_COUNT=$(echo "$ROOMS_JSON" | grep -o '"room_id"' | wc -l | tr -d ' ')
        echo "Joined Rooms: ${ROOM_COUNT}"
        if [ "$ROOM_COUNT" -gt 0 ]; then
            echo ""
            echo "Room List:"
            echo "$ROOMS_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for idx, room_id in enumerate(data.get('joined_rooms', []), 1):
    print(f\"  {idx}. {room_id}\")
" | head -10
        fi
    else
        echo "Full User ID: ${FULL_USERNAME}"
        print_warning "Install python3 for detailed information"
    fi

    echo "=========================================="
}

# Room list function
room_list() {
    local LIMIT=100
    local ORDER_BY="name"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --limit)
                LIMIT="$2"
                shift 2
                ;;
            --order-by)
                ORDER_BY="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    get_admin_access
    print_info "Fetching rooms..."

    ROOMS_JSON=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X GET "http://localhost:8008/_synapse/admin/v1/rooms?from=0&limit=${LIMIT}&order_by=${ORDER_BY}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" 2>/dev/null)

    echo ""
    echo "============================================================================"
    echo "  Matrix Synapse Rooms"
    echo "============================================================================"
    printf "%-40s %-20s %-10s\n" "Room ID" "Name" "Members"
    echo "----------------------------------------------------------------------------"

    if command -v python3 &> /dev/null; then
        echo "$ROOMS_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for room in data.get('rooms', []):
    room_id = room.get('room_id', '')[:38]
    name = (room.get('name') or '<unnamed>')[:18]
    members = room.get('joined_members', 0)
    print(f'{room_id:<40} {name:<20} {members:<10}')
"
    else
        print_warning "Install python3 for room details"
    fi

    echo "============================================================================"
    TOTAL=$(echo "$ROOMS_JSON" | grep -o '"room_id"' | wc -l | tr -d ' ')
    print_success "Total rooms: ${TOTAL}"
}

# Room info function
room_info() {
    local ROOM_ID=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--room)
                ROOM_ID="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$ROOM_ID" ]; then
        print_error "Room ID required!"
        exit 1
    fi

    get_admin_access
    
    ROOM_JSON=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X GET "http://localhost:8008/_synapse/admin/v1/rooms/${ROOM_ID}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" 2>/dev/null)

    if echo "$ROOM_JSON" | grep -q '"errcode"'; then
        print_error "Room not found!"
        exit 1
    fi

    echo ""
    echo "=========================================="
    echo "  Room Details"
    echo "=========================================="

    if command -v python3 &> /dev/null; then
        echo "$ROOM_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"Room ID: {data.get('room_id', 'N/A')}\")
print(f\"Name: {data.get('name', '<unnamed>')}\")
print(f\"Topic: {data.get('topic', '<none>')}\")
print(f\"Creator: {data.get('creator', 'N/A')}\")
print(f\"Members: {data.get('joined_members', 0)}\")
print(f\"Public: {'Yes' if data.get('public', False) else 'No'}\")
print(f\"Encryption: {data.get('encryption', '<none>')}\")
"
    else
        print_warning "Install python3 for details"
    fi

    echo "=========================================="
}

# Room create function
room_create() {
    local NAME=""
    local TOPIC=""
    local ALIAS=""
    local PUBLIC=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                NAME="$2"
                shift 2
                ;;
            -t|--topic)
                TOPIC="$2"
                shift 2
                ;;
            -a|--alias)
                ALIAS="$2"
                shift 2
                ;;
            --public)
                PUBLIC=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$NAME" ]; then
        print_error "Room name required!"
        exit 1
    fi

    get_admin_access

    SERVER_NAME=$(kubectl get configmap ${RELEASE_NAME}-synapse-config -n ${NAMESPACE} -o jsonpath='{.data.homeserver-override\.yaml}' 2>/dev/null | grep "^server_name:" | awk '{print $2}' | tr -d '"')

    local VIS="private"
    [ "$PUBLIC" = true ] && VIS="public"

    local JSON="{\"name\":\"${NAME}\",\"visibility\":\"${VIS}\""
    [ -n "$TOPIC" ] && JSON="${JSON},\"topic\":\"${TOPIC}\""
    [ -n "$ALIAS" ] && JSON="${JSON},\"room_alias_name\":\"${ALIAS}\""
    JSON="${JSON}}"

    RESPONSE=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X POST "http://localhost:8008/_matrix/client/r0/createRoom" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "${JSON}" 2>/dev/null)

    ROOM_ID=$(echo "$RESPONSE" | grep -o '"room_id":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$ROOM_ID" ]; then
        print_success "Room created!"
        echo "Room ID: ${ROOM_ID}"
        [ -n "$ALIAS" ] && echo "Alias: #${ALIAS}:${SERVER_NAME}"
    else
        print_error "Failed to create room!"
        exit 1
    fi
}

# Room delete function
room_delete() {
    local ROOM_ID=""
    local CONFIRM=false
    local PURGE=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--room)
                ROOM_ID="$2"
                shift 2
                ;;
            -y|--yes)
                CONFIRM=true
                shift
                ;;
            --purge)
                PURGE=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$ROOM_ID" ]; then
        print_error "Room ID required!"
        exit 1
    fi

    if [ "$CONFIRM" = false ]; then
        print_warning "This will DELETE room: ${ROOM_ID}"
        read -p "Are you sure? (yes/no): " REPLY
        if [ "$REPLY" != "yes" ]; then
            print_info "Cancelled"
            exit 0
        fi
    fi

    get_admin_access

    PURGE_VAL="false"
    [ "$PURGE" = true ] && PURGE_VAL="true"

    RESPONSE=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- \
        curl -s -X DELETE "http://localhost:8008/_synapse/admin/v2/rooms/${ROOM_ID}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"block\":true,\"purge\":${PURGE_VAL}}" 2>/dev/null)

    if echo "$RESPONSE" | grep -q '"delete_id"\|"kicked_users"'; then
        print_success "Room deleted!"
    else
        print_error "Failed to delete room!"
        exit 1
    fi
}


# Parse command
COMMAND="${1:-}"
shift || true

case "$COMMAND" in
    create)
        # Create user - continue with existing logic below
        ;;
    list)
        list_users "$@"
        exit 0
        ;;
    info)
        user_info "$@"
        exit 0
        ;;
    delete)
        delete_user "$@"
        exit 0
        ;;
    update-password)
        update_password "$@"
        exit 0
        ;;
    deactivate)
        deactivate_user "$@"
        exit 0
        ;;
    room-list)
        room_list "$@"
        exit 0
        ;;
    room-info)
        room_info "$@"
        exit 0
        ;;
    room-create)
        room_create "$@"
        exit 0
        ;;
    room-delete)
        room_delete "$@"
        exit 0
        ;;
    -h|--help|help|"")
        show_usage
        exit 0
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac

# Parse arguments for create command
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

# Create config file for register_new_matrix_user and capture output
REGISTRATION_OUTPUT=$(kubectl exec deployment/${RELEASE_NAME}-synapse -n ${NAMESPACE} -- bash -c "
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
" 2>&1)

# Check if registration was successful by looking for error messages
if echo "$REGISTRATION_OUTPUT" | grep -qi "already taken"; then
    print_error "Failed to create user!"
    echo ""
    echo "$REGISTRATION_OUTPUT"
    echo ""
    print_warning "The username '@${USERNAME}:${SERVER_NAME}' is already taken or was previously deleted."
    print_warning "Matrix Synapse permanently reserves deleted usernames and they CANNOT be reused."
    print_warning "Please choose a different username (e.g., '${USERNAME}2' or '${USERNAME}_new')."
    exit 1
elif echo "$REGISTRATION_OUTPUT" | grep -qi "error\|failed"; then
    print_error "Failed to create user!"
    echo "$REGISTRATION_OUTPUT"
    exit 1
fi

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
