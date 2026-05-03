variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "fitness-tracker"
}

variable "base_domain" {
  description = "Root domain managed in Route53 (e.g. cs686.live)"
  type        = string
  default     = "cs686.live"
}
