variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alb_dns_name" {
  description = "DNS name of the EKS ALB (created by AWS Load Balancer Controller)"
  type        = string
}

variable "api_domain" {
  description = "Custom domain for the API (e.g. dev-api.cs686.live)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the wildcard ACM certificate from bootstrap"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID from bootstrap"
  type        = string
}
