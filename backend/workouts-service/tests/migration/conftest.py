import os
import sys
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine

sys.path.insert(0, str(Path(__file__).parents[3]))  # backend/            — for shared/
sys.path.insert(0, str(Path(__file__).parents[2]))  # backend/workouts-service — for app/


@pytest.fixture(scope="session")
def db_url():
    url = os.environ.get("DATABASE_URL")
    assert url, "DATABASE_URL must be set for migration tests"
    return url


@pytest.fixture(scope="session")
def alembic_cfg(db_url):
    cfg = Config("alembic.ini")
    cfg.set_main_option("sqlalchemy.url", db_url)
    return cfg


@pytest.fixture(scope="session")
def db_engine(db_url):
    engine = create_engine(db_url)
    yield engine
    engine.dispose()


@pytest.fixture(scope="session", autouse=True)
def run_migrations(alembic_cfg):
    command.upgrade(alembic_cfg, "head")
    yield
    command.downgrade(alembic_cfg, "base")
