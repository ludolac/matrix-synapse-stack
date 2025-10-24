# Matrix Synapse SSO Configuration Guide

This guide explains how to configure Single Sign-On (SSO) authentication for Matrix Synapse.

## Table of Contents

- [Overview](#overview)
- [Supported Providers](#supported-providers)
- [OIDC Configuration](#oidc-configuration)
- [SAML2 Configuration](#saml2-configuration)
- [Common Providers](#common-providers)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

---

## Overview

Matrix Synapse supports multiple SSO methods:
- **OpenID Connect (OIDC)** - Modern standard (Google, GitHub, Keycloak, Authentik, Azure AD)
- **SAML2** - Enterprise standard (Okta, OneLogin, Azure AD)
- **CAS** - Central Authentication Service (not covered in this chart)

### Benefits of SSO

✅ **Centralized Authentication** - Single source of truth for user credentials
✅ **Better Security** - Leverage existing security policies
✅ **Easier Onboarding** - Users can reuse existing accounts
✅ **Compliance** - Meet enterprise authentication requirements

---

## Supported Providers

### OIDC Providers

| Provider | Tested | Configuration Complexity |
|----------|--------|-------------------------|
| **Google** | ✅ | Easy |
| **GitHub** | ✅ | Easy |
| **Keycloak** | ✅ | Medium |
| **Authentik** | ✅ | Medium |
| **Azure AD / Entra ID** | ✅ | Medium |
| **Okta** | ⚠️ | Medium |
| **Auth0** | ⚠️ | Easy |
| **GitLab** | ⚠️ | Easy |

### SAML2 Providers

| Provider | Tested | Configuration Complexity |
|----------|--------|-------------------------|
| **Okta** | ⚠️ | Hard |
| **OneLogin** | ⚠️ | Hard |
| **Azure AD** | ⚠️ | Hard |

---

## OIDC Configuration

### Step 1: Configure Your Identity Provider

You need to register Matrix Synapse as an OAuth2/OIDC client in your IdP.

**Required Information:**
- **Redirect URI**: `https://matrix.example.com/_synapse/client/oidc/callback`
- **Scopes**: `openid`, `profile`, `email` (minimum)

### Step 2: Update `values-prod.yaml`

Add SSO configuration to your production values file:

```yaml
synapse:
  server:
    sso:
      enabled: true

      oidc:
        enabled: true
        providers:
          - idp_id: "my-sso"
            idp_name: "Corporate Login"
            discover: true
            issuer: "https://sso.example.com"
            client_id: "matrix-client-id"
            client_secret: "your-client-secret"
            scopes: ["openid", "profile", "email"]
            user_mapping:
              localpart_template: "{{ user.preferred_username }}"
              display_name_template: "{{ user.name }}"
              email_template: "{{ user.email }}"
            allow_existing_users: true
```

### Step 3: Apply Configuration

```bash
# Upgrade Helm release
helm upgrade matrix-synapse . \
  --namespace matrix \
  --values values-prod.yaml

# Wait for Synapse to restart
kubectl rollout status deployment/matrix-synapse-synapse -n matrix
```

### Step 4: Test SSO Login

1. Open Element Web: https://element.example.com
2. Click **"Sign In"**
3. Click **"Sign in with SSO"**
4. You should see your configured IdP button
5. Click it and authenticate

---

## SAML2 Configuration

### Step 1: Configure Your IdP

Register Matrix Synapse as a SAML Service Provider:

**Required Information:**
- **Entity ID**: `https://matrix.example.com/_synapse/client/saml2/metadata.xml`
- **ACS URL**: `https://matrix.example.com/_synapse/client/saml2/authn_response`

### Step 2: Update `values-prod.yaml`

```yaml
synapse:
  server:
    sso:
      enabled: true

      saml2:
        enabled: true
        metadata_url: "https://sso.example.com/saml/metadata"
        entity_id: "https://matrix.example.com"
        mxid_source_attribute: "uid"
        mxid_mapping: "dotreplace"
```

### Step 3: Apply and Test

Same as OIDC steps 3-4 above.

---

## Common Providers

### Google

**1. Create OAuth2 Credentials:**
- Go to https://console.cloud.google.com/apis/credentials
- Create OAuth 2.0 Client ID
- Application type: **Web application**
- Authorized redirect URIs: `https://matrix.waadoo.ovh/_synapse/client/oidc/callback`

**2. Configuration:**

```yaml
synapse:
  server:
    sso:
      enabled: true
      oidc:
        enabled: true
        providers:
          - idp_id: google
            idp_name: "Google"
            discover: true
            issuer: "https://accounts.google.com/"
            client_id: "YOUR_CLIENT_ID.apps.googleusercontent.com"
            client_secret: "YOUR_CLIENT_SECRET"
            scopes: ["openid", "profile", "email"]
            user_mapping:
              localpart_template: "{{ user.email.split('@')[0] }}"
              display_name_template: "{{ user.name }}"
              email_template: "{{ user.email }}"
```

---

### GitHub

**1. Create OAuth App:**
- Go to https://github.com/settings/developers
- New OAuth App
- Homepage URL: `https://matrix.waadoo.ovh`
- Authorization callback URL: `https://matrix.waadoo.ovh/_synapse/client/oidc/callback`

**2. Configuration:**

```yaml
synapse:
  server:
    sso:
      enabled: true
      oidc:
        enabled: true
        providers:
          - idp_id: github
            idp_name: "GitHub"
            discover: false  # GitHub doesn't support discovery
            issuer: "https://github.com/"
            client_id: "YOUR_GITHUB_CLIENT_ID"
            client_secret: "YOUR_GITHUB_CLIENT_SECRET"
            authorization_endpoint: "https://github.com/login/oauth/authorize"
            token_endpoint: "https://github.com/login/oauth/access_token"
            userinfo_endpoint: "https://api.github.com/user"
            scopes: ["read:user", "user:email"]
            user_mapping:
              localpart_template: "{{ user.login }}"
              display_name_template: "{{ user.name }}"
              email_template: "{{ user.email }}"
```

---

### Keycloak / Authentik

**1. Create Client:**
- Go to your Keycloak/Authentik admin console
- Create new OIDC client
- Client ID: `matrix`
- Valid Redirect URIs: `https://matrix.waadoo.ovh/_synapse/client/oidc/callback`
- Access Type: `confidential`

**2. Configuration:**

```yaml
synapse:
  server:
    sso:
      enabled: true
      oidc:
        enabled: true
        providers:
          - idp_id: keycloak
            idp_name: "Corporate SSO"
            discover: true
            issuer: "https://sso.waadoo.ovh/auth/realms/master"
            client_id: "matrix"
            client_secret: "YOUR_CLIENT_SECRET"
            scopes: ["openid", "profile", "email"]
            user_mapping:
              localpart_template: "{{ user.preferred_username }}"
              display_name_template: "{{ user.name }}"
              email_template: "{{ user.email }}"
            allow_existing_users: true
```

---

### Azure AD / Microsoft Entra ID

**1. Register Application:**
- Go to https://portal.azure.com
- Azure Active Directory → App registrations → New registration
- Name: `Matrix Synapse`
- Redirect URI (Web): `https://matrix.waadoo.ovh/_synapse/client/oidc/callback`
- API permissions: Add `User.Read`, `email`, `openid`, `profile`

**2. Configuration:**

```yaml
synapse:
  server:
    sso:
      enabled: true
      oidc:
        enabled: true
        providers:
          - idp_id: microsoft
            idp_name: "Microsoft"
            discover: true
            issuer: "https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0"
            client_id: "YOUR_APPLICATION_ID"
            client_secret: "YOUR_CLIENT_SECRET"
            scopes: ["openid", "profile", "email"]
            user_mapping:
              localpart_template: "{{ user.preferred_username.split('@')[0] }}"
              display_name_template: "{{ user.name }}"
              email_template: "{{ user.email }}"
```

---

## Testing

### 1. Check Configuration

```bash
# Verify ConfigMap has SSO config
kubectl get configmap matrix-synapse-synapse-config -n matrix -o yaml | grep -A 20 "oidc_providers"

# Should show your OIDC providers configuration
```

### 2. Test SSO Flow

```bash
# Get the OIDC metadata endpoint
curl https://matrix.waadoo.ovh/_synapse/client/oidc/providers

# Should return JSON with your configured providers
```

### 3. Check Logs

```bash
# Watch Synapse logs during SSO login
kubectl logs -f deployment/matrix-synapse-synapse -n matrix | grep -i oidc
```

### 4. Test Login

1. Open https://element.waadoo.ovh
2. Click **"Sign In"**
3. Click **"Sign in with SSO"** or **"Continue with [Provider]"**
4. Authenticate with your IdP
5. You should be redirected back and logged in

---

## Troubleshooting

### "Invalid redirect URI"

**Problem:** IdP rejects the redirect URI.

**Solution:** Ensure redirect URI exactly matches:
```
https://matrix.waadoo.ovh/_synapse/client/oidc/callback
```

### "OIDC discovery failed"

**Problem:** Synapse can't fetch provider metadata.

**Solution 1:** Check issuer URL is correct and accessible:
```bash
curl https://your-idp.com/.well-known/openid-configuration
```

**Solution 2:** If discovery isn't supported, set `discover: false` and manually specify endpoints:
```yaml
discover: false
authorization_endpoint: "https://..."
token_endpoint: "https://..."
userinfo_endpoint: "https://..."
jwks_uri: "https://..."
```

### "User not found" after SSO login

**Problem:** User mapping template doesn't match any existing users.

**Solution:** Check the user mapping template matches the claims from your IdP:

```bash
# Enable debug logging
kubectl edit configmap matrix-synapse-synapse-config -n matrix
# Change: level: DEBUG

# Restart Synapse
kubectl rollout restart deployment/matrix-synapse-synapse -n matrix

# Check logs for claims
kubectl logs deployment/matrix-synapse-synapse -n matrix | grep "OIDC"
```

### "Client secret invalid"

**Problem:** Wrong client secret configured.

**Solution:** Verify the client secret matches what's in your IdP:

```bash
# Check current secret
kubectl get configmap matrix-synapse-synapse-config -n matrix -o yaml | grep client_secret

# Update in values-prod.yaml and reapply
```

### SSO button doesn't appear

**Problem:** Element Web doesn't show SSO option.

**Solution 1:** Check `.well-known` endpoints:
```bash
curl https://matrix.waadoo.ovh/.well-known/matrix/client
# Should mention SSO providers
```

**Solution 2:** Clear browser cache and reload Element Web.

### Multiple providers - wrong one selected

**Problem:** Users see multiple SSO providers but click the wrong one.

**Solution:** Use `idp_icon` and `idp_brand` to make providers visually distinct:

```yaml
- idp_id: corporate
  idp_name: "Company Login"
  idp_icon: "mxc://example.com/your-logo"
  idp_brand: "corporate"  # Can be: "google", "github", "apple", "microsoft", etc.
```

---

## Security Considerations

### 1. Client Secret Protection

**Store sensitive secrets in Kubernetes Secrets:**

```bash
# Create secret for client credentials
kubectl create secret generic matrix-sso-credentials -n matrix \
  --from-literal=google-client-secret="YOUR_SECRET" \
  --from-literal=github-client-secret="YOUR_SECRET"

# Reference in values:
# client_secret: "${GOOGLE_CLIENT_SECRET}"
# Then add env var to deployment
```

### 2. HTTPS Required

SSO **only works over HTTPS**. Ensure your ingress has valid TLS certificates.

### 3. Allow Existing Users

If you enable SSO after users already exist with password auth, set:

```yaml
allow_existing_users: true
```

This allows SSO users to link to existing Matrix accounts.

### 4. Restrict SSO to Specific Domains

For Google, limit to your domain:

```yaml
- idp_id: google
  # ... other config ...
  user_mapping:
    localpart_template: "{{ user.email.split('@')[0] }}"
  # Add domain restriction via email template
  email_template: "{{ user.email if '@yourdomain.com' in user.email else raise_error('Not authorized') }}"
```

---

## Advanced Configuration

### Multiple OIDC Providers

You can configure multiple SSO providers:

```yaml
synapse:
  server:
    sso:
      enabled: true
      oidc:
        enabled: true
        providers:
          - idp_id: google
            idp_name: "Google"
            # ... Google config ...

          - idp_id: github
            idp_name: "GitHub"
            # ... GitHub config ...

          - idp_id: corporate
            idp_name: "Corporate SSO"
            # ... Corporate IdP config ...
```

### Custom User Mapping

Advanced Jinja2 templates for user mapping:

```yaml
user_mapping:
  # Extract first part of email before @
  localpart_template: "{{ user.email.split('@')[0] }}"

  # Combine first and last name
  display_name_template: "{{ user.given_name }} {{ user.family_name }}"

  # Use custom claim
  email_template: "{{ user.custom_email_claim }}"

  # Conditional mapping
  localpart_template: >-
    {% if user.email.endswith('@company.com') %}
      {{ user.email.split('@')[0] }}
    {% else %}
      external_{{ user.email.split('@')[0] }}
    {% endif %}
```

---

## References

- **Synapse OIDC Documentation**: https://element-hq.github.io/synapse/latest/openid.html
- **Synapse SAML Documentation**: https://element-hq.github.io/synapse/latest/saml.html
- **OAuth2 RFC**: https://oauth.net/2/
- **OpenID Connect Specification**: https://openid.net/connect/

---

## Support

For issues with SSO configuration:

1. Check Synapse logs: `kubectl logs deployment/matrix-synapse-synapse -n matrix`
2. Enable DEBUG logging in ConfigMap
3. Verify IdP configuration matches exactly
4. Test IdP endpoints manually with `curl`
5. Check Matrix community: #synapse:matrix.org
