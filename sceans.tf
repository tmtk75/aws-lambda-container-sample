locals {
  lambda_config = {
    role_arn           = local.simple_lambda_exec_role_arn 
    subnet_ids         = tolist(data.aws_subnet_ids.main.ids)
    security_group_ids = [aws_security_group.main.id]
  }
  simple_lambda_exec_role_arn = module.common.lambda_exec_role_arn
  bucket_name                 = "${local.prefix}firehose-target"
  log_group_name              = aws_cloudwatch_log_group.main.name
}

module "firehose" {
  source         = "./modules/firehose"
  prefix         = local.prefix
  log_group_name = local.log_group_name
  image_uri      = "${aws_ecr_repository.main.repository_url}:nodejs"
  lambda_config  = local.lambda_config
  bucket_name    = local.bucket_name
  depends_on = [
    aws_lambda_function.main,
    aws_s3_bucket.bucket,
  ]
}

module "subscribe" {
  source         = "./modules/subscribe"
  prefix         = local.prefix
  log_group_name = local.log_group_name
  image_uri      = "${aws_ecr_repository.main.repository_url}:nodejs"
  lambda_config  = local.lambda_config
  depends_on = [
    aws_lambda_function.main,
    aws_cloudwatch_log_group.main,
  ]
}

module "bash-runtime" {
  source        = "./modules/custom-runtime"
  prefix        = local.prefix
  lambda_config = local.lambda_config
}

module "efs" {
  source        = "./modules/with-efs"
  prefix        = local.prefix
  vpc_id        = var.vpc_id
  lambda_config = local.lambda_config
}

#
# incomplete
#
#module "extension" {
#  source        = "./modules/with-extension"
#  prefix        = local.prefix
#  lambda_config = local.lambda_config
#}
