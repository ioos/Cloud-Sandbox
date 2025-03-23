# Base SG - Allows all traffic within the same security group
resource "aws_security_group" "base_sg" {
  vpc_id = local.vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name    = "${var.name_tag} Base SG"
    Project = var.project_tag
  }
}

# EFS SG - Allows NFS traffic only from base_sg
resource "aws_security_group" "efs_sg" {
  vpc_id = local.vpc.id
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.base_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name    = "${var.name_tag} EFS SG"
    Project = var.project_tag
  }
}

# SSH SG - Allows SSH only from approved IPs
resource "aws_security_group" "ssh_ingress" {
  vpc_id = local.vpc.id
  ingress {
    description = "Allow SSH from approved IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_list
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name    = "${var.name_tag} SSH SG"
    Project = var.project_tag
  }
}

