import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Float, DateTime, ForeignKey
from sqlalchemy.types import Uuid
from sqlalchemy.orm import relationship
from shared.database.base import Base


class Workout(Base):
    __tablename__ = "workouts"

    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(Uuid(as_uuid=True), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    logged_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    exercises = relationship("Exercise", back_populates="workout", cascade="all, delete")


class Exercise(Base):
    __tablename__ = "exercises"

    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    workout_id = Column(Uuid(as_uuid=True), ForeignKey("workouts.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    sets = Column(Integer, nullable=False)
    reps = Column(Integer, nullable=False)
    weight_kg = Column(Float, nullable=True)
    workout = relationship("Workout", back_populates="exercises")
