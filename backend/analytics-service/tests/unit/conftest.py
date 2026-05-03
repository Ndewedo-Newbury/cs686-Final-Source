import os

os.environ["DATABASE_URL"] = "sqlite+pysqlite:///:memory:"
os.environ["JWT_SECRET"] = "test-secret"
os.environ["SQS_QUEUE_URL"] = "http://dummy/queue"

import asyncio
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

import app.models.stats  # noqa

Base.metadata.create_all(bind=_db.engine)

from app.main import app  # noqa
from shared.auth.jwt import create_access_token


async def _noop_consume():
    # Replaces the real SQS polling loop so TestClient startup doesn't hang
    await asyncio.sleep(0)


@pytest.fixture(scope="module")
def token():
    return create_access_token("00000000-0000-0000-0000-000000000002")


@pytest.fixture(scope="module")
def client():
    with patch("app.main.consume", _noop_consume):
        with TestClient(app) as c:
            yield c
