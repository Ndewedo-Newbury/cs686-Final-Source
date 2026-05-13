"""
Smoke tests for auth-service.
Verifies the service is reachable and its public endpoints respond correctly.
No user registration or auth tokens required.
"""
import requests


def test_health(api_url):
    r = requests.get(f"{api_url}/api/v1/auth/health", timeout=10)
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_login_rejects_bad_credentials(api_url):
    r = requests.post(
        f"{api_url}/api/v1/auth/login",
        json={"email": "nobody@smoke.test", "password": "InvalidPass1!"},
        timeout=10,
    )
    assert r.status_code == 401


def test_me_requires_auth(api_url):
    r = requests.get(f"{api_url}/api/v1/auth/me", timeout=10)
    assert r.status_code in (401, 403)
