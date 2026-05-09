"""
E2E conftest — makes real HTTP calls to the deployed API Gateway.
API_URL env var is injected by the Lambda (e.g. https://dev-api.cs686.live).
"""
import os
import uuid

import pytest
import requests


@pytest.fixture(scope="module")
def api_url():
    url = os.environ["API_URL"].rstrip("/")
    return url


@pytest.fixture(scope="module")
def registered_user(api_url):
    email = f"e2e-{uuid.uuid4().hex[:8]}@test.com"
    password = "E2ePass1!"
    r = requests.post(f"{api_url}/api/v1/auth/register", json={"email": email, "password": password})
    assert r.status_code == 201, r.text
    return {"email": email, "password": password, "token": r.json()["access_token"]}
