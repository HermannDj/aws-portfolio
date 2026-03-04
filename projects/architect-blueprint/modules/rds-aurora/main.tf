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

# --- KMS key dedicated to Aurora storage encryption
resource "aws_kms_key" "aurora" {
  description             = "KMS key for Aurora PostgreSQL encryption — ${var.project_name}-${var.environment}"
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
        Sid    = "Allow RDS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
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
    Name = "${var.project_name}-${var.environment}-aurora-kms"
  }
}

resource "aws_kms_alias" "aurora" {
  name          = "alias/${var.project_name}-${var.environment}-aurora"
  target_key_id = aws_kms_key.aurora.key_id
}

# --- Security group for Aurora — ingress only from EKS worker nodes on port 5432
resource "aws_security_group" "aurora" {
  name        = "${var.project_name}-${var.environment}-aurora-sg"
  description = "Aurora PostgreSQL: allow inbound from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS worker nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
  }

  # No egress rule — Aurora does not need outbound internet access

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-sg"
  }
}

# --- DB subnet group — registers isolated database subnets with Aurora
resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-${var.environment}-aurora-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-subnet-group"
  }
}

# --- Secrets Manager secret for Aurora credentials (fallback if not using manage_master_user_password)
resource "aws_secretsmanager_secret" "aurora" {
  # checkov:skip=CKV2_AWS_57: Rotation requires dedicated Lambda; managed via aws_rds_cluster manage_master_user_password instead
  name        = "${var.project_name}/${var.environment}/aurora/credentials"
  description = "Aurora PostgreSQL master credentials for ${var.project_name}-${var.environment}"
  kms_key_id  = aws_kms_key.aurora.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-secret"
  }
}

resource "aws_secretsmanager_secret_version" "aurora" {
  secret_id = aws_secretsmanager_secret.aurora.id
  secret_string = jsonencode({
    username = var.master_username
    dbname   = var.database_name
    engine   = "aurora-postgresql"
    port     = 5432
    host     = aws_rds_cluster.main.endpoint
  })

  lifecycle {
    ignore_changes = [secret_string] # managed externally after initial creation
  }
}

# --- IAM role for RDS Enhanced Monitoring (publishes OS-level metrics to CloudWatch)
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# --- Aurora cluster parameter group with query logging (CKV2_AWS_27)
resource "aws_rds_cluster_parameter_group" "aurora" {
  name        = "${var.project_name}-${var.environment}-aurora-pg"
  family      = var.aurora_parameter_group_family
  description = "Aurora PostgreSQL cluster parameter group with query logging"

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-pg"
  }
}

# --- Aurora PostgreSQL cluster — Multi-AZ, encryption, PITR, IAM auth
# Cost: ~$58/month for db.t3.medium writer + reader
resource "aws_rds_cluster" "main" {
  cluster_identifier = "${var.project_name}-${var.environment}-aurora"

  engine         = "aurora-postgresql"
  engine_version = var.aurora_engine_version

  database_name   = var.database_name
  master_username = var.master_username

  # AWS manages the master password and stores it in Secrets Manager
  manage_master_user_password = true

  storage_encrypted = true
  kms_key_id        = aws_kms_key.aurora.arn

  backup_retention_period = var.backup_retention_days
  preferred_backup_window = "03:00-04:00"

  # Protects against accidental terraform destroy in production
  deletion_protection = true

  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Allows authentication using IAM tokens instead of passwords
  iam_database_authentication_enabled = true

  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  vpc_security_group_ids          = [aws_security_group.aurora.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-aurora-final-${var.final_snapshot_suffix}"

  copy_tags_to_snapshot = true # CKV_AWS_313

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora"
  }
}

# --- Aurora cluster instances: instance 0 = writer, instance 1 = reader
resource "aws_rds_cluster_instance" "main" {
  count = 2

  identifier         = "${var.project_name}-${var.environment}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.aurora_instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  db_subnet_group_name = aws_db_subnet_group.aurora.name

  # Performance Insights adds query-level monitoring at no extra cost for 7 days retention
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.aurora.arn # CKV_AWS_354

  # Enhanced Monitoring: OS-level metrics every 60 seconds
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  auto_minor_version_upgrade = true

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-${count.index == 0 ? "writer" : "reader"}"
  }
}

# --- AWS Backup vault and plan for Aurora (CKV2_AWS_8)
resource "aws_backup_vault" "aurora" {
  name        = "${var.project_name}-${var.environment}-aurora-backup-vault"
  kms_key_arn = aws_kms_key.aurora.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-backup-vault"
  }
}

resource "aws_backup_plan" "aurora" {
  name = "${var.project_name}-${var.environment}-aurora-backup"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.aurora.name
    schedule          = "cron(0 2 * * ? *)"

    lifecycle {
      delete_after = 30
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-backup-plan"
  }
}

resource "aws_iam_role" "backup" {
  name = "${var.project_name}-${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_selection" "aurora" {
  name         = "${var.project_name}-${var.environment}-aurora-selection"
  plan_id      = aws_backup_plan.aurora.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [aws_rds_cluster.main.arn]
}
