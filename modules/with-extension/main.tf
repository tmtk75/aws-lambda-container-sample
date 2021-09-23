variable "prefix" {}
variable "lambda_config" {
  default = {
    role_arn           = ""
    subnet_ids         = ""
    security_group_ids = []
  }
}
output "function_name" { value = aws_lambda_function.main.function_name }

locals {
  prefix = var.prefix
}

resource "aws_lambda_function" "main" {
  filename         = data.archive_file.main-function.output_path
  source_code_hash = data.archive_file.main-function.output_base64sha256
  runtime          = "provided.al2"
  handler          = "function.handler" # if miss-match, you wil get "line 6: /var/task/foobar.sh: No such file or directory"
  timeout          = 30
  function_name    = "${local.prefix}with-extension"
  role             = var.lambda_config.role_arn

  layers = [aws_lambda_layer_version.logs-api.arn]

  vpc_config {
    subnet_ids         = var.lambda_config.subnet_ids
    security_group_ids = var.lambda_config.security_group_ids
  }
}

data "archive_file" "main-function" {
  type        = "zip"
  source_dir  = "functions/ruby"
  output_path = "functions/ruby.zip"
}

resource "aws_lambda_layer_version" "logs-api" {
  filename         = data.archive_file.logs-api.output_path
  layer_name       = "${local.prefix}extension"
  source_code_hash = data.archive_file.logs-api.output_base64sha256
}

locals {
  source_dir = "layers/logs-api"
}

data "archive_file" "logs-api" {
  type        = "zip"
  source_dir  = local.source_dir
  output_path = "${local.source_dir}.zip"
}

