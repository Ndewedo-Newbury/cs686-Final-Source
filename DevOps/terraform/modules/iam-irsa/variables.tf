variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC provider (without https://)"
  type        = string
}

variable "sqs_workout_events_arn" {
  description = "ARN of the workout-events SQS queue"
  type        = string
}

variable "lab_role_arn" {
  description = "ARN of a pre-existing IAM role to use (e.g. Voclabs LabRole). When set, no IAM roles or policies are created."
  type        = string
  default     = ""
}
