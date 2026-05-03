#!/usr/bin/env bash
# One-time bootstrap — run this once before any other Terraform command.
# Creates the S3 state bucket and DynamoDB lock table used by all environments.
set -euo pipefail

BOOTSTRAP_DIR="$(cd "$(dirname "$0")/../DevOps/terraform/bootstrap" && pwd)"

echo "==> Initialising Terraform bootstrap..."
terraform -chdir="$BOOTSTRAP_DIR" init

echo "==> Applying bootstrap (S3 bucket + DynamoDB lock table)..."
terraform -chdir="$BOOTSTRAP_DIR" apply -auto-approve

echo ""
echo "Bootstrap complete. State bucket and lock table are ready."
echo "You can now run 'terraform init' inside any environment folder."
