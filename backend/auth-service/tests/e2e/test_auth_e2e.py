"""
E2E tests for auth-service — calls the live API Gateway over HTTPS.
"""
import uuid

import requests


def test_health(api_url):
    r = requests.get(f"{api_url}/api/v1/auth/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_register_returns_token(api_url):
    email = f"e2e-{uuid.uuid4().hex[:8]}@test.com"
    r = requests.post(f"{api_url}/api/v1/auth/register", json={"email": email, "password": "E2ePass1!"})
    assert r.status_code == 201
    assert "access_token" in r.json()


def test_login_returns_token(registered_user, api_url):
    r = requests.post(
        f"{api_url}/api/v1/auth/login",
        json={"email": registered_user["email"], "password": registered_user["password"]},
    )
    assert r.status_code == 200
    assert "access_token" in r.json()


def test_me_with_valid_token(registered_user, api_url):
    r = requests.get(
        f"{api_url}/api/v1/auth/me",
        headers={"Authorization": f"Bearer {registered_user['token']}"},
    )
    assert r.status_code == 200
    assert "user_id" in r.json()


def test_me_without_token_rejected(api_url):
    r = requests.get(f"{api_url}/api/v1/auth/me")
    assert r.status_code in (401, 403)


def test_duplicate_registration_rejected(api_url):
    email = f"e2e-dup-{uuid.uuid4().hex[:8]}@test.com"
    requests.post(f"{api_url}/api/v1/auth/register", json={"email": email, "password": "E2ePass1!"})
    r = requests.post(f"{api_url}/api/v1/auth/register", json={"email": email, "password": "E2ePass1!"})
    assert r.status_code == 400
