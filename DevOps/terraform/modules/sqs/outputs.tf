output "queue_url" {
  value = aws_sqs_queue.workout_events.url
}

output "queue_arn" {
  value = aws_sqs_queue.workout_events.arn
}

output "dlq_arn" {
  value = aws_sqs_queue.workout_events_dlq.arn
}
