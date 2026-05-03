"""
Lambda handler for running Alembic migrations.
Invoked by promote.yml before every prod deploy.

Payload: {"service": "auth-service" | "workouts-service" | "analytics-service"}
Returns: {"success": true, "output": "..."}
"""
import json
import os
import subprocess
import sys

import boto3


def handler(event, context):
    service = event["service"]
    env     = os.environ["ENVIRONMENT"]
    project = os.environ["PROJECT"]
    region  = os.environ.get("AWS_REGION_NAME", "us-east-1")

    sm = boto3.client("secretsmanager", region_name=region)

    db_secret_paths = {
        "auth-service":      f"{project}/{env}/auth/db",
        "workouts-service":  f"{project}/{env}/workouts/db",
        "analytics-service": f"{project}/{env}/analytics/db",
    }
    db = json.loads(
        sm.get_secret_value(SecretId=db_secret_paths[service])["SecretString"]
    )
    database_url = (
        f"postgresql://{db['username']}:{db['password']}"
        f"@{db['host']}:{db['port']}/{db['dbname']}"
    )

    result = subprocess.run(
        ["alembic", "upgrade", "head"],
        capture_output=True,
        text=True,
        cwd=f"/app/backend/{service}",
        env={**os.environ, "DATABASE_URL": database_url},
    )

    return {
        "success": result.returncode == 0,
        "output":  result.stdout[-4000:] + result.stderr[-2000:],
    }
