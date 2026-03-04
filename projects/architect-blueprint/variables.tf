variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "Disaster recovery AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project, used as a prefix for all resource names"
  type        = string
  default     = "architect-blueprint"
}

variable "domain_name" {
  description = "Route53 hosted zone domain name"
  type        = string
  default     = "example.com"
}

variable "vpc_cidr" {
  description = "CIDR block for the primary VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dr_vpc_cidr" {
  description = "CIDR block for the DR VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "List of EC2 instance types for the EKS managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes in the EKS managed node group"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes in the EKS managed node group"
  type        = number
  default     = 10
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes in the EKS managed node group"
  type        = number
  default     = 3
}

variable "aurora_instance_class" {
  description = "Instance class for Aurora PostgreSQL cluster instances"
  type        = string
  default     = "db.t3.medium"
}

variable "aurora_engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "aurora_backup_retention_days" {
  description = "Number of days to retain Aurora automated backups (1-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.aurora_backup_retention_days >= 1 && var.aurora_backup_retention_days <= 35
    error_message = "aurora_backup_retention_days must be between 1 and 35."
  }
}

variable "enable_waf" {
  description = "Whether to attach a WAF v2 WebACL to the CloudFront distribution"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Whether to enable Amazon GuardDuty threat detection"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Whether to enable AWS Security Hub"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Whether to enable multi-region AWS CloudTrail"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address to receive SNS alert notifications"
  type        = string
  default     = ""
}

variable "cost_alert_threshold" {
  description = "Monthly USD cost threshold that triggers a budget alert"
  type        = number
  default     = 200
}
