"""initial

Revision ID: 0001
Revises:
Create Date: 2026-04-28
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "workouts",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("logged_at", sa.DateTime(), server_default=sa.text("now()")),
    )
    op.create_index("ix_workouts_user_id", "workouts", ["user_id"])

    op.create_table(
        "exercises",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "workout_id",
            UUID(as_uuid=True),
            sa.ForeignKey("workouts.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("sets", sa.Integer(), nullable=False),
        sa.Column("reps", sa.Integer(), nullable=False),
        sa.Column("weight_kg", sa.Float(), nullable=True),
    )
    op.create_index("ix_exercises_workout_id", "exercises", ["workout_id"])


def downgrade():
    op.drop_index("ix_exercises_workout_id", table_name="exercises")
    op.drop_table("exercises")
    op.drop_index("ix_workouts_user_id", table_name="workouts")
    op.drop_table("workouts")
