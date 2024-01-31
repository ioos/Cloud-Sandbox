# base sg
resource "aws_security_group" "base_sg" {
  vpc_id = local.vpc.id
  ingress {
    self      = true
    from_port = 0
    to_port   = 0
    protocol  = -1
  }
  egress {
    self      = true
    from_port = 0
    to_port   = 0
    protocol  = -1
  }
  tags = {
    Name    = "${var.name_tag} Base SG"
    Project = var.project_tag
  }
}

resource "aws_security_group" "efs_sg" {
   vpc_id = local.vpc.id
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
  vpc_id = local.vpc.id
  ingress {
    description = "Allow SSH from approved IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_list
  }
  tags = {
      Name = "${var.name_tag} SSH SG"
      Project = var.project_tag
   }
}
