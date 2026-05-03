import asyncio
import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient
from shared.database.base import Base, engine
from shared.auth.jwt import create_access_token

Base.metadata.create_all(bind=engine)

from app.main import app  # noqa


async def _noop_consume():
    await asyncio.sleep(0)


@pytest.fixture(scope="module")
def token():
    return create_access_token("00000000-0000-0000-0000-000000000098")


@pytest.fixture(scope="module")
def client():
    with patch("app.main.consume", _noop_consume):
        with TestClient(app) as c:
            yield c
