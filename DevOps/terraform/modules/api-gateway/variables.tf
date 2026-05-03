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
  description = "Custom domain for the API (e.g. api.dev.fittracker.example.com)"
  type        = string
}
