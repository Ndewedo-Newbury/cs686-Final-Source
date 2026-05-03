variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "project_name" {
  type    = string
  default = "fitness-tracker"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "jwt_secret_key" {
  type      = string
  sensitive = true
}

variable "alb_dns_name" {
  type    = string
  default = ""
}

variable "base_domain" {
  description = "Root domain (e.g. cs686.live)"
  type        = string
  default     = "cs686.live"
}

variable "alert_email" {
  description = "Email address to receive alert notifications"
  type        = string
}

variable "acm_certificate_arn" {
  description = "Wildcard ACM cert ARN from bootstrap (terraform output acm_certificate_arn)"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID from bootstrap (terraform output route53_zone_id)"
  type        = string
}
