# ─────────────────────────────────────────────────────────────────────────────
# modules/ec2/variables.tf — Variables du module EC2
# modules/ec2/variables.tf — EC2 module variables
# ─────────────────────────────────────────────────────────────────────────────

variable "project_name" {
  description = "Nom du projet pour les noms et tags de ressources / Project name for resource names and tags"
  type        = string
}

variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod) / Deployment environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "Identifiant du VPC dans lequel créer les ressources EC2 / VPC identifier in which to create EC2 resources"
  type        = string
}

variable "subnet_id" {
  description = "Identifiant du subnet dans lequel déployer l'instance EC2 / Subnet identifier in which to deploy the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2 (doit être éligible au Free Tier) / EC2 instance type (must be Free Tier eligible)"
  type        = string
  default     = "t2.micro"
}

variable "allowed_ssh_cidr" {
  description = "Bloc CIDR autorisé pour SSH (restreindre en production !) / CIDR block allowed for SSH (restrict in production!)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "enable_key_pair" {
  description = "Créer et associer une paire de clés SSH / Create and associate an SSH key pair"
  type        = bool
  default     = false
}

variable "public_key_material" {
  description = "Contenu de la clé publique SSH / SSH public key content"
  type        = string
  default     = ""
}
