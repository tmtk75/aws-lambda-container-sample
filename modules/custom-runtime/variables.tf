variable "prefix" {}

variable "lambda_config" {
  type = object({
    role_arn : string,
    subnet_ids : list(string),
    security_group_ids : list(string)

  })
  default = {
    role_arn           = ""
    subnet_ids         = []
    security_group_ids = []
  }
}
