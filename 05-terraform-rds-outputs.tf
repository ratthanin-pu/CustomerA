# RDS Module - terraform/modules/rds/outputs.tf

output "cluster_identifier" {
  description = "RDS cluster identifier"
  value       = aws_rds_cluster.main.cluster_identifier
}

output "cluster_endpoint" {
  description = "RDS cluster write endpoint"
  value       = aws_rds_cluster.main.endpoint
  sensitive   = false
}

output "cluster_reader_endpoint" {
  description = "RDS cluster read-only endpoint"
  value       = aws_rds_cluster.main.reader_endpoint
  sensitive   = false
}

output "cluster_port" {
  description = "RDS cluster port"
  value       = aws_rds_cluster.main.port
}

output "cluster_resource_id" {
  description = "RDS cluster resource ID"
  value       = aws_rds_cluster.main.cluster_resource_id
}

output "instance_endpoints" {
  description = "RDS instance endpoints"
  value       = aws_rds_cluster_instance.main[*].endpoint
}

output "database_name" {
  description = "Database name"
  value       = aws_rds_cluster.main.database_name
}

output "master_username" {
  description = "Master username"
  value       = aws_rds_cluster.main.master_username
  sensitive   = true
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}

output "security_group_id" {
  description = "RDS security group ID"
  value       = var.security_group_id
}
