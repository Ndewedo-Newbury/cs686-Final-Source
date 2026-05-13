import asyncio
import logging
import os
import uuid
import boto3

logger = logging.getLogger(__name__)
from shared.events.schemas import WorkoutLoggedEvent
from shared.database.base import SessionLocal
from app.models.stats import UserStats

_sqs_kwargs = {"region_name": os.getenv("AWS_DEFAULT_REGION", "us-west-2")}
if os.getenv("SQS_ENDPOINT_URL"):
    _sqs_kwargs["endpoint_url"] = os.getenv("SQS_ENDPOINT_URL")

sqs = boto3.client("sqs", **_sqs_kwargs)

QUEUE_URL = os.getenv("SQS_QUEUE_URL")


def _process_event(event: WorkoutLoggedEvent) -> None:
    db = SessionLocal()
    try:
        stats = db.query(UserStats).filter(UserStats.user_id == uuid.UUID(event.user_id)).first()
        if not stats:
            stats = UserStats(id=uuid.uuid4(), user_id=uuid.UUID(event.user_id), total_workouts=0, current_streak=0)
            db.add(stats)
        stats.total_workouts += 1
        stats.last_workout_at = event.logged_at
        db.commit()
    finally:
        db.close()


def _poll() -> None:
    response = sqs.receive_message(
        QueueUrl=QUEUE_URL,
        MaxNumberOfMessages=10,
        WaitTimeSeconds=5,
    )
    for message in response.get("Messages", []):
        event = WorkoutLoggedEvent.model_validate_json(message["Body"])
        _process_event(event)
        sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=message["ReceiptHandle"])


async def consume() -> None:
    while True:
        try:
            await asyncio.to_thread(_poll)
        except Exception:
            logger.exception("SQS poll error, retrying in 5s")
            await asyncio.sleep(5)
