
variable "aws_profile" {
  type    = string
  default = "lcsb-admin"
}
variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "instance_type" {
  type    = string
  default = "t3.2xlarge"
}

variable "ami_name" {
  type    = string
  default = "skills-image-{{timestamp}}"
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

variable "vpc" {
  type    = string
  default = "vpc-0b008988bcc9ce636"
}
variable "subnet" {
  type    = string
  default = "subnet-0db88d9c9d9a1621c"
}
variable "volume_size" {
  type    = number
  default = 100
}
variable "ami_description" {
  type    = string
  default = "Skills image created by Packer"
}