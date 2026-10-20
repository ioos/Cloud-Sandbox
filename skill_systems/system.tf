provider "aws" {
    region = "us-east-2"  # Change to your desired region
}

data "aws_ami" "amazon_linux" {
    most_recent = true
    owners      = ["amazon"]
    
    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_instance" "example" {
    ami           = data.aws_ami.amazon_linux.id
    instance_type = "r5.2xlarge"  # Change as needed
    
    tags = {
        Name = "example-instance"
    }
    
    # Optional: Add key pair for SSH access
    key_name = "trial"
    
    # Optional: Security group
    # vpc_security_group_ids = [aws_security_group.example.id]
}

# Uncomment to create a security group if needed
# resource "aws_security_group" "example" {
#   name        = "example-security-group"
#   description = "Allow SSH and other necessary traffic"
#
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]  # Warning: Open to the world, restrict as needed
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }