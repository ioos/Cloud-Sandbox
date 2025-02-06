output "instance_id" {
  description = "The EC2 instance id"
  value       = one(aws_instance.head_node[*]).id
}

output "instance_public_ip" {
  description = "Public IP Address of the EC2 Instance"
  value       = one(aws_eip.head_node[*]) != null ? one(aws_eip.head_node[*]).public_ip : null
}

output "instance_public_dns" {
  description = "Public DNS Address of the EC2 Instance"
  value       = one(aws_eip.head_node[*]) != null ? one(aws_eip.head_node[*]).public_dns : null
}

output "key_name" {
  description = "Key-pair used"
  value       = var.key_name
}

output "ami_name" {
  description = "Used for AMI creation"
  value       = "${var.name_tag}-${random_pet.ami_id.id}"
}

output "aws_security_groups" {
  description = "AWS Security Groups"
  value = [aws_security_group.base_sg.id,
    aws_security_group.ssh_ingress.id,
  aws_security_group.efs_sg.id]
}

output "aws_security_group-efs" {
  description = "EFS AWS Security Group"
  value       = aws_security_group.efs_sg.id
}

output "aws_security_group-ssh" {
  description = "SSH AWS Security Group"
  value       = aws_security_group.ssh_ingress.id
}

output "name_tag" {
  description = "Name to use for tagging"
  value       = var.name_tag
}

output "project_tag" {
  description = "Project to use for tagging"
  value       = var.project_tag
}

output "aws_vpc" {
    description = "AWS VPC"
    value = local.vpc.id
}

output "aws_subnet" {
    description = "AWS Subnet"
    value = local.subnet.id
}

output "aws_placement_group" {
  description = "AWS Cluster Placement Group"
  value       = aws_placement_group.cloud_sandbox_placement_group.id
}

/* This is just a little helper output: See the "./login" script. 
   If an elastic ip (EIP) is specified, use the public_dns name, otherwise use the private_dns name
   An EIP is not used when an existing pre-provisioned subnet is specified, e.g. NOAA/NOS environments do not allow public IPs.
   TODO: Better logic for this, an existing subnet with public visibility might be specified, breaking this.
*/
output "login_command" {
   description = "SSH Login"
   value = one(aws_eip.head_node[*]) != null ? "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${one(aws_eip.head_node[*]).public_dns}" : "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_instance.head_node.private_dns}"
}
