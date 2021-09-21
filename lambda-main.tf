provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
  default_tags {
    tags = var.tags
  }
}

locals {
  prefix     = var.my_prefix
  subnet_ids = data.aws_subnet_ids.main.ids # FIXME if needed
}

resource "aws_lambda_function" "main" {
  function_name = "${local.prefix}main"
  role          = local.simple_lambda_exec_role_arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.main.repository_url}:${var.image_tag}"
  timeout       = 60

  vpc_config {
    subnet_ids = tolist(local.subnet_ids)
    security_group_ids = [
      aws_security_group.main.id
    ]
  }

  lifecycle {
    ignore_changes = [image_uri]
  }

  depends_on = [
    aws_ecr_repository.main,
  ]
}

resource "aws_ecr_repository" "main" {
  name                 = "${local.prefix}main"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_security_group" "main" {
  name        = "${local.prefix}main"
  description = "${local.prefix}main Kinesis Firehose sample."
  vpc_id      = data.aws_vpc.main.id
}

# simple role to execute lambda.
resource "aws_iam_role" "lambda-exec" {
  name               = "${local.prefix}lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda-exec.json
}

data "aws_iam_policy_document" "lambda-exec" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

locals {
  managedRoles = [
    "AWSLambdaVPCAccessExecutionRole",
  ]
}

resource "aws_iam_role_policy_attachment" "lambda-exec" {
  count      = length(local.managedRoles)
  role       = aws_iam_role.lambda-exec.id
  policy_arn = data.aws_iam_policy.lambda-exec[count.index].arn
}

data "aws_iam_policy" "lambda-exec" {
  count = length(local.managedRoles)
  name  = local.managedRoles[count.index]
}

