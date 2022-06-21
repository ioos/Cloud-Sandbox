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
 
  # Region must be defined in AWS_DEFAULT_REGION env var
  # region_name = 'us-east-2'
  #ec2 = boto3.client('ec2', region_name=region_name )

  ec2 = boto3.client('ec2')

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

  # Wait for snapshot to be created - will throw an exception after 10 minutes
  #resrc = boto3.resource('ec2',region_name=region_name)
  resrc = boto3.resource('ec2')
  snapshot = resrc.Snapshot(snapshotId)

  print(f"... waiting for snapshot ... : snapshotId: {snapshot}")
  try:
    snapshot.wait_until_completed()
  except Exception as e:
    print("Exception: " + str(e))
    sys.exit(1)
 
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

  # Give it a Name tag also
  ec2.create_tags(
    Resources=[ response['ImageId'] ],
    Tags=[ { 'Key': 'Name',
             'Value': imageName } ])

  return response['ImageId']

#####################################################################
if __name__ == '__main__':
    main()
