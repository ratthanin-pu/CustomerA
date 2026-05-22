# RDS Module - terraform/modules/rds/main.tf
# Creates RDS Aurora MySQL cluster with Multi-AZ, encryption, and automated backups

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# RDS Subnet Group (required for RDS in VPC)
resource "aws_db_subnet_group" "main" {
  name            = "${var.project_name}-db-subnet-group"
  subnet_ids      = var.database_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-subnet-group"
    }
  )
}

# RDS Aurora Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier              = "${var.project_name}-aurora-cluster"
  engine                          = var.engine
  engine_version                  = var.engine_version
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password

  # Multi-AZ Configuration
  availability_zones              = var.availability_zones
  db_subnet_group_name            = aws_db_subnet_group.main.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name

  # Security
  vpc_security_group_ids          = [var.security_group_id]
  storage_encrypted               = true
  kms_key_id                      = var.kms_key_id
  enable_iam_database_authentication = true

  # Backup & Recovery
  backup_retention_period         = var.backup_retention_days
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  copy_tags_to_snapshot          = true

  # High Availability
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  enable_http_endpoint            = false

  # Performance Insights
  enable_performance_insights      = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id  = var.kms_key_id

  # Deletion Protection
  deletion_protection             = var.deletion_protection
  skip_final_snapshot            = var.skip_final_snapshot
  final_snapshot_identifier      = "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-aurora-cluster"
    }
  )

  depends_on = [aws_rds_cluster_parameter_group.main]
}

# RDS Cluster Instances (Multi-AZ)
resource "aws_rds_cluster_instance" "main" {
  count              = var.cluster_size
  identifier         = "${var.project_name}-aurora-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  performance_insights_enabled    = true
  performance_insights_kms_key_id = var.kms_key_id
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  auto_minor_version_upgrade      = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-aurora-instance-${count.index + 1}"
    }
  )
}

# RDS Cluster Parameter Group
resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.project_name}-aurora-params"
  family      = var.parameter_group_family
  description = "Custom parameter group for Aurora cluster"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-aurora-params"
    }
  )
}

# IAM Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
  }

  alarm_description = "Alert when RDS CPU exceeds 80%"
  alarm_actions     = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
}

resource "aws_cloudwatch_metric_alarm" "rds_db_connections" {
  alarm_name          = "${var.project_name}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
  }

  alarm_description = "Alert when RDS connections exceed 100"
  alarm_actions     = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
}
