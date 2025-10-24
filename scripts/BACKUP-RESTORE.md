# Matrix Synapse Backup and Restore Guide

Complete guide for backing up and restoring your Matrix Synapse deployment on Kubernetes.

## Table of Contents

- [Overview](#overview)
- [Backup Script](#backup-script)
- [Restore Script](#restore-script)
- [Automated Backups](#automated-backups)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

The backup and restore scripts provide a complete solution for disaster recovery of your Matrix Synapse deployment.

### What Gets Backed Up

✅ **PostgreSQL Database** - All user data, messages, room state, encryption keys
✅ **Media Store** - Uploaded files, images, videos, avatars
✅ **Signing Keys** - Server cryptographic signing keys
✅ **Kubernetes Secrets** - PostgreSQL credentials, admin credentials

### Backup Location

All backups are stored in the `.backup/` directory with the following structure:

```
.backup/
├── latest -> 20251024_120000  # Symlink to latest backup
├── 20251024_120000/
│   ├── MANIFEST.txt           # Backup metadata
│   ├── database/
│   │   └── synapse.sql.gz     # Compressed database dump
│   ├── media/
│   │   └── media-store.tar.gz # Compressed media files
│   ├── keys/
│   │   └── matrix.example.com.signing.key
│   └── secrets/
│       ├── postgresql-secret.yaml
│       └── admin-credentials-secret.yaml
└── 20251023_180000/
    └── ...
```

---

## Backup Script

### Basic Usage

```bash
# Create a backup with default settings
./scripts/backup.sh

# Backup from specific namespace
./scripts/backup.sh --namespace matrix

# Backup to custom directory
./scripts/backup.sh --destination /mnt/backups

# Create uncompressed backup
./scripts/backup.sh --compress false
```

### Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--namespace` | `-n` | Kubernetes namespace | `matrix` |
| `--destination` | `-d` | Backup destination directory | `.backup` |
| `--compress` | `-c` | Compress backups with gzip | `true` |
| `--help` | `-h` | Show help message | - |

### What Happens During Backup

1. **Discovery** - Finds PostgreSQL and Synapse pods
2. **Database Dump** - Exports PostgreSQL database to SQL file
3. **Media Archive** - Creates compressed archive of media store
4. **Keys Export** - Copies server signing keys
5. **Secrets Export** - Exports Kubernetes secrets to YAML
6. **Manifest** - Creates backup manifest with metadata
7. **Symlink** - Updates `latest` symlink to new backup

### Example Output

```
[INFO] Starting Matrix Synapse backup to: .backup/20251024_120000
[INFO] Namespace: matrix
[SUCCESS] Found PostgreSQL pod: matrix-synapse-postgresql-0
[SUCCESS] Found Synapse pod: matrix-synapse-synapse-7d9f8b5c4d-x7j2k
[INFO] Backing up PostgreSQL database...
[SUCCESS] Database backup completed (145M)
[INFO] Backing up media store...
[SUCCESS] Media store backup completed (2.3G)
[INFO] Backing up signing keys...
[SUCCESS] Signing keys backup completed
[INFO] Backing up Kubernetes secrets...
[SUCCESS] Kubernetes secrets backup completed
[SUCCESS] Backup manifest created

╔════════════════════════════════════════════════════════════╗
║              Backup Completed Successfully                 ║
╠════════════════════════════════════════════════════════════╣
║ Timestamp:     20251024_120000                             ║
║ Location:      .backup/20251024_120000                     ║
║ Total Size:    2.5G                                        ║
║                                                            ║
║ Backed up:                                                 ║
║   ✓ PostgreSQL Database                                    ║
║   ✓ Media Store                                            ║
║   ✓ Signing Keys                                           ║
║   ✓ Kubernetes Secrets                                     ║
╚════════════════════════════════════════════════════════════╝

[INFO] To restore this backup, run:
[INFO]   ./scripts/restore.sh -b 20251024_120000
```

---

## Restore Script

### Basic Usage

```bash
# Restore from specific backup
./scripts/restore.sh --backup 20251024_120000

# Restore from latest backup
./scripts/restore.sh --backup latest

# Restore without confirmation prompt
./scripts/restore.sh --backup 20251024_120000 --yes

# Restore to specific namespace
./scripts/restore.sh --backup 20251024_120000 --namespace matrix
```

### Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--backup` | `-b` | Backup timestamp to restore (required) | - |
| `--namespace` | `-n` | Kubernetes namespace | `matrix` |
| `--backup-dir` | `-d` | Backup directory | `.backup` |
| `--yes` | `-y` | Skip confirmation prompts | `false` |
| `--help` | `-h` | Show help message | - |

### What Happens During Restore

1. **Validation** - Verifies backup exists and is complete
2. **Confirmation** - Prompts user to confirm (unless `-y` flag used)
3. **Secrets** - Restores Kubernetes secrets first
4. **Database** - Drops existing database and restores from backup
5. **Media** - Replaces media store with backup
6. **Keys** - Restores signing keys
7. **Restart** - Restarts Synapse to apply changes
8. **Verification** - Waits for pods to be ready

### ⚠️ Important Warnings

- **Destructive Operation**: Restore will DELETE all current data
- **Downtime**: Synapse will be unavailable during restore
- **Credentials**: Secrets will be replaced with backup versions
- **Backup First**: Always backup current state before restoring

### Example Output

```
[INFO] Restore configuration:
[INFO]   Backup: 20251024_120000
[INFO]   Path: .backup/20251024_120000
[INFO]   Namespace: matrix

WARNING: This will restore Matrix Synapse from backup!
This operation will:
  1. DROP and restore the PostgreSQL database
  2. Replace all media files
  3. Replace signing keys
  4. Restore Kubernetes secrets

Are you sure you want to continue? (yes/no): yes

[SUCCESS] Found PostgreSQL pod: matrix-synapse-postgresql-0
[SUCCESS] Found Synapse pod: matrix-synapse-synapse-7d9f8b5c4d-x7j2k
[INFO] Restoring PostgreSQL secret...
[SUCCESS] PostgreSQL secret restored
[INFO] Restoring database (this may take a while)...
[SUCCESS] Database restored successfully
[INFO] Restoring media store...
[SUCCESS] Media store restored successfully
[INFO] Restoring signing keys...
[SUCCESS] Signing keys restored
[INFO] Restarting Synapse to apply changes...
[SUCCESS] Synapse restarted successfully

╔════════════════════════════════════════════════════════════╗
║              Restore Completed Successfully                ║
╠════════════════════════════════════════════════════════════╣
║ Backup:        20251024_120000                             ║
║ Namespace:     matrix                                      ║
║                                                            ║
║ Restored:                                                  ║
║   ✓ PostgreSQL Database                                    ║
║   ✓ Media Store                                            ║
║   ✓ Signing Keys                                           ║
║   ✓ Kubernetes Secrets                                     ║
╚════════════════════════════════════════════════════════════╝
```

---

## Automated Backups

### Using Kubernetes CronJob

Create a CronJob to automatically backup daily at 2 AM:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: matrix-synapse-backup
  namespace: matrix
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: bitnami/kubectl:latest
            command:
            - /bin/bash
            - -c
            - |
              # Clone the repository (or mount the scripts)
              git clone https://github.com/ludolac/matrix-synapse-stack.git /tmp/scripts
              cd /tmp/scripts
              ./scripts/backup.sh --namespace matrix --destination /backups
            volumeMounts:
            - name: backup-storage
              mountPath: /backups
          restartPolicy: OnFailure
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
```

### Using Cron (Local Machine)

Add to your crontab for automated backups:

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /path/to/matrix-synapse-stack && ./scripts/backup.sh >> /var/log/matrix-backup.log 2>&1

# Add weekly cleanup (keep last 30 days)
0 3 * * 0 find .backup/* -type d -mtime +30 -exec rm -rf {} +
```

### Backup to Remote Storage

#### S3-Compatible Storage

```bash
#!/bin/bash
# backup-to-s3.sh

# Run backup
./scripts/backup.sh

# Get latest backup
LATEST=$(readlink .backup/latest)

# Upload to S3
aws s3 sync .backup/${LATEST}/ s3://my-bucket/matrix-backups/${LATEST}/ \
  --storage-class STANDARD_IA

# Cleanup old backups (keep last 30 days)
aws s3 ls s3://my-bucket/matrix-backups/ | \
  awk '{print $2}' | \
  while read -r backup; do
    DAYS_OLD=$(( ($(date +%s) - $(date -d "${backup%/}" +%s)) / 86400 ))
    if [ $DAYS_OLD -gt 30 ]; then
      aws s3 rm s3://my-bucket/matrix-backups/${backup} --recursive
    fi
  done
```

#### Rsync to Remote Server

```bash
#!/bin/bash
# backup-to-remote.sh

# Run backup
./scripts/backup.sh

# Get latest backup
LATEST=$(readlink .backup/latest)

# Rsync to remote server
rsync -avz --progress \
  .backup/${LATEST}/ \
  backup-server:/backups/matrix/${LATEST}/

# Cleanup old backups on remote (keep last 14)
ssh backup-server "cd /backups/matrix && ls -t | tail -n +15 | xargs rm -rf"
```

---

## Best Practices

### 1. Regular Backup Schedule

- **Daily backups** - Minimum for production systems
- **Before upgrades** - Always backup before version changes
- **Before maintenance** - Backup before major configuration changes

### 2. Backup Retention

Recommended retention policy:

- **Daily backups**: Keep for 7 days
- **Weekly backups**: Keep for 4 weeks
- **Monthly backups**: Keep for 6 months
- **Before major changes**: Keep indefinitely

Example cleanup script:

```bash
#!/bin/bash
# cleanup-old-backups.sh

BACKUP_DIR=".backup"

# Keep daily backups for 7 days
find ${BACKUP_DIR} -maxdepth 1 -type d -mtime +7 -not -name "weekly-*" -not -name "monthly-*" -exec rm -rf {} +

# Weekly backups (create on Sundays)
if [ $(date +%u) -eq 7 ]; then
  LATEST=$(readlink ${BACKUP_DIR}/latest)
  cp -al ${BACKUP_DIR}/${LATEST} ${BACKUP_DIR}/weekly-$(date +%Y%m%d)
fi

# Monthly backups (create on 1st of month)
if [ $(date +%d) -eq 01 ]; then
  LATEST=$(readlink ${BACKUP_DIR}/latest)
  cp -al ${BACKUP_DIR}/${LATEST} ${BACKUP_DIR}/monthly-$(date +%Y%m)
fi

# Keep weekly backups for 4 weeks
find ${BACKUP_DIR} -maxdepth 1 -type d -name "weekly-*" -mtime +28 -exec rm -rf {} +

# Keep monthly backups for 6 months
find ${BACKUP_DIR} -maxdepth 1 -type d -name "monthly-*" -mtime +180 -exec rm -rf {} +
```

### 3. Backup Verification

Always verify backups periodically:

```bash
# Check backup integrity
./scripts/restore.sh --backup latest --namespace matrix-test --yes

# Verify data
kubectl exec -it deployment/matrix-synapse-synapse-test -n matrix-test -- \
  psql -U synapse -d synapse -c "SELECT COUNT(*) FROM users;"

# Cleanup test namespace
kubectl delete namespace matrix-test
```

### 4. Encryption

Encrypt backups containing sensitive data:

```bash
# Encrypt backup
tar czf - .backup/20251024_120000 | \
  gpg --symmetric --cipher-algo AES256 > backup-20251024_120000.tar.gz.gpg

# Decrypt backup
gpg --decrypt backup-20251024_120000.tar.gz.gpg | tar xzf -
```

### 5. Off-Site Storage

- Store backups in multiple locations
- Use different geographic regions
- Test restore from off-site backups regularly

### 6. Monitoring

Monitor backup success/failure:

```bash
# Add to backup.sh
if [ $? -eq 0 ]; then
  curl -fsS -m 10 --retry 5 https://hc-ping.com/your-check-id
fi
```

---

## Troubleshooting

### Backup Issues

#### Error: "PostgreSQL pod not found"

**Solution**: Check namespace and pod status:
```bash
kubectl get pods -n matrix -l app.kubernetes.io/component=postgresql
```

#### Error: "Permission denied" during media backup

**Solution**: Check pod permissions:
```bash
kubectl exec -it <synapse-pod> -n matrix -- ls -la /data/media_store
```

#### Backup is very slow

**Solution**:
- Large media stores can take time
- Consider incremental backups for media
- Use faster storage for backup destination

### Restore Issues

#### Error: "Backup not found"

**Solution**: List available backups:
```bash
ls -1 .backup/
./scripts/restore.sh -h
```

#### Database restore fails

**Solution**: Check PostgreSQL logs:
```bash
kubectl logs <postgres-pod> -n matrix
```

#### Synapse won't start after restore

**Solution**:
1. Check signing keys match server name
2. Verify secrets are correct
3. Check pod logs:
```bash
kubectl logs <synapse-pod> -n matrix
```

### Recovery Scenarios

#### Accidental Data Loss

```bash
# Restore from latest backup
./scripts/restore.sh -b latest -y
```

#### Corrupted Database

```bash
# Restore from last known good backup
./scripts/restore.sh -b 20251023_180000
```

#### Disaster Recovery (New Cluster)

```bash
# 1. Deploy Matrix Synapse to new cluster
helm install matrix-synapse . -n matrix --values values-prod.yaml

# 2. Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=matrix-synapse -n matrix

# 3. Restore from backup
./scripts/restore.sh -b 20251024_120000 -n matrix -y

# 4. Verify restoration
kubectl get pods -n matrix
```

---

## Additional Resources

- [Main README](../README.md) - Chart documentation
- [Backup Best Practices](../README.md#backup-and-restore) - General backup guide
- [Synapse Documentation](https://element-hq.github.io/synapse/) - Official docs

---

## Support

For issues or questions:

1. Check logs: `kubectl logs -n matrix -l app.kubernetes.io/instance=matrix-synapse`
2. Review backup manifest: `cat .backup/latest/MANIFEST.txt`
3. Test restore in isolated environment first
4. Create issue: https://github.com/ludolac/matrix-synapse-stack/issues
