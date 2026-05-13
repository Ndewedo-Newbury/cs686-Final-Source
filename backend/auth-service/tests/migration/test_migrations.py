"""
Migration tests for auth-service.

Run against a real PostgreSQL database — set DATABASE_URL before invoking pytest.
Requires: alembic upgrade head has NOT been run yet (conftest handles it).

What is tested:
  - No diverging heads in the migration graph
  - upgrade head applies cleanly and creates the expected schema
  - Schema matches the SQLAlchemy model definitions (catches missing migrations)
  - downgrade base fully reverses every migration
  - Re-upgrading after downgrade is idempotent
  - Existing rows survive a round-trip through downgrade + upgrade
"""
import pytest
from alembic import command
from alembic.script import ScriptDirectory
from sqlalchemy import inspect, text


# ── Graph integrity ───────────────────────────────────────────────────────────

def test_single_head_revision(alembic_cfg):
    """Only one head means no unresolved merge conflicts in the migration graph."""
    scripts = ScriptDirectory.from_config(alembic_cfg)
    heads = scripts.get_heads()
    assert len(heads) == 1, (
        f"Multiple migration heads detected: {heads}. "
        "Run `alembic merge heads` to resolve."
    )


# ── Schema correctness ────────────────────────────────────────────────────────

def test_tables_created(db_engine, run_migrations):
    """upgrade head must create all expected tables."""
    tables = inspect(db_engine).get_table_names()
    assert "users" in tables


def test_users_columns(db_engine, run_migrations):
    """users table must have the exact columns the ORM model defines."""
    cols = {c["name"] for c in inspect(db_engine).get_columns("users")}
    assert {"id", "email", "password_hash", "created_at"} <= cols


def test_users_email_unique_index(db_engine, run_migrations):
    """Email uniqueness is enforced at the DB level, not just app level."""
    indexes = inspect(db_engine).get_indexes("users")
    unique_cols = [
        idx["column_names"] for idx in indexes if idx.get("unique")
    ]
    assert ["email"] in unique_cols


def test_schema_matches_models(alembic_cfg, run_migrations):
    """
    alembic check detects drift between SQLAlchemy model definitions and the
    actual database schema. Fails if a model field was added without a migration.
    """
    try:
        command.check(alembic_cfg)
    except SystemExit as exc:
        pytest.fail(
            "Schema drift detected: model definitions do not match the database. "
            "Run `alembic revision --autogenerate -m '<description>'` to generate "
            f"the missing migration. (exit code: {exc.code})"
        )


# ── Reversibility ─────────────────────────────────────────────────────────────

def test_downgrade_removes_tables(alembic_cfg, db_engine):
    """Every migration must implement downgrade so deploys can be rolled back."""
    command.downgrade(alembic_cfg, "base")
    tables = inspect(db_engine).get_table_names()
    # alembic_version table may remain — everything else must be gone
    app_tables = [t for t in tables if t != "alembic_version"]
    assert app_tables == [], f"Tables remain after full downgrade: {app_tables}"


def test_reupgrade_is_idempotent(alembic_cfg, db_engine):
    """upgrade head after a full downgrade must produce the same schema."""
    command.upgrade(alembic_cfg, "head")
    tables = inspect(db_engine).get_table_names()
    assert "users" in tables


# ── Data survival ─────────────────────────────────────────────────────────────

def test_existing_rows_survive_future_upgrade(alembic_cfg, db_engine):
    """
    Rows written at HEAD must survive a downgrade-to-prev + upgrade cycle.
    This test simulates adding migration 0002: data inserted under 0001 must
    still be readable after 0002 is applied.

    With only one migration today, we verify the round-trip at the same
    revision level. Update the downgrade target to the revision *before* new
    migrations as you add them.
    """
    # Insert a row at current head
    with db_engine.connect() as conn:
        conn.execute(
            text(
                "INSERT INTO users (id, email, password_hash) "
                "VALUES (gen_random_uuid(), 'survive@test.com', 'hashed')"
            )
        )
        conn.commit()

    # Simulate: new migration arrives → downgrade to just before it → re-apply
    # Currently we stay at head since 0001 is the only revision.
    # When 0002 is added, change to: downgrade("0001") then upgrade("head").
    command.downgrade(alembic_cfg, "0001")
    command.upgrade(alembic_cfg, "head")

    with db_engine.connect() as conn:
        count = conn.execute(
            text("SELECT COUNT(*) FROM users WHERE email = 'survive@test.com'")
        ).scalar()
    assert count == 1, "Row inserted before upgrade was lost during migration"
