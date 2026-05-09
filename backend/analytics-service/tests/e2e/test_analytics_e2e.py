"""
E2E tests for analytics-service — calls the live API Gateway over HTTPS.
Stats are populated via SQS consumer after a workout is logged (conftest seeds this).
"""
import requests

STATS_URL = "/api/v1/analytics/stats"


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def test_health(api_url):
    r = requests.get(f"{api_url}/api/v1/analytics/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_stats_endpoint_returns_ok(api_url, token):
    r = requests.get(f"{api_url}{STATS_URL}", headers=_auth(token))
    assert r.status_code == 200
    body = r.json()
    assert "total_workouts" in body
    assert "current_streak" in body


def test_stats_reflect_seeded_workout(api_url, token):
    r = requests.get(f"{api_url}{STATS_URL}", headers=_auth(token))
    assert r.status_code == 200
    assert r.json()["total_workouts"] >= 1


def test_unauthenticated_request_rejected(api_url):
    r = requests.get(f"{api_url}{STATS_URL}")
    assert r.status_code in (401, 403)
