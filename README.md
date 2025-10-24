# Matrix Synapse Helm Chart

Production-ready Helm chart for deploying Matrix Synapse homeserver with Element Web client on Kubernetes.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [User Management](#user-management)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Upgrading](#upgrading)
- [Uninstalling](#uninstalling)

---

## Features

✅ **Matrix Synapse** v1.140.0 - Full-featured Matrix homeserver  
✅ **Element Web** v1.12.2 - Modern web client  
✅ **PostgreSQL 16** - Reliable database backend  
✅ **Automated Secret Management** - Scripts for credential generation  
✅ **Admin User Creation** - Post-install job creates admin automatically  
✅ **Ingress Support** - NGINX ingress with TLS  
✅ **Persistent Storage** - Longhorn/PVC for data persistence  
✅ **Metrics & Monitoring** - Prometheus metrics enabled  
✅ **Production Ready** - Tested configuration with best practices  

---

## Requirements

### Infrastructure

- **Kubernetes Cluster**: v1.24+
- **Helm**: v3.8+
- **kubectl**: Configured for your cluster
- **Ingress Controller**: NGINX (with cert-manager for TLS)
- **Storage Class**: Dynamic provisioning (Longhorn, NFS, etc.)

### Resources

**Minimum:**
- CPU: 2 cores
- Memory: 4GB RAM
- Storage: 20GB

**Recommended:**
- CPU: 4 cores
- Memory: 8GB RAM
- Storage: 50GB+

### DNS Configuration

You need two DNS records pointing to your ingress:
- `matrix.example.com` - Synapse homeserver
- `element.example.com` - Element Web client

### Optional Services

- **SMTP Server** - For email notifications and registration
- **TURN Server** - For NAT traversal in video calls (e.g., `turn.example.com`)

---

## Quick Start

```bash
# 1. Clone or navigate to the chart directory
cd matrix-synapse-chart

# 2. Create namespace
kubectl create namespace matrix

# 3. Generate secrets
./scripts/generate-secrets.sh all

# 4. Customize values (edit values-prod.yaml)
vi values-prod.yaml

# 5. Install the chart
helm install matrix-synapse . \
  --namespace matrix \
  --values values-prod.yaml \
  --timeout 10m

# 6. Wait for deployment
kubectl get pods -n matrix -w

# 7. Get admin credentials
cat .secrets/admin-credentials.txt

# 8. Access Element Web
# Open https://element.example.com
# Login with admin credentials
```

---

## Installation

### Step 1: Prepare Your Environment

```bash
# Create namespace
kubectl create namespace matrix

# Verify storage class is available
kubectl get storageclass

# Verify ingress controller is running
kubectl get pods -n ingress-nginx
```

### Step 2: Generate Secrets

The chart requires secrets for PostgreSQL and admin user credentials:

```bash
# Generate all secrets (PostgreSQL + Admin)
./scripts/generate-secrets.sh all
```

This creates:
- `matrix-synapse-postgresql` - Database credentials
- `matrix-synapse-admin-credentials` - Admin user credentials

Credentials are saved to:
```
.secrets/
├── postgresql-credentials.txt
├── admin-credentials.txt
└── users/
    └── <username>.txt  # Created when you add users
```

### Step 3: Configure Values

Copy and edit the production values file:

```bash
cp values.yaml values-prod.yaml
vi values-prod.yaml
```

**Key settings to configure:**

```yaml
synapse:
  server:
    name: "matrix.example.com"  # Your domain

  ingress:
    enabled: true
    hostname: "matrix.example.com"
    tls:
      enabled: true
      secretName: "matrix-synapse-tls"

element:
  ingress:
    enabled: true
    hostname: "element.example.com"
    tls:
      enabled: true
      secretName: "matrix-element-tls"
```

See [Configuration](#configuration) section for all options.

### Step 4: Install Chart

```bash
helm install matrix-synapse . \
  --namespace matrix \
  --values values-prod.yaml \
  --timeout 10m
```

### Step 5: Verify Deployment

```bash
# Check pods
kubectl get pods -n matrix

# Expected output:
# NAME                                      READY   STATUS      RESTARTS   AGE
# matrix-synapse-create-admin-xxxxx         0/1     Completed   0          2m
# matrix-synapse-element-xxxxx              1/1     Running     0          2m
# matrix-synapse-postgresql-0               1/1     Running     0          2m
# matrix-synapse-synapse-xxxxx              1/1     Running     0          2m

# Check admin job logs
kubectl logs job/matrix-synapse-create-admin -n matrix

# Get admin credentials
cat .secrets/admin-credentials.txt
```

### Step 6: Access Your Matrix Server

1. **Open Element Web**: https://element.example.com
2. **Login** with admin credentials from `.secrets/admin-credentials.txt`
3. **Change Password** (recommended)
4. **Create Rooms** and invite users!

---

## Configuration

### Core Configuration

#### Server Settings

```yaml
synapse:
  server:
    name: "matrix.example.com"        # Server domain (FQDN)
    reportStats: true                 # Report anonymous stats to matrix.org
```

#### Database

```yaml
postgresql:
  enabled: true
  username: "synapse"
  database: "synapse_prod"
  persistence:
    enabled: true
    size: "5Gi"
    storageClass: "longhorn"          # Your storage class
```

#### Admin User

```yaml
synapse:
  server:
    adminUser:
      enabled: true
      username: "admin"                # Username (without @ or :domain)
      email: "admin@example.com"
      admin: true                      # Server admin privileges
      displayName: "Administrator"
```

#### Media Storage

```yaml
synapse:
  server:
    media:
      maxUploadSize: "100M"            # Max file upload size
      maxImagePixels: "64M"            # Max image size

  persistence:
    enabled: true
    size: "5Gi"                        # Media storage size
    storageClass: "longhorn"
```

#### Email Configuration

```yaml
synapse:
  server:
    email:
      enabled: true
      smtpHost: "smtp.example.com"
      smtpPort: 587
      smtpUser: "matrix-noreply"
      smtpPass: "your-smtp-password"
      notifFrom: "Matrix <matrix@example.com>"
      appName: "My Matrix Server"
```

#### TURN Server (Video Calls)

```yaml
synapse:
  server:
    turn:
      enabled: true
      uris:
        - "turn:turn.example.com:3478?transport=udp"
        - "turn:turn.example.com:3478?transport=tcp"
      sharedSecret: "your-turn-secret"
      userLifetime: "1h"
```

#### Registration

```yaml
synapse:
  server:
    registration:
      enabled: true                    # Allow new user registration
      requireEmail: true               # Require email for registration
      allowGuests: false               # Disable guest access
```

#### Ingress & TLS

```yaml
synapse:
  ingress:
    enabled: true
    className: "nginx"
    hostname: "matrix.example.com"
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    tls:
      enabled: true
      secretName: "matrix-synapse-tls"

element:
  ingress:
    enabled: true
    className: "nginx"
    hostname: "element.example.com"
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    tls:
      enabled: true
      secretName: "matrix-element-tls"
```

### Full Configuration Reference

See `values.yaml` for all available configuration options with detailed comments.

---

## User Management

### Admin User

The admin user is automatically created during installation by a post-install Helm job.

**Get admin credentials:**
```bash
cat .secrets/admin-credentials.txt

# Or from Kubernetes secret:
kubectl get secret matrix-synapse-admin-credentials -n matrix \
  -o jsonpath='{.data.password}' | base64 -d
```

### Creating Additional Users

Use the provided script to create new users:

```bash
# Basic user with auto-generated password
./scripts/create-user.sh -u alice -e alice@example.com

# Admin user with custom password
./scripts/create-user.sh -u bob -p SecurePass123 -e bob@example.com -a

# User with display name
./scripts/create-user.sh -u charlie -d "Charlie Brown" -e charlie@example.com
```

**Script options:**
- `-u, --username` - Username (required, without `@` or `:domain`)
- `-p, --password` - Password (optional, auto-generated if not provided)
- `-e, --email` - Email address (optional)
- `-a, --admin` - Make user a server admin
- `-d, --display-name` - Display name (optional)

**User credentials are saved to:**
```
.secrets/users/<username>.txt
```

See [scripts/README.md](scripts/README.md) for detailed user management documentation.

---

## Backup and Restore

### What to Backup

1. **PostgreSQL Database** - All user data, messages, room state
2. **Media Store** - Uploaded files, images, videos
3. **Signing Keys** - Server cryptographic keys
4. **Secrets** - Kubernetes secrets (optional, can regenerate)

### Manual Backup

#### Backup PostgreSQL Database

```bash
# Create database backup
kubectl exec matrix-synapse-postgresql-0 -n matrix -- \
  pg_dump -U synapse synapse_prod | gzip > matrix-db-$(date +%Y%m%d).sql.gz

# Or backup to pod then copy out
kubectl exec matrix-synapse-postgresql-0 -n matrix -- \
  pg_dump -U synapse synapse_prod > /tmp/backup.sql

kubectl cp matrix/matrix-synapse-postgresql-0:/tmp/backup.sql \
  ./matrix-db-$(date +%Y%m%d).sql
```

#### Backup Media Store

```bash
# Get Synapse pod name
POD=$(kubectl get pod -n matrix -l app.kubernetes.io/component=synapse -o jsonpath='{.items[0].metadata.name}')

# Backup media store
kubectl exec $POD -n matrix -- tar czf /tmp/media-store.tar.gz /data/media_store

# Copy to local machine
kubectl cp matrix/$POD:/tmp/media-store.tar.gz \
  ./matrix-media-$(date +%Y%m%d).tar.gz
```

#### Backup Signing Keys

```bash
# Backup signing keys
kubectl exec $POD -n matrix -- cat /data/matrix.example.com.signing.key > \
  ./matrix-signing-key-$(date +%Y%m%d).key
```

#### Backup Kubernetes Secrets

```bash
# Export all Matrix secrets
kubectl get secrets -n matrix -o yaml > matrix-secrets-$(date +%Y%m%d).yaml

# Or specific secrets
kubectl get secret matrix-synapse-postgresql -n matrix -o yaml > postgres-secret.yaml
kubectl get secret matrix-synapse-admin-credentials -n matrix -o yaml > admin-secret.yaml
```

### Restore Procedures

#### Restore PostgreSQL Database

```bash
# Copy SQL dump to PostgreSQL pod
kubectl cp ./matrix-db-20251023.sql.gz matrix/matrix-synapse-postgresql-0:/tmp/

# Restore database
kubectl exec -it matrix-synapse-postgresql-0 -n matrix -- bash

# Inside pod:
gunzip /tmp/matrix-db-20251023.sql.gz
psql -U synapse synapse_prod < /tmp/matrix-db-20251023.sql
exit
```

#### Restore Media Store

```bash
# Copy media archive to Synapse pod
kubectl cp ./matrix-media-20251023.tar.gz matrix/$POD:/tmp/

# Extract media
kubectl exec $POD -n matrix -- \
  tar xzf /tmp/matrix-media-20251023.tar.gz -C /data/
```

#### Restore Signing Keys

```bash
# Copy signing key to pod
kubectl cp ./matrix-signing-key-20251023.key matrix/$POD:/data/matrix.example.com.signing.key

# Restart Synapse to load key
kubectl rollout restart deployment/matrix-synapse-synapse -n matrix
```

#### Restore Kubernetes Secrets

```bash
# Delete existing secrets (if any)
kubectl delete secret matrix-synapse-postgresql -n matrix
kubectl delete secret matrix-synapse-admin-credentials -n matrix

# Apply backed up secrets
kubectl apply -f matrix-secrets-20251023.yaml
```

### Complete Disaster Recovery

Full recovery procedure from backups:

```bash
# 1. Create namespace
kubectl create namespace matrix

# 2. Restore secrets
kubectl apply -f matrix-secrets-backup.yaml

# 3. Install chart (this creates PVCs)
helm install matrix-synapse . \
  --namespace matrix \
  --values values-prod.yaml

# 4. Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod/matrix-synapse-postgresql-0 -n matrix --timeout=300s

# 5. Restore database
kubectl cp ./matrix-db-backup.sql.gz matrix/matrix-synapse-postgresql-0:/tmp/
kubectl exec -it matrix-synapse-postgresql-0 -n matrix -- \
  bash -c "gunzip /tmp/matrix-db-backup.sql.gz && psql -U synapse synapse_prod < /tmp/matrix-db-backup.sql"

# 6. Restore media and signing keys
POD=$(kubectl get pod -n matrix -l app.kubernetes.io/component=synapse -o jsonpath='{.items[0].metadata.name}')
kubectl cp ./matrix-media-backup.tar.gz matrix/$POD:/tmp/
kubectl exec $POD -n matrix -- tar xzf /tmp/matrix-media-backup.tar.gz -C /data/
kubectl cp ./matrix-signing-key.key matrix/$POD:/data/matrix.example.com.signing.key

# 7. Restart Synapse
kubectl rollout restart deployment/matrix-synapse-synapse -n matrix

# 8. Verify
kubectl get pods -n matrix
```

### Backup Best Practices

1. **Automate Backups** - Use CronJobs or backup tools
2. **Multiple Locations** - Store backups in S3, NFS, and local
3. **Test Restores** - Regularly verify backup integrity
4. **Retention Policy** - Keep daily for 7 days, weekly for 4 weeks, monthly for 6 months
5. **Encrypt Backups** - Use encryption for sensitive data
6. **Monitor Backups** - Alert on backup failures
7. **Document Process** - Keep restore procedures updated

---

## Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n matrix

# Check pod events
kubectl describe pod <pod-name> -n matrix

# Check logs
kubectl logs <pod-name> -n matrix
```

**Common causes:**
- PVC not binding (check storage class)
- Image pull errors (check registry access)
- Resource limits (check node capacity)
- Secret not found (regenerate secrets)

#### Admin Login Fails

```bash
# Verify admin credentials
cat .secrets/admin-credentials.txt

# Check registration secret is substituted
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  cat /data/homeserver-override.yaml | grep registration_shared_secret

# Should show actual hex value, not ${REGISTRATION_SHARED_SECRET}

# Check admin job logs
kubectl logs job/matrix-synapse-create-admin -n matrix

# Test login via API
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  curl -s -X POST http://localhost:8008/_matrix/client/r0/login \
  -H "Content-Type: application/json" \
  -d '{"type":"m.login.password","user":"admin","password":"YOUR_PASSWORD"}'
```

#### Database Connection Errors

```bash
# Check PostgreSQL is running
kubectl get pod matrix-synapse-postgresql-0 -n matrix

# Check PostgreSQL logs
kubectl logs matrix-synapse-postgresql-0 -n matrix

# Verify database credentials
kubectl get secret matrix-synapse-postgresql -n matrix -o yaml

# Test connection from Synapse pod
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  pg_isready -h matrix-synapse-postgresql -p 5432
```

#### Video Calls Not Working

**Error: "Call invites are not allowed in public rooms"**

**Solution:** Change room to private (invite-only):
1. Open room settings in Element Web
2. Go to "Security & Privacy"
3. Change "Room Access" to "Private (invite only)"
4. Save

**Alternative:** Use direct messages (DMs) for 1-on-1 calls - these always support calls.

**Why:** Matrix Synapse blocks calls in public rooms by design for privacy/security reasons.

#### Ingress Not Working

```bash
# Check ingress
kubectl get ingress -n matrix

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Verify DNS
nslookup matrix.example.com
nslookup element.example.com

# Test internal service
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n matrix -- \
  curl http://matrix-synapse-synapse:8008/_matrix/static/
```

#### TLS Certificate Issues

```bash
# Check certificate
kubectl get certificate -n matrix

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Describe certificate for errors
kubectl describe certificate matrix-synapse-tls -n matrix
```

### Getting Help

1. **Check Logs:**
   ```bash
   # Synapse logs
   kubectl logs -l app.kubernetes.io/component=synapse -n matrix --tail=100

   # All component logs
   kubectl logs -l app.kubernetes.io/instance=matrix-synapse -n matrix --tail=50
   ```

2. **Check Events:**
   ```bash
   kubectl get events -n matrix --sort-by='.lastTimestamp'
   ```

3. **Synapse Admin API:**
   ```bash
   # Get server version
   kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
     curl -s http://localhost:8008/_synapse/admin/v1/server_version

   # Check health
   kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
     curl -s http://localhost:8008/health
   ```

4. **Increase Log Verbosity:**

   Edit ConfigMap to set log level to DEBUG:
   ```bash
   kubectl edit configmap matrix-synapse-synapse-config -n matrix
   # Change: level: DEBUG
   kubectl rollout restart deployment/matrix-synapse-synapse -n matrix
   ```

### Advanced Debugging

#### Access Synapse Shell

```bash
kubectl exec -it deployment/matrix-synapse-synapse -n matrix -- /bin/bash
```

#### Access PostgreSQL Shell

```bash
kubectl exec -it matrix-synapse-postgresql-0 -n matrix -- psql -U synapse synapse_prod
```

**Useful queries:**
```sql
-- List all users
SELECT name, admin, deactivated FROM users;

-- List all rooms
SELECT room_id, name, topic FROM room_stats_state LIMIT 10;

-- Check database size
SELECT pg_size_pretty(pg_database_size('synapse_prod'));
```

---

## Security

### Best Practices

1. **Change Default Passwords**
   - Change admin password after first login
   - Rotate database passwords periodically

2. **Use TLS Everywhere**
   - Enable TLS for ingress (Let's Encrypt)
   - Use cert-manager for automatic renewal

3. **Restrict Network Access**
   - Use NetworkPolicies to limit pod communication
   - Firewall database access to only Synapse pods

4. **Secret Management**
   - Delete local `.secrets/` files after saving to password manager
   - Use Kubernetes secrets, not ConfigMaps
   - Consider external secret managers (Vault, Sealed Secrets)

5. **Regular Updates**
   - Keep Synapse, Element, and PostgreSQL updated
   - Monitor security advisories

6. **Backup Encryption**
   - Encrypt backups before storing
   - Secure backup storage access

7. **Audit Logs**
   - Enable audit logging
   - Monitor for suspicious activity

---

## Upgrading

### Upgrade Chart Version

```bash
# Backup first!
kubectl exec matrix-synapse-postgresql-0 -n matrix -- \
  pg_dump -U synapse synapse_prod | gzip > backup-before-upgrade.sql.gz

# Update chart
helm upgrade matrix-synapse . \
  --namespace matrix \
  --values values-prod.yaml \
  --timeout 10m

# Verify
kubectl get pods -n matrix
```

### Upgrade Synapse Version

1. Update image tag in `values-prod.yaml`:
   ```yaml
   synapse:
     image:
       tag: "v1.141.0"  # New version
   ```

2. Check release notes: https://github.com/element-hq/synapse/releases

3. Backup database before upgrading

4. Apply upgrade:
   ```bash
   helm upgrade matrix-synapse . \
     --namespace matrix \
     --values values-prod.yaml
   ```

### Database Migrations

Synapse automatically runs database migrations on startup. Monitor logs:

```bash
kubectl logs -f deployment/matrix-synapse-synapse -n matrix
```

---

## Uninstalling

### Complete Removal

```bash
# 1. Uninstall Helm release
helm uninstall matrix-synapse -n matrix

# 2. Delete PVCs (WARNING: Deletes all data!)
kubectl delete pvc --all -n matrix

# 3. Delete secrets
kubectl delete secrets --all -n matrix

# 4. Delete namespace
kubectl delete namespace matrix
```

### Keep Data for Reinstall

```bash
# Uninstall but keep PVCs and secrets
helm uninstall matrix-synapse -n matrix

# Secrets and PVCs remain - can reinstall later
helm install matrix-synapse . --namespace matrix --values values-prod.yaml
```

---

## Additional Resources

### Documentation

- **Matrix Specification**: https://spec.matrix.org/
- **Synapse Documentation**: https://element-hq.github.io/synapse/
- **Element Documentation**: https://element.io/user-guide

### Scripts

- [scripts/README.md](scripts/README.md) - Detailed script documentation
- [scripts/generate-secrets.sh](scripts/generate-secrets.sh) - Secret management
- [scripts/create-user.sh](scripts/create-user.sh) - User creation

### Configuration Files

- `values.yaml` - Default values with all options
- `values-prod.yaml` - Your production configuration
- `Chart.yaml` - Chart metadata

---

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review logs: `kubectl logs -n matrix -l app.kubernetes.io/instance=matrix-synapse`
3. Check Matrix community: #synapse:matrix.org
4. Synapse issues: https://github.com/element-hq/synapse/issues

---

## License

This Helm chart is provided as-is for deploying Matrix Synapse.

- Matrix Synapse: Apache License 2.0
- Element Web: Apache License 2.0
- PostgreSQL: PostgreSQL License

---

## Chart Information

- **Chart Version**: 1.2.0
- **Synapse Version**: v1.140.0
- **Element Web Version**: v1.12.2
- **PostgreSQL Version**: 16

**Maintainer**: Internal Infrastructure Team
