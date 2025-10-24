# Matrix Authentication Service (MAS) Integration Guide

## Overview

Matrix Authentication Service (MAS) is Element's modern authentication and authorization service that provides enhanced features beyond Synapse's built-in authentication.

**Current Status**: Not yet integrated (planned enhancement)
**Priority**: Medium (current Authelia SSO + TOTP 2FA working well)
**Complexity**: High (requires database, secrets, Synapse reconfiguration)

---

## What is Matrix Authentication Service?

MAS is a standalone OAuth2/OIDC provider and account management service that:

### Key Features
✅ **Advanced OAuth2/OIDC**: Full-featured OAuth2/OIDC provider
✅ **Account Management**: Web UI for password reset, email verification
✅ **Enhanced 2FA**: WebAuthn, TOTP, backup codes
✅ **Session Management**: Better control over active sessions
✅ **Admin Interface**: Manage users, sessions, and clients
✅ **Email Flows**: Registration, verification, password reset
✅ **Better UX**: Modern authentication flows in Element

### Why Add MAS?

**Current Setup (Synapse + Authelia)**:
- ✅ Working SSO via Authelia OIDC
- ✅ TOTP 2FA support
- ❌ No self-service password reset
- ❌ No email verification flows
- ❌ Limited account management UI

**With MAS**:
- ✅ Everything current setup has
- ✅ Self-service password reset
- ✅ Email verification
- ✅ Better account management
- ✅ Modern Element integration
- ✅ Centralized authentication service

---

## Architecture

### Current Architecture
```
┌─────────────┐
│   Element   │
└──────┬──────┘
       │ (Matrix Client-Server API)
       ▼
┌─────────────┐     ┌──────────┐
│   Synapse   │────▶│ Authelia │ (SSO)
└──────┬──────┘     └──────────┘
       │
       ▼
┌─────────────┐
│ PostgreSQL  │
└─────────────┘
```

### With MAS Architecture
```
┌─────────────┐
│   Element   │
└──────┬──────┘
       │ (Matrix Client-Server API)
       ▼
┌─────────────┐     ┌──────────┐
│   Synapse   │────▶│   MAS    │───▶┌──────────┐
└──────┬──────┘     └────┬─────┘    │ Authelia │ (upstream SSO)
       │                 │           └──────────┘
       │                 ▼
       │           ┌──────────┐
       │           │ MAS DB   │
       │           └──────────┘
       ▼
┌─────────────┐
│ Synapse DB  │
└─────────────┘
```

**MAS acts as middleware** between Synapse and authentication providers.

---

## Prerequisites

Before implementing MAS:

1. ✅ **Working Synapse deployment** (you have this)
2. ✅ **PostgreSQL** (you have this)
3. ✅ **Ingress/TLS** (you have this)
4. ✅ **DNS records** (you have this)
5. 🔲 **MAS subdomain** (need: `auth.waadoo.ovh` or similar)
6. 🔲 **Email SMTP** (for password reset, verification)

---

## Implementation Steps

### Phase 1: Configuration Structure

Add to `values.yaml`:

```yaml
# Matrix Authentication Service (MAS)
mas:
  enabled: false  # Enable when ready to deploy

  image:
    registry: ghcr.io
    repository: element-hq/matrix-authentication-service
    tag: "1.2.0"
    pullPolicy: IfNotPresent

  replicaCount: 1

  # Service configuration
  service:
    type: ClusterIP
    port: 8080
    targetPort: 8080

  # Ingress configuration
  ingress:
    enabled: true
    host: "auth.waadoo.ovh"
    tls:
      enabled: true
      secretName: mas-tls

  # Database configuration
  database:
    # Create separate database in existing PostgreSQL
    name: mas
    user: mas
    # Password from secret: matrix-synapse-mas-credentials

  # Synapse integration
  synapse:
    # Internal service endpoint
    endpoint: "http://matrix-synapse-synapse:8008"
    # Shared secret for Synapse-MAS communication
    # Generated automatically if not provided
    sharedSecret: ""

  # Encryption keys
  secrets:
    # AES encryption key for sensitive data
    # Generated automatically if not provided
    encryptionSecret: ""

  # OIDC upstream providers (e.g., Authelia)
  oidc:
    enabled: true
    providers:
      - id: authelia
        name: "Waadoo SSO"
        issuer: "https://authelia.waadoo.ovh"
        clientId: "mas"
        clientSecret: ""  # From Kubernetes secret
        scopes:
          - openid
          - profile
          - email

  # Account management features
  features:
    # Allow users to register accounts
    registration: true
    # Email verification required for registration
    emailVerification: true
    # Enable password reset flow
    passwordReset: true
    # Allow password changes
    passwordChange: true
    # Display name management
    displayNameChange: true

  # Email configuration
  email:
    enabled: true
    from: "auth@waadoo.ovh"
    replyTo: "noreply@waadoo.ovh"
    # Email templates
    templates:
      verification: "default"
      passwordReset: "default"

  # Resources
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

### Phase 2: Create Templates

Need to create these templates:

1. **mas-deployment.yaml**
   - Deployment with MAS container
   - Environment variables for database, secrets
   - Volume mounts for config

2. **mas-service.yaml**
   - ClusterIP service on port 8080

3. **mas-configmap.yaml**
   - MAS configuration (mas-config.yaml)
   - Database connection settings
   - OIDC provider configuration
   - Feature flags

4. **mas-ingress.yaml**
   - Ingress for auth.waadoo.ovh
   - TLS configuration

5. **mas-secrets-init-job.yaml**
   - Pre-install job to generate:
     - Encryption secret
     - Synapse shared secret
     - Database password

6. **mas-networkpolicy.yaml** (if NetworkPolicy enabled)
   - Allow ingress from Traefik
   - Allow egress to Synapse
   - Allow egress to PostgreSQL
   - Allow egress to Authelia (OIDC)

### Phase 3: Update Synapse Configuration

Update `synapse-configmap.yaml` to enable MAS:

```yaml
# Experimental Matrix Authentication Service
experimental_features:
  msc3861:
    enabled: true
    issuer: "https://auth.waadoo.ovh/"
    account_management_url: "https://auth.waadoo.ovh/account"
    client_id: "synapse"
    client_auth_method: "client_secret_basic"
    client_secret: "${MAS_SYNAPSE_SHARED_SECRET}"
```

### Phase 4: Database Setup

MAS needs its own database in PostgreSQL:

```sql
CREATE DATABASE mas WITH ENCODING 'UTF8' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8';
CREATE USER mas WITH PASSWORD '<generated>';
GRANT ALL PRIVILEGES ON DATABASE mas TO mas;
```

This should be handled by an init job or PostgreSQL init script.

### Phase 5: Configure Authelia

Update Authelia to add MAS as OIDC client:

```yaml
identity_providers:
  oidc:
    clients:
      - id: mas
        description: Matrix Authentication Service
        secret: <hashed-secret>
        public: false
        authorization_policy: two_factor
        redirect_uris:
          - https://auth.waadoo.ovh/oauth2/callback
        scopes:
          - openid
          - profile
          - email
        grant_types:
          - authorization_code
          - refresh_token
```

### Phase 6: Testing Checklist

- [ ] MAS pod starts successfully
- [ ] MAS can connect to PostgreSQL
- [ ] MAS can reach Authelia OIDC endpoints
- [ ] Synapse can communicate with MAS
- [ ] Element Web redirects to MAS for login
- [ ] SSO login through MAS → Authelia works
- [ ] Password login works (if enabled)
- [ ] 2FA enrollment works
- [ ] Password reset flow works
- [ ] Email verification works
- [ ] Account management UI accessible

---

## Migration Strategy

### Option A: Fresh Install (Recommended)
1. Deploy MAS alongside existing Synapse
2. Test thoroughly in parallel
3. Switch Element to use MAS endpoint
4. Migrate users gradually
5. Disable old authentication methods

### Option B: In-Place Upgrade
1. Backup all databases
2. Deploy MAS
3. Update Synapse config with MAS settings
4. Restart Synapse
5. Users must re-authenticate

**Recommendation**: Option A for production (less risk)

---

## Required Secrets

MAS requires these secrets:

1. **mas-encryption-secret**: AES key for encrypting sensitive data
   ```bash
   openssl rand -hex 32
   ```

2. **mas-synapse-shared-secret**: For Synapse-MAS communication
   ```bash
   openssl rand -hex 32
   ```

3. **mas-database-password**: PostgreSQL password
   ```bash
   openssl rand -base64 32
   ```

4. **mas-oidc-client-secret**: For upstream OIDC (Authelia)
   ```bash
   openssl rand -hex 32
   ```

Create Kubernetes secret:
```bash
kubectl create secret generic matrix-synapse-mas-credentials \
  --from-literal=encryption-secret="<secret1>" \
  --from-literal=synapse-shared-secret="<secret2>" \
  --from-literal=database-password="<secret3>" \
  --from-literal=oidc-client-secret="<secret4>" \
  --namespace matrix
```

---

## DNS Requirements

Add DNS record for MAS:

```
auth.waadoo.ovh    A/CNAME    <your-ingress-ip>
```

Or use same domain with path-based routing:
```
matrix.waadoo.ovh/auth    →  MAS service
```

---

## NetworkPolicy Considerations

If NetworkPolicy is enabled, MAS needs:

**Ingress**:
- From Traefik (port 8080)
- From Synapse (port 8080) - for health checks

**Egress**:
- To PostgreSQL (port 5432)
- To Synapse (port 8008) - for user verification
- To Authelia (port 443) - for OIDC
- To DNS (port 53)
- To SMTP (port 587) - for emails

---

## Benefits After Implementation

1. **Better User Experience**
   - Modern authentication UI
   - Self-service password reset
   - Email verification
   - Better session management

2. **Enhanced Security**
   - Better 2FA flows
   - WebAuthn/FIDO2 support
   - Session invalidation
   - Account recovery options

3. **Operational Benefits**
   - Centralized authentication
   - Better admin tools
   - Easier to manage users
   - Better logging/auditing

4. **Element Integration**
   - Native MAS support in Element
   - Better UX for auth flows
   - Seamless SSO experience

---

## Estimated Implementation Time

- **Configuration**: 2-3 hours
- **Template Creation**: 4-6 hours
- **Testing**: 3-4 hours
- **Documentation**: 1-2 hours
- **Total**: ~10-15 hours

---

## References

- **MAS Documentation**: https://element-hq.github.io/matrix-authentication-service/
- **MAS GitHub**: https://github.com/element-hq/matrix-authentication-service
- **MAS Configuration Reference**: https://element-hq.github.io/matrix-authentication-service/reference/configuration.html
- **Synapse MAS Integration**: https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html#experimental_features

---

## Decision: When to Implement?

### Implement Now If:
- ❌ Current authentication UX is problematic
- ❌ Users need self-service password reset urgently
- ❌ Email verification is critical requirement
- ❌ You have 10-15 hours available for implementation

### Implement Later If:
- ✅ Current Authelia SSO + TOTP 2FA is working well (your case)
- ✅ Users can contact admin for password resets
- ✅ Email verification not critical
- ✅ Want to stabilize current deployment first

### Current Recommendation

**DEFER to Phase 2** - Your current setup with Authelia SSO and TOTP 2FA is working well. Focus on:
1. Stabilizing current deployment
2. User adoption
3. Monitoring and optimization

Implement MAS later when:
- Current setup limitations become apparent
- User demand for self-service features increases
- You have dedicated time for thorough testing

---

## Quick Start (When Ready)

When you decide to implement MAS:

1. Review this guide thoroughly
2. Test in development environment first
3. Create all required secrets
4. Set up DNS records
5. Update Authelia configuration
6. Deploy MAS components
7. Test authentication flows
8. Gradually migrate users
9. Update user documentation

---

**Status**: Ready for implementation when needed
**Last Updated**: 2025-10-23
**Author**: Claude (AI Assistant)
