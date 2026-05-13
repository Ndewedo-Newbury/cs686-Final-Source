"""
Smoke tests for analytics-service.
Verifies the service is reachable and protected endpoints reject unauthenticated requests.
No auth tokens required.
"""
import requests


def test_health(api_url):
    r = requests.get(f"{api_url}/api/v1/analytics/health", timeout=10)
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_stats_requires_auth(api_url):
    r = requests.get(f"{api_url}/api/v1/analytics/stats", timeout=10)
    assert r.status_code in (401, 403)
