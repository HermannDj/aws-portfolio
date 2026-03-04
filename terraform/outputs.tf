# ─────────────────────────────────────────────────────────────────────────────
# outputs.tf — Sorties du module racine
# outputs.tf — Root module outputs
#
# Ces valeurs sont affichées après un `terraform apply` réussi.
# These values are displayed after a successful `terraform apply`.
# Elles peuvent être référencées par d'autres configurations Terraform.
# They can be referenced by other Terraform configurations.
# ─────────────────────────────────────────────────────────────────────────────

# ─── Outputs du module Networking ─────────────────────────────────────────────

output "vpc_id" {
  description = "Identifiant unique du VPC créé / Unique identifier of the created VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Liste des IDs des subnets publics / List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Liste des IDs des subnets privés / List of private subnet IDs"
  value       = module.networking.private_subnet_ids
}

# ─── Outputs du module EC2 ────────────────────────────────────────────────────

output "ec2_instance_id" {
  description = "Identifiant de l'instance EC2 / EC2 instance identifier"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Adresse IP publique de l'instance EC2 / Public IP address of the EC2 instance"
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "Nom DNS public de l'instance EC2 / Public DNS name of the EC2 instance"
  value       = module.ec2.public_dns
}

# ─── Outputs du module S3 ─────────────────────────────────────────────────────

output "s3_bucket_name" {
  description = "Nom du bucket S3 créé / Name of the created S3 bucket"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN du bucket S3 (Amazon Resource Name) / ARN of the S3 bucket (Amazon Resource Name)"
  value       = module.s3.bucket_arn
}

output "s3_bucket_domain_name" {
  description = "Nom de domaine du bucket S3 / S3 bucket domain name"
  value       = module.s3.bucket_domain_name
}
