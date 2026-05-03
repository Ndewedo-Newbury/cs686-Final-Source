terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "fitness-tracker-terraform-state-793012580999"
    key          = "qa/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = "qa"
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b"]
}

module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  environment        = "qa"
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  node_instance_type = "t3.medium"
  node_desired_count = 1
  node_min_count     = 1
  node_max_count     = 2
}

module "rds" {
  source = "../../modules/rds"

  project_name          = var.project_name
  environment           = "qa"
  private_subnet_ids    = module.vpc.private_subnet_ids
  rds_security_group_id = module.vpc.rds_security_group_id
  instance_class        = "db.t3.micro"
  db_username           = var.db_username
  db_password           = var.db_password
  multi_az              = false
}

module "sqs" {
  source = "../../modules/sqs"

  project_name = var.project_name
  environment  = "qa"
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = "qa"
}

module "iam_irsa" {
  source = "../../modules/iam-irsa"

  project_name           = var.project_name
  environment            = "qa"
  aws_region             = var.aws_region
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  sqs_workout_events_arn = module.sqs.queue_arn
}

module "secrets" {
  source = "../../modules/secrets"

  project_name   = var.project_name
  environment    = "qa"
  rds_host       = module.rds.host
  rds_port       = module.rds.port
  db_username    = var.db_username
  db_password    = var.db_password
  jwt_secret_key = var.jwt_secret_key
  sqs_queue_url  = module.sqs.queue_url
}

module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name = var.project_name
  environment  = "qa"
  alb_dns_name = var.alb_dns_name
  api_domain   = "api.qa.${var.base_domain}"
}

module "test_runner" {
  source = "../../modules/test-runner"

  project_name          = var.project_name
  environment           = "qa"
  aws_region            = var.aws_region
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  rds_security_group_id = module.vpc.rds_security_group_id
  sqs_queue_arn         = module.sqs.queue_arn
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name      = var.project_name
  environment       = "qa"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  alert_email       = var.alert_email
}
