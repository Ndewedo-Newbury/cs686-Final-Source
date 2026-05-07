from datetime import datetime
from pydantic import BaseModel


class WorkoutLoggedEvent(BaseModel):
    event: str = "workout.logged"
    schema_version: str = "1.0"
    user_id: str
    workout_id: str
    exercise_count: int
    logged_at: datetime
