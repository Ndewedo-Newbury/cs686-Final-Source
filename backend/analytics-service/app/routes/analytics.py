import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

from shared.database.base import get_db
from shared.auth.jwt import verify_token
from app.models.stats import UserStats

router = APIRouter(prefix="/api/v1/analytics", tags=["analytics"])


@router.get("/health")
def health():
    return {"status": "ok"}


class StatsOut(BaseModel):
    user_id: str
    total_workouts: int
    current_streak: int
    last_workout_at: Optional[datetime]

    class Config:
        from_attributes = True


@router.get("/stats", response_model=StatsOut)
def get_stats(user_id: str = Depends(verify_token), db: Session = Depends(get_db)):
    stats = db.query(UserStats).filter(UserStats.user_id == uuid.UUID(user_id)).first()
    if not stats:
        raise HTTPException(status_code=404, detail="No stats found — log a workout first")
    return StatsOut(
        user_id=user_id,
        total_workouts=stats.total_workouts,
        current_streak=stats.current_streak,
        last_workout_at=stats.last_workout_at,
    )
