variable "aws_profile" {
  description = "Profile name in your ~/.aws/config"
}

variable "aws_region" {
  default = "ap-northeast-1"
}

variable "my_prefix" {
  description = "Your unique string to be used for name of created resource like s3 bucket, kinesis firehose, security group, etc."
}

//variable "iam_role_name" {
//  description = "Name of an IAM role to invoke main lambda."
//}

variable "vpc_id" {
  description = "VPC ID to be used"
}

variable "subnet_ids_tags" {
  type = map(any)
  default = {
    Tier = "Private" # FIXME as your env.
  }
}

variable "image_tag" {
  default     = "nodejs"
  description = "Tag of image to be deployed for main Lambda."
}

variable "tags" {
  description = "Default tags"
}
