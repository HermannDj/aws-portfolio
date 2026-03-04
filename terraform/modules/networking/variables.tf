# ─────────────────────────────────────────────────────────────────────────────
# modules/networking/variables.tf — Variables du module Networking
# modules/networking/variables.tf — Networking module variables
# ─────────────────────────────────────────────────────────────────────────────

variable "project_name" {
  description = "Nom du projet pour les noms et tags de ressources / Project name for resource names and tags"
  type        = string
}

variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod) / Deployment environment (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "Bloc CIDR du VPC / VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Liste des blocs CIDR pour les subnets publics / List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Liste des blocs CIDR pour les subnets privés / List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "enable_nat_gateway" {
  description = "Activer la NAT Gateway pour les subnets privés (coûts supplémentaires) / Enable NAT Gateway for private subnets (additional costs)"
  type        = bool
  default     = false
}
