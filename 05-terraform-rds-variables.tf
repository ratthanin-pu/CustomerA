# RDS Module - terraform/modules/rds/variables.tf

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "database_subnet_ids" {
  description = "List of database subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "engine" {
  description = "Database engine (aurora-mysql, aurora-postgresql)"
  type        = string
  default     = "aurora-mysql"
  validation {
    condition     = contains(["aurora-mysql", "aurora-postgresql"], var.engine)
    error_message = "Engine must be aurora-mysql or aurora-postgresql."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0.mysql_aurora.3.02.0"
}

variable "database_name" {
  description = "Initial database name"
  type        = string
  default     = "ecommerce"
}

variable "master_username" {
  description = "Master database username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "master_password" {
  description = "Master database password (should use Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS instance class (e.g., db.t3.small, db.r6g.large)"
  type        = string
  default     = "db.r6g.large"
}

variable "cluster_size" {
  description = "Number of RDS instances in cluster (minimum 2 for Multi-AZ)"
  type        = number
  default     = 2
  validation {
    condition     = var.cluster_size >= 2
    error_message = "Cluster size must be at least 2 for Multi-AZ."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "parameter_group_family" {
  description = "Parameter group family"
  type        = string
  default     = "aurora-mysql8.0"
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 1 and 35 days."
  }
}

variable "preferred_backup_window" {
  description = "Preferred backup window (UTC, e.g., 03:00-04:00)"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Preferred maintenance window (e.g., sun:04:00-sun:05:00)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion (for production, keep false)"
  type        = bool
  default     = false
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}
