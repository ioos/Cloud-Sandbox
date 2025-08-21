# Spefify this file when running terraform.

# Examples:
# terraform plan -var-file="mysettings.tfvars"
# terraform apply -var-file="mysettings.tfvars"
# terraform destroy -var-file="mysettings.tfvars"

#------------------------------------------------------------
# The following variables must be defined, no defaults exist:
#------------------------------------------------------------

# Specify the cloud sandbox branch or tag to use for the node setup
# will default to main if not defined. 
# Examples:
# sandbox_version = "main"

sandbox_version = "v2.1.0"

# List of the specific IP's or IP address ranges that are allowed SSH access to the system
# They should be in the format ###.###.###.###/32 for a single IP, any number of IPs can be added to the list.
# Example:  
allowed_ssh_cidr_list =  ["72.0.162.256/32", "94.256.4.28/32" ]

# Specify the PUBLIC SSL key below. (See the deployment documentation on how to create SSL keys.)
# The PRIVATE key should be in a secure folder with permissions only available to the user.

# Example:
key_name = "my-sandbox-key"
public_key = "ssh-rsa AAAABbbccd+long-sequence-of-characters+a123abcd+XYX/z910A"

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

# You can give your AWS resources a unique name to avoid conflicts
# with other deployed sandboxes

# nameprefix="my-cloud-sandbox"
#---------------------------------------------------------------
