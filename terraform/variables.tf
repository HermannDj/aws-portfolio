# ─────────────────────────────────────────────────────────────────────────────
# variables.tf — Variables d'entrée du module racine
# variables.tf — Root module input variables
#
# Toutes les variables sont typées avec des descriptions en français et en anglais.
# All variables are typed with descriptions in French and English.
# Les validations garantissent que les valeurs saisies sont correctes.
# Validations ensure that input values are correct.
# ─────────────────────────────────────────────────────────────────────────────

# ─── Région AWS ───────────────────────────────────────────────────────────────
variable "aws_region" {
  description = "Région AWS où déployer l'infrastructure / AWS region where to deploy the infrastructure"
  type        = string
  default     = "us-east-1"

  # Validation : la région doit être une valeur AWS valide
  # Validation: the region must be a valid AWS value
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "La région AWS doit être au format 'us-east-1', 'eu-west-1', etc. / AWS region must be in format 'us-east-1', 'eu-west-1', etc."
  }
}

# ─── Environnement ────────────────────────────────────────────────────────────
variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod) / Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  # Validation : seuls les environnements autorisés sont acceptés
  # Validation: only allowed environments are accepted
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être 'dev', 'staging' ou 'prod' / Environment must be 'dev', 'staging', or 'prod'."
  }
}

# ─── Nom du projet ────────────────────────────────────────────────────────────
variable "project_name" {
  description = "Nom du projet utilisé dans les tags et les noms de ressources / Project name used in tags and resource names"
  type        = string
  default     = "aws-portfolio"

  # Validation : le nom ne doit contenir que des lettres minuscules, chiffres et tirets
  # Validation: name must contain only lowercase letters, numbers and hyphens
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Le nom du projet ne doit contenir que des lettres minuscules, chiffres et tirets / Project name must contain only lowercase letters, numbers and hyphens."
  }
}

# ─── Configuration réseau VPC ─────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "Bloc CIDR du VPC principal / CIDR block of the main VPC"
  type        = string
  default     = "10.0.0.0/16"

  # Validation : le CIDR doit être un bloc IPv4 valide
  # Validation: CIDR must be a valid IPv4 block
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Le bloc CIDR du VPC doit être une adresse IPv4 CIDR valide / VPC CIDR block must be a valid IPv4 CIDR address."
  }
}

# ─── Subnets publics ──────────────────────────────────────────────────────────
variable "public_subnet_cidrs" {
  description = "Liste des blocs CIDR pour les subnets publics (un par zone de disponibilité) / List of CIDR blocks for public subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  # Validation : il faut au moins un subnet public
  # Validation: at least one public subnet is required
  validation {
    condition     = length(var.public_subnet_cidrs) >= 1
    error_message = "Au moins un subnet public est requis / At least one public subnet is required."
  }
}

# ─── Subnets privés ───────────────────────────────────────────────────────────
variable "private_subnet_cidrs" {
  description = "Liste des blocs CIDR pour les subnets privés (un par zone de disponibilité) / List of CIDR blocks for private subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]

  # Validation : il faut au moins un subnet privé
  # Validation: at least one private subnet is required
  validation {
    condition     = length(var.private_subnet_cidrs) >= 1
    error_message = "Au moins un subnet privé est requis / At least one private subnet is required."
  }
}

# ─── Type d'instance EC2 ──────────────────────────────────────────────────────
variable "ec2_instance_type" {
  description = "Type d'instance EC2 (doit être éligible au Free Tier AWS) / EC2 instance type (must be eligible for AWS Free Tier)"
  type        = string
  default     = "t2.micro"

  # Validation : seuls les types Free Tier sont autorisés pour maîtriser les coûts
  # Validation: only Free Tier types are allowed to control costs
  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3a.micro"], var.ec2_instance_type)
    error_message = "Le type d'instance doit être éligible au Free Tier AWS : t2.micro, t3.micro ou t3a.micro / Instance type must be AWS Free Tier eligible: t2.micro, t3.micro, or t3a.micro."
  }
}

# ─── Nom du bucket S3 ─────────────────────────────────────────────────────────
variable "s3_bucket_name" {
  description = "Nom du bucket S3 (doit être globalement unique sur AWS) / S3 bucket name (must be globally unique on AWS)"
  type        = string
  default     = "app-bucket-hermanndj"

  # Validation : le nom doit respecter les règles de nommage AWS S3
  # Validation: name must follow AWS S3 naming rules
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*\\.?[a-z0-9-]*){1,61}[a-z0-9]$", var.s3_bucket_name)) && !can(regex("\\.\\.", var.s3_bucket_name))
    error_message = "Le nom du bucket S3 doit avoir entre 3 et 63 caractères, en minuscules, chiffres, tirets ou points / S3 bucket name must be 3-63 characters, lowercase letters, numbers, hyphens, or dots."
  }
}

# ─── Activation de la NAT Gateway ────────────────────────────────────────────
variable "enable_nat_gateway" {
  description = "Activer la NAT Gateway pour les subnets privés (ATTENTION: coûts supplémentaires ~$32/mois) / Enable NAT Gateway for private subnets (WARNING: additional costs ~$32/month)"
  type        = bool
  default     = false # Désactivé par défaut pour éviter les frais / Disabled by default to avoid costs
}

# ─── CIDR autorisé pour SSH ───────────────────────────────────────────────────
variable "allowed_ssh_cidr" {
  description = "Bloc CIDR autorisé pour les connexions SSH (restreindre à votre IP en production !) / CIDR block allowed for SSH connections (restrict to your IP in production!)"
  type        = string
  default     = "0.0.0.0/0" # À restreindre en production / Should be restricted in production

  # Validation : le CIDR doit être valide
  # Validation: CIDR must be valid
  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "Le CIDR SSH doit être une adresse IPv4 CIDR valide / SSH CIDR must be a valid IPv4 CIDR address."
  }
}

# ─── Activation de la paire de clés SSH ───────────────────────────────────────
variable "enable_key_pair" {
  description = "Créer et associer une paire de clés SSH à l'instance EC2 / Create and associate an SSH key pair with the EC2 instance"
  type        = bool
  default     = false # Désactivé par défaut (utiliser SSM Session Manager à la place) / Disabled by default (use SSM Session Manager instead)
}

# ─── Clé publique SSH ─────────────────────────────────────────────────────────
variable "public_key_material" {
  description = "Contenu de la clé publique SSH (requis si enable_key_pair = true) / SSH public key content (required if enable_key_pair = true)"
  type        = string
  default     = ""
  sensitive   = false # La clé publique n'est pas sensible / Public key is not sensitive
}
