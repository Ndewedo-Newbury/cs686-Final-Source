"""
E2E tests for workouts-service — calls the live API Gateway over HTTPS.
"""
import requests

WORKOUTS_URL = "/api/v1/workouts/"

_SAMPLE = {
    "name": "E2E Push Day",
    "exercises": [{"name": "Bench Press", "sets": 3, "reps": 10, "weight_kg": 60.0}],
}


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def test_health(api_url):
    r = requests.get(f"{api_url}/api/v1/workouts/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_create_workout(api_url, token):
    r = requests.post(f"{api_url}{WORKOUTS_URL}", json=_SAMPLE, headers=_auth(token))
    assert r.status_code == 201
    assert "id" in r.json()


def test_get_workout_by_id(api_url, token):
    r = requests.post(f"{api_url}{WORKOUTS_URL}", json=_SAMPLE, headers=_auth(token))
    workout_id = r.json()["id"]

    r = requests.get(f"{api_url}{WORKOUTS_URL}{workout_id}", headers=_auth(token))
    assert r.status_code == 200
    assert r.json()["name"] == _SAMPLE["name"]


def test_list_workouts(api_url, token):
    requests.post(f"{api_url}{WORKOUTS_URL}", json=_SAMPLE, headers=_auth(token))
    r = requests.get(f"{api_url}{WORKOUTS_URL}", headers=_auth(token))
    assert r.status_code == 200
    assert isinstance(r.json(), list)
    assert len(r.json()) >= 1


def test_delete_workout(api_url, token):
    r = requests.post(f"{api_url}{WORKOUTS_URL}", json=_SAMPLE, headers=_auth(token))
    workout_id = r.json()["id"]

    requests.delete(f"{api_url}{WORKOUTS_URL}{workout_id}", headers=_auth(token))
    r = requests.get(f"{api_url}{WORKOUTS_URL}{workout_id}", headers=_auth(token))
    assert r.status_code == 404


def test_unauthenticated_request_rejected(api_url):
    r = requests.get(f"{api_url}{WORKOUTS_URL}")
    assert r.status_code in (401, 403)
