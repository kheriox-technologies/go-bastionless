variable "aws_region" {
  description = "AWS region used to deploy AWS resources"
  default     = "ap-southeast-2"
}

variable "app_name" {}
variable "vpc_id" {}
variable "vpc_cidr" {}
variable "private_subnet" {}
variable "public_subnet" {}
variable "root_block_device" {
  default = {
    type = "gp2",
    size = "10"
  }
}
variable "my_ip" {}
variable "managed_policies" {
  default = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}
variable "instance_type" {
  default = "t2.small"
}

variable "vpc_endpoints" {
  default = [
    "com.amazonaws.ap-southeast-2.ssm",
    "com.amazonaws.ap-southeast-2.ec2messages",
    "com.amazonaws.ap-southeast-2.ec2",
    "com.amazonaws.ap-southeast-2.ssmmessages"
  ]
}
