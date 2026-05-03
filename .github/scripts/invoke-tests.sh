#!/usr/bin/env bash
# Usage: invoke-tests.sh <function-name> <service> <suite>
# Invokes the test-runner Lambda and fails if tests did not pass.
set -euo pipefail

FUNCTION=$1
SERVICE=$2
SUITE=$3

aws lambda invoke \
  --function-name "${FUNCTION}" \
  --payload "{\"service\":\"${SERVICE}\",\"suite\":\"${SUITE}\"}" \
  --cli-binary-format raw-in-base64-out \
  /tmp/lambda-result.json

echo "--- Lambda output (${SERVICE} / ${SUITE}) ---"
jq . /tmp/lambda-result.json

jq -e '.passed == true' /tmp/lambda-result.json
