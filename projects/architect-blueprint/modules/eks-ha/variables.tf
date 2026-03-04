variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "private_subnet_ids" {
  description = "IDs of private subnets where EKS nodes will be placed"
  type        = list(string)
}

variable "node_instance_types" {
  description = "EC2 instance types for the general-purpose managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Minimum number of nodes in the general node group"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in the general node group"
  type        = number
  default     = 10
}

variable "node_desired_size" {
  description = "Desired number of nodes in the general node group"
  type        = number
  default     = 3
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the EKS public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_spot_nodes" {
  description = "Whether to create a Spot instance node group (cost savings ~70%)"
  type        = bool
  default     = false
}
