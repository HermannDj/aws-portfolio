variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name for Route53 and ACM certificate"
  type        = string
}

variable "enable_waf" {
  description = "Whether to attach a WAF v2 WebACL to the CloudFront distribution"
  type        = bool
  default     = true
}

variable "geo_restriction_locations" {
  description = "Optional list of ISO 3166-1 country codes for geo-restriction (empty = no restriction)"
  type        = list(string)
  default     = []
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (ALB) used as CloudFront API origin"
  type        = string
  default     = ""
}
