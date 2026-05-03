"""
Unit tests for workouts-service.
SQS publish is mocked — no AWS access required.
"""

WORKOUTS_URL = "/api/v1/workouts/"

_SAMPLE_WORKOUT = {
    "name": "Leg Day",
    "exercises": [
        {"name": "Squat", "sets": 3, "reps": 10, "weight_kg": 80.0},
        {"name": "Lunge", "sets": 3, "reps": 12, "weight_kg": None},
    ],
}


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def test_health(client, token):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_log_workout_returns_201(client, token):
    r = client.post(WORKOUTS_URL, json=_SAMPLE_WORKOUT, headers=_auth(token))
    assert r.status_code == 201
    body = r.json()
    assert body["name"] == "Leg Day"
    assert len(body["exercises"]) == 2
    assert "id" in body


def test_list_workouts_returns_logged_workout(client, token):
    client.post(WORKOUTS_URL, json=_SAMPLE_WORKOUT, headers=_auth(token))
    r = client.get(WORKOUTS_URL, headers=_auth(token))
    assert r.status_code == 200
    assert len(r.json()) >= 1


def test_get_workout_by_id(client, token):
    r = client.post(WORKOUTS_URL, json=_SAMPLE_WORKOUT, headers=_auth(token))
    workout_id = r.json()["id"]
    r = client.get(f"{WORKOUTS_URL}{workout_id}", headers=_auth(token))
    assert r.status_code == 200
    assert r.json()["id"] == workout_id


def test_delete_workout(client, token):
    r = client.post(WORKOUTS_URL, json=_SAMPLE_WORKOUT, headers=_auth(token))
    workout_id = r.json()["id"]
    r = client.delete(f"{WORKOUTS_URL}{workout_id}", headers=_auth(token))
    assert r.status_code == 204


def test_get_deleted_workout_returns_404(client, token):
    r = client.post(WORKOUTS_URL, json=_SAMPLE_WORKOUT, headers=_auth(token))
    workout_id = r.json()["id"]
    client.delete(f"{WORKOUTS_URL}{workout_id}", headers=_auth(token))
    r = client.get(f"{WORKOUTS_URL}{workout_id}", headers=_auth(token))
    assert r.status_code == 404


def test_unauthenticated_request_rejected(client, token):
    r = client.get(WORKOUTS_URL)
    assert r.status_code == 403
