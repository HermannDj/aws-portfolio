output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_certificate_authority" {
  description = "Base64-encoded certificate authority data for the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider (used for IRSA — IAM Roles for Service Accounts)"
  value       = aws_iam_openid_connect_provider.main.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = aws_iam_openid_connect_provider.main.url
}

output "node_security_group_id" {
  description = "ID of the security group attached to EKS worker nodes"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_role_arn" {
  description = "ARN of the IAM role used by the EKS control plane"
  value       = aws_iam_role.cluster.arn
}
