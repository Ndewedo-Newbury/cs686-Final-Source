output "service_role_arns" {
  value = var.lab_role_arn != "" ? {
    "auth-service"      = var.lab_role_arn
    "workouts-service"  = var.lab_role_arn
    "analytics-service" = var.lab_role_arn
  } : { for k, v in aws_iam_role.service : k => v.arn }
}
