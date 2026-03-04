# ─────────────────────────────────────────────────────────────────────────────
# modules/s3/outputs.tf — Sorties du module S3
# modules/s3/outputs.tf — S3 module outputs
# ─────────────────────────────────────────────────────────────────────────────

output "bucket_name" {
  description = "Nom du bucket S3 créé / Name of the created S3 bucket"
  value       = aws_s3_bucket.main.bucket
}

output "bucket_arn" {
  description = "ARN du bucket S3 (Amazon Resource Name) / ARN of the S3 bucket (Amazon Resource Name)"
  value       = aws_s3_bucket.main.arn
}

output "bucket_id" {
  description = "Identifiant du bucket S3 / S3 bucket identifier"
  value       = aws_s3_bucket.main.id
}

output "bucket_domain_name" {
  description = "Nom de domaine du bucket S3 / S3 bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Nom de domaine régional du bucket S3 / S3 bucket regional domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "versioning_status" {
  description = "Statut du versioning du bucket / Bucket versioning status"
  value       = aws_s3_bucket_versioning.main.versioning_configuration[0].status
}
