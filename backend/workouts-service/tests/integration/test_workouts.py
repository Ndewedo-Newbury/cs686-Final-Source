"""
Integration tests for workouts-service.
Run by Lambda inside the VPC against the real RDS instance.
SQS publish is still mocked — SQS delivery is tested separately in E2E.
"""

WORKOUTS_URL = "/api/v1/workouts/"

_SAMPLE_WORKOUT = {
    "name": "Integration Push Day",
    "exercises": [
        {"name": "Bench Press", "sets": 4, "reps": 8, "weight_kg": 70.0},
    ],
}


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def test_health(client, token):
    r = client.get("/api/v1/workouts/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_workout_persisted_to_rds(client, token):
    r = client.post(WORKOUTS_URL, json=_SAMPLE_WORKOUT, headers=_auth(token))
    assert r.status_code == 201
    workout_id = r.json()["id"]

    # Fetch by ID to confirm it was actually written to RDS
    r = client.get(f"{WORKOUTS_URL}{workout_id}", headers=_auth(token))
    assert r.status_code == 200
    assert r.json()["name"] == "Integration Push Day"


def test_workout_appears_in_list(client, token):
    client.post(WORKOUTS_URL, json=_SAMPLE_WORKOUT, headers=_auth(token))
    r = client.get(WORKOUTS_URL, headers=_auth(token))
    assert r.status_code == 200
    assert len(r.json()) >= 1


def test_delete_removes_from_rds(client, token):
    r = client.post(WORKOUTS_URL, json=_SAMPLE_WORKOUT, headers=_auth(token))
    workout_id = r.json()["id"]
    client.delete(f"{WORKOUTS_URL}{workout_id}", headers=_auth(token))

    r = client.get(f"{WORKOUTS_URL}{workout_id}", headers=_auth(token))
    assert r.status_code == 404
