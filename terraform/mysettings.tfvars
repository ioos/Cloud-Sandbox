# Spefify this file when running terraform.

# Examples:
# terraform plan -var-file="mysettings.tfvars"
# terraform apply -var-file="mysettings.tfvars"
# terraform destroy -var-file="mysettings.tfvars"

#------------------------------------------------------------
# The following variables must be defined, no default exists:
#------------------------------------------------------------

# List of the IP's address the are allowed SSH access to the system
# They should be in the format ###.###.###.###/32
# Example:  
# allowed_ssh_cidr_list =  ["72.200.162.64/32", "96.238.4.28/32", "96.238.4.30/32"]

allowed_ssh_cidr_list =  ["72.200.162.64/32", "96.238.4.28/32", "96.238.4.30/32"]


# Specify the SSL key below.

# Example:
# key_name = "ioos-sandbox"
# public_key = "ssh-rsa AANzaC2AADAQABAAABAQC2cQ3fzP1R2uQJcCd3g2ylW5clzyjun6eWz2PZKMwtJh7E28B1jp3F8YTP5XBPg0ouvZO6gkcrbgjhuM0A4NKJM6RylGAOqqPYnIbhd9eI3RKhSQbxsghjf5hwS7tIG1FebO9HuObaM23LDBQvebxLK62bP5CrpV4XY5ybWOZ0T3m4pVNfhfl71ZtPLTuAVvsR4RWk7t75IwpHwiPBcgZn/PTpN45z"

key_name   = "" # the filename of the private SSL key 
public_key = "" # the matching public key (ssh-keygen -y -f your-key-pair.pem) 


# Example: 
# vpc_id = "vpc-0381e9f82c9ae68e7"
# vpc_id = "" 		# the ID of an existing VPC to deploy resources to


# Example: 
# subnet_id = "subnet-01ce99f9006e8ed06"
# subnet_id = ""		# the ID of an existing Subnet within the VPC to deploy resources to

# Must specify this when not using a pre-provisioned subnet:
subnet_cidr = "10.0.0.0/24"

#------------------------------------------------------------


#---------------------------------------------------------------
# Optionally uncomment and change the defaults shown
#---------------------------------------------------------------

# preferred_region = "us-east-2"
# name_tag = "IOOS-Cloud-Sandbox"
# availability_zone = "us-east-2b"
# project_tag = "IOOS-Cloud-Sandbox"
# instance_type = "t3.medium"
# use_efa = false 

# You can give your AWS resources a unique name to avoid conflicts
# with other deployed sandboxes

# nameprefix="ioos-cloud-sandbox"
#---------------------------------------------------------------
