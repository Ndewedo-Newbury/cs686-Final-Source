# ── VPC ─────────────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB / NAT)"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (EKS nodes, RDS, Lambda)"
  value       = module.vpc.private_subnet_ids
}

# ── EKS ─────────────────────────────────────────────────────────────────────
output "eks_cluster_name" {
  description = "EKS cluster name — use with: aws eks update-kubeconfig --name <value>"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN used for IRSA role trust policies"
  value       = module.eks.oidc_provider_arn
}

# ── RDS ─────────────────────────────────────────────────────────────────────
output "rds_endpoint" {
  description = "Full RDS endpoint (host:port)"
  value       = module.rds.endpoint
  sensitive   = true
}

output "rds_host" {
  description = "RDS hostname"
  value       = module.rds.host
  sensitive   = true
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.port
}

# ── SQS ─────────────────────────────────────────────────────────────────────
output "sqs_queue_url" {
  description = "SQS workout-events queue URL"
  value       = module.sqs.queue_url
}

output "sqs_queue_arn" {
  description = "SQS workout-events queue ARN"
  value       = module.sqs.queue_arn
}

output "sqs_dlq_arn" {
  description = "SQS dead-letter queue ARN"
  value       = module.sqs.dlq_arn
}

# ── ECR ─────────────────────────────────────────────────────────────────────
output "ecr_repository_urls" {
  description = "ECR repository URLs keyed by service name"
  value       = module.ecr.repository_urls
}

output "ecr_registry_id" {
  description = "ECR registry ID (AWS account ID)"
  value       = module.ecr.registry_id
}

output "ecr_test_runner_repository_url" {
  description = "ECR repository URL for the test-runner / migrate image"
  value       = module.test_runner.ecr_repository_url
}

# ── API Gateway ──────────────────────────────────────────────────────────────
output "api_gateway_url" {
  description = "Custom domain URL for the API (https://dev-api.cs686.live)"
  value       = module.api_gateway.custom_domain_url
}

output "api_gateway_invoke_url" {
  description = "Raw API Gateway stage invoke URL (before custom domain)"
  value       = module.api_gateway.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = module.api_gateway.api_id
}

# ── Secrets Manager ──────────────────────────────────────────────────────────
output "secret_arns" {
  description = "Secrets Manager secret ARNs keyed by secret name"
  value       = module.secrets.secret_arns
}

# ── IAM / IRSA ───────────────────────────────────────────────────────────────
output "service_role_arns" {
  description = "IAM role ARNs used by each service pod via IRSA"
  value       = module.iam_irsa.service_role_arns
}

# ── Lambda (test-runner / migrate) ───────────────────────────────────────────
output "test_runner_function_name" {
  description = "Lambda function name for running integration/E2E tests"
  value       = module.test_runner.function_name
}

output "test_runner_function_arn" {
  description = "Lambda function ARN for the test runner"
  value       = module.test_runner.function_arn
}

# ── Monitoring (SNS + AlertManager) ─────────────────────────────────────────
output "sns_alerts_topic_arn" {
  description = "SNS topic ARN that AlertManager publishes to"
  value       = module.monitoring.sns_topic_arn
}

output "alertmanager_role_arn" {
  description = "IAM role ARN used by AlertManager IRSA"
  value       = module.monitoring.alertmanager_role_arn
}
