#!/usr/bin/env python3

import sys
import traceback

import boto3
from botocore.exceptions import ClientError

DEBUG=False

def main():

    lenargs = len(sys.argv) - 1
    if lenargs == 3:
      instance_id = sys.argv[1]
      image_name = sys.argv[2]
      project_tag = sys.argv[3]
    else:
      print(f"{sys.argv[0]} <instance_id> <image_name> <project_tag>")
      sys.exit(1)

    snapshot_id = create_snapshot(instance_id, image_name)
    image_id = create_image_from_snapshot(snapshot_id, image_name)
    return image_id


def create_snapshot(instance_id: str, name_tag: str, project_tag: str)

  ''' NOTE: Run 'sync' on filesystem to flush the disk cache before running this ''' 
  ec2 = boto3.client('ec2')

  try: 
    response = ec2.create_snapshots(
      # Description='string',
      InstanceSpecification={
          'InstanceId': instance_id,
          'ExcludeBootVolume': False
      },
      OutpostArn='string',
      TagSpecifications=[
          {
              'ResourceType': 'snapshot'
              'Tags': [
                  { 'Key': 'Name', 'Value': name_tag },
                  { 'Key': 'Project', 'Value': project_tag }
              ]
          },
      ],
      DryRun=False,
      CopyTagsFromSource='volume'
    )
  except Exception as e:
    print(str(e))
    if DEBUG: traceback.print_stack()
    return None

  snapshot_id = response['Snapshots'][0]['SnapshotId']
  return snapshot_id


def create_image_from_snapshot(snapshot_id: str, image_name: str):

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
      'SnapshotId': snapshot_id,
      'VolumeType': 'gp2'
    }
  }

  # Wait for snapshot to be created - will throw an exception after 10 minutes
  #resrc = boto3.resource('ec2',region_name=region_name)
  resrc = boto3.resource('ec2')
  snapshot = resrc.Snapshot(snapshot_id)

  print(f"... waiting for snapshot ... : snapshot_id: {snapshot}")

  maxtries=2
  tries=0
  while tries < maxtries:
    try:
      snapshot.wait_until_completed()
      break
    except Exception as e:
      print("Exception: " + str(e))
      tries += 1
      if tries == maxtries:
        print("ERROR: maxtries reached. something went wrong")
        sys.exit(2)
  
 
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
