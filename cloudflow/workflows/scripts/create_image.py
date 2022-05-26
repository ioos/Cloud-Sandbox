#!/usr/bin/env python3

import sys
import traceback

import boto3
from botocore.exceptions import ClientError

DEBUG=False

def main():

    lenargs = len(sys.argv) - 1
    if lenargs == 2:
      snapshotid = sys.argv[1]
      imagename = sys.argv[2]
    else:
      print(f"{sys.argv[0]} <snapshot id> <image name>")
      sys.exit(1)

    imageid = create_image_from_snapshot(snapshotid, imagename)
    print(imageid)


def create_image_from_snapshot(snapshotId: str, imageName: str):

  # imagename needs to be unique

  region_name = 'us-east-2'
  ec2 = boto3.client('ec2', region_name=region_name )

  description='sandbox image from snapshot'
  imagename = imageName

  root_mapping = {
    'DeviceName': '/dev/sda1',
    'Ebs': {
      'DeleteOnTermination': True,
      'SnapshotId': snapshotId,
      'VolumeType': 'gp2'
    }
  }

  response=''

  try:
    response = ec2.register_image(
      Architecture='x86_64',
      BlockDeviceMappings=[ root_mapping ],
      Description=description,
      #DryRun=True,
      EnaSupport=True,
      Name=imagename,
      RootDeviceName='/dev/sda1',
      VirtualizationType='hvm'
    )
  except Exception as e:
    print(str(e))
    if DEBUG: traceback.print_stack()
    return None

  return response['ImageId']

#####################################################################
if __name__ == '__main__':
    main()
