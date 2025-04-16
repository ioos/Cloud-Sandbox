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


source "amazon-ebs" "skills" {
  profile       = var.aws_profile
  region        = var.aws_region
  instance_type = var.instance_type
  ssh_username  = var.ssh_username
  vpc_id        = var.vpc
  subnet_id     = var.subnet

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = var.volume_size
    volume_type           = "gp2"
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
  ami_description = var.ami_description
  tags = {
    Name        = var.ami_name
    CreatedBy   = "Packer"
    Description = var.ami_description
  }
  aws_polling {
    delay_seconds = 30
    max_attempts  = 200
  }
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