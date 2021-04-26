terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  region  = var.preferred_region
}

resource "aws_vpc" "cloud_vpc" {
   cidr_block = "10.0.0.0/16"
   tags = {
      Name = "IOOS Cloud Sandbox VPC Terraform"
      Project = var.project_name
    }
}

resource "aws_subnet" "main" {
  vpc_id   = aws_vpc.cloud_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = var.availability_zone
   tags = {
      Name = "IOOS Cloud Sandbox VPC Subnet Terraform"
      Project = var.project_name
    }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.cloud_vpc.id
   tags = {
      Name = "IOOS Cloud Sandbox VPC Subnet Internet Gateway"
      Project = var.project_name
    }
}

resource "aws_route_table" "default" {
    vpc_id = aws_vpc.cloud_vpc.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }

   tags = {
      Name = "IOOS Cloud Sandbox VPC Subnet Internet Gateway"
      Project = var.project_name
    }
}

resource "aws_route_table_association" "main" {
  subnet_id = aws_subnet.main.id
  route_table_id = aws_route_table.default.id
}

# base sg
resource "aws_security_group" "base_sg" {
   vpc_id = aws_vpc.cloud_vpc.id
   tags = {
      Name = "IOOS Cloud Sandbox Base SG"
      Project = var.project_name
    }
}

resource "aws_security_group" "efs_ingress" {
   vpc_id = aws_vpc.cloud_vpc.id
   ingress {
     security_groups = [aws_security_group.base_sg.id]
     from_port = 2049
     to_port = 2049
     protocol = "tcp"
   }
   tags = {
      Name = "IOOS Cloud Sandbox Base SG"
      Project = var.project_name
   }

   # allow all outgoing from NFS
   egress {
      security_groups = [aws_security_group.base_sg.id]
      from_port = 0
      to_port = 0
      protocol = "all"
   }
}


# TODO: fix these so that the managed policies attach properly
resource "aws_iam_role" "sandbox_iam_role" {
  name = "ioos_cloud_sandbox_terraform_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = var.instance_name
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "sandbox_role_policy_attach" {
   count = length(var.managed_policies)
   policy_arn = element(var.managed_policies, count.index)
   role = aws_iam_role.sandbox_iam_role.name
}

resource "aws_iam_instance_profile" "cloud_sandbox_iam_instance_profile" {
    name = "ioos_cloud_sandbox_terraform_role"
    role = aws_iam_role.sandbox_iam_role.name
}

resource "aws_security_group" "ssh_ingress" {
  vpc_id = aws_vpc.cloud_vpc.id
  ingress {
          description = "Allow SSH from approved IP addresses"
          from_port = 22
          to_port   = 22
          protocol = "tcp"
          cidr_blocks = [var.ssh_cidr]
         }
}

resource "aws_key_pair" "default" {
   key_name = "main_key"
   public_key = var.public_key
}

# uncomment to make CentOS 7 HVM AMI available for use.  Will need to also
# be reflected in the instance's AMI id
data "aws_ami" "centos_7_latest" {
  owners = ["679593333241"]
  most_recent = true

  filter {
    name = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS ENA*"]
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

resource "aws_instance" "model_head_node" {
  # Base CentOS 7 AMI
  ami = data.aws_ami.centos_7_latest.id
  # AMI for NOSOFS Setup
  #ami           = "ami-0c5fc45da5f63247b"
  # c5n.18xlarge is required for EFA support
  instance_type = "c5n.18xlarge"
  iam_instance_profile = aws_iam_instance_profile.cloud_sandbox_iam_instance_profile.name
  # TODO: Terraform does not yet support enabling EFA.  Find some other means
  #       of doing so.
  associate_public_ip_address = true
  root_block_device {
        delete_on_termination = true
        volume_size = 12
      }
  cpu_threads_per_core = 1
  depends_on = [aws_internet_gateway.gw]
  key_name = "main_key"
  subnet_id = aws_subnet.main.id
  vpc_security_group_ids = [
    aws_security_group.base_sg.id,
    aws_security_group.ssh_ingress.id,
    aws_security_group.efs_ingress.id
  ]
  tags = {
    Name = var.instance_name
    Project = var.project_name
  }
}


resource "aws_placement_group" "cloud_sandbox_placement_group" {
  name = "IOOS Cloud Sandbox Terraform Placement Group"
  strategy = "cluster"
  tags = {
    project = var.project_name
  }
}

resource "aws_efs_file_system" "main_efs" {
  encrypted = false
  availability_zone_name = var.availability_zone
  tags = {
     Name = "Cloud sandbox Terraform EFS"
     Project = var.project_name
  }
}

resource "aws_efs_mount_target" "mount_target_main_efs" {
    subnet_id = aws_subnet.main.id
    file_system_id = aws_efs_file_system.main_efs.id
}
