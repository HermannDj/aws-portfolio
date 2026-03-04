output "distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.id
}

output "domain_name" {
  description = "CloudFront domain name (e.g. d1234.cloudfront.net)"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.arn
}

output "web_acl_id" {
  description = "ID of the WAF v2 WebACL (empty string when WAF is disabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].id : ""
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate attached to the CloudFront distribution"
  value       = aws_acm_certificate.main.arn
}

output "route53_record_fqdn" {
  description = "FQDN of the Route53 record pointing to CloudFront"
  value       = aws_route53_record.main.fqdn
}
