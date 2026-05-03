"""
Unit tests for analytics-service.
Stats are only created by the SQS consumer, so most tests verify the 404
path (no stats yet). The consumer itself is covered by integration tests.
"""

STATS_URL = "/api/v1/analytics/stats"


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def test_health(client, token):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_stats_returns_404_when_no_workouts_logged(client, token):
    # Fresh user has no stats record — consumer has never processed an event
    r = client.get(STATS_URL, headers=_auth(token))
    assert r.status_code == 404


def test_stats_unauthenticated_request_rejected(client, token):
    r = client.get(STATS_URL)
    assert r.status_code == 403
