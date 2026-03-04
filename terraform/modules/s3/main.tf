# ─────────────────────────────────────────────────────────────────────────────
# modules/s3/main.tf — Module S3
# modules/s3/main.tf — S3 Module
#
# Ce module crée un bucket S3 sécurisé avec :
# This module creates a secure S3 bucket with:
#   - Versioning activé / Enabled versioning
#   - Chiffrement côté serveur AES256 / AES256 server-side encryption
#   - Blocage total de l'accès public / Complete public access blocking
#   - Règles de cycle de vie / Lifecycle rules
#   - Politique HTTPS uniquement / HTTPS-only policy
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# Bucket S3
# S3 Bucket
# Le bucket est la ressource de base — toutes les autres ressources s'y rattachent
# The bucket is the base resource — all other resources are attached to it
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
  }

  # Empêcher la destruction accidentelle du bucket (données importantes)
  # Prevent accidental destruction of the bucket (important data)
  lifecycle {
    prevent_destroy = false # Mettre à true en production / Set to true in production
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Versioning du bucket S3
# S3 Bucket Versioning
# Le versioning conserve toutes les versions d'un objet pour récupération
# Versioning keeps all versions of an object for recovery
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    # Activer le versioning / Enable versioning
    status = "Enabled"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Chiffrement côté serveur
# Server-Side Encryption
# Chiffre automatiquement tous les objets avec AES256 (gratuit)
# Automatically encrypts all objects with AES256 (free)
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      # AES256 = chiffrement géré par AWS, gratuit
      # AES256 = AWS-managed encryption, free
      sse_algorithm = "AES256"
    }

    # Forcer le chiffrement sur tous les nouveaux objets
    # Force encryption on all new objects
    bucket_key_enabled = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Blocage de l'accès public
# Public Access Block
# Bloque TOUTES les formes d'accès public au bucket et aux objets
# Blocks ALL forms of public access to the bucket and objects
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  # Bloquer les ACLs publiques / Block public ACLs
  block_public_acls = true

  # Ignorer les ACLs publiques existantes / Ignore existing public ACLs
  ignore_public_acls = true

  # Bloquer les politiques de bucket publiques / Block public bucket policies
  block_public_policy = true

  # Restreindre l'accès public aux buckets / Restrict public bucket access
  restrict_public_buckets = true
}

# ─────────────────────────────────────────────────────────────────────────────
# Configuration du cycle de vie
# Lifecycle Configuration
# Optimise les coûts en déplaçant automatiquement les objets vers des classes moins chères
# Optimizes costs by automatically moving objects to cheaper storage classes
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  # Cette configuration dépend du versioning
  # This configuration depends on versioning
  depends_on = [aws_s3_bucket_versioning.main]

  # ─── Règle pour les objets courants ──────────────────────────────────────
  # Rule for current objects
  rule {
    id     = "transition-and-expire-objects"
    status = "Enabled"

    # Filtre : s'applique à tous les objets (préfixe vide)
    # Filter: applies to all objects (empty prefix)
    filter {
      prefix = ""
    }

    # Transition vers STANDARD_IA après 30 jours
    # Transition to STANDARD_IA after 30 days
    # STANDARD_IA = Infrequent Access, moins cher que STANDARD pour les données peu accédées
    # STANDARD_IA = Infrequent Access, cheaper than STANDARD for infrequently accessed data
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Expiration après 365 jours (suppression automatique)
    # Expiration after 365 days (automatic deletion)
    expiration {
      days = 365
    }
  }

  # ─── Règle pour les anciennes versions (versioning) ──────────────────────
  # Rule for old versions (versioning)
  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # Expiration des anciennes versions après 90 jours
    # Expiration of old versions after 90 days
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Politique du bucket — HTTPS uniquement
# Bucket Policy — HTTPS only
# Refuse tout accès non chiffré (HTTP) au bucket
# Refuses all unencrypted access (HTTP) to the bucket
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  # La politique dépend du blocage d'accès public (doit être configuré avant)
  # The policy depends on public access block (must be configured first)
  depends_on = [aws_s3_bucket_public_access_block.main]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Identifiant unique de la règle / Unique rule identifier
        Sid    = "DenyNonHTTPS"
        Effect = "Deny"

        # S'applique à tous les principals (utilisateurs, rôles, services)
        # Applies to all principals (users, roles, services)
        Principal = "*"

        # Toutes les actions S3 / All S3 actions
        Action = "s3:*"

        # S'applique à tous les objets du bucket / Applies to all objects in the bucket
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]

        # Condition : refuser si la connexion n'est PAS HTTPS
        # Condition: deny if connection is NOT HTTPS
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
