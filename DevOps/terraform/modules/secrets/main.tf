locals {
  secrets = {
    auth_db = {
      name  = "${var.project_name}/${var.environment}/auth/db"
      value = jsonencode({
        host     = var.rds_host
        port     = tostring(var.rds_port)
        username = var.db_username
        password = var.db_password
        dbname   = "auth_db"
      })
    }
    workouts_db = {
      name  = "${var.project_name}/${var.environment}/workouts/db"
      value = jsonencode({
        host     = var.rds_host
        port     = tostring(var.rds_port)
        username = var.db_username
        password = var.db_password
        dbname   = "workouts_db"
      })
    }
    analytics_db = {
      name  = "${var.project_name}/${var.environment}/analytics/db"
      value = jsonencode({
        host     = var.rds_host
        port     = tostring(var.rds_port)
        username = var.db_username
        password = var.db_password
        dbname   = "analytics_db"
      })
    }
    jwt = {
      name  = "${var.project_name}/${var.environment}/auth/jwt"
      value = jsonencode({
        secret_key = var.jwt_secret_key
      })
    }
    sqs = {
      name  = "${var.project_name}/${var.environment}/workouts/sqs"
      value = jsonencode({
        queue_url = var.sqs_queue_url
      })
    }
  }
}

resource "aws_secretsmanager_secret" "secrets" {
  for_each                = local.secrets
  name                    = each.value.name
  recovery_window_in_days = 0

  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "secrets" {
  for_each      = local.secrets
  secret_id     = aws_secretsmanager_secret.secrets[each.key].id
  secret_string = each.value.value
}
