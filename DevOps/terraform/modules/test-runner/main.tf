locals {
  create_role      = var.lab_role_arn == ""
  test_runner_role = var.lab_role_arn != "" ? var.lab_role_arn : aws_iam_role.test_runner[0].arn
}

data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "test_runner" {
  name                 = "${var.project_name}/test-runner"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Environment = var.environment }
}

resource "aws_security_group" "test_runner" {
  name        = "${var.project_name}-${var.environment}-test-runner-sg"
  description = "Test runner Lambda - egress only"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Environment = var.environment }
}

# Allow test-runner Lambda to reach RDS on 5432
resource "aws_security_group_rule" "test_runner_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.test_runner.id
  security_group_id        = var.rds_security_group_id
}

resource "aws_iam_role" "test_runner" {
  count = local.create_role ? 1 : 0
  name  = "${var.project_name}-${var.environment}-test-runner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  count      = local.create_role ? 1 : 0
  role       = aws_iam_role.test_runner[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "test_runner" {
  count = local.create_role ? 1 : 0
  name  = "${var.project_name}-${var.environment}-test-runner-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "test_runner" {
  count      = local.create_role ? 1 : 0
  role       = aws_iam_role.test_runner[0].name
  policy_arn = aws_iam_policy.test_runner[0].arn
}

resource "aws_lambda_function" "test_runner" {
  count         = var.create_lambda ? 1 : 0
  function_name = "${var.project_name}-${var.environment}-test-runner"
  role          = local.test_runner_role
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.test_runner.repository_url}:latest"
  timeout       = 900
  memory_size   = 1024

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.test_runner.id]
  }

  environment {
    variables = {
      ENVIRONMENT     = var.environment
      PROJECT         = var.project_name
      AWS_REGION_NAME = var.aws_region
      API_URL         = var.api_url
    }
  }

  tags = { Environment = var.environment }
}

resource "aws_lambda_function" "migrate" {
  count         = var.create_lambda ? 1 : 0
  function_name = "${var.project_name}-${var.environment}-migrate"
  role          = local.test_runner_role
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.test_runner.repository_url}:latest"
  image_config {
    command = ["migrate_handler.handler"]
  }
  timeout     = 300
  memory_size = 512

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.test_runner.id]
  }

  environment {
    variables = {
      ENVIRONMENT     = var.environment
      PROJECT         = var.project_name
      AWS_REGION_NAME = var.aws_region
    }
  }

  tags = { Environment = var.environment }
}
