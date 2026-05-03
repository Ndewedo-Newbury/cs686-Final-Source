import os
import boto3
from shared.events.schemas import WorkoutLoggedEvent

sqs = boto3.client(
    "sqs",
    endpoint_url=os.getenv("SQS_ENDPOINT_URL", "http://localstack:4566"),
    region_name=os.getenv("AWS_DEFAULT_REGION", "us-east-1"),
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID", "test"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY", "test"),
)

QUEUE_URL = os.getenv("SQS_QUEUE_URL")


def publish_workout_logged(event: WorkoutLoggedEvent) -> None:
    sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=event.model_dump_json(),
    )
