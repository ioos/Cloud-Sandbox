#!/bin/bash

IFACE=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs)

SUBNET_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${IFACE}/subnet-id)

VPC_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${IFACE}/vpc-id)

REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')

echo "IFACE: $IFACE"
echo "SUBNET_ID: $SUBNET_ID"
echo "VPC_ID: $VPC_ID"
echo "REGION: $REGION"
