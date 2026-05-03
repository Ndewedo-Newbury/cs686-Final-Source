variable "aws_region" {
  type    = string
  default = "us-east-1"
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
  description = "DNS name of the EKS ALB (set after EKS + AWS LBC deploy)"
  type        = string
  default     = ""
}

variable "base_domain" {
  description = "Base domain for all environments (e.g. fittracker.example.com)"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive alert notifications"
  type        = string
}
