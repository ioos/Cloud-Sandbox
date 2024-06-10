terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.47"
    }
  }
  backend "s3" {
    key    = "tfstate"
  }
}

provider "aws" {
  region = var.preferred_region
}

resource "aws_iam_role" "sandbox_iam_role" {
  name = "${var.nameprefix}-${var.availability_zone}_terraform_role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AttachedIAMRole",
          "Effect" : "Allow"
          "Action" : "sts:AssumeRole",
          "Principal" : { "Service" : "ec2.amazonaws.com" },
        }
      ]
  })
  tags = {
    Name    = "${var.name_tag} IAM Role"
    Project = var.project_tag
  }
}

resource "aws_iam_role_policy_attachment" "sandbox_role_policy_attach" {
  count      = length(var.managed_policies)
  policy_arn = element(var.managed_policies, count.index)
  role       = aws_iam_role.sandbox_iam_role.name
}

resource "aws_iam_instance_profile" "cloud_sandbox_iam_instance_profile" {
  name = "${var.nameprefix}-${var.availability_zone}_terraform_instance_profile"
  role = aws_iam_role.sandbox_iam_role.name
}


resource "aws_placement_group" "cloud_sandbox_placement_group" {
  name     = "${var.nameprefix}-${var.availability_zone}_Terraform_Placement_Group"
  strategy = "cluster"
  tags = {
    project = var.project_tag
  }
}

resource "aws_vpc" "cloud_vpc" {
   # we only will create this vpc if vpc_id is not passed in as a variable
   count = var.vpc_id != null ? 0 : 1
   # This is a large vpc, 256 x 256 IPs available
   cidr_block = "10.0.0.0/16"
   enable_dns_support = true
   enable_dns_hostnames = true
   tags = {
      Name = "${var.name_tag} VPC"
      Project = var.project_tag
    }
}


data "aws_vpc" "pre-provisioned" {
  # the pre-provisioned VPC will be returned if vpc_id matches an existing VPC
  count = var.vpc_id != null ? 1 : 0
  id = var.vpc_id
}

resource "aws_subnet" "main" {
   count = var.subnet_id != null ? 0 : 1
   vpc_id = local.vpc.id

   # If a subnet_cidr variable is passed explicitly, we use that,  
   # otherwise, divide the VPC by four and use 1/4 for a new subnet 
   cidr_block = var.subnet_cidr != null ? var.subnet_cidr : cidrsubnet(one(data.aws_vpc.pre-provisioned[*]).cidr_block, 2, var.subnet_quartile - 1)
   
   map_public_ip_on_launch = true
   
   availability_zone = var.availability_zone
   
   tags = {
      Name = "${var.name_tag} Subnet"
      Project = var.project_tag
   }
}


data "aws_subnet" "pre-provisioned" {
  # the pre-provisioned Subnet will be returned if subnet_id matches an existing Subnet
  count = var.subnet_id != null ? 1 : 0
  id = var.subnet_id
}


# here we assign local variables for both the VPC and the Subnet we'll need to refer to to deploy further resources below:
# use of the one() function is needed to ensure only a single value is assigned, rather than a tuple/set
locals {
  vpc = var.vpc_id != null ? one(data.aws_vpc.pre-provisioned[*]) : one(aws_vpc.cloud_vpc[*])
  subnet = var.subnet_id != null ? one(data.aws_subnet.pre-provisioned[*]) : one(aws_subnet.main[*])

}


resource "aws_internet_gateway" "gw" {
   count = var.subnet_id != null ? 0 : 1
   vpc_id = local.vpc.id
   tags = {
      Name = "${var.name_tag} Internet Gateway"
      Project = var.project_tag
    }
}

resource "aws_route_table" "default" {
   count = var.subnet_id != null ? 0 : 1
   vpc_id = local.vpc.id

   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = one(aws_internet_gateway.gw[*].id)
   }
   tags = {
     Name = "${var.name_tag} Route Table"
     Project = var.project_tag
   }
}

resource "aws_route_table_association" "main" {
  count = var.subnet_id != null ? 0 : 1
  subnet_id = one(aws_subnet.main[*].id)
  route_table_id = one(aws_route_table.default[*].id)
}


resource "aws_efs_file_system" "main_efs" {
  encrypted              = false
  availability_zone_name = var.availability_zone
  tags = {
    Name    = "${var.name_tag} EFS"
    Project = var.project_tag
  }
}


resource "aws_efs_mount_target" "mount_target_main_efs" {
    subnet_id = local.subnet.id
    security_groups = [aws_security_group.efs_sg.id]
    file_system_id = aws_efs_file_system.main_efs.id
}


### AMI Options
### Specify aws_ami.*****.id in aws_instance section below


###################################
# RHEL 8
# 2023-10-06: ami-057094267c651958e
# AMI name: RHEL-8.7.0_HVM-20230330-x86_64-56-Hourly2-GP2
# Owner account ID 309956199498 Red Hat
##################################

data "aws_ami" "rhel_8" {
  owners = ["309956199498"]
  most_recent = true

  filter {
    name = "name"
    values = ["RHEL-8.7.0_HVM-20230330-x86_64-56-Hourly2-GP2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


###################################
# Centos Stream 9 - untested
# ami-0c2abda83f1b9e09d
# AMI name: CentOS Stream 9 x86_64 
# Owner account ID 125523088429
##################################

data "aws_ami" "centos_stream_9" {
  owners = ["125523088429"]   # CentOS Official CPE
  most_recent = true

  filter {
    name = "description"
    values = ["CentOS Stream 9 *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# Work around to get a public IP assigned when using EFA
resource "aws_eip" "head_node" {
  count = var.subnet_id != null ? 0 : 1
  depends_on = [aws_internet_gateway.gw]
  vpc        = true
  instance   = aws_instance.head_node.id
  tags = {
    Name    = "${var.name_tag} Elastic IP"
    Project = var.project_tag
  }
}


# efa enabled node
resource "aws_instance" "head_node" {

  #################################
  ### Specify which AMI to use here
  #############################################

  ami = data.aws_ami.rhel_8.id

  metadata_options {
     http_endpoint = "enabled"
     http_tokens = "required"
  }	

  instance_type = var.instance_type
  cpu_threads_per_core = 2

  root_block_device {
    encrypted             = true
    delete_on_termination = true
    volume_size           = 16
    volume_type           = "gp3"
    tags                  = {
        Name    = "${var.name_tag} Head Node"
        Project = var.project_tag
    }

  }

  depends_on = [aws_internet_gateway.gw,
                aws_efs_file_system.main_efs,
                aws_efs_mount_target.mount_target_main_efs]

  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.cloud_sandbox_iam_instance_profile.name

  user_data            = templatefile("init_template.tpl", { efs_name = aws_efs_file_system.main_efs.dns_name, ami_name = "${var.name_tag}-${random_pet.ami_id.id}", aws_region = var.preferred_region, project = var.project_tag })

  # associate_public_ip_address = true
  network_interface {
    network_interface_id = aws_network_interface.head_node.id
    device_index = 0
  }

  # This logic isn't perfect since some ena instance types can be in a placement group also
  placement_group = var.use_efa == true ? aws_placement_group.cloud_sandbox_placement_group.id : null

  tags = {
    Name    = "${var.name_tag} EC2 Head Node"
    Project = var.project_tag
  }
}

# A random id to use when creating the AMI
# This needs a new id if the instance_id changes - otherwise it won't create a new AMI
resource "random_pet" "ami_id" {
  keepers = {
    #instance_id = aws_instance.head_node.id
    ami_id = var.ami_id
  }
  length = 2
}


# Can only attach efa adaptor to a stopped instance!
resource "aws_network_interface" "head_node" {
  
  subnet_id   = local.subnet.id
  description = "The network adaptor to attach to the head_node instance"
  security_groups = [aws_security_group.base_sg.id,
                     aws_security_group.ssh_ingress.id,
                     aws_security_group.efs_sg.id]
  
  interface_type = var.use_efa == true ? "efa" : null 

  tags = {
      Name = "${var.name_tag} Head Node Network Adapter"
      Project = var.project_tag
  }
}
