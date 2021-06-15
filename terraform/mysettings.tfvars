
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

allowed_ssh_cidr = "22.128.33.16/32"

# (Key name is only used as a reminder here and in the instance metadata)
# This is the name of the key that matches the public_key

key_name = "my-sandbox-key"
public_key = "ssh-rsa AAOb69pkQ6yZn...redacted...Qil7geTk"
#------------------------------------------------------------

#---------------------------------------------------------------
# Optionally uncomment and change these to override the defaults
#---------------------------------------------------------------
# preferred_region = "us-east-1"
# name_tag = "IOOS Cloud Sandbox - Testing Terraform"
# nameprefix = "terraform_test"
# project_tag = "IOOS-cloud-sandbox"
# availability_zone = "us-east-1a"
# instance_type = "t3.small" 
#---------------------------------------------------------------

