# ─────────────────────────────────────────────────────────────────────────────
# main.tf — Orchestration des modules Terraform
# main.tf — Terraform modules orchestration
#
# Ce fichier instancie les 3 modules qui composent l'infrastructure :
# This file instantiates the 3 modules that make up the infrastructure:
#   1. networking — VPC, Subnets, IGW, NAT GW, Route Tables
#   2. ec2        — Instance EC2, Security Group, IAM Role
#   3. s3         — Bucket S3 sécurisé avec versioning et chiffrement
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# Module 1 : Networking
# Crée l'infrastructure réseau complète (VPC, subnets, IGW, NAT GW, routes)
# Creates the complete network infrastructure (VPC, subnets, IGW, NAT GW, routes)
# ─────────────────────────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  # Identifiants du projet pour les noms et tags de ressources
  # Project identifiers for resource names and tags
  project_name = var.project_name
  environment  = var.environment

  # Configuration du VPC et des subnets
  # VPC and subnets configuration
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  # Activation conditionnelle de la NAT Gateway (coûts supplémentaires)
  # Conditional activation of NAT Gateway (additional costs)
  enable_nat_gateway = var.enable_nat_gateway
}

# ─────────────────────────────────────────────────────────────────────────────
# Module 2 : EC2
# Crée l'instance EC2, le Security Group et le rôle IAM
# Creates the EC2 instance, Security Group and IAM role
# ─────────────────────────────────────────────────────────────────────────────
module "ec2" {
  source = "./modules/ec2"

  # Identifiants du projet
  # Project identifiers
  project_name = var.project_name
  environment  = var.environment

  # Réseau : l'instance est déployée dans le premier subnet public
  # Network: instance is deployed in the first public subnet
  vpc_id    = module.networking.vpc_id
  subnet_id = module.networking.public_subnet_ids[0]

  # Type d'instance Free Tier
  # Free Tier instance type
  instance_type = var.ec2_instance_type

  # Sécurité SSH (restreindre en production)
  # SSH security (restrict in production)
  allowed_ssh_cidr = var.allowed_ssh_cidr

  # Paire de clés SSH (optionnel, SSM préféré)
  # SSH key pair (optional, SSM preferred)
  enable_key_pair     = var.enable_key_pair
  public_key_material = var.public_key_material

  # Dépendance explicite sur le module networking
  # Explicit dependency on networking module
  depends_on = [module.networking]
}

# ─────────────────────────────────────────────────────────────────────────────
# Module 3 : S3
# Crée le bucket S3 sécurisé avec versioning, chiffrement et lifecycle
# Creates the secure S3 bucket with versioning, encryption and lifecycle
# ─────────────────────────────────────────────────────────────────────────────
module "s3" {
  source = "./modules/s3"

  # Identifiants du projet
  # Project identifiers
  project_name = var.project_name
  environment  = var.environment

  # Nom du bucket (doit être globalement unique sur AWS)
  # Bucket name (must be globally unique on AWS)
  bucket_name = var.s3_bucket_name
}
