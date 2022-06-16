# Spefify this file when running terraform.

# Examples:
# terraform plan -var-file="mysettings.tfvars"
# terraform apply -var-file="mysettings.tfvars"
# terraform destroy -var-file="mysettings.tfvars"

#------------------------------------------------------------
# The following variables must be defined, no default exists:
#------------------------------------------------------------

# (This should be the public IPv4 address of your workstation for SSH acceess)
# This should be in the format ###.###.###.###/32
# Example: 72.245.67.89/32

allowed_ssh_cidr = ""

# Specify the SSL key below.

# Example:
# key_name = "ioos-sandbox"
# public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2cQ3fzP1R2uQJcCd3g2ylW5clzyjun6eWz2PZKMwtJh7E28B1jp3F8YTP5XBPg0ouvZO6gkcrbgjhuM0A4NKJM6RylGAOqqPYnIbhd9eI3RKhSQbxsghjf5hwS7tIG1FebO9HuObaM23LDB1/Ra/YMTXB5LHPChlfxrEIlM/7OUfRPNgtudAb/MQZ+YD+6I77QDtTwZwQvebxLK62bP5CrpV4XY5ybWOZ0T3m4pVNfhfl7+QWAvWeStNpH3B3q1ZtPLTuAVvsR4RWk7t75IwpHwiPBcgZn/PTpN45z"

key_name = ""       # the filename of the private SSL key 
public_key = ""     # the matching public key (ssh-keygen -y -f your-key-pair.pem) 

#------------------------------------------------------------


#---------------------------------------------------------------
# Optionally uncomment and change these to override the defaults
#---------------------------------------------------------------

# preferred_region = "us-east-2"
# name_tag = "IOOS Cloud Sandbox - Terraform"
# project_tag = "IOOS-Cloud-Sandbox"
# availability_zone = "us-east-2a"
# instance_type = "t3.medium"
# use_efa = false 

# You can give your AWS resources a unique name to avoid conflicts
# with other deployed sandboxes

# nameprefix="ioos-cloud-sandbox"
#---------------------------------------------------------------
