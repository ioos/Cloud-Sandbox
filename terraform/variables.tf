variable "preferred_region" {
  description = "Preferred region in which to launch EC2 instances. Defaults to us-east-1"
  type        = string
  default     = "us-east-1"
}
variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "IOOS Cloud Sandbox Terraform Test Instance - Head Node"
}
variable "project_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "IOOS Cloud Sandbox"
}
variable "availability_zone" {
  description = "Availability zone to use"
  type        = string
  default     = "us-east-1a"
}
variable "ssh_cidr" {
  description = "CIDR for the accepted SSH string"
  type = string
}
variable "public_key" {
  description = "Contents of the SSH public key to be used for authentication"
  type = string
}

variable "managed_policies" {
  default = ["arn:aws:iam::aws:policy/AmazonEC2FullAccess",
             "arn:aws:iam::aws:policy/aws-service-role/AmazonFSxServiceRolePolicy",
             "arn:aws:iam::aws:policy/AmazonS3FullAccess"]
}
