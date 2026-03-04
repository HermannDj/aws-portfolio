terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# --- Current AWS region and account data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# --- Master KMS key for broad encryption across services
resource "aws_kms_key" "master" {
  description             = "Master KMS key — ${var.project_name}-${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  # CKV2_AWS_64: explicit key policy required
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
        Sid    = "Allow CloudTrail and CloudWatch to use the key"
        Effect = "Allow"
        Principal = {
          Service = [
            "cloudtrail.amazonaws.com",
            "logs.${data.aws_region.current.name}.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-master-kms"
  }
}

resource "aws_kms_alias" "master" {
  name          = "alias/${var.project_name}-${var.environment}-master"
  target_key_id = aws_kms_key.master.key_id
}

# --- EBS encryption by default — all new EBS volumes are encrypted automatically
resource "aws_ebs_encryption_by_default" "main" {
  enabled = true
}

# --- IAM account password policy — CIS benchmark compliant
resource "aws_iam_account_password_policy" "main" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90 # force rotation every 90 days
  password_reuse_prevention      = 24 # cannot reuse last 24 passwords
}

# --- GuardDuty — continuous threat detection with S3, Kubernetes, and malware protection
resource "aws_guardduty_detector" "main" {
  # checkov:skip=CKV2_AWS_3: GuardDuty organization integration requires AWS Organizations setup
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-guardduty"
  }
}

# --- Security Hub — aggregates findings from GuardDuty, Config, Inspector, Macie
resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 1 : 0
}

# --- CIS AWS Foundations Benchmark v1.4.0 standard
resource "aws_securityhub_standards_subscription" "cis" {
  count = var.enable_security_hub ? 1 : 0

  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.4.0"
  depends_on    = [aws_securityhub_account.main]
}

# --- AWS Foundational Security Best Practices
resource "aws_securityhub_standards_subscription" "aws_best_practices" {
  count = var.enable_security_hub ? 1 : 0

  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.main]
}

# --- S3 bucket for CloudTrail logs with 365-day lifecycle
resource "aws_s3_bucket" "cloudtrail" {
  # checkov:skip=CKV_AWS_144: Cross-region replication requires DR provider configuration
  # checkov:skip=CKV_AWS_145: KMS encryption configured in aws_s3_bucket_server_side_encryption_configuration
  # checkov:skip=CKV_AWS_21: Versioning configured in aws_s3_bucket_versioning resource
  # checkov:skip=CKV2_AWS_6: Public access block configured in aws_s3_bucket_public_access_block resource
  # checkov:skip=CKV_AWS_18: Access logging configured in aws_s3_bucket_logging resource
  # checkov:skip=CKV2_AWS_61: Lifecycle noncurrent version expiration in aws_s3_bucket_lifecycle_configuration
  # checkov:skip=CKV2_AWS_62: Event notifications configured in aws_s3_bucket_notification resource
  count = var.enable_cloudtrail ? 1 : 0

  bucket        = "${var.project_name}-${var.environment}-cloudtrail-logs"
  force_destroy = false

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudtrail-logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms" # CKV_AWS_145
      kms_master_key_id = aws_kms_key.master.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  versioning_configuration {
    status = "Enabled" # CKV_AWS_21
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true # CKV2_AWS_6
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    id     = "expire-after-365-days"
    status = "Enabled"

    expiration {
      days = 365
    }
  }

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

resource "aws_s3_bucket_logging" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  target_bucket = aws_s3_bucket.access_logs.id # CKV_AWS_18
  target_prefix = "cloudtrail-bucket/"
}

resource "aws_s3_bucket_notification" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id # CKV2_AWS_62

  topic {
    topic_arn = aws_sns_topic.s3_events.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail[0].arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# --- Shared S3 access logging bucket for all security buckets (CKV_AWS_18)
resource "aws_s3_bucket" "access_logs" {
  # checkov:skip=CKV_AWS_144: Cross-region replication requires DR provider configuration
  # checkov:skip=CKV2_AWS_62: Access logging bucket does not require event notifications
  # checkov:skip=CKV_AWS_18: Access logging buckets should not log to themselves
  bucket        = "${var.project_name}-${var.environment}-security-access-logs"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-${var.environment}-security-access-logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms" # CKV_AWS_145
      kms_master_key_id = aws_kms_key.master.arn
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

# --- SNS topic for S3 event notifications (CKV2_AWS_62)
resource "aws_sns_topic" "s3_events" {
  name              = "${var.project_name}-${var.environment}-s3-events"
  kms_master_key_id = aws_kms_key.master.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-s3-events"
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

# --- SNS topic for CloudTrail alerts (CKV_AWS_252)
resource "aws_sns_topic" "cloudtrail_alerts" {
  count = var.enable_cloudtrail ? 1 : 0

  name              = "${var.project_name}-${var.environment}-cloudtrail-alerts"
  kms_master_key_id = aws_kms_key.master.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudtrail-alerts"
  }
}

# --- CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  name              = "/aws/cloudtrail/${var.project_name}-${var.environment}"
  retention_in_days = var.cloudtrail_log_retention_days
  kms_key_id        = aws_kms_key.master.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudtrail-logs"
  }
}

resource "aws_iam_role" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  name = "${var.project_name}-${var.environment}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  name = "${var.project_name}-${var.environment}-cloudtrail-policy"
  role = aws_iam_role.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
    }]
  })
}

# --- CloudTrail — multi-region audit trail with log integrity validation
resource "aws_cloudtrail" "main" {
  # checkov:skip=CKV2_AWS_10: CloudWatch Logs integration configured via cloud_watch_logs_group_arn attribute
  count = var.enable_cloudtrail ? 1 : 0

  name           = "${var.project_name}-${var.environment}-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail[0].id

  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true # detect tampering via SHA-256 hashes

  kms_key_id = aws_kms_key.master.arn # CKV_AWS_35

  sns_topic_name = aws_sns_topic.cloudtrail_alerts[0].name # CKV_AWS_252

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail[0].arn

  # Capture data events for S3 (all buckets) and Lambda
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudtrail"
  }
}

# --- AWS Config recorder — tracks all resource configuration changes
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-${var.environment}-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "config" {
  name = "${var.project_name}-${var.environment}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# --- S3 bucket for AWS Config delivery
resource "aws_s3_bucket" "config" {
  # checkov:skip=CKV_AWS_144: Cross-region replication requires DR provider configuration
  bucket        = "${var.project_name}-${var.environment}-config-logs"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-${var.environment}-config-logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms" # CKV_AWS_145
      kms_master_key_id = aws_kms_key.master.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id

  versioning_configuration {
    status = "Enabled" # CKV_AWS_21
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket = aws_s3_bucket.config.id

  block_public_acls       = true # CKV2_AWS_6
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "config" {
  bucket = aws_s3_bucket.config.id

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

resource "aws_s3_bucket_logging" "config" {
  bucket = aws_s3_bucket.config.id

  target_bucket = aws_s3_bucket.access_logs.id # CKV_AWS_18
  target_prefix = "config-bucket/"
}

resource "aws_s3_bucket_notification" "config" {
  bucket = aws_s3_bucket.config.id # CKV2_AWS_62

  topic {
    topic_arn = aws_sns_topic.s3_events.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSConfigBucketPermissionsCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.config.arn
      },
      {
        Sid       = "AWSConfigBucketDelivery"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.config.arn}/AWSLogs/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-${var.environment}-config-channel"
  s3_bucket_name = aws_s3_bucket.config.id

  depends_on = [aws_config_configuration_recorder.main]
}

# --- AWS Config managed rules — compliance checks
resource "aws_config_config_rule" "s3_public_read_prohibited" {
  name        = "${var.project_name}-${var.environment}-s3-public-read-prohibited"
  description = "Checks that S3 buckets do not allow public read access"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "restricted_ssh" {
  name        = "${var.project_name}-${var.environment}-restricted-ssh"
  description = "Checks that security groups do not allow unrestricted SSH access"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  input_parameters = jsonencode({ blockedPort1 = "22" })

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "vpc_default_sg_closed" {
  name        = "${var.project_name}-${var.environment}-vpc-default-sg-closed"
  description = "Checks that the default security group of a VPC does not allow inbound or outbound traffic"

  source {
    owner             = "AWS"
    source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}
