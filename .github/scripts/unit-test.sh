#!/usr/bin/env bash
# Usage: unit-test.sh <service>
set -euo pipefail

SERVICE=$1

pip install -r "backend/${SERVICE}/requirements.txt" pytest pytest-asyncio httpx

cd "backend/${SERVICE}"
PYTHONPATH=.. \
DATABASE_URL="sqlite+pysqlite:///:memory:" \
JWT_SECRET="test-secret" \
SQS_QUEUE_URL="http://dummy/queue" \
  pytest tests/unit -v
