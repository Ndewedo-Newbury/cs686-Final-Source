"""
Smoke tests for workouts-service.
Verifies the service is reachable and protected endpoints reject unauthenticated requests.
No auth tokens required.
"""
import requests


def test_health(api_url):
    r = requests.get(f"{api_url}/api/v1/workouts/health", timeout=10)
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_list_workouts_requires_auth(api_url):
    r = requests.get(f"{api_url}/api/v1/workouts/", timeout=10)
    assert r.status_code in (401, 403)


def test_create_workout_requires_auth(api_url):
    r = requests.post(
        f"{api_url}/api/v1/workouts/",
        json={"name": "smoke", "exercises": []},
        timeout=10,
    )
    assert r.status_code in (401, 403)
