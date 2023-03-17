locals {
  prefix = var.prefix
  managedRoles = [
    "AWSLambdaVPCAccessExecutionRole",
  ]
}

# simple role to execute lambda.
resource "aws_iam_role" "main" {
  name               = "${local.prefix}common"
  assume_role_policy = data.aws_iam_policy_document.main.json
}

resource "aws_iam_role_policy_attachment" "main" {
  count      = length(local.managedRoles)
  role       = aws_iam_role.main.id
  policy_arn = data.aws_iam_policy.main[count.index].arn
}

data "aws_iam_policy" "main" {
  count = length(local.managedRoles)
  name  = local.managedRoles[count.index]
}

data "aws_iam_policy_document" "main" {
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
