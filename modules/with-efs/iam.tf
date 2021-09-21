/* */
resource "aws_iam_role" "efs" {
  name               = "${local.prefix}efs"
  assume_role_policy = data.aws_iam_policy_document.efs.json
}

data "aws_iam_policy_document" "efs" {
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
    "AmazonElasticFileSystemClientReadWriteAccess"
  ]
}

resource "aws_iam_role_policy_attachment" "efs" {
  count      = length(local.managedRoles)
  role       = aws_iam_role.efs.id
  policy_arn = data.aws_iam_policy.efs[count.index].arn
}

data "aws_iam_policy" "efs" {
  count = length(local.managedRoles)
  name  = local.managedRoles[count.index]
}
