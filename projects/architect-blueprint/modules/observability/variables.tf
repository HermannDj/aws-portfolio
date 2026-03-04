variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive SNS alert notifications (leave empty to skip subscription)"
  type        = string
  default     = ""
}

variable "cost_alert_threshold" {
  description = "Monthly USD budget limit that triggers a cost alert notification"
  type        = number
  default     = 200
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster (used for CloudWatch metric filters)"
  type        = string
}

variable "aurora_cluster_id" {
  description = "ID of the Aurora cluster (used for CloudWatch alarms)"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution (used for CloudWatch alarms)"
  type        = string
}
