<div align="center">
  <img src="https://matrix.org/images/matrix-logo.svg" alt="Matrix Logo" width="200"/>

  # Matrix Synapse Helm Chart

  Production-ready Helm chart for deploying Matrix Synapse homeserver with Element Web client on Kubernetes.
</div>

[![Helm Chart](https://img.shields.io/badge/helm-chart-blue)](https://ludolac.github.io/matrix-synapse-stack/)
[![Chart Version](https://img.shields.io/badge/dynamic/yaml?url=https://ludolac.github.io/matrix-synapse-stack/index.yaml&query=$.entries.matrix-synapse[0].version&label=chart&color=0F1689&logo=helm)](https://ludolac.github.io/matrix-synapse-stack/)
[![Synapse Version](https://img.shields.io/badge/synapse-v1.140.0-green)](https://github.com/element-hq/synapse)
[![Security Scan](https://github.com/ludolac/matrix-synapse-stack/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ludolac/matrix-synapse-stack/actions/workflows/trivy-scan.yml)
[![Security](https://img.shields.io/badge/security-trivy-blue?logo=security)](https://github.com/ludolac/matrix-synapse-stack/security/code-scanning)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 📖 About Matrix Synapse

**Matrix Synapse** is the reference homeserver implementation of the [Matrix protocol](https://matrix.org) - an open standard for secure, decentralized, real-time communication. Matrix enables users to communicate across different platforms and services while maintaining full control over their data.

### What is Matrix?

Matrix is an open network for secure, decentralized communication that provides:

- 🔐 **End-to-End Encryption** - Secure messaging with full E2EE support
- 🌐 **Decentralized Architecture** - No single point of control or failure
- 🔗 **Interoperability** - Bridge to other chat platforms (Slack, Discord, WhatsApp, etc.)
- 📱 **Multi-Platform** - Native apps for web, mobile, and desktop
- 🏢 **Self-Hosted** - Complete ownership and control of your data
- 🚀 **Feature-Rich** - Voice/video calls, file sharing, rooms, spaces, and more

### Why Use This Helm Chart?

This production-ready Helm chart simplifies the deployment of Matrix Synapse on Kubernetes with:

- ⚡ **Easy Installation** - Deploy a complete Matrix homeserver in minutes
- 🔧 **Highly Configurable** - Extensive customization options via values.yaml
- 🛡️ **Security Focused** - Regular vulnerability scans and security best practices
- 📦 **All-in-One** - Includes Synapse, Element Web, PostgreSQL, and Coturn
- 🔄 **Auto-Updates** - Simple upgrade path with Helm
- 📊 **Production Ready** - Tested configurations with health checks and monitoring

---

## 🔒 Security Scan Summary

**Automated Security Scanning with Trivy** - This chart is continuously scanned for security vulnerabilities and misconfigurations.

### Overall Security Status

| Scan Type | Status | Schedule | Critical | High | Medium | Low |
|-----------|--------|----------|----------|------|--------|-----|
| **Configuration** | ![Status](https://img.shields.io/badge/status-scanned-success) | Daily at 2AM UTC | ![Critical](https://img.shields.io/badge/critical-0-success) | ![High](https://img.shields.io/badge/high-4-important) | ![Medium](https://img.shields.io/badge/medium-7-orange) | ![Low](https://img.shields.io/badge/low-20-informational) |
| **Helm Manifests** | ![Status](https://img.shields.io/badge/status-scanned-success) | On every push | ![Critical](https://img.shields.io/badge/critical-0-success) | ![High](https://img.shields.io/badge/high-4-important) | ![Medium](https://img.shields.io/badge/medium-7-orange) | ![Low](https://img.shields.io/badge/low-20-informational) |
| **Container Images** | ![Status](https://img.shields.io/badge/status-scanned-success) | Daily + On Push | ![Critical](https://img.shields.io/badge/critical-11-critical) | ![High](https://img.shields.io/badge/high-39-important) | ![Medium](https://img.shields.io/badge/medium-141-orange) | ![Low](https://img.shields.io/badge/low-108-informational) |

### Container Images Scanned

| Image | Version | Critical | High | Medium | Low |
|-------|---------|----------|------|--------|-----|
| **Synapse** | v1.140.0 | [![Critical](https://img.shields.io/badge/critical-6-critical)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![High](https://img.shields.io/badge/high-31-important)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![Medium](https://img.shields.io/badge/medium-82-orange)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![Low](https://img.shields.io/badge/low-103-informational)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) |
| **Element Web** | v1.12.2 | [![Critical](https://img.shields.io/badge/critical-3-critical)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![High](https://img.shields.io/badge/high-2-important)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![Medium](https://img.shields.io/badge/medium-28-orange)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![Low](https://img.shields.io/badge/low-5-informational)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) |
| **PostgreSQL** | 16-alpine | [![Critical](https://img.shields.io/badge/critical-0-success)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![High](https://img.shields.io/badge/high-2-important)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![Medium](https://img.shields.io/badge/medium-10-orange)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![Low](https://img.shields.io/badge/low-0-informational)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) |
| **Coturn** | 4.7-alpine | [![Critical](https://img.shields.io/badge/critical-2-critical)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![High](https://img.shields.io/badge/high-4-important)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![Medium](https://img.shields.io/badge/medium-21-orange)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![Low](https://img.shields.io/badge/low-0-informational)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) |

### Security Features

✅ **Automated Daily Scans** - Runs automatically every day at 2 AM UTC

✅ **PR Security Checks** - All pull requests are scanned before merge

✅ **Container Vulnerability Scanning** - All Docker images scanned for CVEs

✅ **GitHub Security Tab** - Detailed findings available in [Security Dashboard](https://github.com/ludolac/matrix-synapse-stack/security/code-scanning)

✅ **SARIF Reports** - Structured results for easy tracking

✅ **Multi-Level Scanning** - Chart configs + rendered manifests + container images

### What We Scan

- 🔍 **Helm chart YAML** configurations
- 🔍 **Rendered Kubernetes** manifests
- 🔍 **Container images** (Synapse, Element Web, PostgreSQL, Coturn)
- 🔍 **Security misconfigurations** and best practices
- 🔍 **Known vulnerabilities** (CVEs) in container images
- 🔍 **OS packages** and application dependencies

### View Detailed Results

- **Latest Scan**: [GitHub Actions Workflow](https://github.com/ludolac/matrix-synapse-stack/actions/workflows/trivy-scan.yml)
- **Security Findings**: [Code Scanning Alerts](https://github.com/ludolac/matrix-synapse-stack/security/code-scanning)
- **Historical Scans**: [All Workflow Runs](https://github.com/ludolac/matrix-synapse-stack/actions/workflows/trivy-scan.yml)
- **Download Reports**: Click any vulnerability badge to view the scan run and download detailed CSV/JSON reports

> **Note**: Vulnerability counts are updated automatically after each scan. **Click any badge** in the Container Images table to see the full scan run with downloadable CSV reports containing CVE IDs, affected packages, versions, and descriptions.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
  - [Core Configuration](#core-configuration)
  - [SSO/OIDC Integration](#ssooidc-integration)
  - [Two-Factor Authentication (2FA)](#two-factor-authentication-2fa)
  - [URL Previews](#url-previews)
  - [Element Web Theming](#element-web-theming)
- [Coturn TURN Server](#coturn-turn-server-videovoice-calls)
- [User Management](#user-management)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Upgrading](#upgrading)
- [Uninstalling](#uninstalling)

---

## Features

✅ **Matrix Synapse** v1.140.0 - Full-featured Matrix homeserver

✅ **Element Web** v1.12.2 - Modern web client with dark theme

✅ **PostgreSQL 16** - Reliable database backend

✅ **Coturn TURN Server** - Integrated WebRTC support for video/voice calls

✅ **URL Previews** - Rich link previews with OpenGraph metadata and SSRF protection

✅ **SSO/OIDC Support** - Integrate with Authelia, Keycloak, Google, GitHub, Azure AD

✅ **Two-Factor Authentication** - TOTP support for enhanced security

✅ **Automated Secret Management** - Scripts for credential generation

✅ **Admin User Creation** - Post-install job creates admin automatically

✅ **Ingress Support** - Traefik ingress with TLS

✅ **Persistent Storage** - Longhorn/PVC for data persistence

✅ **Network Policies** - Fine-grained network security

✅ **Security Hardened** - Pod security, secret management, SSRF protection

✅ **Metrics & Monitoring** - Prometheus metrics enabled

✅ **Production Ready** - Tested configuration with best practices

---

## Requirements

### Core Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| **Kubernetes** | v1.24+ | ✅ Yes | Container orchestration platform |
| **Helm** | v3.8+ | ✅ Yes | Package manager for Kubernetes |
| **kubectl** | v1.24+ | ✅ Yes | Kubernetes command-line tool |

### Infrastructure Components

| Component | Version | Required | Purpose | Notes |
|-----------|---------|----------|---------|-------|
| **Ingress Controller** | Latest | ✅ Yes | HTTP/HTTPS routing | Traefik recommended, Nginx compatible |
| **cert-manager** | v1.11+ | ⚠️ Recommended | TLS certificate management | Required for automatic HTTPS |
| **Storage Provisioner** | - | ✅ Yes | Persistent volume provisioning | Longhorn, OpenEBS, NFS, or cloud provider |
| **external-dns** | v0.13+ | ⚙️ Optional | Automatic DNS management | Automates DNS record creation |
| **Prometheus** | v2.40+ | ⚙️ Optional | Metrics collection | For monitoring and alerting |
| **PostgreSQL** | 16-alpine | [![Critical](https://img.shields.io/badge/critical-0-success)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![High](https://img.shields.io/badge/high-2-important)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![Medium](https://img.shields.io/badge/medium-10-orange)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) | [![Low](https://img.shields.io/badge/low-0-informational)](https://github.com/ludolac/matrix-synapse-stack/actions/runs/21465172573) |

### Traefik Ingress Configuration

This chart is optimized for **Traefik** ingress controller with the following features:

- **HTTP/HTTPS Routes**: Standard web traffic on ports 80/443
- **Federation Port**: Matrix federation on port 8448 (custom entrypoint required)
- **TLS Termination**: Automatic via cert-manager integration
- **Annotations**: Pre-configured for Traefik routing

**Traefik Setup Requirements:**

```yaml
# Traefik values.yaml - Add federation entrypoint
ports:
  websecure:
    port: 443
    exposedPort: 443
  matrix-federation:
    port: 8448
    exposedPort: 8448
    protocol: TCP
```

**Alternative Ingress Controllers:**

- **Nginx Ingress**: Supported, requires annotation adjustments
- **Kong**: Compatible with configuration changes
- **HAProxy**: Supported with custom annotations

### cert-manager Configuration

**Installation:**

```bash
# Add Jetstack repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.0 \
  --set installCRDs=true
```

**ClusterIssuer Setup (Let's Encrypt):**

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: traefik
```

### external-dns (Optional)

Automatically manages DNS records for your Matrix homeserver.

**Supported Providers:**
- Cloudflare
- AWS Route53
- Google Cloud DNS
- Azure DNS
- OVH
- And [many more](https://github.com/kubernetes-sigs/external-dns)

**Example Configuration (Cloudflare):**

```yaml
# external-dns values
provider: cloudflare
cloudflare:
  apiToken: "your-api-token"
  proxied: false
domainFilters:
  - yourdomain.com
txtOwnerId: "matrix-synapse"
```

### Storage Classes

The chart requires a **StorageClass** for persistent volumes:

| Storage Type | Use Case | Performance | Recommended |
|--------------|----------|-------------|-------------|
| **Longhorn** | Self-hosted, replicated | Good | ✅ Production |
| **OpenEBS** | Self-hosted, flexible | Good | ✅ Production |
| **NFS** | Simple, shared storage | Medium | ⚠️ Development |
| **Local Path** | Node-local storage | Fast | ⚠️ Single-node only |
| **Cloud Provider** | AWS EBS, GCE PD, Azure Disk | Excellent | ✅ Production |

**Check Available Storage Classes:**

```bash
kubectl get storageclass
```

### Network Requirements

**Ports:**

| Port | Protocol | Purpose | Exposure |
|------|----------|---------|----------|
| 443 | HTTPS | Client API, Element Web | Public |
| 8448 | HTTPS | Matrix Federation | Public |
| 3478 | UDP/TCP | TURN/STUN (Coturn) | Public |
| 5349 | TCP | TURN over TLS | Public |
| 49152-65535 | UDP | TURN relay ports | Public |

**DNS Records Required:**

```
matrix.yourdomain.com          → Ingress IP (A/AAAA)
element.yourdomain.com         → Ingress IP (A/AAAA)
turn.yourdomain.com            → Coturn IP (A/AAAA)

# Optional: Auto-discovery
_matrix._tcp.yourdomain.com    → SRV record (for federation)
```

### Kubernetes Version Compatibility

| Kubernetes Version | Status | Notes |
|--------------------|--------|-------|
| v1.31+ | ✅ Tested | Latest release |
| v1.30 | ✅ Tested | Stable |
| v1.29 | ✅ Tested | Stable |
| v1.28 | ✅ Tested | Stable |
| v1.27 | ✅ Supported | Tested |
| v1.26 | ✅ Supported | Tested |
| v1.25 | ⚠️ Compatible | Untested |
| v1.24 | ⚠️ Compatible | Untested |
| < v1.24 | ❌ Not Supported | EOL versions |

### Resources

**Minimum Requirements:**
- **CPU**: 2 cores
- **Memory**: 4GB RAM
- **Storage**: 20GB

**Recommended for Production:**
- **CPU**: 4 cores
- **Memory**: 8GB RAM
- Storage: 50GB+

### DNS Configuration

You need DNS records pointing to your ingress:
- `matrix.example.com` - Synapse homeserver
- `element.example.com` - Element Web client
- `turn.example.com` (optional) - TURN server for video calls

---

## Quick Start

```bash
# 1. Add Helm repository
helm repo add matrix-synapse https://ludolac.github.io/matrix-synapse-stack/
helm repo update

# 2. Create namespace
kubectl create namespace matrix

# 3. Clone repository for scripts and example config
git clone https://github.com/ludolac/matrix-synapse-stack.git
cd matrix-synapse-stack

# 4. Create your production values file
cp values-prod.yaml.example values-prod.yaml
vi values-prod.yaml  # Edit with your configuration

# 5. Generate secrets
./scripts/generate-secrets.sh all

# 6. Install the chart
helm install matrix-synapse matrix-synapse/matrix-synapse \
  --namespace matrix \
  --values values-prod.yaml \
  --timeout 10m

# 7. Wait for deployment
kubectl get pods -n matrix -w

# 8. Get admin credentials
cat .secrets/admin-credentials.txt

# 9. Access Element Web at https://element.example.com
```

---

## Installation

### Step 1: Add Helm Repository

```bash
helm repo add matrix-synapse https://ludolac.github.io/matrix-synapse-stack/
helm repo update
helm search repo matrix-synapse
```

### Step 2: Prepare Environment

```bash
# Create namespace
kubectl create namespace matrix

# Verify storage class
kubectl get storageclass

# Verify ingress controller
kubectl get pods -n traefik
```

### Step 3: Configure Values

```bash
# Clone repository
git clone https://github.com/ludolac/matrix-synapse-stack.git
cd matrix-synapse-stack

# Create production values
cp values-prod.yaml.example values-prod.yaml
vi values-prod.yaml
```

**Key settings:**
```yaml
synapse:
  server:
    name: "matrix.example.com"

ingress:
  synapse:
    host: matrix.example.com
  element:
    host: element.example.com
```

### Step 4: Generate Secrets

```bash
# Generate all secrets (PostgreSQL + Admin + TURN)
./scripts/generate-secrets.sh all
```

Credentials are saved to `.secrets/` directory.

### Step 5: Install Chart

```bash
helm install matrix-synapse matrix-synapse/matrix-synapse \
  --namespace matrix \
  --values values-prod.yaml \
  --timeout 10m
```

### Step 6: Verify Deployment

```bash
# Check pods
kubectl get pods -n matrix

# Get admin credentials
cat .secrets/admin-credentials.txt

# Access Element Web
open https://element.example.com
```

---

## Configuration

### Core Configuration

#### Server Settings

```yaml
synapse:
  server:
    name: "matrix.example.com"
    reportStats: true

    registration:
      enabled: false              # Disable public registration
      requireEmail: true
      allowGuests: false

    media:
      maxUploadSize: "100M"
      maxImagePixels: "64M"
```

#### Database

```yaml
postgresql:
  enabled: true
  database: "synapse_prod"
  username: "synapse"
  persistence:
    size: "5Gi"
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
      notifFrom: "Matrix <matrix@example.com>"
      appName: "My Matrix Server"
```

---

### SSO/OIDC Integration

Matrix Synapse supports Single Sign-On through OpenID Connect (OIDC). This allows users to log in using existing identity providers.

#### Supported Providers

| Provider | Status | Complexity |
|----------|--------|------------|
| **Authelia** | ✅ Tested | Medium |
| **Keycloak** | ✅ Tested | Medium |
| **Google** | ✅ Tested | Easy |
| **GitHub** | ✅ Tested | Easy |
| **Azure AD** | ✅ Tested | Medium |
| **Authentik** | ✅ Tested | Medium |
| **Okta** | ⚠️ Compatible | Medium |

#### Basic OIDC Configuration

```yaml
synapse:
  server:
    sso:
      enabled: true
      oidc:
        enabled: true
        providers:
          - idp_id: my_provider
            idp_name: "My SSO"
            discover: true
            issuer: "https://sso.example.com"
            client_id: "matrix"
            # client_secret stored in Kubernetes secret
            scopes: ["openid", "profile", "email"]
            user_mapping_provider:
              config:
                localpart_template: "{{ user.preferred_username }}"
                display_name_template: "{{ user.name }}"
                email_template: "{{ user.email }}"
```

#### Example: Authelia Integration

**1. Generate client secret:**
```bash
openssl rand -hex 32
```

**2. Configure Authelia** (`authentif` namespace):

Edit Authelia ConfigMap to add Matrix as OIDC client:
```yaml
identity_providers:
  oidc:
    clients:
      - client_id: matrix
        client_name: Matrix Synapse
        client_secret: YOUR_CLIENT_SECRET_HASH  # bcrypt hash
        redirect_uris:
          - https://matrix.example.com/_synapse/client/oidc/callback
        scopes:
          - openid
          - profile
          - email
          - groups
        grant_types:
          - authorization_code
```

**3. Create Kubernetes secret:**
```bash
kubectl create secret generic matrix-synapse-sso-credentials \
  --from-literal=client-secret=YOUR_CLIENT_SECRET \
  -n matrix
```

**4. Configure Matrix values:**
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
            discover: true
            issuer: "https://authelia.example.com"
            client_id: "matrix"
            allow_existing_users: true
            scopes: ["openid", "profile", "email", "groups"]
            user_mapping_provider:
              config:
                localpart_template: "{{ user.preferred_username }}"
                display_name_template: "{{ user.name }}"
                email_template: "{{ user.email }}"
```

#### Network Policy for SSO

If using NetworkPolicies, allow egress to SSO provider:

```yaml
networkPolicy:
  enabled: true
  egress:
    sso:
      namespaceSelector:
        kubernetes.io/metadata.name: authentif  # Authelia namespace
      podSelector: {}
```

#### Testing SSO

1. Navigate to Element Web login page
2. Click "Sign in with Authelia SSO" (or your provider name)
3. Authenticate with SSO provider
4. You'll be redirected back to Element

**Troubleshooting:**
```bash
# Check OIDC configuration
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  cat /data/homeserver-override.yaml | grep -A 30 oidc_providers

# Check SSO logs
kubectl logs deployment/matrix-synapse-synapse -n matrix | grep -i oidc

# Test OIDC discovery
curl https://authelia.example.com/.well-known/openid-configuration
```

---

### Two-Factor Authentication (2FA)

Matrix Synapse supports TOTP (Time-based One-Time Password) for two-factor authentication.

#### Server Configuration

Enable TOTP in your values:

```yaml
synapse:
  server:
    mfa:
      totp:
        enabled: true
        algorithm: "sha1"       # Standard TOTP algorithm
        digits: 6               # 6-digit codes
        period: 30              # 30-second validity
        issuer: "My Matrix"     # Name shown in authenticator apps
```

#### User Setup Guide

**1. Install an authenticator app:**
- Google Authenticator (iOS/Android)
- Microsoft Authenticator (iOS/Android)
- Authy (iOS/Android/Desktop)
- 1Password, Bitwarden (with TOTP support)

**2. Enable 2FA in Element Web:**

1. Log in to Element Web
2. Click your avatar → **All Settings**
3. Go to **Security & Privacy** tab
4. Scroll to **Secure Backup** section
5. Click **Set up** next to "Secure Messages with Recovery Key"
6. Follow the prompts and save your recovery key
7. Scroll to **Two-factor Authentication**
8. Click **Set up**
9. Scan QR code with your authenticator app
10. Enter the 6-digit code to confirm
11. **Save recovery codes** in a safe place!

**3. Login with 2FA:**

After enabling 2FA, logins will require:
1. Username + password
2. 6-digit code from authenticator app

#### Recovery Codes

Recovery codes allow access if you lose your authenticator device.

**To view/regenerate recovery codes:**
1. Settings → Security & Privacy
2. Two-factor Authentication → **View recovery codes**
3. Save them securely (password manager recommended)

**To use recovery code:**
1. At 2FA prompt, click "Use a recovery code"
2. Enter one of your recovery codes
3. **Each code can only be used once**

#### Security Best Practices

✅ **Save recovery codes** - Store in password manager

✅ **Enable on critical accounts first** - Admin users should enable 2FA

✅ **Backup authenticator app** - Use apps with cloud backup (Microsoft Authenticator)

✅ **Test recovery process** - Verify recovery codes work before relying on them

❌ **Don't screenshot QR codes** - They can compromise your 2FA

❌ **Don't share recovery codes** - Treat them like passwords

#### Disabling 2FA

If you need to disable 2FA:
1. Settings → Security & Privacy
2. Two-factor Authentication → **Remove**
3. Confirm with password and current 2FA code

**If locked out:**
Server administrators can disable 2FA via admin API:
```bash
# Get admin access token first
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  register_new_matrix_user -c /data/homeserver.yaml -a

# Disable user's 2FA
./scripts/matrix-admin.sh reset-2fa -u username
```

---

### URL Previews

URL previews show rich link previews (title, description, image) when URLs are posted in rooms.

#### Server Configuration

```yaml
synapse:
  server:
    urlPreviews:
      enabled: true
```

This configures Synapse with:
- OpenGraph metadata fetching
- SSRF protection (blocks internal IPs)
- 10MB max preview size
- HTTP/HTTPS egress via NetworkPolicy

#### Client Configuration

URL previews are **per-room settings** that users must enable:

**Step 1: Enable in User Settings**
1. Element Web → Click avatar → **All Settings**
2. **Preferences** tab
3. **Timeline** section
4. Enable:
   - ✅ "Show previews for links in messages"
   - ✅ "Show inline URL previews"

**Step 2: Enable in Room Settings**
1. Open room → Click room name → **Settings**
2. **General** tab (⚠️ NOT Security & Privacy!)
3. Enable:
   - ✅ "Enable URL previews for this room"

**Step 3: Test**
Send a link: `https://github.com`

Preview appears in 2-10 seconds with title, description, and image!

#### Security

URL preview is protected against SSRF attacks:

```yaml
url_preview_ip_range_blacklist:
  - '127.0.0.0/8'      # Localhost
  - '10.0.0.0/8'       # Private networks
  - '172.16.0.0/12'
  - '192.168.0.0/16'
  - '169.254.0.0/16'   # Link-local
  - '::1/128'          # IPv6 localhost
  - 'fe80::/10'        # IPv6 link-local
```

#### Troubleshooting

**Previews not appearing:**
```bash
# 1. Check Synapse config
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  cat /data/homeserver-override.yaml | grep url_preview_enabled

# 2. Check NetworkPolicy allows HTTP/HTTPS
kubectl get networkpolicy matrix-synapse-synapse -n matrix -o yaml

# 3. Test URL fetch from Synapse pod
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  curl -I https://github.com

# 4. Check Synapse logs
kubectl logs deployment/matrix-synapse-synapse -n matrix | grep preview
```

**Common issues:**
- ❌ Room setting not enabled → Enable in room General tab
- ❌ NetworkPolicy blocking egress → Check port 80/443 allowed
- ❌ URL returns 403/404 → Some sites block preview bots
- ❌ SSRF protection triggered → URL pointing to internal IP

---

### Element Web Theming

Element Web supports dark theme for the main application interface.

#### Configuration

```yaml
element:
  config:
    # Set default theme
    defaultTheme: "dark"

    # Branding
    branding:
      authHeaderLogoUrl: "https://example.com/logo.png"
      welcomeBackgroundUrl: "https://example.com/background.jpg"
```

#### Custom Theme Colors

You can define custom color schemes:

```yaml
element:
  config:
    customThemes:
      - name: "Dark"
        is_dark: true
        colors:
          accent-color: "#0dbd8b"
          primary-color: "#0dbd8b"
          warning-color: "#ff6b6b"
          sidebar-color: "#15191e"
          roomlist-background-color: "#15191e"
          timeline-background-color: "#21262c"
          timeline-text-color: "#ffffff"
```

#### Known Limitation: Login Page Theme

⚠️ **Important**: Element Web's login/registration pages are **hardcoded to light theme** in the source code. This is a [known Element Web issue (#24530)](https://github.com/element-hq/element-web/issues/24530).

**What this means:**
- ✅ Dark theme works perfectly **after logging in**
- ❌ Login page remains light-themed
- ❌ Cannot be changed via configuration
- ❌ Affects ALL Element Web instances (not specific to this chart)

**Workarounds:**
1. **Accept it** - Standard behavior for all Element Web deployments
2. **Custom build** - Fork Element Web and modify login page styling (requires maintenance)
3. **Wait for fix** - Element team working on redesign (no ETA)

**Why?**
The Element team indicated this requires "a full design sprint for the sign-in flow" - it's not just a config option but needs design work.

---

## Coturn TURN Server (Video/Voice Calls)

Coturn TURN server enables video and voice calls to work through NAT/firewalls.

### Quick Start

**1. Generate TURN secret:**
```bash
./scripts/generate-secrets.sh turn
```

**2. Enable in values:**
```yaml
coturn:
  enabled: true
  externalIP: "YOUR_PUBLIC_IP"
  realm: "turn.example.com"

  service:
    type: LoadBalancer
    externalDns:
      enabled: true
      hostname: "turn.example.com"
```

**3. Deploy:**
```bash
helm upgrade matrix-synapse . -n matrix -f values-prod.yaml
```

### Architecture

Synapse automatically configures TURN when `coturn.enabled: true`:
- Shared secret injected from Kubernetes secret
- TURN URIs auto-configured
- No manual configuration needed

### Network Requirements

**Required ports:**
- `3478/UDP` - TURN (UDP)
- `3478/TCP` - TURN (TCP)
- `5349/UDP` - TURNS (secure)
- `5349/TCP` - TURNS (secure)
- `49152-49252/UDP` - Media relay ports

**Firewall rules:**
```bash
# TURN ports
iptables -A INPUT -p udp --dport 3478 -j ACCEPT
iptables -A INPUT -p tcp --dport 3478 -j ACCEPT
iptables -A INPUT -p udp --dport 5349 -j ACCEPT
iptables -A INPUT -p tcp --dport 5349 -j ACCEPT

# Media relay
iptables -A INPUT -p udp --dport 49152:49252 -j ACCEPT
```

### Configuration Examples

**Production with LoadBalancer:**
```yaml
coturn:
  enabled: true
  externalIP: "203.0.113.50"
  realm: "turn.example.com"

  service:
    type: LoadBalancer
    loadBalancerIP: "203.0.113.50"

  tls:
    enabled: true
    secretName: "coturn-tls"

  resources:
    limits:
      cpu: 1000m
      memory: 512Mi
```

**NodePort setup:**
```yaml
coturn:
  enabled: true
  externalIP: "203.0.113.50"

  service:
    type: NodePort
    nodePorts:
      turnUdp: 30478
      turnTcp: 30478
```

### Troubleshooting

```bash
# Check coturn pod
kubectl get pods -n matrix | grep coturn

# View logs
kubectl logs -n matrix deployment/matrix-synapse-coturn

# Test connectivity
nc -zv turn.example.com 3478

# Verify Synapse config
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  cat /data/homeserver-override.yaml | grep -A 10 turn_uris
```

**Common issues:**

1. **Calls fail** - Check TURN shared secret matches
2. **One-way audio** - External IP misconfigured or firewall blocking
3. **TURN unreachable** - LoadBalancer IP not assigned or ports not open

See full Coturn documentation in original README for advanced configuration.

---

## User Management

### Admin User

Created automatically during installation:

```bash
# Get credentials
cat .secrets/admin-credentials.txt

# Or from Kubernetes
kubectl get secret matrix-synapse-admin-credentials -n matrix \
  -o jsonpath='{.data.password}' | base64 -d
```

### Creating Users

Use the administration script:

```bash
# Create user with auto-generated password
./scripts/matrix-admin.sh create -u alice -e alice@example.com

# Create admin user
./scripts/matrix-admin.sh create -u bob -p SecurePass123 -e bob@example.com -a

# List all users
./scripts/matrix-admin.sh list

# Show user details
./scripts/matrix-admin.sh info -u alice

# Update password
./scripts/matrix-admin.sh update-password -u alice -p NewPassword

# Deactivate user
./scripts/matrix-admin.sh deactivate -u alice

# Delete user
./scripts/matrix-admin.sh delete -u alice
```

**Credentials saved to:**
```
.secrets/users/<username>.txt
```

See `scripts/README.md` for full documentation.

---

## Backup and Restore

### What to Backup

1. **PostgreSQL Database** - All user data, messages, room state
2. **Media Store** - Uploaded files, images, videos
3. **Signing Keys** - Server cryptographic keys
4. **Secrets** - Kubernetes secrets

### Backup Commands

**Database:**
```bash
kubectl exec matrix-synapse-postgresql-0 -n matrix -- \
  pg_dump -U synapse synapse_prod | gzip > matrix-db-$(date +%Y%m%d).sql.gz
```

**Media Store:**
```bash
POD=$(kubectl get pod -n matrix -l app.kubernetes.io/component=synapse -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -n matrix -- tar czf /tmp/media.tar.gz /data/media_store
kubectl cp matrix/$POD:/tmp/media.tar.gz ./matrix-media-$(date +%Y%m%d).tar.gz
```

**Signing Keys:**
```bash
kubectl exec $POD -n matrix -- cat /data/matrix.example.com.signing.key > \
  matrix-signing-key-$(date +%Y%m%d).key
```

**Secrets:**
```bash
kubectl get secrets -n matrix -o yaml > matrix-secrets-$(date +%Y%m%d).yaml
```

### Restore Procedures

**Database:**
```bash
kubectl cp ./matrix-db-backup.sql.gz matrix/matrix-synapse-postgresql-0:/tmp/
kubectl exec -it matrix-synapse-postgresql-0 -n matrix -- \
  bash -c "gunzip /tmp/matrix-db-backup.sql.gz && \
           psql -U synapse synapse_prod < /tmp/matrix-db-backup.sql"
```

**Media & Keys:**
```bash
POD=$(kubectl get pod -n matrix -l app.kubernetes.io/component=synapse -o jsonpath='{.items[0].metadata.name}')
kubectl cp ./matrix-media-backup.tar.gz matrix/$POD:/tmp/
kubectl exec $POD -n matrix -- tar xzf /tmp/matrix-media-backup.tar.gz -C /data/
kubectl cp ./matrix-signing-key.key matrix/$POD:/data/matrix.example.com.signing.key
kubectl rollout restart deployment/matrix-synapse-synapse -n matrix
```

### Best Practices

1. **Automate backups** - Use CronJobs
2. **Multiple locations** - S3, NFS, and local
3. **Test restores** - Verify backups work
4. **Retention policy** - Daily/weekly/monthly
5. **Encrypt backups** - Sensitive data protection
6. **Monitor backups** - Alert on failures

---

## Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
kubectl get pods -n matrix
kubectl describe pod <pod-name> -n matrix
kubectl logs <pod-name> -n matrix
```

**Causes:** PVC not binding, image pull errors, resource limits, missing secrets

#### Admin Login Fails

```bash
# Verify credentials
cat .secrets/admin-credentials.txt

# Check admin job logs
kubectl logs job/matrix-synapse-create-admin -n matrix

# Test API login
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  curl -X POST http://localhost:8008/_matrix/client/r0/login \
  -H "Content-Type: application/json" \
  -d '{"type":"m.login.password","user":"admin","password":"PASSWORD"}'
```

#### Database Connection Errors

```bash
# Check PostgreSQL
kubectl get pod matrix-synapse-postgresql-0 -n matrix
kubectl logs matrix-synapse-postgresql-0 -n matrix

# Test connection
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  pg_isready -h matrix-synapse-postgresql -p 5432
```

#### Video Calls Not Working

**Error:** "Call invites are not allowed in public rooms"

**Solution:** Change room to private (invite-only):
1. Room settings → Security & Privacy
2. Change "Room Access" to "Private (invite only)"
3. Save

**Alternative:** Use direct messages (DMs) - always support calls

#### Ingress/TLS Issues

```bash
# Check ingress
kubectl get ingress -n matrix

# Check certificates
kubectl get certificate -n matrix
kubectl describe certificate matrix-synapse-tls -n matrix

# Test internal service
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n matrix -- \
  curl http://matrix-synapse-synapse:8008/_matrix/static/
```

### Getting Help

```bash
# View logs
kubectl logs -l app.kubernetes.io/component=synapse -n matrix --tail=100

# Check events
kubectl get events -n matrix --sort-by='.lastTimestamp'

# Health check
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  curl -s http://localhost:8008/health
```

---

## Security

### Best Practices

1. **Change default passwords** immediately
2. **Enable TLS** with Let's Encrypt
3. **Use NetworkPolicies** for pod isolation
4. **Secure secrets** - Use external secret managers
5. **Regular updates** - Monitor security advisories
6. **Enable 2FA** for admin accounts
7. **Backup encryption** - Encrypt backup storage
8. **Audit logs** - Monitor for suspicious activity

### Network Security

```yaml
networkPolicy:
  enabled: true
  ingress:
    traefik:
      namespaceSelector:
        name: traefik
  egress:
    sso:
      namespaceSelector:
        kubernetes.io/metadata.name: authentif
```

---

## Upgrading

### Upgrade Chart

```bash
# Backup first!
kubectl exec matrix-synapse-postgresql-0 -n matrix -- \
  pg_dump -U synapse synapse_prod | gzip > backup-before-upgrade.sql.gz

# Update repository
helm repo update

# Upgrade
helm upgrade matrix-synapse matrix-synapse/matrix-synapse \
  --namespace matrix \
  --values values-prod.yaml \
  --timeout 10m

# Verify
kubectl get pods -n matrix
```

### Upgrade Synapse Version

1. Update image tag in `values-prod.yaml`
2. Check [release notes](https://github.com/element-hq/synapse/releases)
3. Backup database
4. Apply upgrade

Synapse runs database migrations automatically on startup.

---

## Uninstalling

### Complete Removal

```bash
# Uninstall chart
helm uninstall matrix-synapse -n matrix

# Delete data (WARNING: Permanent!)
kubectl delete pvc --all -n matrix

# Delete secrets
kubectl delete secrets --all -n matrix

# Delete namespace
kubectl delete namespace matrix
```

### Keep Data

```bash
# Uninstall but keep PVCs and secrets
helm uninstall matrix-synapse -n matrix

# Reinstall later
helm install matrix-synapse . --namespace matrix --values values-prod.yaml
```

---

## Additional Resources

### Documentation

- **Matrix Specification**: https://spec.matrix.org/
- **Synapse Docs**: https://element-hq.github.io/synapse/
- **Element Guide**: https://element.io/user-guide
- **Scripts README**: [scripts/README.md](scripts/README.md)

### Support

1. Check [Troubleshooting](#troubleshooting) section
2. Review logs: `kubectl logs -n matrix -l app.kubernetes.io/instance=matrix-synapse`
3. Matrix community: #synapse:matrix.org
4. Synapse issues: https://github.com/element-hq/synapse/issues

---

## License

This Helm chart is licensed under the **MIT License** - see [LICENSE](LICENSE) file.

**Deployed Software:**
- **Matrix Synapse**: Apache License 2.0
- **Element Web**: Apache License 2.0
- **PostgreSQL**: PostgreSQL License
- **Coturn**: BSD License

---

## Chart Information

- **Chart Version**: 1.5.0
- **Synapse Version**: v1.140.0
- **Element Web Version**: v1.12.2
- **PostgreSQL Version**: 16-alpine
- **Coturn Version**: 4.6-alpine

**Maintainer**: WAADOO - contact@waadoo.ovh
