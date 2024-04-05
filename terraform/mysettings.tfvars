# Spefify this file when running terraform.

# Examples:
# terraform plan -var-file="mysettings.tfvars"
# terraform apply -var-file="mysettings.tfvars"
# terraform destroy -var-file="mysettings.tfvars"

#------------------------------------------------------------
# The following variables must be defined, no defaults exist:
#------------------------------------------------------------

# List of the specific IP's or IP address rangest the are allowed SSH access to the system
# They should be in the format ###.###.###.###/32 for a single IP, any number of IPs can be added to the list.
# Example:  
allowed_ssh_cidr_list =  ["72.200.162.64/32", "96.238.4.28/32", "96.238.4.30/32"]

# Specify the PUBLIC SSL key below. (See the deployment documentation on how to create SSL keys.)
# The PRIVATE key should be in a secure folder with permissions only available to the user.

# Example:
key_name = "ioos-sandbox"
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2cQ3fq/VNzP1R2+94nGwonW9k20nuQJcCd3g2ylW5clzyjun6eWz2PZKMwtJh7E28B1jp3F8YTP5XBPg+Z++hpvcthL2XtAwANd0ouvZO6gkcrbgjhuM0A4NKJM6RylGAOqqPY/ZE6gOUGrnIbhd9eI3RKhSQbxf5hwS7tIG1FebO9HuObaM23LDB1/Ra/YMTXB5LHPChlfxrEIlM/0//tO7OUfRPNgtudAb/MQZ+YD+6I77QDtTwZwQvebxLK62bP5CrpV4XY5ybWOZ0T3m4pVNfhfl7+QWAvWeStNpH3B3q1ZtPLTuAVvsR4RWk7t75IwpHwiPBcgZn/PTpN45z"

# (Optional VPC) If using an existing VPC use the ID to deploy resources to use that VPC ID, otherwise leave blank
# vpc_id = "vpc-0dd381e9f82c9ae68e7"

# (Optional subnet) If using an existing subnet use the ID to deploy resources to use that subnet ID, otherwise leave blank
# Optional subnet.  Example: 
# subnet_id = "subnet-01ce99f9006e8ed06"

# Must specify this when not using a pre-provisioned subnet:
# A 10.* subnet is the recommended subnet addressing. It is private and un-routable from external networks.
subnet_cidr = "10.0.0.0/24"

#------------------------------------------------------------

#---------------------------------------------------------------
# Optionally uncomment and change the defaults shown
#---------------------------------------------------------------

# preferred_region = "us-east-2"
# name_tag = "IOOS-Cloud-Sandbox"
# availability_zone = "us-east-2b"
# project_tag = "IOOS-Cloud-Sandbox"
# instance_type = "t3.xlarge"
# use_efa = false 

# You can give your AWS resources a unique name to avoid conflicts
# with other deployed sandboxes

# nameprefix="ioos-cloud-sandbox"
#---------------------------------------------------------------
