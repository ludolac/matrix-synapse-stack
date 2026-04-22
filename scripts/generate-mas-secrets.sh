#!/bin/bash
# Generate cryptographic material required by Matrix Authentication Service (MAS)
# and create the Kubernetes Secret referenced by mas.existingSecret.
#
# Usage:
#   ./scripts/generate-mas-secrets.sh [--namespace matrix] [--name matrix-synapse-mas-secrets] \
#                                     [--authelia-secret <existing-authelia-client-secret>]
#
# Generated keys:
#   - ENCRYPTION_KEY              : hex32, encrypts OAuth tokens at rest
#   - SIGNING_KEY_RSA             : RSA 2048 private key (PEM), signs JWTs
#   - SYNAPSE_CLIENT_SECRET       : hex32, client_secret for MSC3861 OAuth2 client
#   - SYNAPSE_SHARED_SECRET       : hex32, admin_token between MAS and Synapse
#   - UPSTREAM_AUTHELIA_CLIENT_SECRET : Authelia client_secret (prompted if not given)
#
# Any value can be overridden via env:
#   ENCRYPTION_KEY=... SIGNING_KEY_RSA="$(cat key.pem)" ./scripts/generate-mas-secrets.sh

set -euo pipefail

NAMESPACE="matrix"
SECRET_NAME="matrix-synapse-mas-secrets"
AUTHELIA_SECRET=""
AUTHELIA_SECRET_KEY="authelia-client-secret"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace) NAMESPACE="$2"; shift 2 ;;
    --name)      SECRET_NAME="$2"; shift 2 ;;
    --authelia-secret) AUTHELIA_SECRET="$2"; shift 2 ;;
    --authelia-secret-key) AUTHELIA_SECRET_KEY="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | head -25
      exit 0 ;;
    *)  echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

command -v kubectl >/dev/null || { echo "kubectl required" >&2; exit 1; }
command -v openssl >/dev/null || { echo "openssl required" >&2; exit 1; }

# Values (allow env overrides for idempotency)
ENCRYPTION_KEY="${ENCRYPTION_KEY:-$(openssl rand -hex 32)}"
SIGNING_KEY_RSA="${SIGNING_KEY_RSA:-$(openssl genrsa 2048 2>/dev/null)}"
SYNAPSE_CLIENT_SECRET="${SYNAPSE_CLIENT_SECRET:-$(openssl rand -hex 32)}"
SYNAPSE_SHARED_SECRET="${SYNAPSE_SHARED_SECRET:-$(openssl rand -hex 32)}"

# Upstream Authelia client_secret: prompt or reuse an existing Kubernetes secret
UPSTREAM_SECRET=""
if [[ -n "${UPSTREAM_AUTHELIA_CLIENT_SECRET:-}" ]]; then
  UPSTREAM_SECRET="$UPSTREAM_AUTHELIA_CLIENT_SECRET"
elif [[ -n "$AUTHELIA_SECRET" ]]; then
  echo "Pulling Authelia client_secret from secret/$AUTHELIA_SECRET in $NAMESPACE..."
  UPSTREAM_SECRET="$(kubectl -n "$NAMESPACE" get secret "$AUTHELIA_SECRET" \
    -o jsonpath="{.data.$AUTHELIA_SECRET_KEY}" | base64 -d)"
  if [[ -z "$UPSTREAM_SECRET" ]]; then
    echo "ERROR: could not read $AUTHELIA_SECRET_KEY from secret/$AUTHELIA_SECRET" >&2
    exit 1
  fi
else
  read -rsp "Authelia client_secret for MAS upstream (input hidden): " UPSTREAM_SECRET
  echo
  [[ -z "$UPSTREAM_SECRET" ]] && { echo "empty secret, aborting" >&2; exit 1; }
fi

echo "Creating Kubernetes secret $SECRET_NAME in namespace $NAMESPACE..."
kubectl -n "$NAMESPACE" create secret generic "$SECRET_NAME" \
  --from-literal=ENCRYPTION_KEY="$ENCRYPTION_KEY" \
  --from-literal=SIGNING_KEY_RSA="$SIGNING_KEY_RSA" \
  --from-literal=SYNAPSE_CLIENT_SECRET="$SYNAPSE_CLIENT_SECRET" \
  --from-literal=SYNAPSE_SHARED_SECRET="$SYNAPSE_SHARED_SECRET" \
  --from-literal=UPSTREAM_AUTHELIA_CLIENT_SECRET="$UPSTREAM_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF

Done. Reference it in your values with:

  mas:
    enabled: true
    existingSecret: $SECRET_NAME

Rotation: re-run this script with one or more values overridden via env, e.g.
  SYNAPSE_CLIENT_SECRET=\$(openssl rand -hex 32) ./scripts/generate-mas-secrets.sh
Rotating ENCRYPTION_KEY invalidates all existing MAS-issued sessions.
EOF
