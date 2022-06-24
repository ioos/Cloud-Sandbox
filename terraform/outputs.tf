output "instance_id" {
   description = "The EC2 instance id"
   value = aws_instance.head_node.id
}

output "instance_public_ip" {
   description = "Public IP Address of the EC2 Instance"
   value = aws_eip.head_node.public_ip
}

output "instance_public_dns" {
   description = "Public DNS Address of the EC2 Instance"
   value = aws_eip.head_node.public_dns
}

output "key_name" {
   description = "Key-pair used"
   value = var.key_name
}

output "ami_name" {
    description = "Used for AMI creation"
    value = "${var.name_tag}-${random_pet.ami_id.id}"
}

output "aws_security_groups" {
    description = "AWS Security Groups"
    value = [aws_security_group.base_sg.id,
            aws_security_group.ssh_ingress.id,
            aws_security_group.efs_sg.id]
}

output "aws_security_group-efs" {
    description = "EFS AWS Security Group"
    value = aws_security_group.efs_sg.id
}

output "aws_security_group-ssh" {
    description = "SSH AWS Security Group"
    value = aws_security_group.ssh_ingress.id
}

output "name_tag" {
    description = "Name to use for tagging"
    value = var.name_tag
}

output "project_tag" {
    description = "Project to use for tagging"
    value = var.project_tag
}

output "aws_subnet" {
    description = "AWS Subnet"
    value = aws_subnet.main.id
}

output "aws_placement_group" {
    description = "AWS Cluster Placement Group"
    value = aws_placement_group.cloud_sandbox_placement_group.id
}

output "login_command" {
   description = "SSH Login"
   value = "ssh -i ${var.key_name}.pem centos@${aws_eip.head_node.public_dns}"
}

