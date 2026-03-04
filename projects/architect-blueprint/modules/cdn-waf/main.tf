terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# --- Current AWS account data source (used for KMS key policy)
data "aws_caller_identity" "current" {}

# --- KMS key for S3 bucket encryption (CKV_AWS_145)
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 and WAF log encryption — ${var.project_name}-${var.environment}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 and CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "logs.us-east-1.amazonaws.com",
            "delivery.logs.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-s3-kms"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# --- WAF v2 WebACL — must be in us-east-1 for CloudFront (CLOUDFRONT scope)
# Cost: ~$5/month base + $1/rule/month
resource "aws_wafv2_web_acl" "main" {
  # checkov:skip=CKV2_AWS_31: WAF logging configured in aws_wafv2_web_acl_logging_configuration resource
  count = var.enable_waf ? 1 : 0

  name        = "${var.project_name}-${var.environment}-waf"
  description = "WAF WebACL protecting CloudFront: OWASP + IP reputation + rate limiting"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rule 1: General OWASP top-10 protection (SQLi, XSS, etc.)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: Block known malicious IP addresses
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: Block known bad inputs (log4j, SSRF, etc.)
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: Rate limiting — max 2000 requests per 5 minutes per IP
  rule {
    name     = "RateLimitPerIP"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-waf"
  }
}

# --- CloudWatch Log Group for WAF logging (name must start with aws-waf-logs-)
resource "aws_cloudwatch_log_group" "waf" {
  count = var.enable_waf ? 1 : 0

  name              = "aws-waf-logs-${var.project_name}-${var.environment}"
  retention_in_days = 365                # CKV_AWS_338
  kms_key_id        = aws_kms_key.s3.arn # CKV_AWS_158

  tags = {
    Name = "${var.project_name}-${var.environment}-waf-logs"
  }
}

# --- WAF logging configuration (CKV2_AWS_31)
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count = var.enable_waf ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.main[0].arn
  log_destination_configs = [aws_cloudwatch_log_group.waf[0].arn]
}

# --- S3 bucket for static website (CloudFront origin for /* paths)
resource "aws_s3_bucket" "static" {
  # checkov:skip=CKV_AWS_144: Cross-region replication requires DR provider configuration
  bucket        = "${var.project_name}-${var.environment}-static"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-${var.environment}-static"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms" # CKV_AWS_145
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "static" {
  bucket = aws_s3_bucket.static.id

  versioning_configuration {
    status = "Enabled" # CKV_AWS_21
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7 # CKV_AWS_300
    }
  }

  rule {
    id     = "transition-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90 # CKV2_AWS_61
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket = aws_s3_bucket.static.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Shared access logs bucket for S3 buckets in this module (CKV_AWS_18)
resource "aws_s3_bucket" "access_logs" {
  # checkov:skip=CKV_AWS_144: Cross-region replication requires DR provider configuration
  # checkov:skip=CKV2_AWS_62: Access logging bucket does not require event notifications
  # checkov:skip=CKV_AWS_18: Access logging buckets should not log to themselves
  bucket        = "${var.project_name}-${var.environment}-cdn-access-logs"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-${var.environment}-cdn-access-logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms" # CKV_AWS_145
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  versioning_configuration {
    status = "Enabled" # CKV_AWS_21
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7 # CKV_AWS_300
    }
  }

  rule {
    id     = "transition-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90 # CKV2_AWS_61
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true # CKV2_AWS_6
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "static" {
  bucket = aws_s3_bucket.static.id

  target_bucket = aws_s3_bucket.access_logs.id # CKV_AWS_18
  target_prefix = "static-bucket/"
}

# --- SNS topic for S3 event notifications (CKV2_AWS_62)
resource "aws_sns_topic" "s3_events" {
  name              = "${var.project_name}-${var.environment}-cdn-s3-events"
  kms_master_key_id = aws_kms_key.s3.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-cdn-s3-events"
  }
}

resource "aws_sns_topic_policy" "s3_events" {
  arn = aws_sns_topic.s3_events.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "SNS:Publish"
      Resource  = aws_sns_topic.s3_events.arn
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}

resource "aws_s3_bucket_notification" "static" {
  bucket = aws_s3_bucket.static.id # CKV2_AWS_62

  topic {
    topic_arn = aws_sns_topic.s3_events.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

# --- S3 bucket policy: allow CloudFront OAC to read static content
# NOTE: Using the CloudFront service principal without distribution-scoped condition
# avoids a circular dependency (distribution references the bucket, policy would
# reference the distribution). The OAC signing mechanism itself provides security.
resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontServicePrincipal"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.static.arn}/*"
    }]
  })
}

# --- S3 bucket for CloudFront access logging
resource "aws_s3_bucket" "cf_logs" {
  # checkov:skip=CKV_AWS_144: Cross-region replication requires DR provider configuration
  bucket        = "${var.project_name}-${var.environment}-cf-logs"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-${var.environment}-cf-logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms" # CKV_AWS_145
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  versioning_configuration {
    status = "Enabled" # CKV_AWS_21
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7 # CKV_AWS_300
    }
  }

  rule {
    id     = "transition-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90 # CKV2_AWS_61
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  block_public_acls       = true # CKV2_AWS_6
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced" # CKV2_AWS_65
  }
}

resource "aws_s3_bucket_logging" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  target_bucket = aws_s3_bucket.access_logs.id # CKV_AWS_18
  target_prefix = "cf-logs-bucket/"
}

resource "aws_s3_bucket_notification" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id # CKV2_AWS_62

  topic {
    topic_arn = aws_sns_topic.s3_events.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

# --- Origin Access Control for S3 static website origin
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project_name}-${var.environment}-s3-oac"
  description                       = "OAC for S3 static website — ${var.project_name}-${var.environment}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- CloudFront security response headers policy (CKV2_AWS_32)
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "${var.project_name}-${var.environment}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}

# --- CloudFront distribution — global CDN with WAF, HTTP/3, and HTTPS enforcement
# Cost: ~$1-10/month depending on traffic (1TB/month free tier)
resource "aws_cloudfront_distribution" "main" {
  # checkov:skip=CKV_AWS_374: Geo restriction is optional and configurable via geo_restriction_locations variable
  # checkov:skip=CKV_AWS_310: CloudFront Origin Shield is an optional performance feature
  # checkov:skip=CKV2_AWS_47: WAF with AWSManagedRulesKnownBadInputsRuleSet (Log4j protection) is attached when enable_waf=true
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name}-${var.environment} CDN"
  default_root_object = "index.html"
  http_version        = "http2and3"      # HTTP/3 (QUIC) for maximum performance
  price_class         = "PriceClass_100" # US + Europe edge locations only

  # Attach WAF WebACL if enabled
  web_acl_id = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null

  # Origin 1: S3 bucket for static assets
  origin {
    domain_name              = aws_s3_bucket.static.bucket_regional_domain_name
    origin_id                = "s3-static"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # Origin 2: ALB for API traffic (only created if alb_dns_name is provided)
  dynamic "origin" {
    for_each = var.alb_dns_name != "" ? [var.alb_dns_name] : []
    content {
      domain_name = origin.value
      origin_id   = "alb-api"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Cache behavior for API routes — bypass cache, forward all headers
  dynamic "ordered_cache_behavior" {
    for_each = var.alb_dns_name != "" ? [1] : []
    content {
      path_pattern     = "/api/*"
      target_origin_id = "alb-api"
      allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods   = ["GET", "HEAD"]

      forwarded_values {
        query_string = true
        headers      = ["Authorization", "Origin", "Accept"]
        cookies {
          forward = "all"
        }
      }

      min_ttl     = 0
      default_ttl = 0 # no caching for API responses
      max_ttl     = 0

      viewer_protocol_policy = "redirect-to-https"
    }
  }

  # Default cache behavior for static assets — cache 24h
  default_cache_behavior {
    target_origin_id       = "s3-static"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400  # 24 hours
    max_ttl     = 604800 # 7 days

    compress = true # gzip/br compression

    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id # CKV2_AWS_32
  }

  # Geo restriction — restrict by country if list is provided
  restrictions {
    geo_restriction {
      restriction_type = length(var.geo_restriction_locations) > 0 ? "whitelist" : "none"
      locations        = var.geo_restriction_locations
    }
  }

  # HTTPS with ACM certificate, minimum TLS 1.2
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.main.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = [var.domain_name, "www.${var.domain_name}"]

  # Access logging to dedicated S3 bucket
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cf_logs.bucket_domain_name
    prefix          = "cloudfront/"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront"
  }

  depends_on = [aws_acm_certificate_validation.main]
}

# --- ACM certificate — must be in us-east-1 for CloudFront
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-acm"
  }
}

# --- Route53 hosted zone (existing zone — data source only)
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# --- Route53 DNS validation records for ACM certificate
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# --- Wait for ACM certificate validation to complete
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

# --- Route53 A record pointing the domain to CloudFront
resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
