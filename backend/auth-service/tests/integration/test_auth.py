"""
Integration tests for auth-service.
Run by Lambda inside the VPC against the real RDS instance.
Each test uses a unique email so runs are idempotent.
"""
import uuid

REGISTER_URL = "/api/v1/auth/register"
LOGIN_URL    = "/api/v1/auth/login"
ME_URL       = "/api/v1/auth/me"


def _unique_email():
    return f"integ-{uuid.uuid4().hex[:8]}@test.com"


def test_health(client):
    r = client.get("/api/v1/auth/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_register_and_login_round_trip(client):
    email = _unique_email()
    password = "IntegPass1!"

    r = client.post(REGISTER_URL, json={"email": email, "password": password})
    assert r.status_code == 201
    token = r.json()["access_token"]
    assert token

    r = client.post(LOGIN_URL, json={"email": email, "password": password})
    assert r.status_code == 200
    assert "access_token" in r.json()


def test_registered_user_can_call_me(client):
    email = _unique_email()
    r = client.post(REGISTER_URL, json={"email": email, "password": "IntegPass1!"})
    token = r.json()["access_token"]

    r = client.get(ME_URL, headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert "user_id" in r.json()


def test_duplicate_registration_rejected(client):
    email = _unique_email()
    client.post(REGISTER_URL, json={"email": email, "password": "IntegPass1!"})
    r = client.post(REGISTER_URL, json={"email": email, "password": "IntegPass1!"})
    assert r.status_code == 400
