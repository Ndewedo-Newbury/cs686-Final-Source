"""
Migration tests for analytics-service.
See auth-service/tests/migration/test_migrations.py for test rationale.
"""
import pytest
from alembic import command
from alembic.script import ScriptDirectory
from sqlalchemy import inspect, text


def test_single_head_revision(alembic_cfg):
    scripts = ScriptDirectory.from_config(alembic_cfg)
    heads = scripts.get_heads()
    assert len(heads) == 1, (
        f"Multiple migration heads detected: {heads}. "
        "Run `alembic merge heads` to resolve."
    )


def test_tables_created(db_engine, run_migrations):
    tables = inspect(db_engine).get_table_names()
    assert "user_stats" in tables


def test_user_stats_columns(db_engine, run_migrations):
    cols = {c["name"] for c in inspect(db_engine).get_columns("user_stats")}
    assert {"id", "user_id", "total_workouts", "current_streak",
            "last_workout_at", "updated_at"} <= cols


def test_user_stats_user_id_unique(db_engine, run_migrations):
    """One stats row per user — enforced at the DB level."""
    indexes = inspect(db_engine).get_indexes("user_stats")
    unique_cols = [idx["column_names"] for idx in indexes if idx.get("unique")]
    assert ["user_id"] in unique_cols


def test_schema_matches_models(alembic_cfg, run_migrations):
    try:
        command.check(alembic_cfg)
    except SystemExit as exc:
        pytest.fail(
            "Schema drift detected: model definitions do not match the database. "
            "Run `alembic revision --autogenerate -m '<description>'` to generate "
            f"the missing migration. (exit code: {exc.code})"
        )


def test_downgrade_removes_tables(alembic_cfg, db_engine):
    command.downgrade(alembic_cfg, "base")
    tables = inspect(db_engine).get_table_names()
    app_tables = [t for t in tables if t != "alembic_version"]
    assert app_tables == [], f"Tables remain after full downgrade: {app_tables}"


def test_reupgrade_is_idempotent(alembic_cfg, db_engine):
    command.upgrade(alembic_cfg, "head")
    tables = inspect(db_engine).get_table_names()
    assert "user_stats" in tables


def test_existing_rows_survive_future_upgrade(alembic_cfg, db_engine):
    """
    Rows written at HEAD survive a downgrade-to-prev + upgrade cycle.
    Update the downgrade target revision as new migrations are added.
    """
    with db_engine.connect() as conn:
        conn.execute(
            text(
                "INSERT INTO user_stats (id, user_id, total_workouts, current_streak) "
                "VALUES (gen_random_uuid(), gen_random_uuid(), 5, 3)"
            )
        )
        conn.commit()

    command.downgrade(alembic_cfg, "0001")
    command.upgrade(alembic_cfg, "head")

    with db_engine.connect() as conn:
        count = conn.execute(
            text("SELECT COUNT(*) FROM user_stats WHERE total_workouts = 5")
        ).scalar()
    assert count == 1, "Row inserted before upgrade was lost during migration"
