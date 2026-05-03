output "api_id" {
  value = aws_api_gateway_rest_api.main.id
}

output "invoke_url" {
  value = aws_api_gateway_stage.main.invoke_url
}

output "custom_domain_url" {
  value = "https://${aws_api_gateway_domain_name.main.domain_name}"
}

output "acm_certificate_arn" {
  value = var.acm_certificate_arn
}
