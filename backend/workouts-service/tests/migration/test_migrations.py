"""
Migration tests for workouts-service.
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
    assert "workouts" in tables
    assert "exercises" in tables


def test_workouts_columns(db_engine, run_migrations):
    cols = {c["name"] for c in inspect(db_engine).get_columns("workouts")}
    assert {"id", "user_id", "name", "logged_at"} <= cols


def test_exercises_columns(db_engine, run_migrations):
    cols = {c["name"] for c in inspect(db_engine).get_columns("exercises")}
    assert {"id", "workout_id", "name", "sets", "reps", "weight_kg"} <= cols


def test_exercises_fk_to_workouts(db_engine, run_migrations):
    """exercises.workout_id must cascade-delete when the parent workout is removed."""
    fks = inspect(db_engine).get_foreign_keys("exercises")
    fk_cols = [fk["constrained_columns"] for fk in fks]
    assert ["workout_id"] in fk_cols


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
    assert "workouts" in tables
    assert "exercises" in tables


def test_existing_rows_survive_future_upgrade(alembic_cfg, db_engine):
    """
    Rows written at HEAD survive a downgrade-to-prev + upgrade cycle.
    Update the downgrade target revision as new migrations are added.
    """
    with db_engine.connect() as conn:
        conn.execute(
            text(
                "INSERT INTO workouts (id, user_id, name) "
                "VALUES (gen_random_uuid(), gen_random_uuid(), 'Test Workout')"
            )
        )
        conn.commit()

    command.downgrade(alembic_cfg, "0001")
    command.upgrade(alembic_cfg, "head")

    with db_engine.connect() as conn:
        count = conn.execute(
            text("SELECT COUNT(*) FROM workouts WHERE name = 'Test Workout'")
        ).scalar()
    assert count == 1, "Row inserted before upgrade was lost during migration"
