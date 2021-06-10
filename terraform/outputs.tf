output "instance_public_ip" {
   description = "Public IP Address of the EC2 Instance"
   value = aws_instance.head_node.public_ip
}

output "instance_public_dns" {
   description = "Public DNS Address of the EC2 Instance"
   value = aws_instance.head_node.public_dns
}

output "instance_id" {
   description = "The EC2 instance id"
   value = aws_instance.head_node.id
}

output "login_command" {
   description = "SSH Login"
   value = "ssh -i ${var.key_name}.pem centos@${aws_instance.head_node.public_dns}"
}