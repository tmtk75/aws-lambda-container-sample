variable "prefix" {}
variable "log_group_name" {}
variable "image_uri" {}
variable "lambda_config" {
  default = {
    role_arn           = ""
    subnet_ids         = ""
    security_group_ids = []
  }
}

output "function_name" { value = aws_lambda_function.subscribe.function_name }

locals {
  prefix         = var.prefix
  log_group_name = var.log_group_name
  region         = data.aws_region.current.name
}

resource "aws_lambda_function" "subscribe" {
  function_name = "${local.prefix}subscribe"
  role          = var.lambda_config.role_arn
  package_type  = "Image"
  image_uri     = var.image_uri
  image_config {
    command = ["app.subscribe"]
  }
  timeout = 180

  vpc_config {
    subnet_ids         = var.lambda_config.subnet_ids
    security_group_ids = var.lambda_config.security_group_ids
  }

  lifecycle {
    ignore_changes = [image_uri]
  }
}

data "aws_region" "current" {}

/*
 *
 */
resource "aws_cloudwatch_log_subscription_filter" "lambda-subscribe" {
  name            = "${local.prefix}lambda-subscribe"
  log_group_name  = data.aws_cloudwatch_log_group.lambda-main.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.subscribe.arn
  #role_arn        = aws_iam_role.<...>.arn # instead of add_lambda_function if needed
  depends_on = [
    aws_lambda_permission.lambda-subscribe,
  ]
}

resource "aws_lambda_permission" "lambda-subscribe" {
  statement_id  = "${local.prefix}lambda-subscribe"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.subscribe.arn
  principal     = "logs.${local.region}.amazonaws.com"
  source_arn    = data.aws_cloudwatch_log_group.lambda-main.arn
}

data "aws_cloudwatch_log_group" "lambda-main" {
  name = local.log_group_name
}
