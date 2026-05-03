output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic — set as <ALERTMANAGER_SNS_TOPIC_ARN> in kube-prometheus-stack-values.yaml"
  value       = aws_sns_topic.alerts.arn
}

output "alertmanager_role_arn" {
  description = "IAM role ARN for AlertManager IRSA — set as <ALERTMANAGER_ROLE_ARN> in kube-prometheus-stack-values.yaml"
  value       = aws_iam_role.alertmanager.arn
}
