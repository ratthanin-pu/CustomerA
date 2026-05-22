# Production Environment - terraform/environments/production/terraform.tfvars
# Configuration values for the E-commerce-3 Platform production deployment

# Project and Environment
project_name     = "ecommerce-3"
environment      = "production"
aws_region       = "ap-southeast-1"  # Thailand region
cost_center      = "engineering"
compliance_framework = "soc2-type2-cis-aws"

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = 2

# RDS Aurora Configuration
rds_engine               = "aurora-mysql"
rds_engine_version       = "8.0.mysql_aurora.3.02.0"
rds_instance_class       = "db.r6g.large"      # Supports 5000 concurrent users
rds_cluster_size         = 2                    # Multi-AZ (1 writer + 1 reader minimum)
rds_backup_retention     = 7                    # 7-day backup retention
database_name            = "ecommerce"
db_master_username       = "admin"
db_master_password       = "CHANGE_ME_USE_SECRETS_MANAGER"  # Use AWS Secrets Manager instead

# ElastiCache Redis Configuration
redis_node_type          = "cache.r6g.large"   # High-performance cache for inventory
redis_num_nodes          = 3                    # Multi-AZ with automatic failover
redis_engine_version     = "7.0"
redis_backup_retention   = 7
redis_auth_token         = "CHANGE_ME_MIN_32_CHARS_USE_SECRETS_MANAGER"

# Application Load Balancer
alb_enable_https         = true
acm_certificate_arn      = "arn:aws:acm:ap-southeast-1:ACCOUNT_ID:certificate/CERT_ID"  # Update with your cert

# EC2 Auto Scaling Group
ec2_instance_type        = "t3.xlarge"         # 2 vCPU, 16 GB RAM - suitable for 5000 concurrent users
asg_min_size            = 2                    # Minimum 2 instances (multi-AZ)
asg_max_size            = 10                   # Maximum 10 instances for scaling
asg_desired_capacity    = 3                    # Start with 3 instances

# SQS Configuration (Inventory & Order Processing)
sqs_message_retention    = 86400                # 24 hours

# Logging and Monitoring
log_retention_days       = 30                   # CloudWatch logs retention

# Tags
tags = {
  Application  = "E-commerce-3-Platform"
  Team         = "Platform-Engineering"
  Environment  = "production"
  CostCenter   = "engineering"
  Compliance   = "soc2-type2-cis-aws-foundations"
  BackupPolicy = "daily"
  MonitoringLevel = "enhanced"
  DisasterRecovery = "enabled"
  Region       = "ap-southeast-1"
}
