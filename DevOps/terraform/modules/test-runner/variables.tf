variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "rds_security_group_id" {
  description = "RDS SG — test-runner will be granted ingress on 5432"
  type        = string
}

variable "sqs_queue_arn" {
  type = string
}
