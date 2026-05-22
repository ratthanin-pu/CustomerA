# ElastiCache Module - terraform/modules/elasticache/main.tf
# Creates ElastiCache Redis cluster with Multi-AZ, encryption, and automated backups

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name            = "${var.project_name}-elasticache-subnet-group"
  subnet_ids      = var.private_subnet_ids
  description     = "Subnet group for ElastiCache Redis cluster"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-elasticache-subnet-group"
    }
  )
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.project_name}-redis"
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.main.name
  engine_version       = var.engine_version
  port                 = var.redis_port

  # Availability & Subnet
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [var.security_group_id]

  # Multi-AZ
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  # Encryption
  at_rest_encryption_enabled = true
  kms_key_id                 = var.kms_key_id
  transit_encryption_enabled = true
  auth_token                 = var.auth_token

  # Backup & Recovery
  snapshot_retention_limit = var.snapshot_retention_days
  snapshot_window          = var.snapshot_window

  # Logging
  log_delivery_configuration {
    destination      = var.cloudwatch_log_group_name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    enabled          = true
  }

  # Performance & Monitoring
  notification_topic_arn = var.notification_topic_arn != "" ? var.notification_topic_arn : null

  apply_immediately = var.apply_immediately

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-redis"
    }
  )

  depends_on = [aws_elasticache_parameter_group.main]
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  name        = "${var.project_name}-redis-params"
  family      = var.parameter_group_family
  description = "Custom parameter group for Redis"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  parameter {
    name  = "tcp-keepalive"
    value = "300"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-redis-params"
    }
  )
}

# CloudWatch Log Group for Redis
resource "aws_cloudwatch_log_group" "redis" {
  name              = "/aws/elasticache/${var.project_name}-redis"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-redis-logs"
    }
  )
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${var.project_name}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.main.cluster_id
  }

  alarm_description = "Alert when Redis CPU exceeds 75%"
  alarm_actions     = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []
}

resource "aws_cloudwatch_metric_alarm" "redis_evictions" {
  alarm_name          = "${var.project_name}-redis-evictions"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.main.cluster_id
  }

  alarm_description = "Alert when Redis evictions occur"
  alarm_actions     = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []
}

resource "aws_cloudwatch_metric_alarm" "redis_network_bytes" {
  alarm_name          = "${var.project_name}-redis-network-bytes-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkBytesIn"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000000000" # 1 GB

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.main.cluster_id
  }

  alarm_description = "Alert when network bytes exceed threshold"
  alarm_actions     = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []
}
