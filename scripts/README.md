# Matrix Synapse Scripts

This folder contains utility scripts for managing Matrix Synapse secrets, credentials, and users.

## Scripts Overview

- **generate-secrets.sh** - Generate and manage PostgreSQL and admin secrets
- **create-user.sh** - Create additional Matrix users on existing deployment

---

## create-user.sh

Create additional custom Matrix users on an already deployed Synapse server.

### Quick Start

```bash
# Create user with auto-generated password
./scripts/create-user.sh -u alice -e alice@example.com

# Create admin user with custom password
./scripts/create-user.sh -u bob -p MyPassword123 -e bob@example.com -a

# Create user with display name
./scripts/create-user.sh -u charlie -d "Charlie Brown" -e charlie@example.com
```

### Usage

```bash
./scripts/create-user.sh [options]

Options:
  -u, --username USERNAME     Username (required, without @ or :domain)
  -p, --password PASSWORD     Password (optional, auto-generated if not provided)
  -e, --email EMAIL          Email address (optional)
  -a, --admin                Make user a server admin (default: false)
  -d, --display-name NAME    Display name (optional)
  -h, --help                 Show help message

Environment Variables:
  NAMESPACE       Kubernetes namespace (default: matrix)
  RELEASE_NAME    Helm release name (default: matrix-synapse)
```

### Examples

**Create a regular user:**
```bash
./scripts/create-user.sh -u john -e john@waadoo.ovh
```

**Create an admin user:**
```bash
./scripts/create-user.sh -u admin2 -e admin2@waadoo.ovh -a
```

**Create user with custom password:**
```bash
./scripts/create-user.sh -u alice -p SecurePass123! -e alice@waadoo.ovh
```

**Create user with display name:**
```bash
./scripts/create-user.sh -u bob -d "Bob Smith" -e bob@waadoo.ovh
```

### What It Does

1. Validates the username doesn't already exist
2. Retrieves the registration shared secret from Kubernetes
3. Creates the user using Synapse's `register_new_matrix_user` command
4. Saves credentials to `.secrets/users/<username>.txt`
5. Displays the username and password

### Output

When successful, the script outputs:

```
==========================================
  User Created Successfully!
==========================================
Username: @alice:matrix.waadoo.ovh
Password: xYz123ABC...
Email: alice@example.com
Admin: false
==========================================
```

### Credential Storage

User credentials are saved to:
```
.secrets/users/<username>.txt
```

Each file contains:
- Username
- Full User ID (@username:domain)
- Password
- Email
- Admin status
- Display name
- Creation timestamp

### Prerequisites

- Matrix Synapse must be deployed and running
- The admin credentials secret must exist (`matrix-synapse-admin-credentials`)
- You must have kubectl access to the namespace

### Troubleshooting

**User already exists:**
```
[ERROR] User @alice:matrix.waadoo.ovh already exists!
```
Choose a different username or delete the existing user first.

**Cannot connect to Synapse:**
```
[ERROR] Could not determine server name. Is Synapse deployed?
```
Ensure the Synapse deployment is running:
```bash
kubectl get pods -n matrix
```

**Registration secret not found:**
```
[ERROR] Could not retrieve registration secret!
```
Regenerate the admin credentials:
```bash
./scripts/generate-secrets.sh admin
```

---

## generate-secrets.sh

Unified script to generate and manage all Matrix Synapse secrets.

### Quick Start

```bash
# Generate all secrets (PostgreSQL + Admin user)
./scripts/generate-secrets.sh all

# Generate only PostgreSQL credentials
./scripts/generate-secrets.sh postgres

# Generate only admin user credentials
./scripts/generate-secrets.sh admin

# List all existing secrets
./scripts/generate-secrets.sh list

# Verify required secrets exist
./scripts/generate-secrets.sh verify

# Export secrets to local files
./scripts/generate-secrets.sh export
```

### What It Creates

**1. PostgreSQL Secret** (`matrix-synapse-postgresql`)
- Contains database password
- Used by both PostgreSQL and Synapse pods
- Password format: 64-character hex string

**2. Admin Credentials Secret** (`matrix-synapse-admin-credentials`)
- Username (default: `admin`)
- Password (32-character alphanumeric)
- Registration shared secret (64-character hex)

### Environment Variables

```bash
# Use custom namespace
NAMESPACE=my-matrix ./scripts/generate-secrets.sh all

# Use custom release name
RELEASE_NAME=my-release ./scripts/generate-secrets.sh all

# Set custom admin username
ADMIN_USERNAME=administrator ./scripts/generate-secrets.sh admin
```

### Output Files

All credentials are saved to `.secrets/` directory:

```
.secrets/
├── postgresql-credentials.txt
└── admin-credentials.txt
```

**Security**: Files are created with `600` permissions (owner read/write only).

### Complete Example

```bash
# Step 1: Generate all secrets
cd /path/to/matrix-synapse-chart
./scripts/generate-secrets.sh all

# Output:
# ==========================================
#   Admin Credentials
# ==========================================
# Username: admin
# Password: xYz123ABC...
# Registration Secret: 7622f6271e03cbef...
# ==========================================

# Step 2: Deploy with Helm
helm install matrix-synapse . \
  --namespace matrix \
  --values values-prod.yaml

# Step 3: Verify secrets
./scripts/generate-secrets.sh verify

# Step 4: Access credentials later
kubectl get secret matrix-synapse-admin-credentials -n matrix \
  -o jsonpath='{.data.password}' | base64 -d
```

### Updating Existing Secrets

The script will prompt before overwriting existing secrets:

```bash
$ ./scripts/generate-secrets.sh admin

[WARNING] Secret exists: matrix-synapse-admin-credentials
Recreate? (y/N):
```

### Deleting Secrets

```bash
# Delete all Matrix Synapse secrets
./scripts/generate-secrets.sh delete

# Requires confirmation by typing 'yes'
```

### Integration with Helm Chart

The secrets created by this script are automatically used by the Helm chart:

**PostgreSQL Password:**
```yaml
# Referenced in synapse-deployment.yaml
env:
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: matrix-synapse-postgresql
        key: postgres-password
```

**Admin User:**
```yaml
# Referenced in admin-user-job.yaml
# Uses registration-secret for user creation
# Password and username from the secret
```

### Troubleshooting

**Secret not found error:**
```bash
# Run verify to check status
./scripts/generate-secrets.sh verify

# Regenerate missing secrets
./scripts/generate-secrets.sh all
```

**Permission denied:**
```bash
# Make script executable
chmod +x ./scripts/generate-secrets.sh
```

**Namespace doesn't exist:**
```bash
# Script will create it automatically
# Or create manually:
kubectl create namespace matrix
```

### Security Best Practices

1. **Backup credentials** to a secure password manager
2. **Delete local files** after copying credentials:
   ```bash
   rm -rf .secrets/
   ```
3. **Rotate secrets** periodically:
   ```bash
   ./scripts/generate-secrets.sh all
   helm upgrade matrix-synapse . --namespace matrix --values values-prod.yaml
   ```
4. **Use Kubernetes RBAC** to restrict secret access
5. **Change admin password** after first login

### See Also

- [ADMIN-USER-SETUP.md](../ADMIN-USER-SETUP.md) - Admin user configuration guide
- [README.md](../README.md) - Main chart documentation
