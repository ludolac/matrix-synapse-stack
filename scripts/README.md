# Matrix Synapse Scripts

Comprehensive utility scripts for managing Matrix Synapse deployment, secrets, users, backups, and SSO configuration.

## 📋 Table of Contents

- [Scripts Overview](#scripts-overview)
- [Quick Start Guide](#quick-start-guide)
- [Script Documentation](#script-documentation)
  - [generate-secrets.sh](#generate-secretssh)
  - [matrix-admin.sh](#matrix-adminsh)
  - [backup.sh](#backupsh)
  - [restore.sh](#restoresh)
  - [setup-authelia-sso.sh](#setup-authelia-ssosh)
- [Common Workflows](#common-workflows)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)

---

## Scripts Overview

| Script | Purpose | Use Case |
|--------|---------|----------|
| **generate-secrets.sh** | Generate PostgreSQL & admin credentials | Initial setup, secret rotation |
| **matrix-admin.sh** | Comprehensive user & room management | Add users, manage rooms after deployment |
| **backup.sh** | Full backup (DB + media + keys) | Disaster recovery, migrations |
| **restore.sh** | Restore from backup | Disaster recovery, cloning |
| **setup-authelia-sso.sh** | Configure Authelia SSO integration | SSO/OIDC setup |

---

## Quick Start Guide

### Initial Deployment

```bash
# 1. Generate all secrets
./scripts/generate-secrets.sh all

# 2. Deploy with Helm
helm install matrix-synapse . -n matrix -f values-prod.yaml

# 3. Create additional users
./scripts/matrix-admin.sh create -u alice -e alice@example.com
```

### Backup & Restore

```bash
# Create backup
./scripts/backup.sh

# List backups
ls -la .backup/

# Restore from backup
./scripts/restore.sh -b 20251024_120000
```

### SSO Configuration

```bash
# Set up Authelia OIDC integration
./scripts/setup-authelia-sso.sh
```

---

## Script Documentation

## generate-secrets.sh

**Generate and manage Kubernetes secrets for Matrix Synapse**

### Synopsis

```bash
./scripts/generate-secrets.sh <command> [options]
```

### Commands

| Command | Description |
|---------|-------------|
| `all` | Generate both PostgreSQL and admin secrets |
| `postgres` | Generate only PostgreSQL database password |
| `admin` | Generate only admin user credentials |
| `list` | List all existing Matrix Synapse secrets |
| `verify` | Verify that all required secrets exist |
| `export` | Export secrets to local `.secrets/` directory |
| `delete` | Delete all Matrix Synapse secrets (requires confirmation) |

### Options

```bash
-n, --namespace NAMESPACE    Kubernetes namespace (default: matrix)
-r, --release RELEASE        Helm release name (default: matrix-synapse)
-u, --username USERNAME      Admin username (default: admin)
-h, --help                   Show help message
```

### Environment Variables

```bash
NAMESPACE         # Override default namespace
RELEASE_NAME      # Override default release name
ADMIN_USERNAME    # Custom admin username
```

### Examples

**Generate all secrets:**
```bash
./scripts/generate-secrets.sh all
```

**Generate for custom namespace:**
```bash
NAMESPACE=my-matrix ./scripts/generate-secrets.sh all
```

**Generate with custom admin username:**
```bash
ADMIN_USERNAME=administrator ./scripts/generate-secrets.sh admin
```

**List existing secrets:**
```bash
./scripts/generate-secrets.sh list
```

**Verify secrets before deployment:**
```bash
./scripts/generate-secrets.sh verify
```

**Export secrets to files:**
```bash
./scripts/generate-secrets.sh export
```

### Generated Secrets

#### 1. PostgreSQL Secret (`matrix-synapse-postgresql`)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: matrix-synapse-postgresql
data:
  postgres-password: <base64-encoded-64-char-hex>
```

**Used by:**
- PostgreSQL StatefulSet
- Synapse Deployment (for database connection)

#### 2. Admin Credentials Secret (`matrix-synapse-admin-credentials`)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: matrix-synapse-admin-credentials
data:
  username: <base64-encoded-username>
  password: <base64-encoded-32-char-password>
  registration-secret: <base64-encoded-64-char-hex>
```

**Used by:**
- Admin user creation Job
- User management scripts

### Output Files

Credentials are saved to `.secrets/` (gitignored):

```
.secrets/
├── postgresql-credentials.txt      # Database password
├── admin-credentials.txt            # Admin username, password, reg secret
└── users/                           # User credentials (from matrix-admin.sh)
    ├── alice.txt
    └── bob.txt
```

**File permissions:** `600` (owner read/write only)

### Workflow Integration

```bash
# Initial setup
./scripts/generate-secrets.sh all

# Helm chart automatically references these secrets
helm install matrix-synapse . -n matrix -f values-prod.yaml

# Admin user is created automatically by post-install job
# using credentials from matrix-synapse-admin-credentials
```

### Secret Rotation

```bash
# 1. Backup current secrets
./scripts/generate-secrets.sh export

# 2. Generate new secrets
./scripts/generate-secrets.sh all

# 3. Upgrade deployment
helm upgrade matrix-synapse . -n matrix -f values-prod.yaml

# 4. Restart pods to use new secrets
kubectl rollout restart deployment/matrix-synapse-synapse -n matrix
kubectl rollout restart statefulset/matrix-synapse-postgresql -n matrix
```

---

## matrix-admin.sh

**Comprehensive Matrix Synapse administration tool for user and room management**

### Synopsis

```bash
./scripts/matrix-admin.sh <command> [options]
```

### User Management Commands

```bash
create              Create a new user
list                List all users on the server
info                Show detailed user information (including joined rooms)
delete              Delete a user (permanently erase account and data)
update-password     Update a user's password
deactivate          Deactivate a user account (keeps data, prevents login)
```

### Room Management Commands

```bash
room-list           List all rooms on the server
room-info           Show detailed room information
room-create         Create a new room
room-delete         Delete a room
room-export         Export room state and messages to JSON file
room-import         Import room from exported JSON file
```

### Create User Options

```bash
-u, --username USERNAME       Username (required, without @ or :domain)
-p, --password PASSWORD       Password (optional, auto-generated if not provided)
-e, --email EMAIL            Email address (optional)
-a, --admin                  Make user a server admin (default: false)
-d, --display-name NAME      Display name (optional)
-h, --help                   Show help message
```

### List User Options

```bash
--guests               Show only guest users
--admins               Show only admin users
--deactivated          Show only deactivated users
-h, --help             Show help message
```

### Delete User Options

```bash
-u, --username USERNAME     Username to delete (required, without @ or :domain)
-y, --yes                  Skip confirmation prompt
-h, --help                 Show help message
```

### Update Password Options

```bash
-u, --username USERNAME     Username (required, without @ or :domain)
-p, --password PASSWORD     New password (optional, auto-generated if not provided)
-y, --yes                  Skip confirmation prompt
-h, --help                 Show help message
```

### Deactivate User Options

```bash
-u, --username USERNAME     Username to deactivate (required, without @ or :domain)
-y, --yes                  Skip confirmation prompt
-h, --help                 Show help message
```

### Room List Options

```bash
--limit LIMIT              Maximum number of rooms to display (default: 100)
--order-by ORDER          Sort order: name, size, joined_members (default: name)
-h, --help                Show help message
```

### Room Info Options

```bash
-r, --room ROOM_ID        Room ID to query (required)
-h, --help                Show help message
```

### Room Create Options

```bash
-n, --name NAME           Room name (required)
-t, --topic TOPIC         Room topic (optional)
-a, --alias ALIAS         Room alias (optional, without # or :domain)
--public                  Make room publicly joinable (default: private)
-h, --help                Show help message
```

### Room Delete Options

```bash
-r, --room ROOM_ID        Room ID to delete (required)
-y, --yes                 Skip confirmation prompt
--purge                   Purge room history from database (default: false)
-h, --help                Show help message
```

### Room Export Options

```bash
-r, --room ROOM_ID        Room ID to export (required)
-o, --output FILE         Output file path (default: .backup/rooms/<room_id>_<timestamp>.json)
--include-messages        Include message history in export (default: state only)
--limit N                 Maximum number of messages to export (default: 1000)
-h, --help                Show help message
```

### Room Import Options

```bash
-f, --file FILE           JSON export file to import (required)
--room-id ROOM_ID         Target room ID (default: create new room)
-y, --yes                 Skip confirmation prompt
-h, --help                Show help message
```

### Environment Variables

```bash
NAMESPACE              Kubernetes namespace (default: matrix)
RELEASE_NAME           Helm release name (default: matrix-synapse)
```

### Examples

**Create basic user:**
```bash
./scripts/matrix-admin.sh create -u alice -e alice@example.com
```

**Create admin user:**
```bash
./scripts/matrix-admin.sh create -u admin2 -e admin2@example.com -a
```

**Create user with custom password:**
```bash
./scripts/matrix-admin.sh create -u bob -p MySecurePass123! -e bob@example.com
```

**Create user with display name:**
```bash
./scripts/matrix-admin.sh create -u charlie -d "Charlie Brown" -e charlie@example.com
```

**List all users:**
```bash
./scripts/matrix-admin.sh list
```

**Show detailed user information:**
```bash
./scripts/matrix-admin.sh info -u alice
```

**List only admin users:**
```bash
./scripts/matrix-admin.sh list --admins
```

**List only deactivated users:**
```bash
./scripts/matrix-admin.sh list --deactivated
```

**Delete a user (with confirmation):**
```bash
./scripts/matrix-admin.sh delete -u john
```

**Delete user without confirmation:**
```bash
./scripts/matrix-admin.sh delete -u john -y
```

**Update user password (auto-generated):**
```bash
./scripts/matrix-admin.sh update-password -u alice
```

**Update user password (custom password):**
```bash
./scripts/matrix-admin.sh update-password -u alice -p NewSecurePass456!
```

**Deactivate user (keeps data):**
```bash
./scripts/matrix-admin.sh deactivate -u bob
```

**Deactivate without confirmation:**
```bash
./scripts/matrix-admin.sh deactivate -u bob -y
```

**List all rooms:**
```bash
./scripts/matrix-admin.sh room-list
```

**List rooms with custom limit:**
```bash
./scripts/matrix-admin.sh room-list --limit 50
```

**List rooms sorted by member count:**
```bash
./scripts/matrix-admin.sh room-list --order-by joined_members
```

**Show room details:**
```bash
./scripts/matrix-admin.sh room-info -r '!AbCdEfG:matrix.example.com'
```

**Create a private room:**
```bash
./scripts/matrix-admin.sh room-create -n "Team Chat" -t "Internal team discussion"
```

**Create a public room with alias:**
```bash
./scripts/matrix-admin.sh room-create -n "Community" -a general --public
```

**Delete a room (with confirmation):**
```bash
./scripts/matrix-admin.sh room-delete -r '!AbCdEfG:matrix.example.com'
```

**Delete room and purge history:**
```bash
./scripts/matrix-admin.sh room-delete -r '!AbCdEfG:matrix.example.com' --purge -y
```

**Export room (state only):**
```bash
./scripts/matrix-admin.sh room-export -r '!AbCdEfG:matrix.example.com'
```

**Export room with messages:**
```bash
./scripts/matrix-admin.sh room-export -r '!AbCdEfG:matrix.example.com' --include-messages --limit 5000
```

**Export to specific file:**
```bash
./scripts/matrix-admin.sh room-export -r '!AbCdEfG:matrix.example.com' -o my_room_backup.json
```

**Import room (creates new room):**
```bash
./scripts/matrix-admin.sh room-import -f .backup/rooms/room_export.json
```

**Import to existing room:**
```bash
./scripts/matrix-admin.sh room-import -f export.json --room-id '!AbCdEfG:matrix.example.com' -y
```

**Use custom namespace:**
```bash
NAMESPACE=my-matrix ./scripts/matrix-admin.sh list
NAMESPACE=my-matrix ./scripts/matrix-admin.sh room-list
```

### What It Does

**Create Command:**
1. **Validates** username doesn't already exist
2. **Retrieves** registration shared secret from Kubernetes
3. **Determines** server name from Synapse configuration
4. **Creates** user using `register_new_matrix_user` command
5. **Saves** credentials to `.secrets/users/<username>.txt`
6. **Displays** credentials for immediate use

**List Command:**
1. **Authenticates** using admin credentials from Kubernetes secret
2. **Fetches** user list via Synapse Admin API (`/_synapse/admin/v2/users`)
3. **Parses** JSON response (uses Python if available, falls back to grep)
4. **Displays** formatted table with: Username, Admin status, Guest status, Active/Deactivated
5. **Supports** filtering by admin, guest, or deactivated status

**Info Command:**
1. **Authenticates** using admin credentials from Kubernetes secret
2. **Fetches** user details via Synapse Admin API (`/_synapse/admin/v2/users/<user>`)
3. **Fetches** joined rooms via Admin API (`/_synapse/admin/v1/users/<user>/joined_rooms`)
4. **Parses** JSON responses using Python (if available)
5. **Displays** detailed information: Full User ID, Display Name, Admin status, User Type, Deactivated status, Creation Time, Joined Rooms count, List of room IDs

**Delete Command:**
1. **Confirms** deletion with user (unless `-y` flag provided)
2. **Authenticates** using admin credentials from Kubernetes secret
3. **Deletes** user and erases all data via Synapse Admin API (`/_synapse/admin/v1/deactivate/<user>` with `erase: true`)
4. **Removes** local credential file from `.secrets/users/` if exists
5. **Logs out** user and prevents future logins (CANNOT be undone)
6. **Reserves** username permanently - deleted usernames CANNOT be reused (Synapse limitation)

**Update Password Command:**
1. **Confirms** password update with user (unless `-y` flag provided)
2. **Generates** secure random password if not provided (32 characters)
3. **Authenticates** using admin credentials from Kubernetes secret
4. **Updates** password via Synapse Admin API (`/_synapse/admin/v2/users/<user>` PUT request)
5. **Updates** local credential file in `.secrets/users/` with new password
6. **Forces** user to re-login with new password on all devices

**Deactivate Command:**
1. **Confirms** deactivation with user (unless `-y` flag provided)
2. **Authenticates** using admin credentials from Kubernetes secret
3. **Deactivates** user via Synapse Admin API (`/_synapse/admin/v1/deactivate/<user>` with `erase: false`)
4. **Preserves** all user data (messages, rooms, etc.) in database
5. **Logs out** user from all sessions and prevents future logins
6. **Marks** local credential file as deactivated (keeps file for records)
7. **Note:** Username remains reserved and cannot be reused (Synapse limitation)

**Room List Command:**
1. **Authenticates** using admin credentials from Kubernetes secret
2. **Fetches** room list via Synapse Admin API (`/_synapse/admin/v1/rooms`)
3. **Supports** pagination (--limit) and sorting (--order-by)
4. **Parses** JSON response using Python (if available)
5. **Displays** formatted table with: Room ID, Room Name, Member Count
6. **Shows** total room count

**Room Info Command:**
1. **Authenticates** using admin credentials from Kubernetes secret
2. **Fetches** room details via Synapse Admin API (`/_synapse/admin/v1/rooms/<room_id>`)
3. **Parses** JSON response using Python (if available)
4. **Displays** detailed information: Room ID, Name, Topic, Creator, Member Count, Public status, Encryption type

**Room Create Command:**
1. **Authenticates** using admin credentials from Kubernetes secret
2. **Constructs** room creation request with name, topic, alias, visibility
3. **Creates** room via Matrix Client API (`/_matrix/client/r0/createRoom`)
4. **Returns** room ID and alias (if specified)
5. **Sets** admin user as room creator

**Room Delete Command:**
1. **Confirms** deletion with user (unless `-y` flag provided)
2. **Authenticates** using admin credentials from Kubernetes secret
3. **Deletes** room via Synapse Admin API (`/_synapse/admin/v2/rooms/<room_id>`)
4. **Blocks** room to prevent re-creation
5. **Optionally** purges room history from database (--purge flag)
6. **Kicks** all members from room

**Room Export Command:**
1. **Authenticates** using admin credentials from Kubernetes secret
2. **URL-encodes** room ID for API compatibility
3. **Fetches** room state via Admin API (`/_synapse/admin/v1/rooms/<room_id>/state`)
4. **Fetches** room details via Admin API (`/_synapse/admin/v1/rooms/<room_id>`)
5. **Extracts** room members from state events (m.room.member events)
6. **Optionally** fetches message history via Client API (--include-messages flag)
7. **Creates** JSON export file with all data using Python for proper formatting
8. **Saves** to `.backup/rooms/` by default or custom path
9. **Displays** export summary with file size and timestamp

**⚠️ Encrypted Room Limitation:**
Rooms with end-to-end encryption (E2EE) **cannot export message history**:
- Matrix uses client-side encryption (m.megolm.v1.aes-sha2)
- Server doesn't have decryption keys
- Messages in export are encrypted blobs (unusable without keys)
- Only room metadata (name, topic, members, settings) can be exported
- This is a Matrix protocol security feature, not a bug

For E2EE rooms, export only captures room configuration and membership.

**Room Import Command:**
1. **Validates** export file exists and is readable
2. **Parses** JSON export to extract room metadata
3. **Shows** confirmation prompt with room details (unless `-y` flag)
4. **Authenticates** using admin credentials from Kubernetes secret
5. **Creates** new room or uses specified target room (--room-id flag)
6. **Imports** room state events (name, topic, avatar, join rules)
7. **Reports** what was imported and message count available
8. **Note:** Full message import requires manual database manipulation for timestamp preservation

### Output

**Create Command - Success message:**
```
==========================================
  User Created Successfully!
==========================================
Username: @alice:matrix.example.com
Password: xYz123ABC...
Email: alice@example.com
Admin: false
Display Name: Alice
==========================================

Credentials saved to: .secrets/users/alice.txt
```

**List Command - Output:**
```
==========================================
  Matrix Synapse Users
==========================================
Username                       Admin      Guest        Status
----------------------------------------
@admin:matrix.example.com      Yes        No           Active
@alice:matrix.example.com      No         No           Active
@bob:matrix.example.com        No         No           Deactivated
@charlie:matrix.example.com    No         No           Active
==========================================

Total users: 4
```

**Delete Command - Output:**
```
[WARNING] This will PERMANENTLY DELETE the user account: @john:matrix.example.com
[WARNING] The user will be logged out and all their data will be erased.
[WARNING] The username will still be reserved and CANNOT be reused.
[WARNING] This action CANNOT be undone!

Are you sure you want to delete this user? (yes/no): yes

[INFO] Authenticating...
[INFO] Deleting user @john:matrix.example.com and erasing all data...
[SUCCESS] User @john:matrix.example.com has been deleted and all data erased!
[INFO] Removed local credential file

==========================================
  User Deleted
==========================================
Username: @john:matrix.example.com
Status: Deleted (data erased)

[WARNING] Note: The username 'john' is now reserved
[WARNING] and CANNOT be reused for a new account.
[WARNING] This is a Matrix Synapse limitation.
==========================================
```

**Update Password Command - Output:**
```
[WARNING] This will update the password for: @alice:matrix.example.com

Are you sure you want to update this user's password? (yes/no): yes

[INFO] Authenticating...
[INFO] Auto-generated password for user
[INFO] Updating password for @alice:matrix.example.com...
[SUCCESS] Password updated successfully for @alice:matrix.example.com!
[INFO] Updated local credential file

==========================================
  Password Updated
==========================================
Username: @alice:matrix.example.com
New Password: xYz789NewPassword...
==========================================

[INFO] User must re-login with the new password
```

**Deactivate Command - Output:**
```
[WARNING] This will DEACTIVATE the user account: @bob:matrix.example.com
[WARNING] The user will be logged out and cannot log in again.
[WARNING] User data will be PRESERVED (not deleted).
[WARNING] This action CANNOT be undone!

Are you sure you want to deactivate this user? (yes/no): yes

[INFO] Authenticating...
[INFO] Deactivating user @bob:matrix.example.com (keeping data)...
[SUCCESS] User @bob:matrix.example.com has been deactivated!
[INFO] Marked local credential file as deactivated

==========================================
  User Deactivated
==========================================
Username: @bob:matrix.example.com
Status: Deactivated (data preserved)

[INFO] Note: User data is preserved in database
[INFO] The user cannot login but messages/rooms remain
==========================================
```

### Credential Files

Each user's credentials are saved to:
```
.secrets/users/<username>.txt
```

**File contents:**
```
==========================================
  Matrix User Credentials
==========================================
Username: alice
Full User ID: @alice:matrix.example.com
Password: xYz123ABC...
Email: alice@example.com
Admin: false
Display Name: Alice
Created: 2025-10-24 12:30:45
==========================================
```

### Prerequisites

- ✅ Matrix Synapse deployed and running
- ✅ Admin credentials secret exists
- ✅ kubectl access to namespace
- ✅ Synapse pod is healthy

### Common Errors

**Create Command Errors:**

**User already exists:**
```
[ERROR] User @alice:matrix.example.com already exists!
```
**Solution:** Choose different username or delete existing user first

**Cannot determine server name:**
```
[ERROR] Could not determine server name. Is Synapse deployed?
```
**Solution:** Check Synapse is running: `kubectl get pods -n matrix`

**Registration secret not found:**
```
[ERROR] Could not retrieve registration secret!
```
**Solution:** Regenerate admin secret: `./scripts/generate-secrets.sh admin`

**List Command Errors:**

**Could not retrieve admin credentials:**
```
[ERROR] Could not retrieve admin credentials!
```
**Solution:** Ensure admin credentials secret exists:
```bash
kubectl get secret matrix-synapse-admin-credentials -n matrix
# If missing, regenerate secrets:
./scripts/generate-secrets.sh admin
```

**Failed to authenticate:**
```
[ERROR] Failed to authenticate. Check admin credentials.
```
**Solution:** Verify admin credentials are correct:
```bash
kubectl get secret matrix-synapse-admin-credentials -n matrix -o yaml
```

**Delete Command Errors:**

**User not found:**
```
# API returns error when user doesn't exist
```
**Solution:** Use `./scripts/matrix-admin.sh list` to verify username

**Username already taken (after deletion):**
```
[ERROR] User ID already taken.
```
**Solution:** This is a **Matrix Synapse limitation** - deleted usernames are permanently reserved and cannot be reused. You must choose a different username (e.g., `alice` → `alice2` or `alice_new`).

**Why this happens:** When you delete a user, Synapse marks the account as deactivated in the database but does NOT remove the user ID. This prevents security issues like user impersonation and maintains message history integrity.

**General Errors:**

**Pod not ready:**
```
[ERROR] Synapse pod is not ready!
```
**Solution:** Wait for pod to become ready: `kubectl get pods -n matrix -w`

---

## backup.sh

**Complete backup of Matrix Synapse deployment**

### Synopsis

```bash
./scripts/backup.sh [options]
```

### Options

```bash
-n, --namespace NAMESPACE      Kubernetes namespace (default: matrix)
-d, --destination DIR          Backup destination directory (default: .backup)
-c, --compress BOOL            Compress backups with gzip (default: true)
-h, --help                     Show help message
```

### What Gets Backed Up

| Component | Location | Format | Description |
|-----------|----------|--------|-------------|
| **PostgreSQL Database** | `database/` | SQL dump (gzipped) | All user data, messages, room state |
| **Media Store** | `media/` | tar.gz archive | Uploaded files, images, videos |
| **Signing Keys** | `keys/` | Raw key file | Server cryptographic keys |
| **Kubernetes Secrets** | `secrets/` | YAML files | Admin credentials (PostgreSQL secret excluded) |

### Examples

**Basic backup:**
```bash
./scripts/backup.sh
```

**Backup to custom directory:**
```bash
./scripts/backup.sh -d /mnt/backups/matrix
```

**Backup custom namespace:**
```bash
./scripts/backup.sh -n my-matrix
```

**Uncompressed backup:**
```bash
./scripts/backup.sh -c false
```

### Backup Structure

```
.backup/
└── 20251024_120000/
    ├── database/
    │   └── synapse.sql.gz              # PostgreSQL dump
    ├── media/
    │   └── media-store.tar.gz          # Media files
    ├── keys/
    │   └── matrix.example.com.signing.key  # Signing key
    ├── secrets/
    │   └── admin-credentials-secret.yaml   # Admin credentials
    └── backup-info.txt                 # Backup metadata
```

### Backup Process

1. **Validate** - Check namespace and pods exist
2. **Database** - Dump PostgreSQL using `pg_dump`
3. **Media** - Archive media_store directory
4. **Keys** - Copy signing key from Synapse pod
5. **Secrets** - Export admin credentials secret
6. **Compress** - Optionally gzip all files
7. **Verify** - Check all backup files exist
8. **Summary** - Display backup size and location

### Output Example

```
[INFO] Starting Matrix Synapse backup...
[INFO] Namespace: matrix
[INFO] Backup directory: .backup/20251024_120000

[INFO] Backing up PostgreSQL database...
[SUCCESS] Database backup completed (45 MB)

[INFO] Backing up media store...
[SUCCESS] Media store backup completed (1.2 GB)

[INFO] Backing up signing keys...
[SUCCESS] Signing keys backup completed

[INFO] Backing up Kubernetes secrets...
[SUCCESS] Secrets backup completed

==========================================
  Backup Completed Successfully!
==========================================
Timestamp: 20251024_120000
Location: .backup/20251024_120000
Total Size: 1.3 GB
Duration: 2m 15s

Files:
  - database/synapse.sql.gz (45 MB)
  - media/media-store.tar.gz (1.2 GB)
  - keys/.signing.key (2 KB)
  - secrets/admin-credentials-secret.yaml (1 KB)
==========================================
```

### Automated Backups

**Using cron:**
```bash
# Daily backup at 2 AM
0 2 * * * cd /path/to/chart && ./scripts/backup.sh -d /mnt/backups/matrix
```

**Using Kubernetes CronJob:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: matrix-backup
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: your-backup-image
            command: ["/scripts/backup.sh"]
```

### Important Notes

- ⚠️ **PostgreSQL secret NOT included** - Uses current credentials (prevents auth failures on restore)
- ⚠️ **Large backups** - Media store can be several GB
- ⚠️ **Storage space** - Ensure sufficient disk space
- ⚠️ **Retention** - Implement backup rotation policy

---

## restore.sh

**Restore Matrix Synapse from backup**

### Synopsis

```bash
./scripts/restore.sh [options]
```

### Options

```bash
-b, --backup TIMESTAMP        Backup timestamp to restore (required)
-n, --namespace NAMESPACE     Kubernetes namespace (default: matrix)
-d, --backup-dir DIR          Backup directory (default: .backup)
-y, --yes                     Skip confirmation prompts
-h, --help                    Show help message
```

### Examples

**Restore specific backup:**
```bash
./scripts/restore.sh -b 20251024_120000
```

**Restore with auto-confirm:**
```bash
./scripts/restore.sh -b 20251024_120000 -y
```

**Restore from custom directory:**
```bash
./scripts/restore.sh -b 20251024_120000 -d /mnt/backups/matrix
```

**List available backups:**
```bash
ls -la .backup/
```

### Restore Process

1. **Validate** - Check backup exists and is complete
2. **Confirm** - Prompt for confirmation (unless `-y` flag)
3. **Secrets** - Restore admin credentials (skip PostgreSQL secret)
4. **Scale Down** - Stop Synapse to prevent conflicts
5. **Database** - Drop and restore PostgreSQL database
6. **Scale Up** - Start Synapse with restored data
7. **Media** - Restore media store files
8. **Keys** - Restore signing keys
9. **Restart** - Restart Synapse to load changes
10. **Verify** - Check pod status

### Important Behavior

**PostgreSQL Secret Handling:**
The restore script **DOES NOT** restore the PostgreSQL secret. This is intentional to prevent authentication failures when restoring to a fresh installation with new credentials.

- ✅ **Keeps** current PostgreSQL credentials
- ✅ **Restores** database contents using new credentials
- ✅ **Restores** admin credentials
- ✅ **Works** with fresh Helm installations

### Output Example

```
==========================================
  Matrix Synapse Restore
==========================================
Backup: 20251024_120000
Namespace: matrix
==========================================

[WARNING] This will OVERWRITE existing data!
[WARNING] Ensure you have a recent backup.

Backup contents:
  - database/synapse.sql.gz (45 MB)
  - media/media-store.tar.gz (1.2 GB)
  - keys/.signing.key (2 KB)
  - secrets/admin-credentials-secret.yaml (1 KB)

Continue with restore? (yes/no): yes

[INFO] Restoring Kubernetes secrets...
[WARNING] Skipping PostgreSQL secret restore (using current credentials)
[SUCCESS] Admin credentials restored

[INFO] Scaling down Synapse...
[SUCCESS] Synapse scaled to 0 replicas

[INFO] Restoring PostgreSQL database...
[SUCCESS] Database restored

[INFO] Scaling up Synapse...
[SUCCESS] Synapse scaled to 1 replica

[INFO] Restoring media store...
[SUCCESS] Media store restored (1.2 GB)

[INFO] Restoring signing keys...
[SUCCESS] Signing keys restored

[INFO] Restarting Synapse...
[SUCCESS] Synapse restarted

==========================================
  Restore Completed Successfully!
==========================================
Duration: 5m 30s

Next steps:
1. Verify Synapse is running: kubectl get pods -n matrix
2. Check logs: kubectl logs deployment/matrix-synapse-synapse -n matrix
3. Test login at https://element.example.com
==========================================
```

### Common Scenarios

**Disaster Recovery:**
```bash
# 1. Deploy fresh Helm chart
helm install matrix-synapse . -n matrix -f values-prod.yaml

# 2. Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=matrix-synapse -n matrix --timeout=300s

# 3. Restore from backup
./scripts/restore.sh -b 20251024_120000 -y
```

**Migrate to New Cluster:**
```bash
# 1. Backup from old cluster
./scripts/backup.sh

# 2. Copy .backup/ directory to new cluster

# 3. Deploy on new cluster
helm install matrix-synapse . -n matrix -f values-prod.yaml

# 4. Restore
./scripts/restore.sh -b 20251024_120000 -y
```

**Clone for Testing:**
```bash
# 1. Backup production
./scripts/backup.sh

# 2. Deploy to test namespace
helm install matrix-synapse-test . -n matrix-test -f values-test.yaml

# 3. Restore to test
./scripts/restore.sh -b 20251024_120000 -n matrix-test -y
```

### Troubleshooting

**Database connection errors after restore:**
- Check PostgreSQL pod is running
- Verify credentials match between secret and database
- Check Synapse logs for connection errors

**Media files not accessible:**
- Check PVC permissions
- Verify media store path is correct
- Check Synapse pod has access to PVC

**Signing key errors:**
- Ensure signing key is in correct location
- Check file permissions
- Restart Synapse pod

---

## setup-authelia-sso.sh

**Configure Authelia OIDC integration for Matrix Synapse**

### Synopsis

```bash
./scripts/setup-authelia-sso.sh
```

### What It Does

1. **Generates** OIDC client secret (64-char hex)
2. **Finds** Authelia pod in `authentif` namespace
3. **Hashes** secret using Authelia's password utility
4. **Displays** configuration for both Synapse and Authelia

### Prerequisites

- ✅ Authelia deployed and running
- ✅ Authelia in `authentif` namespace (or modify script)
- ✅ kubectl access to both namespaces

### Output Example

```
==========================================
  Matrix Synapse + Authelia SSO Setup
==========================================

[INFO] Step 1: Generating OIDC client secret...
[SUCCESS] Client secret generated!

  Plain Secret (for Matrix):
  7622f6271e03cbef9d4a8b2f1e5c8a9d3f7b4e6c1a2d5f8e9c3b7a4d6f2e8c1b

[INFO] Step 2: Getting Authelia pod...
[SUCCESS] Found Authelia pod: authelia-5d7b8c9f6d-xyz12

[INFO] Step 3: Hashing secret for Authelia...
[SUCCESS] Secret hashed successfully!

  Hashed Secret (for Authelia):
  $pbkdf2-sha512$310000$...

==========================================
  Configuration Instructions
==========================================

1. UPDATE MATRIX SYNAPSE values-prod.yaml:

synapse:
  server:
    sso:
      enabled: true
      oidc:
        enabled: true
        providers:
          - idp_id: authelia
            idp_name: "Authelia SSO"
            discover: true
            issuer: "https://auth.example.com"
            client_id: "matrix-synapse"
            client_secret: "7622f6271e03cbef..."
            scopes: ["openid", "profile", "email"]
            user_mapping:
              localpart_template: "{{ user.preferred_username }}"
              display_name_template: "{{ user.name }}"
              email_template: "{{ user.email }}"

2. UPDATE AUTHELIA configuration.yml:

identity_providers:
  oidc:
    clients:
      - id: matrix-synapse
        description: Matrix Synapse Homeserver
        secret: "$pbkdf2-sha512$310000$..."
        public: false
        authorization_policy: two_factor
        redirect_uris:
          - https://matrix.example.com/_synapse/client/oidc/callback
        scopes:
          - openid
          - profile
          - email
        grant_types:
          - authorization_code
        response_types:
          - code

3. APPLY CHANGES:
   - Upgrade Synapse: helm upgrade matrix-synapse . -n matrix -f values-prod.yaml
   - Restart Authelia: kubectl rollout restart deployment/authelia -n authentif

4. TEST SSO LOGIN:
   - Visit: https://element.example.com
   - Click "Continue with Authelia SSO"
   - Login with Authelia credentials
==========================================
```

### Configuration Files

After running the script, you'll need to update:

**1. Matrix Synapse (`values-prod.yaml`):**
```yaml
synapse:
  server:
    sso:
      enabled: true
      oidc:
        enabled: true
        providers:
          - idp_id: authelia
            idp_name: "Authelia SSO"
            client_id: "matrix-synapse"
            client_secret: "<PLAIN_SECRET>"
            # ... other settings from output
```

**2. Authelia (`configuration.yml`):**
```yaml
identity_providers:
  oidc:
    clients:
      - id: matrix-synapse
        secret: "<HASHED_SECRET>"
        # ... other settings from output
```

### Deployment

```bash
# 1. Run SSO setup script
./scripts/setup-authelia-sso.sh

# 2. Update values-prod.yaml with plain secret

# 3. Update Authelia configuration with hashed secret

# 4. Upgrade Synapse
helm upgrade matrix-synapse . -n matrix -f values-prod.yaml

# 5. Restart Authelia
kubectl rollout restart deployment/authelia -n authentif

# 6. Test SSO login
```

### Troubleshooting

**Authelia pod not found:**
```bash
# Check Authelia is running
kubectl get pods -n authentif

# If in different namespace, modify script
```

**SSO login fails:**
- Check redirect URI matches exactly
- Verify client secret matches between systems
- Check Authelia logs: `kubectl logs deployment/authelia -n authentif`
- Check Synapse logs: `kubectl logs deployment/matrix-synapse-synapse -n matrix`

**"Invalid client" error:**
- Verify client_id matches in both configurations
- Check Authelia configuration is loaded
- Restart Authelia after config changes

---

## Common Workflows

### Initial Deployment

```bash
# 1. Generate secrets
./scripts/generate-secrets.sh all

# 2. Deploy with Helm
helm install matrix-synapse . -n matrix -f values-prod.yaml

# 3. Wait for pods
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=matrix-synapse -n matrix --timeout=300s

# 4. Get admin credentials
cat .secrets/admin-credentials.txt

# 5. Create additional users
./scripts/matrix-admin.sh create -u alice -e alice@example.com
./scripts/matrix-admin.sh create -u bob -e bob@example.com -a

# 6. Create first backup
./scripts/backup.sh
```

### Secret Rotation

```bash
# 1. Backup current secrets
./scripts/generate-secrets.sh export
cp -r .secrets .secrets.backup

# 2. Generate new secrets
./scripts/generate-secrets.sh all

# 3. Upgrade deployment
helm upgrade matrix-synapse . -n matrix -f values-prod.yaml

# 4. Restart services
kubectl rollout restart deployment/matrix-synapse-synapse -n matrix
kubectl rollout restart statefulset/matrix-synapse-postgresql -n matrix

# 5. Verify
kubectl get pods -n matrix
```

### Disaster Recovery

```bash
# 1. Deploy fresh instance
helm install matrix-synapse . -n matrix -f values-prod.yaml

# 2. Wait for ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=matrix-synapse -n matrix --timeout=300s

# 3. Restore from backup
./scripts/restore.sh -b 20251024_120000 -y

# 4. Verify
kubectl get pods -n matrix
kubectl logs deployment/matrix-synapse-synapse -n matrix

# 5. Test login
# Visit https://element.example.com
```

### Migration to New Cluster

```bash
# OLD CLUSTER
# 1. Create final backup
./scripts/backup.sh

# 2. Copy backup directory
scp -r .backup/ user@new-cluster:/path/to/chart/

# NEW CLUSTER
# 3. Deploy chart
helm install matrix-synapse . -n matrix -f values-prod.yaml

# 4. Restore data
./scripts/restore.sh -b 20251024_120000 -y

# 5. Update DNS
# Point matrix.example.com to new cluster

# 6. Verify
kubectl get pods -n matrix
```

### Setting Up SSO

```bash
# 1. Run SSO setup script
./scripts/setup-authelia-sso.sh

# 2. Copy configuration output

# 3. Update values-prod.yaml

# 4. Update Authelia configuration

# 5. Deploy changes
helm upgrade matrix-synapse . -n matrix -f values-prod.yaml
kubectl rollout restart deployment/authelia -n authentif

# 6. Test SSO login
# Visit https://element.example.com
# Click "Continue with Authelia SSO"
```

---

## Troubleshooting

### General Issues

**Script not executable:**
```bash
chmod +x ./scripts/*.sh
```

**Namespace doesn't exist:**
```bash
kubectl create namespace matrix
```

**kubectl not configured:**
```bash
kubectl config get-contexts
kubectl config use-context <your-context>
```

### Secret Issues

**Secret already exists:**
```
[WARNING] Secret exists: matrix-synapse-postgresql
Recreate? (y/N):
```
**Solution:** Type `y` to recreate or `N` to keep existing

**Cannot create secret:**
```
[ERROR] Failed to create secret
```
**Solution:** Check RBAC permissions: `kubectl auth can-i create secrets -n matrix`

### Backup Issues

**Pod not found:**
```
[ERROR] PostgreSQL pod not found
```
**Solution:** Check pods are running: `kubectl get pods -n matrix`

**Permission denied:**
```
[ERROR] Cannot create backup directory
```
**Solution:** Check directory permissions or specify custom destination

**Backup too large:**
```
[ERROR] Insufficient disk space
```
**Solution:** Clean old backups or use external storage

### Restore Issues

**Database connection failed:**
```
[ERROR] Could not connect to database
```
**Solution:** Verify PostgreSQL pod is running and credentials are correct

**Backup not found:**
```
[ERROR] Backup 20251024_120000 not found
```
**Solution:** List available backups: `ls -la .backup/`

**Pod crash after restore:**
```
[ERROR] Synapse pod is crash-looping
```
**Solution:** Check logs: `kubectl logs deployment/matrix-synapse-synapse -n matrix`

### User Creation Issues

**User already exists:**
```
[ERROR] User @alice:matrix.example.com already exists!
```
**Solution:** Choose different username or delete existing user

**Registration secret missing:**
```
[ERROR] Could not retrieve registration secret!
```
**Solution:** Regenerate: `./scripts/generate-secrets.sh admin`

---

## Security Best Practices

### Secret Management

✅ **DO:**
- Store credentials in a password manager
- Delete local `.secrets/` files after copying
- Use unique passwords for each user
- Rotate secrets periodically
- Use Kubernetes RBAC to restrict secret access

❌ **DON'T:**
- Commit `.secrets/` directory to git (it's gitignored)
- Share credentials over unencrypted channels
- Use default passwords in production
- Store secrets in values-prod.yaml (gitignored)

### Backup Security

✅ **DO:**
- Encrypt backups before off-site storage
- Store backups in multiple locations
- Test restore procedures regularly
- Implement backup retention policy
- Monitor backup job success/failure

❌ **DON'T:**
- Store backups on the same server
- Leave backups unencrypted
- Skip backup verification
- Keep infinite backups (disk space)

### Access Control

✅ **DO:**
- Use admin accounts only for administration
- Create regular users with `matrix-admin.sh`
- Enable 2FA/MFA for admin accounts
- Regularly audit user accounts
- Remove inactive users

❌ **DON'T:**
- Share admin credentials
- Create admin users unnecessarily
- Use predictable usernames
- Skip access logs review

### Network Security

✅ **DO:**
- Use TLS/HTTPS for all connections
- Configure network policies
- Use private container registries
- Keep software updated
- Monitor security advisories

❌ **DON'T:**
- Expose PostgreSQL externally
- Use HTTP (unencrypted)
- Skip certificate validation
- Ignore security updates

---

## Additional Resources

### Documentation

- [Main Chart README](../README.md) - Comprehensive chart documentation
- [BACKUP-RESTORE.md](BACKUP-RESTORE.md) - Detailed backup/restore guide
- [Matrix Synapse Docs](https://element-hq.github.io/synapse/) - Official documentation
- [Authelia Docs](https://www.authelia.com/) - SSO configuration

### Support

For issues or questions:

1. Check this README and troubleshooting section
2. Review logs: `kubectl logs -n matrix -l app.kubernetes.io/instance=matrix-synapse`
3. Check Matrix community: #synapse:matrix.org
4. Open issue: https://github.com/ludolac/matrix-synapse-stack/issues

---

## Script Compatibility

| Script | Kubernetes | Helm | kubectl | jq | python3 |
|--------|------------|------|---------|-----|---------|
| generate-secrets.sh | 1.24+ | 3.8+ | ✅ | ❌ | ❌ |
| matrix-admin.sh | 1.24+ | 3.8+ | ✅ | ❌ | Optional (recommended for formatted output) |
| backup.sh | 1.24+ | - | ✅ | ❌ | ❌ |
| restore.sh | 1.24+ | - | ✅ | ❌ | ❌ |
| setup-authelia-sso.sh | 1.24+ | - | ✅ | ❌ | ❌ |

---

**Last Updated:** 2025-10-24
**Chart Version:** 1.2.x
**License:** MIT
