# ─────────────────────────────────────────────────────────────────────────────
# modules/networking/outputs.tf — Sorties du module Networking
# modules/networking/outputs.tf — Networking module outputs
#
# Ces valeurs sont exposées aux autres modules qui utilisent ce module.
# These values are exposed to other modules using this module.
# ─────────────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "Identifiant unique du VPC créé / Unique identifier of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "Bloc CIDR du VPC / CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Liste des IDs des subnets publics / List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Liste des IDs des subnets privés / List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "Identifiant de l'Internet Gateway / Internet Gateway identifier"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "Identifiant de la NAT Gateway (null si désactivée) / NAT Gateway identifier (null if disabled)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "public_route_table_id" {
  description = "Identifiant de la table de routage publique / Public route table identifier"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Identifiant de la table de routage privée / Private route table identifier"
  value       = aws_route_table.private.id
}
