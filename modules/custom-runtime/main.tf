locals {
  prefix     = var.prefix
  source_dir = "layers/bash"
}

resource "aws_lambda_function" "custom" {
  filename         = data.archive_file.custom-function.output_path
  source_code_hash = data.archive_file.custom-function.output_base64sha256
  runtime          = "provided.al2"
  handler          = "function.handler" # if miss-match, you wil get "line 6: /var/task/foobar.sh: No such file or directory"
  timeout          = 30
  function_name    = "${local.prefix}custom"
  role             = var.lambda_config.role_arn

  layers = [aws_lambda_layer_version.bash-runtime.arn]

  vpc_config {
    subnet_ids         = var.lambda_config.subnet_ids
    security_group_ids = var.lambda_config.security_group_ids
  }
}

data "archive_file" "bash-runtime" {
  type        = "zip"
  source_dir  = local.source_dir
  output_path = "${local.source_dir}.zip"
}

resource "aws_cloudwatch_log_group" "log" {
  name = "/aws/lambda/${aws_lambda_function.custom.function_name}"
}

data "archive_file" "custom-function" {
  type        = "zip"
  source_dir  = "functions/bash"
  output_path = "functions/bash.zip"
}

resource "aws_lambda_layer_version" "bash-runtime" {
  filename         = data.archive_file.bash-runtime.output_path
  layer_name       = "${local.prefix}bash-runtime"
  source_code_hash = data.archive_file.bash-runtime.output_base64sha256
}

resource "aws_cloudwatch_event_rule" "periodic" {
  name        = "${local.prefix}custom-periodic"
  description = ""
  #schedule_expression = "cron(0 * * * ? *)" # cron(0 20 * * ? *) or rate(5 minutes).
  schedule_expression = "rate(120 minutes)"
}

resource "aws_cloudwatch_event_target" "periodic" {
  rule = aws_cloudwatch_event_rule.periodic.name
  arn  = aws_lambda_function.custom.arn
  input_transformer {
    input_template = <<EOT
{
  "commands": [
    "ls /"
  ]
}
EOT
  }

  depends_on = [
    aws_lambda_permission.lambda-custom
  ]
}

resource "aws_lambda_permission" "lambda-custom" {
  statement_id  = "${local.prefix}lambda-custom"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.custom.arn
  #principal     = "events.${local.region}.amazonaws.com" # NOTE: if region is given, you will get "InvalidParameterValueException: The provided principal was invalid. Please check the principal and try again."
  principal  = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.periodic.arn
}
