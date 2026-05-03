locals {
  create_roles     = var.lab_role_arn == ""
  services_to_create = local.create_roles ? toset(["auth-service", "workouts-service", "analytics-service"]) : toset([])
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "service" {
  for_each = local.services_to_create
  name     = "${var.project_name}-${var.environment}-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.environment}:${each.key}"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Environment = var.environment
    Service     = each.key
  }
}

resource "aws_iam_policy" "auth_service" {
  count = local.create_roles ? 1 : 0
  name  = "${var.project_name}-${var.environment}-auth-service-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/auth/*"
      }
    ]
  })
}

resource "aws_iam_policy" "workouts_service" {
  count = local.create_roles ? 1 : 0
  name  = "${var.project_name}-${var.environment}-workouts-service-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/workouts/*"
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = var.sqs_workout_events_arn
      }
    ]
  })
}

resource "aws_iam_policy" "analytics_service" {
  count = local.create_roles ? 1 : 0
  name  = "${var.project_name}-${var.environment}-analytics-service-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/analytics/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_workout_events_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "auth_service" {
  count      = local.create_roles ? 1 : 0
  role       = aws_iam_role.service["auth-service"].name
  policy_arn = aws_iam_policy.auth_service[0].arn
}

resource "aws_iam_role_policy_attachment" "workouts_service" {
  count      = local.create_roles ? 1 : 0
  role       = aws_iam_role.service["workouts-service"].name
  policy_arn = aws_iam_policy.workouts_service[0].arn
}

resource "aws_iam_role_policy_attachment" "analytics_service" {
  count      = local.create_roles ? 1 : 0
  role       = aws_iam_role.service["analytics-service"].name
  policy_arn = aws_iam_policy.analytics_service[0].arn
}
