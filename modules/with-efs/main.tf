variable "prefix" {}
variable "vpc_id" {}
variable "lambda_config" {
  default = {
    subnet_ids = ""
  }
}

output "function_name" { value = aws_lambda_function.main.function_name }

locals {
  prefix = var.prefix
}

resource "aws_lambda_function" "main" {
  filename         = data.archive_file.ruby.output_path
  source_code_hash = data.archive_file.ruby.output_base64sha256
  runtime          = "ruby2.7"
  handler          = "handler.lambda_handler"
  timeout          = 30
  function_name    = "${local.prefix}efs"
  role             = aws_iam_role.efs.arn

  vpc_config {
    subnet_ids         = var.lambda_config.subnet_ids
    security_group_ids = [aws_security_group.efs.id]
  }

  file_system_config {
    local_mount_path = "/mnt/efs"
    arn              = aws_efs_access_point.lambda.arn
  }

  depends_on = [
    aws_efs_mount_target.alpha
  ]
}

data "archive_file" "ruby" {
  type        = "zip"
  source_dir  = "functions/ruby"
  output_path = "functions/ruby.zip"
}

/*
 * ref: https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/with-efs
 */
resource "aws_efs_file_system" "shared" {}

resource "aws_efs_mount_target" "alpha" {
  count           = length(var.lambda_config.subnet_ids)
  file_system_id  = aws_efs_file_system.shared.id
  subnet_id       = var.lambda_config.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "lambda" {
  file_system_id = aws_efs_file_system.shared.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/home/with-efs"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0777"
    }
  }
}

/*
 * Lambda and EFS communicate at :2049.
 */
resource "aws_security_group" "efs" {
  name        = "${local.prefix}efs"
  description = "${local.prefix}efs."
  vpc_id      = var.vpc_id
}

locals {
  rules = {
    ingress = { type = "ingress", port = 2049, self = true, cidr = [] }
    egress  = { type = "egress", port = 2049, self = false, cidr = ["0.0.0.0/0"] }
  }
}

resource "aws_security_group_rule" "rules" {
  for_each          = local.rules
  type              = each.value.type
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  cidr_blocks       = length(each.value.cidr) == 0 ? null : each.value.cidr
  self              = each.value.self ? true : null
  security_group_id = aws_security_group.efs.id
}
