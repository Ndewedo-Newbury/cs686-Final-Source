#!/usr/bin/env bash
# Usage: invoke-tests.sh <function-name> <service> <suite> [environment] [api_url]
# Optional env/api_url args override the Lambda's baked-in env vars (used when
# the dev Lambda runs smoke tests against a different environment, e.g. UAT).
# Invokes the test-runner Lambda and fails if tests did not pass.
set -euo pipefail

FUNCTION=$1
SERVICE=$2
SUITE=$3
ENVIRONMENT=${4:-}
API_URL=${5:-}

PAYLOAD="{\"service\":\"${SERVICE}\",\"suite\":\"${SUITE}\""
[[ -n "${ENVIRONMENT}" ]] && PAYLOAD+=",\"environment\":\"${ENVIRONMENT}\""
[[ -n "${API_URL}" ]]     && PAYLOAD+=",\"api_url\":\"${API_URL}\""
PAYLOAD+="}"

aws lambda invoke \
  --function-name "${FUNCTION}" \
  --payload "${PAYLOAD}" \
  --cli-binary-format raw-in-base64-out \
  /tmp/lambda-result.json

echo "--- Lambda output (${SERVICE} / ${SUITE}) ---"
jq . /tmp/lambda-result.json

jq -e '.passed == true' /tmp/lambda-result.json
