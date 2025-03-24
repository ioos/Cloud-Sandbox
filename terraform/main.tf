terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.47"
    }
  }

  backend "s3" {
    key = "tfstate"
  }
}

provider "aws" {
  region = var.preferred_region
}

resource "aws_iam_role" "sandbox_iam_role" {
  name               = "${var.nameprefix}-${var.availability_zone}_terraform_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Sid    = "AttachedIAMRole",
      Principal = {
        Service = ["ec2.amazonaws.com"]
      },
      Effect = "Allow"
    }]
  })

  tags = {
    Name    = "${var.name_tag} IAM Role"
    Project = var.project_tag
  }
}

resource "aws_iam_role_policy" "sandbox_iam_role_policy" {
  name   = "${var.nameprefix}-${var.availability_zone}_terraform_role_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "ListObjectsInBucket",
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = ["arn:aws:s3:::ioos-coastalsb-*puts"]
      },
      {
        Sid      = "AllObjectActions",
        Effect   = "Allow",
        Action   = "s3:*Object",
        Resource = ["arn:aws:s3:::ioos-coastalsb-*puts/*"]
      }
    ]
  })
  role = aws_iam_role.sandbox_iam_role.id
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
  count             = var.vpc_id != null ? 0 : 1
  cidr_block        = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name    = "${var.name_tag} VPC"
    Project = var.project_tag
  }
}

data "aws_vpc" "pre-provisioned" {
  count = var.vpc_id != null ? 1 : 0
  id    = var.vpc_id
}

resource "aws_subnet" "main" {
  count = var.subnet_id != null ? 0 : 1
  vpc_id = local.vpc.id
  cidr_block = var.subnet_cidr != null ? var.subnet_cidr : cidrsubnet(one(data.aws_vpc.pre-provisioned[*]).cidr_block, 2, var.subnet_quartile - 1)
  map_public_ip_on_launch = true
  availability_zone = var.availability_zone
  tags = {
    Name    = "${var.name_tag} Subnet"
    Project = var.project_tag
  }
}

data "aws_subnet" "pre-provisioned" {
  count = var.subnet_id != null ? 1 : 0
  id    = var.subnet_id
}

locals {
  vpc    = var.vpc_id != null ? one(data.aws_vpc.pre-provisioned[*]) : one(aws_vpc.cloud_vpc[*])
  subnet = var.subnet_id != null ? one(data.aws_subnet.pre-provisioned[*]) : one(aws_subnet.main[*])
}

resource "aws_internet_gateway" "gw" {
  count  = var.subnet_id != null ? 0 : 1
  vpc_id = local.vpc.id
  tags = {
    Name    = "${var.name_tag} Internet Gateway"
    Project = var.project_tag
  }
}

resource "aws_route_table" "default" {
  count  = var.subnet_id != null ? 0 : 1
  vpc_id = local.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = one(aws_internet_gateway.gw[*].id)
  }

  tags = {
    Name    = "${var.name_tag} Route Table"
    Project = var.project_tag
  }
}

resource "aws_route_table_association" "main" {
  count           = var.subnet_id != null ? 0 : 1
  subnet_id       = one(aws_subnet.main[*].id)
  route_table_id  = one(aws_route_table.default[*].id)
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
  subnet_id      = local.subnet.id
  security_groups = [aws_security_group.efs_sg.id]
  file_system_id = aws_efs_file_system.main_efs.id
}

data "aws_ami" "rhel_8" {
  owners      = ["309956199498"]
  most_recent = true
  filter {
    name   = "name"
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

resource "aws_instance" "head_node" {
  ami                 = data.aws_ami.rhel_8.id
  instance_type       = var.instance_type
  cpu_threads_per_core = 2
  root_block_device {
    encrypted             = true
    delete_on_termination = true
    volume_size           = 16
    volume_type           = "gp3"
    tags = {
      Name    = "${var.name_tag} Head Node"
      Project = var.project_tag
    }
  }

  depends_on = [
    aws_internet_gateway.gw,
    aws_efs_file_system.main_efs,
    aws_efs_mount_target.mount_target_main_efs
  ]

  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.cloud_sandbox_iam_instance_profile.name

  placement_group = var.use_efa ? aws_placement_group.cloud_sandbox_placement_group.id : null

  tags = {
    Name    = "${var.name_tag} EC2 Head Node"
    Project = var.project_tag
  }
}

resource "aws_network_interface" "head_node" {
  subnet_id        = local.subnet.id
  description      = "The network adaptor to attach to the head_node instance"
  security_groups  = [aws_security_group.base_sg.id, aws_security_group.ssh_ingress.id, aws_security_group.efs_sg.id]
  interface_type   = var.use_efa ? "efa" : null
  tags = {
    Name    = "${var.name_tag} Head Node Network Adapter"
    Project = var.project_tag
  }
}

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
