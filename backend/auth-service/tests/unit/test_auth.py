"""
Unit tests for auth-service.
Run against an in-memory SQLite DB — no RDS or network required.
"""

REGISTER_URL = "/api/v1/auth/register"
LOGIN_URL    = "/api/v1/auth/login"
ME_URL       = "/api/v1/auth/me"


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_register_returns_token(client):
    r = client.post(REGISTER_URL, json={"email": "unit@test.com", "password": "Password1!"})
    assert r.status_code == 201
    assert "access_token" in r.json()


def test_register_duplicate_email_rejected(client):
    client.post(REGISTER_URL, json={"email": "dupe@test.com", "password": "Password1!"})
    r = client.post(REGISTER_URL, json={"email": "dupe@test.com", "password": "Password1!"})
    assert r.status_code == 400


def test_login_valid_credentials(client):
    client.post(REGISTER_URL, json={"email": "login@test.com", "password": "Password1!"})
    r = client.post(LOGIN_URL, json={"email": "login@test.com", "password": "Password1!"})
    assert r.status_code == 200
    assert "access_token" in r.json()


def test_login_wrong_password(client):
    client.post(REGISTER_URL, json={"email": "wrong@test.com", "password": "Password1!"})
    r = client.post(LOGIN_URL, json={"email": "wrong@test.com", "password": "wrongpassword"})
    assert r.status_code == 401


def test_me_with_valid_token(client):
    r = client.post(REGISTER_URL, json={"email": "me@test.com", "password": "Password1!"})
    token = r.json()["access_token"]
    r = client.get(ME_URL, headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert "user_id" in r.json()


def test_me_without_token(client):
    r = client.get(ME_URL)
    assert r.status_code == 403
