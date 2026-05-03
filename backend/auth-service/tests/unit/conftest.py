import os

# Set env vars before any app import so shared/database/base.py doesn't fail
os.environ["DATABASE_URL"] = "sqlite+pysqlite:///:memory:"
os.environ["JWT_SECRET"] = "test-secret"

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import shared.database.base as _db
from shared.database.base import Base

# Replace the module-level engine with an in-memory SQLite instance.
# StaticPool ensures all connections share the same in-memory database.
_db.engine = create_engine(
    "sqlite+pysqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
_db.SessionLocal = sessionmaker(bind=_db.engine)

import app.models.user  # noqa — registers User with Base

Base.metadata.create_all(bind=_db.engine)

from app.main import app  # noqa — imported after engine is patched


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c
