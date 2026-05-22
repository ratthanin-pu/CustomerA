# VPC Module - terraform/modules/vpc/variables.tf

variable "project_name" {
  description = "Name of the project (used for tagging and naming resources)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,32}$", var.project_name))
    error_message = "Project name must be 3-32 lowercase alphanumeric characters or hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC (e.g., 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "Number of availability zones (2 or 3)"
  type        = number
  default     = 2
  validation {
    condition     = contains([2, 3], var.availability_zones)
    error_message = "Must be 2 or 3 availability zones."
  }
}

variable "aws_region" {
  description = "AWS region for deployment (e.g., ap-southeast-1)"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "Invalid AWS region format."
  }
}

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
  default     = "production"
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging, or development."
  }
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    ManagedBy   = "terraform"
  }
}
