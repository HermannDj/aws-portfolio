output "api_base_url" {
  description = "Base URL of the deployed API Gateway stage."
  value       = "${aws_api_gateway_stage.main.invoke_url}/items"
}

output "api_id" {
  description = "API Gateway REST API ID."
  value       = aws_api_gateway_rest_api.main.id
}

output "lambda_function_name" {
  description = "Name of the deployed Lambda function."
  value       = aws_lambda_function.api.function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function."
  value       = aws_lambda_function.api.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table."
  value       = aws_dynamodb_table.items.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table."
  value       = aws_dynamodb_table.items.arn
}

output "cloudwatch_log_group_lambda" {
  description = "CloudWatch log group for the Lambda function."
  value       = aws_cloudwatch_log_group.lambda.name
}
