"""
Integration tests for analytics-service.
Run by Lambda inside the VPC against the real RDS instance.

Stats are written by the SQS consumer, not directly through the API.
These tests verify the service reads from RDS correctly by seeding
a stats row directly, then confirming the endpoint returns it.
"""
import uuid
from datetime import datetime, timezone
from shared.database.base import SessionLocal
from app.models.stats import UserStats

STATS_URL = "/api/v1/analytics/stats"

# Fixed user_id that matches the token fixture
_USER_ID = uuid.UUID("00000000-0000-0000-0000-000000000098")


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _seed_stats(total_workouts: int, streak: int):
    db = SessionLocal()
    try:
        existing = db.query(UserStats).filter(UserStats.user_id == _USER_ID).first()
        if existing:
            existing.total_workouts = total_workouts
            existing.current_streak = streak
        else:
            db.add(UserStats(
                id=uuid.uuid4(),
                user_id=_USER_ID,
                total_workouts=total_workouts,
                current_streak=streak,
                last_workout_at=datetime.now(timezone.utc),
            ))
        db.commit()
    finally:
        db.close()


def test_health(client, token):
    r = client.get("/api/v1/analytics/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_stats_returned_from_rds(client, token):
    _seed_stats(total_workouts=5, streak=3)
    r = client.get(STATS_URL, headers=_auth(token))
    assert r.status_code == 200
    body = r.json()
    assert body["total_workouts"] == 5
    assert body["current_streak"] == 3


def test_unauthenticated_request_rejected(client, token):
    r = client.get(STATS_URL)
    assert r.status_code == 403
