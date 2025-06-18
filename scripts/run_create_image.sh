#!/usr/bin/env bash

now=`date -u +\%Y\%m\%d_\%H-\%M`
ami_name="IOOS-Cloud-Sandbox-${now}"
project_tag="IOOS-Cloud-Sandbox"

./create_image.sh $ami_name $project_tag
