resource "aws_sqs_queue" "workout_events_dlq" {
  name                      = "${var.project_name}-${var.environment}-workout-events-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "workout_events" {
  name                       = "${var.project_name}-${var.environment}-workout-events"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400 # 1 day

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.workout_events_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = var.environment
  }
}
