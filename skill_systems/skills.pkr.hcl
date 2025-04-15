packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "ami_name" {
  type    = string
  default = "skills-image-{{timestamp}}"
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

source "amazon-ebs" "skills" {
  profile       = "lcsb-admin"
  region        = var.aws_region
  instance_type = var.instance_type
  ssh_username  = var.ssh_username
  vpc_id        = "vpc-0b008988bcc9ce636"
  subnet_id     = "subnet-0db88d9c9d9a1621c"

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 60
    volume_type = "gp2"
    delete_on_termination = true
  }

  source_ami_filter {
    filters = {
      name         = "RHEL-8.8*2025*"
      architecture = "x86_64"
    }
    most_recent = true
    owners      = ["309956199498"]
  }

  ami_name        = var.ami_name
  ami_description = "Skills image with users added via Ansible"
}

build {
  sources = ["source.amazon-ebs.skills"]

  provisioner "shell" {
    script  = "user_data.sh"
    timeout = "20m"
  }

  provisioner "ansible" {
    playbook_file = "add_users.yml"
    extra_arguments = [
      # "-vvvvv"
    ]
  }
}