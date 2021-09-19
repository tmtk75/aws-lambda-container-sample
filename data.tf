data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
  tags   = var.subnet_ids_tags
}

data "aws_vpc" "main" {
  id = var.vpc_id
}
