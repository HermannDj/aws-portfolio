variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Aurora security group will be created"
  type        = string
}

variable "database_subnet_ids" {
  description = "IDs of the isolated database subnets for the Aurora subnet group"
  type        = list(string)
}

variable "eks_security_group_id" {
  description = "Security group ID of EKS worker nodes — Aurora allows inbound from this SG"
  type        = string
}

variable "aurora_instance_class" {
  description = "Instance class for Aurora cluster instances"
  type        = string
  default     = "db.t3.medium"
}

variable "aurora_engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "database_name" {
  description = "Name of the initial database in the Aurora cluster"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master username for the Aurora cluster"
  type        = string
  default     = "dbadmin"
}

variable "final_snapshot_suffix" {
  description = "Unique suffix appended to the final snapshot identifier to avoid naming conflicts across destroy/apply cycles"
  type        = string
  default     = "v1"
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}
