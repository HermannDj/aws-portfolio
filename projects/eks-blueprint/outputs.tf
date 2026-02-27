output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "API server endpoint of the EKS cluster."
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster."
  value       = aws_eks_cluster.main.version
}

output "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC identity provider."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "lbc_iam_role_arn" {
  description = "ARN of the IAM role used by the AWS Load Balancer Controller (IRSA)."
  value       = aws_iam_role.lbc.arn
}

output "kubeconfig_command" {
  description = "AWS CLI command to update your local kubeconfig."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "sample_ingress_hostname" {
  description = "Hostname of the sample application ALB ingress (may take a few minutes to provision)."
  value       = try(kubernetes_ingress_v1.sample.status[0].load_balancer[0].ingress[0].hostname, "pending")
}
