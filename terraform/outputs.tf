output "instance_public_ip" {
   description = "Public IP Address of the EC2 Instance"
   value = aws_instance.model_head_node.public_ip
}
