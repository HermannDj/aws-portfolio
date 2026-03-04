# ─────────────────────────────────────────────────────────────────────────────
# modules/s3/variables.tf — Variables du module S3
# modules/s3/variables.tf — S3 module variables
# ─────────────────────────────────────────────────────────────────────────────

variable "project_name" {
  description = "Nom du projet pour les tags / Project name for tags"
  type        = string
}

variable "environment" {
  description = "Environnement de déploiement / Deployment environment"
  type        = string
}

variable "bucket_name" {
  description = "Nom unique du bucket S3 (globalement unique sur AWS) / Unique S3 bucket name (globally unique on AWS)"
  type        = string

  # Validation des règles de nommage AWS S3
  # Validation of AWS S3 naming rules
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*\\.?[a-z0-9-]*){1,61}[a-z0-9]$", var.bucket_name)) && !can(regex("\\.\\.", var.bucket_name))
    error_message = "Le nom du bucket doit avoir entre 3 et 63 caractères, en minuscules, chiffres, tirets ou points / Bucket name must be 3-63 characters, lowercase letters, numbers, hyphens, or dots."
  }
}
