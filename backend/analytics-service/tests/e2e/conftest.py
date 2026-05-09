"""
E2E conftest — makes real HTTP calls to the deployed API Gateway.
Registers a fresh user and logs a workout to seed analytics via SQS.
"""
import os
import time
import uuid

import pytest
import requests


@pytest.fixture(scope="module")
def api_url():
    return os.environ["API_URL"].rstrip("/")


@pytest.fixture(scope="module")
def token(api_url):
    email = f"e2e-an-{uuid.uuid4().hex[:8]}@test.com"
    r = requests.post(f"{api_url}/api/v1/auth/register", json={"email": email, "password": "E2ePass1!"})
    assert r.status_code == 201, r.text
    tok = r.json()["access_token"]

    # Log one workout so the SQS consumer can write a stats row
    r = requests.post(
        f"{api_url}/api/v1/workouts/",
        json={"name": "E2E Seed", "exercises": [{"name": "Squat", "sets": 3, "reps": 5, "weight_kg": 80.0}]},
        headers={"Authorization": f"Bearer {tok}"},
    )
    assert r.status_code == 201, r.text

    # Give SQS consumer time to process the event
    time.sleep(10)
    return tok
