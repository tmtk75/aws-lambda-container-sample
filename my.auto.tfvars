#
aws_profile       = "kii-dev"
vpc_id            = "vpc-0ff40b3034b22ac0e"
security_group_id = "sg-00113751da54e59d0"

#
my_prefix = "issue8432-" # Fill your unique string to be used for a few created resources like s3 bucket, kinesis firehose, security group, etc.

#
tags = {
  Environment = "issue8432"
}
