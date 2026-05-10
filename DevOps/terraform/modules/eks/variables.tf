variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.32"
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "node_desired_count" {
  type    = number
  default = 1
}

variable "node_min_count" {
  type    = number
  default = 1
}

variable "node_max_count" {
  type    = number
  default = 3
}

variable "lab_role_arn" {
  description = "ARN of a pre-existing IAM role to use (e.g. Voclabs LabRole). When set, no IAM roles are created."
  type        = string
  default     = ""
}

variable "node_ami_release_version" {
  description = "EKS optimized AMI release version (e.g. 1.32.3-20250501). Update to trigger a zero-downtime rolling node replacement. Get the latest with: aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.32/amazon-linux-2/recommended/release_version --query Parameter.Value --output text"
  type        = string
  default     = null
}
