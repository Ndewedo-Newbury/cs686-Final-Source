#!/usr/bin/env bash
# Usage: update-helm-tag.sh <values-file> <tag> <commit-message>
# Replaces the `tag:` line in the given Helm values file and commits + pushes.
# If AWS_ACCOUNT_ID is set, also resolves <ACCOUNT_ID> placeholders (idempotent).
set -euo pipefail

VALUES_FILE=$1
TAG=$2
COMMIT_MSG=$3

if [[ -n "${AWS_ACCOUNT_ID:-}" ]]; then
  sed -i "s|<ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g" "${VALUES_FILE}"
fi

if [[ -n "${AWS_REGION:-}" ]]; then
  sed -i "s|dkr\.ecr\.[a-z0-9-]*\.amazonaws\.com|dkr.ecr.${AWS_REGION}.amazonaws.com|g" "${VALUES_FILE}"
fi

sed -i "s|tag: .*|tag: ${TAG}|g" "${VALUES_FILE}"

git config user.name  "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add "${VALUES_FILE}"
git diff --staged --quiet || git commit -m "${COMMIT_MSG}"
git push
