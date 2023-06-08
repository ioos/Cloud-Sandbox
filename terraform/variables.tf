variable "preferred_region" {
  description = "Preferred region in which to launch EC2 instances. Defaults to us-east-1"
  type        = string
  default     = "us-east-1"
}

variable "nameprefix" {
  description = "Prefix to use for some resource names to avoid duplicates"
  type        = string
  default     = "ioos_cloud_sandbox"
}

variable "name_tag" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "IOOS-Cloud-Sandbox-Terraform"
}

variable "project_tag" {
  description = "Value of the Project tag for the EC2 instance"
  type        = string
  default     = "IOOS-Cloud-Sandbox"
}

variable "availability_zone" {
  description = "Availability zone to use"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type = string
  #default = "c5n.18xlarge"
  default = "t3.medium"
}

variable "use_efa" {
  description = "Attach EFA Network"
  type = bool
  default = "true"
}

variable "key_name" {
  description = "The name of the key-pair used to access the EC2 instances"
  type        = string
  nullable = false
}

variable "allowed_ssh_cidr" {
  description = "Public IP address/range allowed for SSH access"
  type = string
  nullable = false
}

variable "public_key" {
  description = "Contents of the SSH public key to be used for authentication"
  type        = string
  sensitive = true
  nullable = false

  validation {
    condition     = length(var.public_key) > 8 && substr(var.public_key, 0, 8) == "ssh-rsa "
    error_message = "The public_key value must start with \"ssh-rsa \"."
  }
}

variable "vpc_id" {
  description = "The ID of an existing VPC within the target region.  Specifying this value will skip creation of a new VPC."
  type = string
  default = null

  validation {
    condition     = var.vpc_id == null ? true : ( length(var.vpc_id) > 4 && substr(var.vpc_id, 0, 4) == "vpc-" )
    error_message = "The vpc_id value must start with \"vpc-\"."
  }

}


variable "subnet_id" {
  description = "The ID of an existing Subnet within the target VPC to use.  If not provided a Subnet will be created."
  type = string
  default = null

  validation {
    condition     = var.subnet_id == null ? true : ( length(var.subnet_id) > 7 && substr(var.subnet_id, 0, 7) == "subnet-" )
    error_message = "The subnet_id value must start with \"subnet-\"."
  }

}

variable "subnet_cidr" {
  description = "An explicit CIDR block to use for the created Subnet, if subnet_id is not specified.  Optional."
  type = string
  default = null

  validation {
    condition     = var.subnet_cidr == null ? true : can(cidrhost(var.subnet_cidr, 0))
    error_message = "The subnet_cidr variable must be a valid CIDR notation (e.g. \"10.0.0.0/24\")."
  }

}

variable "subnet_quartile" {
  description = "If a specific subnet_cidr is not provided, the quartile of VPC address space to use for the created subnet.  Optional."
  type = number
  default = 1

}

variable "managed_policies" {
  description = "The attached IAM policies granting machine permissions"
  default = ["arn:aws:iam::aws:policy/AmazonEC2FullAccess",
             "arn:aws:iam::aws:policy/AmazonS3FullAccess",
             "arn:aws:iam::aws:policy/AmazonFSxFullAccess"]
}

variable "ami_id" {
  description = "The random ID used for AMI creation"
  type = string
  default="unknown value"
}
