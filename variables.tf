# Variables for accepting Access Key and Secret key for AWS
# Default region is set to us-east-1
variable "region" {
  default = "us-east-1"
}

variable "images" {
  type = map(string)
  default = {
    mast  = "ami-029ba835ddd43c34f"
    agent = "ami-029ba835ddd43c34f"
  }
}

variable "option_3_aws_admin_ssh_key_name" {
}

variable "option_4_aws_admin_public_ssh_key" {
}

variable "option_7_aws_dev_ssh_key_name" {
}

variable "option_8_aws_dev_public_ssh_key" {
}

variable "option_9_use_rds_database" {
}

variable "option_10_aws_rds_identifier" {
}

variable "option_11_multi_az_rds" {
}

variable "product" {
}

variable "team" {
}

variable "owner" {
}

variable "environment" {
}

variable "organization" {
}

variable "costcenter" {
}

