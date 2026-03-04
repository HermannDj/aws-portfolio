output "sns_topic_arn" {
  description = "ARN of the SNS topic used for alert notifications"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "Name of the main CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "budget_name" {
  description = "Name of the AWS Budgets budget"
  value       = aws_budgets_budget.monthly.name
}

output "xray_group_arn" {
  description = "ARN of the X-Ray group for distributed tracing"
  value       = aws_xray_group.main.arn
}
