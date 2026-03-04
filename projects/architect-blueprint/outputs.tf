# --- Networking outputs (primary VPC)
output "vpc_id" {
  description = "ID of the primary VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the primary VPC"
  value       = module.networking.vpc_cidr
}

output "private_subnet_ids" {
  description = "IDs of the private subnets in the primary VPC"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets in the primary VPC"
  value       = module.networking.public_subnet_ids
}

# --- DR networking outputs
output "dr_vpc_id" {
  description = "ID of the disaster recovery VPC"
  value       = module.networking_dr.vpc_id
}

output "dr_vpc_cidr" {
  description = "CIDR block of the disaster recovery VPC"
  value       = module.networking_dr.vpc_cidr
}

# --- EKS outputs
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks_ha.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API server endpoint of the EKS cluster"
  value       = module.eks_ha.cluster_endpoint
  sensitive   = true
}

output "eks_cluster_version" {
  description = "Kubernetes version running on the EKS cluster"
  value       = module.eks_ha.cluster_version
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks_ha.oidc_provider_arn
}

# --- Aurora outputs
output "aurora_cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster"
  value       = module.rds_aurora.cluster_endpoint
  sensitive   = true
}

output "aurora_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster"
  value       = module.rds_aurora.reader_endpoint
  sensitive   = true
}

output "aurora_cluster_id" {
  description = "Identifier of the Aurora cluster"
  value       = module.rds_aurora.cluster_id
}

# --- CloudFront / WAF outputs
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cdn_waf.distribution_id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cdn_waf.domain_name
}

output "waf_web_acl_id" {
  description = "ID of the WAF v2 WebACL"
  value       = module.cdn_waf.web_acl_id
}

# --- Security outputs
output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = module.security.guardduty_detector_id
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = module.security.cloudtrail_arn
}
