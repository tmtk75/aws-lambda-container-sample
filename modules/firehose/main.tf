variable "prefix" {}
variable "log_group_name" {}
variable "image_uri" {}
variable "bucket_name" {}
variable "lambda_config" {
  default = {
    role_arn           = ""
    subnet_ids         = ""
    security_group_ids = []
  }
}

output "function_name" { value = aws_lambda_function.processor.function_name }

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  prefix                = var.prefix
  account_id            = data.aws_caller_identity.current.id
  region                = data.aws_region.current.name
  log_group_name        = var.log_group_name
  kinesis_firehose_name = "${local.prefix}to-s3bucket"
  bucket_arn            = "arn:aws:s3:::${var.bucket_name}"
}

/*
 *
 */
resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  name        = local.kinesis_firehose_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn        = aws_iam_role.firehose.arn
    bucket_arn      = local.bucket_arn
    buffer_size     = 5
    buffer_interval = 60
    prefix          = "fh/"

    #cloudwatch_logging_options {
    #  enabled         = true
    #  log_group_name  = local.log_group_name
    #  log_stream_name = ".*"
    #}

    // fh/owner=!{partitionKeyFromQuery:owner}/!{timestamp:yyyy}/

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.processor.arn}:$LATEST"
        }
      }
    }
  }
}

/*
 * Lambda function as processor.
 */
resource "aws_lambda_function" "processor" {
  function_name = "${local.prefix}processor"
  role          = var.lambda_config.role_arn
  package_type  = "Image"
  image_uri     = var.image_uri
  image_config {
    command = ["app.process"]
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

/*
 * IAM role for firehose
 */
resource "aws_iam_role" "firehose" {
  name = "${local.prefix}_firehose_role"

  assume_role_policy = data.aws_iam_policy_document.firehose-assumerole.json
}

data "aws_iam_policy_document" "firehose-assumerole" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "firehose.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy" "firehose" {
  name   = "${local.prefix}_firehose"
  role   = aws_iam_role.firehose.id
  policy = data.aws_iam_policy_document.firehose.json
}


data "aws_iam_policy_document" "firehose" {
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      local.bucket_arn,
      "${local.bucket_arn}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration"
    ]
    resources = ["${aws_lambda_function.processor.arn}:${aws_lambda_function.processor.version}"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords"
    ]
    resources = [aws_kinesis_firehose_delivery_stream.firehose.arn]
  }
}

/*
 * subscription filter for firehose.
 */
resource "aws_cloudwatch_log_subscription_filter" "firehose" {
  name            = "${local.prefix}filter-for-firehose"
  log_group_name  = local.log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.firehose.arn
  role_arn        = aws_iam_role.filter-for-firehose.arn
  distribution    = "ByLogStream"
}

/*
 * IAM role for the filter.
 */
resource "aws_iam_role" "filter-for-firehose" {
  name               = "${local.prefix}filter-for-firehose"
  assume_role_policy = data.aws_iam_policy_document.filter-for-firehose-assumerole.json
}

data "aws_iam_policy_document" "filter-for-firehose-assumerole" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "logs.${local.region}.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy" "filter-for-firehose" {
  name = "${local.prefix}filter-for-firehose"
  role = aws_iam_role.filter-for-firehose.id

  policy = data.aws_iam_policy_document.filter-for-firehose.json
}

data "aws_iam_policy_document" "filter-for-firehose" {
  statement {
    effect    = "Allow"
    actions   = ["firehose:*"]
    resources = [aws_kinesis_firehose_delivery_stream.firehose.arn]

  }
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.filter-for-firehose.arn]
  }
}
