# Spefify this file when running terraform.

# Examples:
# terraform plan -var-file="mysettings.tfvars"
# terraform apply -var-file="mysettings.tfvars"
# terraform destroy -var-file="mysettings.tfvars"

#------------------------------------------------------------
# The following variables must be defined, no default exists:
#------------------------------------------------------------

# (This should be the public IPv4 address of your workstation, 
#  for SSH acceess)
# This should be in the format ###.###.###.###/32
# e.g. 72.245.67.89/32
allowed_ssh_cidr = ""


key_name = ""       # the filename of the private SSL key 
public_key = ""     # the matching public key (ssh-keygen -y -f your-key-pair.pem)
#------------------------------------------------------------


#---------------------------------------------------------------
# Optionally uncomment and change these to override the defaults
#---------------------------------------------------------------
 preferred_region = "us-east-2"
 name_tag = "IOOS Cloud Sandbox - Terraform"
 project_tag = "IOOS-Cloud-Sandbox"
 availability_zone = "us-east-2a"
 instance_type = "t3.medium"
 use_efa = false

 # You can give your AWS resources a unique name
 # nameprefix="ioos-cloud-sandbox"
#---------------------------------------------------------------
