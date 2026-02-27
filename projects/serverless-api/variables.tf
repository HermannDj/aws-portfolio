variable "aws_region" {
  type        = string
  description = "AWS region where resources will be deployed."
  default     = "ca-central-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier (e.g. ca-central-1)."
  }
}

variable "project_name" {
  type        = string
  description = "Short name used as a prefix for all resource names."
  default     = "serverless-api"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 4–30 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev | staging | prod)."
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  type        = string
  description = "Team or individual responsible for this stack (used for tagging)."
  default     = "platform-team"
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log group retention in days."
  default     = 14

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365], var.log_retention_days)
    error_message = "log_retention_days must be one of the values allowed by AWS (1,3,5,7,14,30,60,90,120,150,180,365)."
  }
}

variable "lambda_memory_mb" {
  type        = number
  description = "Memory allocated to the Lambda function (MB)."
  default     = 256

  validation {
    condition     = var.lambda_memory_mb >= 128 && var.lambda_memory_mb <= 10240
    error_message = "lambda_memory_mb must be between 128 and 10240 MB."
  }
}

variable "lambda_timeout_seconds" {
  type        = number
  description = "Maximum execution time for the Lambda function (seconds)."
  default     = 30

  validation {
    condition     = var.lambda_timeout_seconds >= 1 && var.lambda_timeout_seconds <= 900
    error_message = "lambda_timeout_seconds must be between 1 and 900."
  }
}

variable "dynamodb_billing_mode" {
  type        = string
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)."
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "dynamodb_billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}
