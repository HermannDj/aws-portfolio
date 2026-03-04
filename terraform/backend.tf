# ─────────────────────────────────────────────────────────────────────────────
# backend.tf — Configuration du backend Terraform (état distant)
# backend.tf — Terraform backend configuration (remote state)
#
# Le backend S3 stocke l'état Terraform de manière distante et sécurisée.
# The S3 backend stores Terraform state remotely and securely.
#
# Prérequis / Prerequisites:
#   1. Créer le bucket S3 manuellement avant le premier `terraform init`
#      Create the S3 bucket manually before the first `terraform init`
#   2. Créer la table DynamoDB pour le verrou d'état
#      Create the DynamoDB table for state locking
#
# Commandes de création / Creation commands:
#   aws s3api create-bucket --bucket terraform-state-hermanndj --region us-east-1
#   aws s3api put-bucket-versioning --bucket terraform-state-hermanndj \
#     --versioning-configuration Status=Enabled
#   aws s3api put-bucket-encryption --bucket terraform-state-hermanndj \
#     --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#   aws dynamodb create-table --table-name terraform-state-lock \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  # Backend S3 pour stocker l'état Terraform de façon distante
  # S3 backend to store Terraform state remotely
  backend "s3" {
    # Nom du bucket S3 contenant l'état / S3 bucket name containing the state
    bucket = "terraform-state-hermanndj"

    # Chemin de l'objet d'état dans le bucket / Path of the state object in the bucket
    key = "aws-portfolio/terraform.tfstate"

    # Région AWS du bucket / AWS region of the bucket
    region = "us-east-1"

    # Chiffrement de l'état au repos / Encrypt state at rest
    encrypt = true

    # Table DynamoDB pour le verrou de l'état (évite les conflits simultanés)
    # DynamoDB table for state locking (prevents simultaneous conflicts)
    dynamodb_table = "terraform-state-lock"
  }
}
