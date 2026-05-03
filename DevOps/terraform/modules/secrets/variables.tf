variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "rds_host" {
  type = string
}

variable "rds_port" {
  type    = number
  default = 5432
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

variable "sqs_queue_url" {
  type = string
}
