output "cluster_id" {
  description = "Identifier of the Aurora cluster"
  value       = aws_rds_cluster.main.id
}

output "cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster (use for read-write connections)"
  value       = aws_rds_cluster.main.endpoint
  sensitive   = true
}

output "reader_endpoint" {
  description = "Reader endpoint for load-balanced read-only connections"
  value       = aws_rds_cluster.main.reader_endpoint
  sensitive   = true
}

output "cluster_port" {
  description = "Port the Aurora cluster listens on"
  value       = aws_rds_cluster.main.port
}

output "security_group_id" {
  description = "ID of the security group attached to Aurora instances"
  value       = aws_security_group.aurora.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt Aurora storage"
  value       = aws_kms_key.aurora.arn
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing Aurora credentials"
  value       = aws_secretsmanager_secret.aurora.arn
  sensitive   = true
}
