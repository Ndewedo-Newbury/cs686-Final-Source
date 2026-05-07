import json
import os
import subprocess
import sys

import boto3


def _get_secret(client, name: str) -> dict:
    response = client.get_secret_value(SecretId=name)
    return json.loads(response["SecretString"])


def handler(event, context):
    """
    Payload schema:
      {
        "service": "auth-service" | "workouts-service" | "analytics-service",
        "suite":   "integration" | "e2e" | "smoke"
      }

    For e2e/smoke suites the tests make HTTP calls to the live API Gateway —
    the URL is read from the API_URL environment variable set per Lambda.
    For integration suites the tests connect directly to RDS via DATABASE_URL,
    which this handler fetches from Secrets Manager at runtime.
    """
    service = event["service"]
    suite   = event["suite"]
    env     = os.environ["ENVIRONMENT"]
    project = os.environ["PROJECT"]
    region  = os.environ.get("AWS_REGION_NAME", "us-east-1")

    sm = boto3.client("secretsmanager", region_name=region)
    test_env = os.environ.copy()

    if suite == "integration":
        db_secret_paths = {
            "auth-service":      f"{project}/{env}/auth/db",
            "workouts-service":  f"{project}/{env}/workouts/db",
            "analytics-service": f"{project}/{env}/analytics/db",
        }
        db = _get_secret(sm, db_secret_paths[service])
        test_env["DATABASE_URL"] = (
            f"postgresql://{db['username']}:{db['password']}"
            f"@{db['host']}:{db['port']}/{db['dbname']}"
        )

        jwt = _get_secret(sm, f"{project}/{env}/auth/jwt")
        test_env["JWT_SECRET_KEY"] = jwt["secret_key"]

        if service in ("workouts-service", "analytics-service"):
            sqs = _get_secret(sm, f"{project}/{env}/workouts/sqs")
            test_env["SQS_QUEUE_URL"] = sqs["queue_url"]

    result = subprocess.run(
        [sys.executable, "-m", "pytest",
         f"backend/{service}/tests/{suite}",
         "-v", "--tb=short", "--no-header"],
        capture_output=True,
        text=True,
        cwd="/app",
        env=test_env,
    )

    # Trim output to stay within Lambda 6 MB response limit
    return {
        "passed":     result.returncode == 0,
        "returncode": result.returncode,
        "stdout":     result.stdout[-8000:],
        "stderr":     result.stderr[-2000:],
    }
