terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# --- Current AWS region data source (used in CloudWatch dashboard widgets)
data "aws_region" "current" {}

# --- SNS topic for alert notifications
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  tags = {
    Name = "${var.project_name}-${var.environment}-alerts"
  }
}

# --- Email subscription to SNS topic (only created when email is provided)
resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# --- CloudWatch Log Groups for each service (90-day retention)
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/observability/${var.project_name}-${var.environment}/eks"
  retention_in_days = 90
  tags              = { Name = "${var.project_name}-${var.environment}-eks-obs-logs" }
}

resource "aws_cloudwatch_log_group" "aurora" {
  name              = "/aws/observability/${var.project_name}-${var.environment}/aurora"
  retention_in_days = 90
  tags              = { Name = "${var.project_name}-${var.environment}-aurora-obs-logs" }
}

resource "aws_cloudwatch_log_group" "cloudfront" {
  name              = "/aws/observability/${var.project_name}-${var.environment}/cloudfront"
  retention_in_days = 90
  tags              = { Name = "${var.project_name}-${var.environment}-cloudfront-obs-logs" }
}

# --- X-Ray group for distributed tracing across EKS services
resource "aws_xray_group" "main" {
  group_name        = "${var.project_name}-${var.environment}"
  filter_expression = "service(\"${var.project_name}-${var.environment}\")"

  insights_configuration {
    insights_enabled      = true
    notifications_enabled = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-xray-group"
  }
}

# --- Main CloudWatch Dashboard — overview of all services
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-overview"

  dashboard_body = jsonencode({
    widgets = [
      # EKS Node CPU utilization
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "EKS Node CPU Utilization"
          metrics = [["ContainerInsights", "node_cpu_utilization", "ClusterName", var.eks_cluster_name]]
          period  = 300
          stat    = "Average"
          view    = "timeSeries"
          region  = data.aws_region.current.name
        }
      },
      # EKS Node Memory utilization
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "EKS Node Memory Utilization"
          metrics = [["ContainerInsights", "node_memory_utilization", "ClusterName", var.eks_cluster_name]]
          period  = 300
          stat    = "Average"
          view    = "timeSeries"
          region  = data.aws_region.current.name
        }
      },
      # Aurora CPU utilization
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title   = "Aurora CPU Utilization"
          metrics = [["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", var.aurora_cluster_id]]
          period  = 300
          stat    = "Average"
          view    = "timeSeries"
          region  = data.aws_region.current.name
        }
      },
      # Aurora DB Connections
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title   = "Aurora Database Connections"
          metrics = [["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", var.aurora_cluster_id]]
          period  = 300
          stat    = "Sum"
          view    = "timeSeries"
          region  = data.aws_region.current.name
        }
      },
      # CloudFront requests
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 8
        height = 6
        properties = {
          title   = "CloudFront Requests"
          metrics = [["AWS/CloudFront", "Requests", "DistributionId", var.cloudfront_distribution_id, "Region", "Global"]]
          period  = 300
          stat    = "Sum"
          view    = "timeSeries"
          region  = data.aws_region.current.name
        }
      },
      # CloudFront error rates
      {
        type   = "metric"
        x      = 8
        y      = 12
        width  = 8
        height = 6
        properties = {
          title = "CloudFront Error Rates"
          metrics = [
            ["AWS/CloudFront", "5xxErrorRate", "DistributionId", var.cloudfront_distribution_id, "Region", "Global"],
            ["AWS/CloudFront", "4xxErrorRate", "DistributionId", var.cloudfront_distribution_id, "Region", "Global"],
          ]
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          region = data.aws_region.current.name
        }
      },
    ]
  })
}

# --- CloudWatch Alarms: EKS
resource "aws_cloudwatch_metric_alarm" "eks_node_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-eks-node-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EKS node CPU utilization above 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  tags = { Name = "${var.project_name}-${var.environment}-alarm-eks-cpu" }
}

resource "aws_cloudwatch_metric_alarm" "eks_pod_restarts_high" {
  alarm_name          = "${var.project_name}-${var.environment}-eks-pod-restarts-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "pod_number_of_container_restarts"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "EKS pod restart count exceeded 5 in 5 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  tags = { Name = "${var.project_name}-${var.environment}-alarm-eks-restarts" }
}

# --- CloudWatch Alarms: Aurora
resource "aws_cloudwatch_metric_alarm" "aurora_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-aurora-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Aurora CPU utilization above 70%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBClusterIdentifier = var.aurora_cluster_id
  }

  tags = { Name = "${var.project_name}-${var.environment}-alarm-aurora-cpu" }
}

resource "aws_cloudwatch_metric_alarm" "aurora_connections_high" {
  alarm_name          = "${var.project_name}-${var.environment}-aurora-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 800 # ~80% of db.t3.medium max connections (~1000)
  alarm_description   = "Aurora connection count above 80% of maximum"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBClusterIdentifier = var.aurora_cluster_id
  }

  tags = { Name = "${var.project_name}-${var.environment}-alarm-aurora-connections" }
}

resource "aws_cloudwatch_metric_alarm" "aurora_replica_lag_high" {
  alarm_name          = "${var.project_name}-${var.environment}-aurora-replica-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "AuroraReplicaLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 60000 # 60 seconds in milliseconds
  alarm_description   = "Aurora replica lag above 60 seconds — potential read inconsistency"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBClusterIdentifier = var.aurora_cluster_id
  }

  tags = { Name = "${var.project_name}-${var.environment}-alarm-aurora-lag" }
}

# --- CloudWatch Alarms: CloudFront
resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_high" {
  alarm_name          = "${var.project_name}-${var.environment}-cf-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 1 # alert if 5xx rate exceeds 1%
  alarm_description   = "CloudFront 5xx error rate above 1%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
    Region         = "Global"
  }

  tags = { Name = "${var.project_name}-${var.environment}-alarm-cf-5xx" }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_high" {
  alarm_name          = "${var.project_name}-${var.environment}-cf-4xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5 # alert if 4xx rate exceeds 5%
  alarm_description   = "CloudFront 4xx error rate above 5%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
    Region         = "Global"
  }

  tags = { Name = "${var.project_name}-${var.environment}-alarm-cf-4xx" }
}

# --- AWS Budgets — monthly cost alert at 80% and 100% of threshold
resource "aws_budgets_budget" "monthly" {
  name         = "${var.project_name}-${var.environment}-monthly-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.cost_alert_threshold)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.alerts.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.alerts.arn]
  }
}

# --- Log metric filters for security event detection
resource "aws_cloudwatch_log_metric_filter" "http_5xx_errors" {
  name           = "${var.project_name}-${var.environment}-http-5xx-errors"
  pattern        = "[timestamp, requestId, level=\"ERROR\", ...]"
  log_group_name = aws_cloudwatch_log_group.cloudfront.name

  metric_transformation {
    name      = "Http5xxErrorCount"
    namespace = "${var.project_name}/${var.environment}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "failed_login_attempts" {
  name           = "${var.project_name}-${var.environment}-failed-logins"
  pattern        = "?\"Failed password\" ?\"authentication failure\" ?\"Invalid user\""
  log_group_name = aws_cloudwatch_log_group.eks.name

  metric_transformation {
    name      = "FailedLoginAttempts"
    namespace = "${var.project_name}/${var.environment}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "${var.project_name}-${var.environment}-unauthorized-api-calls"
  pattern        = "{ ($.errorCode = \"*UnauthorizedAccess*\") || ($.errorCode = \"AccessDenied*\") }"
  log_group_name = aws_cloudwatch_log_group.cloudfront.name

  metric_transformation {
    name      = "UnauthorizedApiCalls"
    namespace = "${var.project_name}/${var.environment}/Security"
    value     = "1"
  }
}
