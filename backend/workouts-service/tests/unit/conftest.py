import os

os.environ["DATABASE_URL"] = "sqlite+pysqlite:///:memory:"
os.environ["JWT_SECRET"] = "test-secret"
os.environ["SQS_QUEUE_URL"] = "http://dummy/queue"

import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import shared.database.base as _db
from shared.database.base import Base

_db.engine = create_engine(
    "sqlite+pysqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
_db.SessionLocal = sessionmaker(bind=_db.engine)

import app.models.workout  # noqa

Base.metadata.create_all(bind=_db.engine)

from app.main import app  # noqa
from shared.auth.jwt import create_access_token


@pytest.fixture(scope="module")
def token():
    return create_access_token("00000000-0000-0000-0000-000000000001")


@pytest.fixture(scope="module")
def client():
    # Patch SQS publish so tests never attempt a network call
    with patch("app.routes.workouts.publish_workout_logged"):
        with TestClient(app) as c:
            yield c
