# Matrix Synapse + Authelia SSO Setup Guide

This guide explains how to configure Matrix Synapse to use your existing Authelia deployment for Single Sign-On (SSO).

## Prerequisites

✅ Authelia deployed in `authentif` namespace
✅ Authelia accessible at `https://authelia.waadoo.ovh`
✅ LLDAP backend configured
✅ Matrix Synapse deployed in `matrix` namespace

---

## Step 1: Generate Client Secret

Generate a secure random secret for the Matrix OIDC client:

```bash
# Generate a random secret
openssl rand -hex 32

# Example output:
# a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef12345
```

**Save this secret** - you'll need it for both Authelia and Matrix configuration.

---

## Step 2: Configure Authelia

You need to add Matrix as an OIDC client in your Authelia configuration.

### Option A: Using Authelia ConfigMap (if using ConfigMap)

```bash
# Edit Authelia ConfigMap
kubectl edit configmap authelia -n authentif
```

Add this to the `identity_providers.oidc.clients` section:

```yaml
identity_providers:
  oidc:
    ## Existing configuration...

    clients:
      ## Your existing clients...

      ## Add Matrix Synapse client
      - id: matrix
        description: Matrix Synapse Homeserver
        secret: '$pbkdf2-sha512$310000$YOUR_HASHED_SECRET'  # See below for hashing
        public: false
        authorization_policy: two_factor  # or 'one_factor' if you don't want 2FA
        redirect_uris:
          - https://matrix.waadoo.ovh/_synapse/client/oidc/callback
        scopes:
          - openid
          - profile
          - email
          - groups
        userinfo_signing_algorithm: none
        token_endpoint_auth_method: client_secret_post
```

### Hash the Client Secret

Authelia requires the client secret to be hashed. Use this command:

```bash
# Get Authelia pod name
AUTHELIA_POD=$(kubectl get pod -n authentif -l app.kubernetes.io/name=authelia -o jsonpath='{.items[0].metadata.name}')

# Hash your secret (replace YOUR_SECRET_HERE)
kubectl exec -it $AUTHELIA_POD -n authentif -- \
  authelia crypto hash generate pbkdf2 --password 'YOUR_SECRET_HERE'

# Example output:
# Digest: $pbkdf2-sha512$310000$c8p38D...
```

**Copy the entire digest** (starting with `$pbkdf2-sha512$...`) and use it as the `secret` value in Authelia config.

### Option B: Using Authelia Helm Chart

If you're using Authelia Helm chart, add to your `values.yaml`:

```yaml
configMap:
  identity_providers:
    oidc:
      clients:
        - id: matrix
          description: Matrix Synapse Homeserver
          secret: '$pbkdf2-sha512$310000$YOUR_HASHED_SECRET'
          public: false
          authorization_policy: two_factor
          redirect_uris:
            - https://matrix.waadoo.ovh/_synapse/client/oidc/callback
          scopes:
            - openid
            - profile
            - email
            - groups
          userinfo_signing_algorithm: none
          token_endpoint_auth_method: client_secret_post
```

Then upgrade Authelia:

```bash
helm upgrade authelia authelia/authelia -n authentif --values authelia-values.yaml
```

---

## Step 3: Restart Authelia

After updating the configuration:

```bash
# Restart Authelia to apply new client
kubectl rollout restart deployment/authelia -n authentif

# Wait for rollout
kubectl rollout status deployment/authelia -n authentif

# Verify Authelia is running
kubectl get pods -n authentif -l app.kubernetes.io/name=authelia
```

---

## Step 4: Update Matrix Synapse Configuration

The Matrix configuration is already added in `values-prod.yaml`. Update the client secret:

```yaml
synapse:
  server:
    sso:
      enabled: true
      oidc:
        enabled: true
        providers:
          - idp_id: authelia
            idp_name: "Waadoo SSO"
            discover: true
            issuer: "https://authelia.waadoo.ovh"
            client_id: "matrix"
            client_secret: "YOUR_PLAIN_SECRET_HERE"  # The SAME secret you generated
            scopes: ["openid", "profile", "email", "groups"]
            user_mapping:
              localpart_template: "{{ user.preferred_username }}"
              display_name_template: "{{ user.name }}"
              email_template: "{{ user.email }}"
            allow_existing_users: true
```

**Important:** In Matrix configuration, use the **plain text secret** (NOT the hashed version).

---

## Step 5: Apply Matrix Configuration

```bash
# Navigate to chart directory
cd /Users/ludo/CODE/OVH/k8s-infra/samples/matrix-synapse-chart

# Upgrade Matrix with SSO enabled
helm upgrade matrix-synapse . \
  --namespace matrix \
  --values values-prod.yaml

# Wait for Matrix to restart
kubectl rollout status deployment/matrix-synapse-synapse -n matrix
```

---

## Step 6: Test SSO Login

### 1. Verify OIDC Discovery

```bash
# Test Authelia OIDC discovery endpoint
curl -s https://authelia.waadoo.ovh/.well-known/openid-configuration | jq .

# Should return JSON with endpoints like:
# {
#   "issuer": "https://authelia.waadoo.ovh",
#   "authorization_endpoint": "https://authelia.waadoo.ovh/api/oidc/authorization",
#   "token_endpoint": "https://authelia.waadoo.ovh/api/oidc/token",
#   ...
# }
```

### 2. Check Matrix OIDC Providers

```bash
# Check Matrix recognizes the provider
curl -s https://matrix.waadoo.ovh/_synapse/client/oidc/providers | jq .

# Should return something like:
# [
#   {
#     "id": "authelia",
#     "name": "Waadoo SSO"
#   }
# ]
```

### 3. Test Login via Element Web

1. **Open Element Web**: https://element.waadoo.ovh
2. **Click "Sign In"**
3. **Click "Sign in with SSO"** or **"Continue with Waadoo SSO"**
4. **You'll be redirected to Authelia**
5. **Login with your LLDAP credentials**
6. **Complete 2FA if enabled**
7. **You'll be redirected back to Element and logged in**

---

## Troubleshooting

### "Invalid redirect URI"

**Problem:** Authelia rejects the redirect.

**Solution:** Ensure the redirect URI in Authelia config exactly matches:
```
https://matrix.waadoo.ovh/_synapse/client/oidc/callback
```

**Check:**
```bash
# View current Authelia config
kubectl get configmap authelia -n authentif -o yaml | grep -A 5 "redirect_uris"
```

### "Client authentication failed"

**Problem:** Client secret mismatch.

**Solution:** Verify the secrets match:
- Authelia: Uses hashed version (`$pbkdf2-sha512$...`)
- Matrix: Uses plain text version

**Test:**
```bash
# Get the plain secret from Matrix config
kubectl get configmap matrix-synapse-synapse-config -n matrix -o yaml | grep client_secret

# Hash it and compare with Authelia
```

### "Discovery failed"

**Problem:** Matrix can't reach Authelia's discovery endpoint.

**Solution 1:** Check network connectivity:
```bash
# From Matrix pod
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  curl -v https://authelia.waadoo.ovh/.well-known/openid-configuration
```

**Solution 2:** Check Authelia ingress:
```bash
kubectl get ingress authelia -n authentif
```

### "User not found" or "Invalid username"

**Problem:** User mapping template doesn't match LLDAP attributes.

**Solution:** Check what attributes Authelia sends:

1. Enable debug logging in Matrix:
```bash
kubectl edit configmap matrix-synapse-synapse-config -n matrix
# Set: level: DEBUG

kubectl rollout restart deployment/matrix-synapse-synapse -n matrix
```

2. Attempt SSO login

3. Check Matrix logs for user claims:
```bash
kubectl logs deployment/matrix-synapse-synapse -n matrix | grep -i "oidc.*claims"
```

4. Adjust user mapping template based on actual claims

Common LLDAP attributes:
- Username: `preferred_username` or `sub`
- Display name: `name`
- Email: `email`

### SSO button doesn't appear in Element

**Problem:** Element Web doesn't show SSO option.

**Solution:** Check Element config includes SSO:

```bash
# Check Element config
kubectl get configmap matrix-synapse-element-config -n matrix -o yaml

# Ensure it references Matrix homeserver correctly
```

### "Two-factor required"

**Problem:** Authelia requires 2FA but user hasn't set it up.

**Solution:** Either:
1. Set up 2FA for the user in Authelia
2. Change authorization policy to `one_factor` in Authelia client config

```yaml
authorization_policy: one_factor  # Instead of two_factor
```

---

## Advanced Configuration

### Restrict SSO to Specific Groups

In Authelia, you can restrict Matrix access to specific groups:

```yaml
clients:
  - id: matrix
    # ...
    authorization_policy: matrix_users  # Custom policy name
```

Then define the policy in `access_control`:

```yaml
access_control:
  default_policy: deny

  rules:
    - domain: matrix.waadoo.ovh
      policy: two_factor
      subject:
        - "group:matrix_users"  # Only users in this LLDAP group
```

### Custom User Mapping

If your LLDAP has different attributes:

```yaml
# In values-prod.yaml
user_mapping:
  # Use 'uid' instead of 'preferred_username'
  localpart_template: "{{ user.uid }}"

  # Combine first and last name
  display_name_template: "{{ user.given_name }} {{ user.family_name }}"

  # Use custom email attribute
  email_template: "{{ user.mail }}"
```

### Allow Existing Users

To let SSO users link to existing Matrix accounts (created with password):

```yaml
allow_existing_users: true
```

**How it works:**
1. User logs in with SSO
2. If a Matrix user with same localpart exists, they're asked to confirm
3. After confirmation, SSO identity is linked to existing account

---

## Security Recommendations

### 1. Use Strong Client Secret

```bash
# Generate strong secret (32 bytes = 64 hex chars)
openssl rand -hex 32
```

### 2. Enable 2FA in Authelia

Set in client config:
```yaml
authorization_policy: two_factor
```

### 3. Restrict by Groups

Only allow specific LLDAP groups to access Matrix:

```yaml
# In Authelia access control
- domain: matrix.waadoo.ovh
  policy: two_factor
  subject:
    - "group:employees"
    - "group:matrix_users"
```

### 4. Monitor SSO Logins

```bash
# Watch Authelia logs for Matrix logins
kubectl logs -f deployment/authelia -n authentif | grep matrix

# Watch Matrix logs for SSO
kubectl logs -f deployment/matrix-synapse-synapse -n matrix | grep -i oidc
```

---

## Complete Configuration Example

### Authelia Configuration (snippet)

```yaml
identity_providers:
  oidc:
    hmac_secret: YOUR_HMAC_SECRET
    issuer_private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      YOUR_PRIVATE_KEY
      -----END RSA PRIVATE KEY-----

    clients:
      - id: matrix
        description: Matrix Synapse Homeserver
        secret: '$pbkdf2-sha512$310000$hashed_secret_here'
        public: false
        authorization_policy: two_factor
        redirect_uris:
          - https://matrix.waadoo.ovh/_synapse/client/oidc/callback
        scopes:
          - openid
          - profile
          - email
          - groups
        userinfo_signing_algorithm: none
        token_endpoint_auth_method: client_secret_post

access_control:
  default_policy: deny
  rules:
    - domain: matrix.waadoo.ovh
      policy: two_factor
      subject:
        - "group:matrix_users"
```

### Matrix Configuration (values-prod.yaml)

```yaml
synapse:
  server:
    sso:
      enabled: true
      oidc:
        enabled: true
        providers:
          - idp_id: authelia
            idp_name: "Waadoo SSO"
            idp_icon: "mxc://waadoo.ovh/authelia"
            discover: true
            issuer: "https://authelia.waadoo.ovh"
            client_id: "matrix"
            client_secret: "your_plain_secret_here"
            scopes: ["openid", "profile", "email", "groups"]
            user_mapping:
              localpart_template: "{{ user.preferred_username }}"
              display_name_template: "{{ user.name }}"
              email_template: "{{ user.email }}"
            allow_existing_users: true
```

---

## Quick Setup Checklist

- [ ] Generate client secret: `openssl rand -hex 32`
- [ ] Hash secret for Authelia: `authelia crypto hash generate pbkdf2`
- [ ] Add Matrix client to Authelia config
- [ ] Restart Authelia: `kubectl rollout restart deployment/authelia -n authentif`
- [ ] Update `values-prod.yaml` with SSO config (plain secret)
- [ ] Upgrade Matrix: `helm upgrade matrix-synapse . -n matrix --values values-prod.yaml`
- [ ] Test OIDC discovery: `curl https://authelia.waadoo.ovh/.well-known/openid-configuration`
- [ ] Test login via Element Web: https://element.waadoo.ovh

---

## References

- **Authelia OIDC Documentation**: https://www.authelia.com/configuration/identity-providers/open-id-connect/
- **Matrix Synapse OIDC Documentation**: https://element-hq.github.io/synapse/latest/openid.html
- **Authelia + Matrix Example**: https://www.authelia.com/integration/openid-connect/matrix-synapse/

---

## Support

If you encounter issues:

1. **Check Authelia logs**: `kubectl logs deployment/authelia -n authentif`
2. **Check Matrix logs**: `kubectl logs deployment/matrix-synapse-synapse -n matrix`
3. **Verify discovery**: `curl https://authelia.waadoo.ovh/.well-known/openid-configuration`
4. **Test connectivity**: From Matrix pod to Authelia service
