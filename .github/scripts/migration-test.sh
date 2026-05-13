#!/usr/bin/env bash
# Usage: migration-test.sh <service>
# Runs migration tests for the given service against a local PostgreSQL instance.
# DATABASE_URL must be set, or PGHOST/PGUSER/PGPASSWORD will be used to build it.
set -euo pipefail

SERVICE=$1

declare -A DB_NAMES=(
    ["auth-service"]="auth_db_test"
    ["workouts-service"]="workouts_db_test"
    ["analytics-service"]="analytics_db_test"
)

DB_NAME="${DB_NAMES[$SERVICE]}"
PGHOST="${PGHOST:-localhost}"
PGUSER="${PGUSER:-postgres}"
PGPASSWORD="${PGPASSWORD:-postgres}"
PGPORT="${PGPORT:-5432}"

# Create the isolated test database (idempotent)
PGPASSWORD="${PGPASSWORD}" psql \
    -h "${PGHOST}" -U "${PGUSER}" -p "${PGPORT}" \
    -c "CREATE DATABASE ${DB_NAME};" 2>/dev/null || true

export DATABASE_URL="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${DB_NAME}"

pip install -q \
    -r "backend/${SERVICE}/requirements.txt" \
    pytest

cd "backend/${SERVICE}"
PYTHONPATH=.. pytest tests/migration -v --tb=short
