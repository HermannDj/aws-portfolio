terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# --- Current AWS region data source
data "aws_region" "current" {}

# --- Master KMS key for broad encryption across services
resource "aws_kms_key" "master" {
  description             = "Master KMS key — ${var.project_name}-${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

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
  count = var.enable_cloudtrail ? 1 : 0

  bucket        = "${var.project_name}-${var.environment}-cloudtrail-logs"
  force_destroy = false

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudtrail-logs"
  }
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
  count = var.enable_cloudtrail ? 1 : 0

  name           = "${var.project_name}-${var.environment}-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail[0].id

  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true # detect tampering via SHA-256 hashes

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
  bucket        = "${var.project_name}-${var.environment}-config-logs"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-${var.environment}-config-logs"
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
