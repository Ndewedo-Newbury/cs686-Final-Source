import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, DateTime
from sqlalchemy.types import Uuid
from shared.database.base import Base


class UserStats(Base):
    __tablename__ = "user_stats"

    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(Uuid(as_uuid=True), unique=True, nullable=False)
    total_workouts = Column(Integer, default=0, nullable=False)
    current_streak = Column(Integer, default=0, nullable=False)
    last_workout_at = Column(DateTime, nullable=True)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
