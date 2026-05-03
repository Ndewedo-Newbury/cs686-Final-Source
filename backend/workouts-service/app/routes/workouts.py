import uuid
from uuid import UUID
from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from pydantic import BaseModel, ConfigDict

from shared.database.base import get_db
from shared.auth.jwt import verify_token
from shared.events.schemas import WorkoutLoggedEvent
from app.models.workout import Workout, Exercise
from app.services.sqs import publish_workout_logged

router = APIRouter(prefix="/api/v1/workouts", tags=["workouts"])


class ExerciseIn(BaseModel):
    name: str
    sets: int
    reps: int
    weight_kg: Optional[float] = None


class WorkoutIn(BaseModel):
    name: str
    exercises: List[ExerciseIn]


class ExerciseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    name: str
    sets: int
    reps: int
    weight_kg: Optional[float]


class WorkoutOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    name: str
    logged_at: datetime
    exercises: List[ExerciseOut]


@router.post("/", status_code=201, response_model=WorkoutOut)
def log_workout(body: WorkoutIn, user_id: str = Depends(verify_token), db: Session = Depends(get_db)):
    workout = Workout(id=uuid.uuid4(), user_id=uuid.UUID(user_id), name=body.name)
    db.add(workout)
    db.flush()

    for ex in body.exercises:
        db.add(Exercise(id=uuid.uuid4(), workout_id=workout.id, **ex.model_dump()))

    db.commit()
    db.refresh(workout)

    publish_workout_logged(WorkoutLoggedEvent(
        user_id=user_id,
        workout_id=str(workout.id),
        exercise_count=len(body.exercises),
        logged_at=workout.logged_at or datetime.now(timezone.utc),
    ))

    return workout


@router.get("/", response_model=List[WorkoutOut])
def list_workouts(
    user_id: str = Depends(verify_token),
    db: Session = Depends(get_db),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
):
    return (
        db.query(Workout)
        .options(joinedload(Workout.exercises))
        .filter(Workout.user_id == uuid.UUID(user_id))
        .order_by(Workout.logged_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


@router.get("/{workout_id}", response_model=WorkoutOut)
def get_workout(workout_id: str, user_id: str = Depends(verify_token), db: Session = Depends(get_db)):
    workout = (
        db.query(Workout)
        .options(joinedload(Workout.exercises))
        .filter(Workout.id == uuid.UUID(workout_id), Workout.user_id == uuid.UUID(user_id))
        .first()
    )
    if not workout:
        raise HTTPException(status_code=404, detail="Workout not found")
    return workout


@router.delete("/{workout_id}", status_code=204)
def delete_workout(workout_id: str, user_id: str = Depends(verify_token), db: Session = Depends(get_db)):
    workout = db.query(Workout).filter(
        Workout.id == uuid.UUID(workout_id), Workout.user_id == uuid.UUID(user_id)
    ).first()
    if not workout:
        raise HTTPException(status_code=404, detail="Workout not found")
    db.delete(workout)
    db.commit()
