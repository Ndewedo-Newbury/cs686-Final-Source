#!/usr/bin/env bash
# Usage: retag-images.sh <source-tag> <target-tag> [<extra-tag> ...]
# Pulls source tag for every service and pushes under all target tags.
# Reads ECR_REGISTRY, PROJECT, and SERVICES from the environment.
set -euo pipefail

SOURCE=$1
shift
TARGETS=("$@")

for svc in ${SERVICES}; do
  REPO="${ECR_REGISTRY}/${PROJECT}/${svc}"
  docker pull "${REPO}:${SOURCE}"
  for tag in "${TARGETS[@]}"; do
    docker tag  "${REPO}:${SOURCE}" "${REPO}:${tag}"
    docker push "${REPO}:${tag}"
  done
done
