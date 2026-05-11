#!/usr/bin/env bash
# Update the ESO AWS credentials secret.
# With permanent IAM credentials this only needs to be run once (or after
# rotating keys). No session token required.
# Usage: ./update-eso-creds.sh

set -euo pipefail

: "${AWS_ACCESS_KEY_ID:?Export AWS credentials first}"
: "${AWS_SECRET_ACCESS_KEY:?Export AWS credentials first}"

kubectl create secret generic aws-credentials \
  -n external-secrets \
  --from-literal=access-key-id="${AWS_ACCESS_KEY_ID}" \
  --from-literal=secret-access-key="${AWS_SECRET_ACCESS_KEY}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "aws-credentials secret updated."
echo "ESO will pick up the new credentials within ~15 seconds."
