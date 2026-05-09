"""
E2E conftest — makes real HTTP calls to the deployed API Gateway.
Registers a fresh user for the test session and yields an auth token.
"""
import os
import uuid

import pytest
import requests


@pytest.fixture(scope="module")
def api_url():
    return os.environ["API_URL"].rstrip("/")


@pytest.fixture(scope="module")
def token(api_url):
    email = f"e2e-wk-{uuid.uuid4().hex[:8]}@test.com"
    r = requests.post(f"{api_url}/api/v1/auth/register", json={"email": email, "password": "E2ePass1!"})
    assert r.status_code == 201, r.text
    return r.json()["access_token"]
