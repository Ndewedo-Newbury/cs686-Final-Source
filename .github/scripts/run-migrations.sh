#!/usr/bin/env bash
# Usage: run-migrations.sh <lambda-function-name>
# Invokes the migrate Lambda for each backend service and fails on any error.
set -euo pipefail

FUNCTION=$1

for svc in auth-service workouts-service analytics-service; do
  aws lambda invoke \
    --function-name "${FUNCTION}" \
    --payload "{\"service\":\"${svc}\"}" \
    --cli-binary-format raw-in-base64-out \
    "/tmp/migrate-${svc}.json"

  echo "--- ${svc} migration result ---"
  jq . "/tmp/migrate-${svc}.json"

  jq -e '.success == true' "/tmp/migrate-${svc}.json"
done
