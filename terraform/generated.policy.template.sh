#!/bin/bash

Region='us-east-2'
Account='579273261343'
SubnetId='subnet-0be869ddbf3096968'
InstanceId='*'
NetworkInterfaceId='*'
SecurityGroupId='*'
ImageId='*'
KeyId='*'


cat << EOF

{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateTags",
				"ec2:DescribeInstanceTypes",
				"ec2:DescribeInstances"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:RunInstances",
				"ec2:TerminateInstances"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:instance/*"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:RunInstances",
			"Resource": "arn:aws:ec2:${Region}:${Account}:network-interface/*"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:RunInstances",
			"Resource": "arn:aws:ec2:${Region}:${Account}:security-group/*"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:RunInstances",
			"Resource": "arn:aws:ec2:${Region}:${Account}:subnet/${SubnetId}"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:RunInstances",
			"Resource": "arn:aws:ec2:${Region}::image/*"
		},
		{
			"Effect": "Allow",
			"Action": "kms:CreateGrant",
			"Resource": "arn:aws:kms:${Region}:${Account}:key/*"
		},
		{
			"Effect": "Allow",
			"Action": "ssm:GetParameters",
			"Resource": "arn:aws:ssm:${Region}:${Account}:parameter/*"
		}
	]
}

EOF
