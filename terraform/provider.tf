# ─────────────────────────────────────────────────────────────────────────────
# provider.tf — Configuration du provider AWS et des exigences Terraform
# provider.tf — AWS provider configuration and Terraform requirements
#
# Ce fichier définit :
# This file defines:
#   - La version minimale de Terraform requise / The minimum required Terraform version
#   - Le provider AWS et sa version / The AWS provider and its version
#   - Les tags par défaut appliqués à toutes les ressources / Default tags applied to all resources
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  # Version minimale de Terraform requise pour ce projet
  # Minimum Terraform version required for this project
  required_version = ">= 1.5.0"

  # Providers requis avec leurs versions contraintes
  # Required providers with constrained versions
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Compatible avec toutes les versions 5.x / Compatible with all 5.x versions
    }
  }
}

# Configuration du provider AWS
# AWS provider configuration
provider "aws" {
  # Région AWS cible — définie dans variables.tf
  # Target AWS region — defined in variables.tf
  region = var.aws_region

  # Tags par défaut appliqués automatiquement à TOUTES les ressources AWS
  # Default tags automatically applied to ALL AWS resources
  # Ceci simplifie la gestion et la facturation par projet/environnement
  # This simplifies management and billing by project/environment
  default_tags {
    tags = {
      # Nom du projet pour regrouper les ressources dans la console AWS
      # Project name to group resources in the AWS console
      Project = var.project_name

      # Environnement de déploiement (dev, staging, prod)
      # Deployment environment (dev, staging, prod)
      Environment = var.environment

      # Indique que ces ressources sont gérées par Terraform (pas manuellement)
      # Indicates these resources are managed by Terraform (not manually)
      ManagedBy = "Terraform"

      # Propriétaire des ressources pour la traçabilité
      # Resource owner for traceability
      Owner = "HermannDj"
    }
  }
}
