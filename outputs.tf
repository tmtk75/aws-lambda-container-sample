output "prefix" {
  value = local.prefix
}

output "lambda_name_custom" {
  value = module.bash-runtime.function_name
}

output "log_group_name" {
  value = module.bash-runtime.log_group_name
}
