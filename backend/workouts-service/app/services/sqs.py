import os
import boto3
from shared.events.schemas import WorkoutLoggedEvent

_sqs_kwargs = {"region_name": os.getenv("AWS_DEFAULT_REGION", "us-west-2")}
if os.getenv("SQS_ENDPOINT_URL"):
    _sqs_kwargs["endpoint_url"] = os.getenv("SQS_ENDPOINT_URL")

sqs = boto3.client("sqs", **_sqs_kwargs)

QUEUE_URL = os.getenv("SQS_QUEUE_URL")


def publish_workout_logged(event: WorkoutLoggedEvent) -> None:
    sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=event.model_dump_json(),
    )
