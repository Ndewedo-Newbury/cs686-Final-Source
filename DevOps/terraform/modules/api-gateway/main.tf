resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-${var.environment}"
  description = "Fitness Tracker API Gateway - ${var.environment}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "v1"
}

locals {
  services = {
    auth      = { path = "auth",      port = 8001 }
    workouts  = { path = "workouts",  port = 8002 }
    analytics = { path = "analytics", port = 8003 }
  }
  # Use a placeholder when ALB doesn't exist yet (pre-EKS deploy).
  # Re-run terraform apply with alb_dns_name set after AWS LBC creates the ALB.
  effective_alb_dns = var.alb_dns_name != "" ? var.alb_dns_name : "pending.${var.api_domain}"
}

resource "aws_api_gateway_resource" "service" {
  for_each    = local.services
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = each.value.path
}

resource "aws_api_gateway_resource" "service_proxy" {
  for_each    = local.services
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.service[each.key].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "service_proxy" {
  for_each      = local.services
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.service_proxy[each.key].id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "service_proxy" {
  for_each                = local.services
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.service_proxy[each.key].id
  http_method             = aws_api_gateway_method.service_proxy[each.key].http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${local.effective_alb_dns}/api/v1/${each.value.path}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.service_proxy,
      aws_api_gateway_method.service_proxy,
      aws_api_gateway_integration.service_proxy,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  tags = {
    Environment = var.environment
  }
}

resource "aws_api_gateway_domain_name" "main" {
  domain_name              = var.api_domain
  regional_certificate_arn = var.acm_certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "api" {
  zone_id = var.zone_id
  name    = var.api_domain
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.main.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.main.regional_zone_id
    evaluate_target_health = false
  }
}

resource "aws_api_gateway_base_path_mapping" "main" {
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.main.domain_name
}
