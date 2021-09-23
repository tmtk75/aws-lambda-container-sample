output "repository_name" {
  value = aws_ecr_repository.main.name
}

output "repository_url" {
  value = aws_ecr_repository.main.repository_url
}

output "lambda_name_main" {
  value = aws_lambda_function.main.function_name
}

output "lambda_name_processor" {
  value = module.firehose.function_name
}

output "lambda_name_subscribe" {
  value = module.subscribe.function_name
}

output "lambda_name_custom" {
  value = module.bash-runtime.function_name
}

output "lambda_name_efs" {
  value = module.efs.function_name
}

output "lambda_name_extension" {
  value = module.extension.function_name
}

output "bucket_name" {
  value = local.bucket_name
}
