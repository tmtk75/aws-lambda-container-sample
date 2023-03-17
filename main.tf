provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
  default_tags {
    tags = var.tags
  }
}

locals {
  prefix     = var.my_prefix
  subnet_ids = data.aws_subnet_ids.main.ids
  lambda_config = {
    role_arn           = module.common.lambda_exec_role_arn
    subnet_ids         = tolist(data.aws_subnet_ids.main.ids)
    security_group_ids = [data.aws_security_group.main.id]
  }
}

module "common" {
  source = "./modules/common"
  prefix = local.prefix
}

module "bash-runtime" {
  source        = "./modules/custom-runtime"
  prefix        = local.prefix
  lambda_config = local.lambda_config
}


data "aws_security_group" "main" {
  id = var.security_group_id
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
  tags   = var.subnet_ids_tags
}

data "aws_vpc" "main" {
  id = var.vpc_id
}
