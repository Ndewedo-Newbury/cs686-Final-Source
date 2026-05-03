output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}

output "route53_name_servers" {
  description = "Add these 4 NS records at Name.com to delegate cs686.live to Route53"
  value       = aws_route53_zone.main.name_servers
}

output "route53_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "acm_certificate_arn" {
  description = "Wildcard cert ARN — use for API Gateway and Grafana load balancer"
  value       = aws_acm_certificate_validation.wildcard.certificate_arn
}
