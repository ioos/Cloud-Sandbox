#!/usr/bin/env bash

now=`date -u +\%Y\%m\%d_\%H-\%M`
ami_name="${now}-IOOS-Cloud-Sandbox"
project_tag="IOOS-Cloud-Sandbox"

./create_image.sh $ami_name $project_tag
