output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : ""
}

output "cloudtrail_arn" {
  description = "ARN of the multi-region CloudTrail trail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : ""
}

output "kms_key_arn" {
  description = "ARN of the master KMS key used for encryption"
  value       = aws_kms_key.master.arn
}

output "security_hub_id" {
  description = "AWS Security Hub account ID (empty if disabled)"
  value       = var.enable_security_hub ? aws_securityhub_account.main[0].id : ""
}
