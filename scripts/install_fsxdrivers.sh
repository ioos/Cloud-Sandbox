#!/usr/bin/env bash

# Run as sudo

# RedHat EL 8
# Kernel - uname -r
# 4.18.0-425.13.1.el8_7.x86_64

# Install rpm key
curl https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -o /tmp/fsx-rpm-public-key.asc

rpm --import /tmp/fsx-rpm-public-key.asc

# Add repo
curl https://fsx-lustre-client-repo.s3.amazonaws.com/el/8/fsx-lustre-client.repo -o /etc/yum.repos.d/aws-fsx.repo

# Do one of the following:

# If the command returns 4.18.0-553*, you don't need to modify the repository configuration. Continue to the To install the Lustre client procedure.

##### If the command returns 4.18.0-513*, you must edit the repository configuration so that it points to the Lustre client for the CentOS, Rocky Linux, and RHEL 8.9 release.

# If the command returns 4.18.0-477*, you must edit the repository configuration so that it points to the Lustre client for the CentOS, Rocky Linux, and RHEL 8.8 release.

# If the command returns 4.18.0-425*, you must edit the repository configuration so that it points to the Lustre client for the CentOS, Rocky Linux, and RHEL 8.7 release.

# sed -i 's#8#8.9#' /etc/yum.repos.d/aws-fsx.repo

yum clean all

yum install -y kmod-lustre-client lustre-client

# Create a new image
echo "Need to create a new AMI to use for the compute nodes"
#now=`date -u +\%Y\%m\%d_\%H-\%M`
#ami_name="IOOS-Cloud-Sandbox-${now}"


