# Production Environment - terraform/environments/production/main.tf
# Root module that instantiates all service modules

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure these values before init
    # bucket         = "ecommerce-terraform-state"
    # key            = "production/terraform.tfstate"
    # region         = "ap-southeast-1"
    # encrypt        = true
    # dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment  = var.environment
      Project      = var.project_name
      ManagedBy    = "Terraform"
      CreatedDate  = timestamp()
      CostCenter   = var.cost_center
      Compliance   = var.compliance_framework
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}

# KMS Key for encryption
module "kms" {
  source = "../modules/kms"

  project_name    = var.project_name
  environment     = var.environment
  enable_key_rotation = true
  key_admin_arns  = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]

  tags = local.common_tags
}

# VPC and Networking
module "vpc" {
  source = "../modules/vpc"

  project_name       = var.project_name
  aws_region         = var.aws_region
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment

  tags = local.common_tags
}

# RDS Aurora Cluster
module "rds" {
  source = "../modules/rds"

  project_name         = var.project_name
  database_subnet_ids  = module.vpc.database_subnet_ids
  security_group_id    = module.vpc.rds_security_group_id
  kms_key_id          = module.kms.key_id
  availability_zones  = data.aws_availability_zones.available.names

  engine              = var.rds_engine
  engine_version      = var.rds_engine_version
  database_name       = var.database_name
  master_username     = var.db_master_username
  master_password     = var.db_master_password
  instance_class      = var.rds_instance_class
  cluster_size        = var.rds_cluster_size
  backup_retention_days = var.rds_backup_retention

  deletion_protection = true
  skip_final_snapshot = false

  alarm_sns_topic_arn = module.monitoring.sns_topic_arn

  tags = local.common_tags

  depends_on = [module.vpc]
}

# ElastiCache Redis
module "elasticache" {
  source = "../modules/elasticache"

  project_name        = var.project_name
  private_subnet_ids  = module.vpc.private_subnet_ids
  security_group_id   = module.vpc.elasticache_security_group_id
  kms_key_id         = module.kms.key_id
  auth_token         = var.redis_auth_token

  node_type          = var.redis_node_type
  num_cache_nodes    = var.redis_num_nodes
  engine_version     = var.redis_engine_version
  multi_az_enabled   = true
  automatic_failover_enabled = true

  snapshot_retention_days = var.redis_backup_retention

  notification_topic_arn = module.monitoring.sns_topic_arn

  tags = local.common_tags

  depends_on = [module.vpc]
}

# ALB (Application Load Balancer)
module "alb" {
  source = "../modules/alb"

  project_name           = var.project_name
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  security_group_id      = module.vpc.alb_security_group_id
  enable_https           = var.alb_enable_https
  certificate_arn        = var.acm_certificate_arn

  tags = local.common_tags

  depends_on = [module.vpc]
}

# EC2 Auto Scaling Group
module "ec2_asg" {
  source = "../modules/ec2"

  project_name           = var.project_name
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  security_group_id      = module.vpc.ec2_security_group_id

  instance_type          = var.ec2_instance_type
  ami_owner              = "amazon"
  ami_filter_name        = "amzn2-ami-hvm-*-x86_64-gp2"

  min_size              = var.asg_min_size
  max_size              = var.asg_max_size
  desired_capacity      = var.asg_desired_capacity
  target_group_arn      = module.alb.target_group_arn

  instance_role_policies = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  enable_monitoring     = true
  kms_key_id           = module.kms.key_id

  tags = local.common_tags

  depends_on = [module.vpc, module.alb]
}

# SQS and SNS
module "messaging" {
  source = "../modules/messaging"

  project_name           = var.project_name
  vpc_id                 = module.vpc.vpc_id
  kms_key_id            = module.kms.key_id

  # SQS Configuration
  inventory_queue_name   = "${var.project_name}-inventory-queue"
  order_queue_name       = "${var.project_name}-order-queue"
  message_retention_seconds = var.sqs_message_retention

  # SNS Configuration
  notification_topic_name = "${var.project_name}-notifications"

  tags = local.common_tags

  depends_on = [module.kms]
}

# S3 and CloudFront
module "storage" {
  source = "../modules/storage"

  project_name                = var.project_name
  aws_region                 = var.aws_region
  kms_key_id                = module.kms.key_id

  product_images_bucket      = "${var.project_name}-products"
  static_assets_bucket       = "${var.project_name}-assets"
  logs_bucket                = "${var.project_name}-logs"

  enable_cloudfront          = true
  cloudfront_enabled_logging = true

  versioning_enabled         = true
  lifecycle_transition_days  = 90

  tags = local.common_tags

  depends_on = [module.kms]
}

# Monitoring and Logging
module "monitoring" {
  source = "../modules/monitoring"

  project_name           = var.project_name
  aws_region            = var.aws_region
  vpc_id                = module.vpc.vpc_id
  kms_key_id           = module.kms.key_id

  log_retention_days    = var.log_retention_days
  cloudtrail_enabled    = true
  vpc_flow_logs_enabled = true

  dashboard_name        = "${var.project_name}-operations"

  tags = local.common_tags

  depends_on = [module.vpc, module.kms]
}

# Locals for common values
locals {
  common_tags = merge(
    var.tags,
    {
      Project      = var.project_name
      Environment  = var.environment
      ManagedBy    = "Terraform"
      CostCenter   = var.cost_center
      Compliance   = var.compliance_framework
    }
  )
}

# Data source for AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}
