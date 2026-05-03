#!/usr/bin/env bash
# Builds and pushes all service images + the test-runner image to ECR.
# Reads ECR_REGISTRY and PROJECT from the environment (set by the workflow).
set -euo pipefail

SHA=$(git rev-parse --short HEAD)

for svc in auth-service workouts-service analytics-service; do
  REPO="${ECR_REGISTRY}/${PROJECT}/${svc}"
  docker build -t "${REPO}:sha-${SHA}" -t "${REPO}:dev-latest" "backend/${svc}/"
  docker push "${REPO}:sha-${SHA}"
  docker push "${REPO}:dev-latest"
done

REPO="${ECR_REGISTRY}/${PROJECT}/frontend"
docker build --target prod -t "${REPO}:sha-${SHA}" -t "${REPO}:dev-latest" frontend/
docker push "${REPO}:sha-${SHA}"
docker push "${REPO}:dev-latest"

# Test-runner + migrate Lambda share one image; built from repo root
# so the Dockerfile can COPY backend/ and shared/
REPO="${ECR_REGISTRY}/${PROJECT}/test-runner"
docker build -f tests/Dockerfile -t "${REPO}:sha-${SHA}" -t "${REPO}:latest" .
docker push "${REPO}:sha-${SHA}"
docker push "${REPO}:latest"
