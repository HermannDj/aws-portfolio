variable "aws_region" {
  type        = string
  description = "AWS region where resources will be deployed."
  default     = "ca-central-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier (e.g. ca-central-1)."
  }
}

variable "project_name" {
  type        = string
  description = "Short name used as a prefix for all resource names."
  default     = "eks-blueprint"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 4–30 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev | staging | prod)."
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  type        = string
  description = "Team or individual responsible for this stack (used for tagging)."
  default     = "platform-team"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to run on the EKS cluster."
  default     = "1.29"

  validation {
    condition     = can(regex("^1\\.(2[0-9]|[3-9][0-9])$", var.kubernetes_version))
    error_message = "kubernetes_version must be a valid EKS version (e.g. 1.29)."
  }
}

variable "node_instance_type" {
  type        = string
  description = "EC2 instance type for the managed node group."
  default     = "t3.medium"
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of nodes in the managed node group."
  default     = 2

  validation {
    condition     = var.node_desired_size >= 1 && var.node_desired_size <= 20
    error_message = "node_desired_size must be between 1 and 20."
  }
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of nodes in the managed node group."
  default     = 1

  validation {
    condition     = var.node_min_size >= 1
    error_message = "node_min_size must be at least 1."
  }
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of nodes in the managed node group."
  default     = 4

  validation {
    condition     = var.node_max_size >= 1 && var.node_max_size <= 50
    error_message = "node_max_size must be between 1 and 50."
  }
}

variable "node_disk_size_gb" {
  type        = number
  description = "Root EBS volume size for each node (GB)."
  default     = 20

  validation {
    condition     = var.node_disk_size_gb >= 20
    error_message = "node_disk_size_gb must be at least 20 GB."
  }
}

variable "lbc_chart_version" {
  type        = string
  description = "Helm chart version for the AWS Load Balancer Controller."
  default     = "1.7.2"
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log group retention in days."
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365], var.log_retention_days)
    error_message = "log_retention_days must be a value allowed by AWS."
  }
}
