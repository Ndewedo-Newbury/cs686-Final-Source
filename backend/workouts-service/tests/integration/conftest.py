import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient
from shared.database.base import Base, engine
from shared.auth.jwt import create_access_token

Base.metadata.create_all(bind=engine)

from app.main import app  # noqa


@pytest.fixture(scope="module")
def token():
    return create_access_token("00000000-0000-0000-0000-000000000099")


@pytest.fixture(scope="module")
def client():
    with patch("app.routes.workouts.publish_workout_logged"):
        with TestClient(app) as c:
            yield c
