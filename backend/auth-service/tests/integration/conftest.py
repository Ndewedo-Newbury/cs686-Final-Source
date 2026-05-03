"""
Integration conftest — DATABASE_URL and JWT_SECRET are injected by the
Lambda handler from AWS Secrets Manager before pytest runs.
Tables are created if they don't already exist.
"""
import pytest
from fastapi.testclient import TestClient
from shared.database.base import Base, engine

Base.metadata.create_all(bind=engine)

from app.main import app  # noqa


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c
