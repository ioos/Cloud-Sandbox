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
  # This is a large vpc, 256 x 256 IPs available
   cidr_block = "10.0.0.0/16"
   enable_dns_support = true
   enable_dns_hostnames = true
   tags = {
      Name = "${var.name_tag} VPC"
      Project = var.project_tag
    }
}

resource "aws_subnet" "main" {
  vpc_id   = aws_vpc.cloud_vpc.id
  # This subnet will allow 256 IPs
  cidr_block = "10.0.0.0/24"
  availability_zone = var.availability_zone
   tags = {
      Name = "${var.name_tag} Subnet"
      Project = var.project_tag
    }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.cloud_vpc.id
   tags = {
      Name = "${var.name_tag} Internet Gateway"
      Project = var.project_tag
    }
}

resource "aws_route_table" "default" {
    vpc_id = aws_vpc.cloud_vpc.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }
   tags = {
      Name = "${var.name_tag} Route Table"
      Project = var.project_tag
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
      Name = "${var.name_tag} Base SG"
      Project = var.project_tag
    }
}

resource "aws_security_group" "efs_sg" {
   vpc_id = aws_vpc.cloud_vpc.id
   ingress {
     self = true
     from_port = 2049
     to_port = 2049
     protocol = "tcp"
   }
   # allow all outgoing from NFS
   egress {
      from_port = 0
      to_port = 0
      protocol = -1
      cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
      Name = "${var.name_tag} EFS SG"
      Project = var.project_tag
   }
}

resource "aws_security_group" "ssh_ingress" {
  vpc_id = aws_vpc.cloud_vpc.id
  ingress {
          description = "Allow SSH from approved IP addresses"
          from_port = 22
          to_port   = 22
          protocol = "tcp"
          cidr_blocks = [var.allowed_ssh_cidr]
  }
  tags = {
      Name = "${var.name_tag} SSH SG"
      Project = var.project_tag
   }
}

resource "aws_iam_role" "sandbox_iam_role" {
  name = "${var.nameprefix}_terraform_role"
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
    Name = "${var.name_tag} IAM Role"
    Project = var.project_tag
  }
}

resource "aws_iam_role_policy_attachment" "sandbox_role_policy_attach" {
   count = length(var.managed_policies)
   policy_arn = element(var.managed_policies, count.index)
   role = aws_iam_role.sandbox_iam_role.name
}

resource "aws_iam_instance_profile" "cloud_sandbox_iam_instance_profile" {
    name = "${var.nameprefix}_terraform_role"
    role = aws_iam_role.sandbox_iam_role.name
}


data "aws_ami" "centos_7" {
  owners = ["125523088429"]   # CentOS "CentOS 7.9.2009 x86_64"
  most_recent = true

  filter {
    name = "name"
    values = ["CentOS 7.*x86_64"]
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


data "aws_ami" "centos_7_aws" {
  owners = ["679593333241"]   # AWS
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

resource "aws_network_interface" "efa_network_adapter" {
  # Only create and attach this if EFA is supported by the node type
  # c5n.18xlarge supports EFA
  count = data.aws_ec2_instance_type.head_node.efa_supported == true ? 1 : 0
  subnet_id   = aws_subnet.main.id
  description = "The Elastic Fabric Adapter to attach to instance if supported"
  security_groups = [aws_security_group.base_sg.id,
                     aws_security_group.ssh_ingress.id,
                     aws_security_group.efs_sg.id]
  
  interface_type = "efa"
  attachment {
    instance     = aws_instance.head_node.id
    device_index = 1
  }
  tags = {
      Name = "${var.name_tag} EFA Network Adapter"
      Project = var.project_tag
  }
}

#resource "aws_key_pair" "default" {
#  # Strange: This creates a new key-pair with name key_name in AWS
#  # Which is completely unused here since we provide the public key for an existing private key
#   key_name = var.key_name
#   public_key = var.public_key
#}

data "aws_ec2_instance_type" "head_node" {
  instance_type = var.instance_type
}

resource "aws_instance" "head_node" {
  # Base CentOS 7 AMI, can use either AWS's marketplace, or direct from CentOS
  # Choosing direct from CentOS as it is more recent
  ami = data.aws_ami.centos_7.id
  instance_type = var.instance_type
  cpu_core_count = data.aws_ec2_instance_type.head_node.default_cores
  cpu_threads_per_core = 1
  root_block_device {
        delete_on_termination = true
        volume_size = 12
  }
  depends_on = [aws_internet_gateway.gw]
  key_name = var.key_name
  iam_instance_profile = aws_iam_instance_profile.cloud_sandbox_iam_instance_profile.name
  user_data = data.template_file.init_instance.rendered
  associate_public_ip_address = true
  subnet_id = data.aws_subnet.noaa-pub-subnet-search.id
  vpc_security_group_ids = [
    aws_security_group.base_sg.id,
    aws_security_group.ssh_ingress.id,
    aws_security_group.efs_sg.id
  ]
  placement_group = data.aws_ec2_instance_type.head_node.ena_support == true ? aws_placement_group.cloud_sandbox_placement_group.id : null
  tags = {
    Name = "${var.name_tag} EC2 Head Node"
    Project = var.project_tag
  }
}

resource "aws_placement_group" "cloud_sandbox_placement_group" {
  name = "${var.nameprefix}_Terraform_Placement_Group"
  strategy = "cluster"
  tags = {
    project = var.project_tag
  }
}

resource "aws_efs_file_system" "main_efs" {
  encrypted = false
  availability_zone_name = var.availability_zone
  tags = {
     Name = "${var.name_tag} EFS"
     Project = var.project_tag
  }
}

resource "aws_efs_mount_target" "mount_target_main_efs" {
    subnet_id = aws_subnet.main.id
    security_groups = [aws_security_group.efs_sg.id]
    file_system_id = aws_efs_file_system.main_efs.id
}

data "template_file" "init_instance" {
   template = file("./init_template.tpl")
   vars = {
       efs_name = aws_efs_file_system.main_efs.dns_name
       ami_name = "${var.name_tag} AMI"
       aws_region = var.preferred_region
       project = var.project_tag
       instance_id = ""
   }
   
   depends_on = [aws_efs_file_system.main_efs,
                 aws_efs_mount_target.mount_target_main_efs]
}
