#!/usr/bin/env bash
# Refresh the ESO AWS credentials secret when Voclabs creds expire (~4 hours).
# Run this whenever ESO starts reporting "NoCredentialProviders" errors.
# Usage: ./update-eso-creds.sh
#
# Requires AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN to be
# exported in the current shell (copy from Voclabs AWS Details panel).

set -euo pipefail

: "${AWS_ACCESS_KEY_ID:?Export Voclabs credentials first}"
: "${AWS_SECRET_ACCESS_KEY:?Export Voclabs credentials first}"
: "${AWS_SESSION_TOKEN:?Export Voclabs credentials first}"

kubectl create secret generic aws-credentials \
  -n external-secrets \
  --from-literal=access-key-id="${AWS_ACCESS_KEY_ID}" \
  --from-literal=secret-access-key="${AWS_SECRET_ACCESS_KEY}" \
  --from-literal=session-token="${AWS_SESSION_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "aws-credentials secret updated."
echo "ESO will pick up the new credentials within ~15 seconds."
