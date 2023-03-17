output "function_name" {
  value = aws_lambda_function.custom.function_name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.log.name
}

