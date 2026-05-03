data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  tags = {
    Environment = var.environment
  }
}

# Subscription requires manual email confirmation after terraform apply.
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_iam_role" "alertmanager" {
  count = var.lab_role_arn == "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-alertmanager"

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
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:monitoring:kube-prometheus-stack-alertmanager"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_policy" "alertmanager" {
  count = var.lab_role_arn == "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-alertmanager-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = aws_sns_topic.alerts.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alertmanager" {
  count      = var.lab_role_arn == "" ? 1 : 0
  role       = aws_iam_role.alertmanager[0].name
  policy_arn = aws_iam_policy.alertmanager[0].arn
}
