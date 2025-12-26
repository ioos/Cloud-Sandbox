#!/usr/bin/env bash

cd ..

nosofs_roms=" cbofs ciofs  dbofs gomofs tbofs  wcofs"
nosofs_fvcom="leofs lmhofs loofs lsofs  ngofs2 sscofs sfbofs"

nosofs_roms="eccofs"
nosofs_fvcom=""

ofslist="$nosofs_roms $nosofs_fvcom"

create_ccfg () {
  ofs=$1
  ccfg=$2

  cat <<-EOL > $ccfg
	{
	"platform"  : "AWS",
	"region"    : "us-east-2",
	"nodeType"  : "hpc7a.96xlarge",
	"nodeCount" : 4,
	"tags"      : [
                { "Key": "Name", "Value": "$ofs-fcst" },
                { "Key": "Project", "Value": "IOOS-Cloud-Sandbox" }
              ],
	"key_name"  : "ioos-sandbox",
	"image_id"  : "ami-05b76b2fbe321afef",
	"sg_ids"    : [
 	"sg-07875712ac6c56ff0",
  	"sg-0ae91116e5c06332e",
  	"sg-0083673d340d5838d"
	],
	"subnet_id" : "subnet-0be869ddbf3096968",
	"placement_group" : "cloud-sandbox-08202025-us-east-2b_Terraform_Placement_Group"
	}
EOL
}


for ofs in $ofslist
do

  echo "ofs: $ofs"
  
  job=job/jobs/OFS/$ofs.fcst
  ccfg=./$ofs.cluster
  create_ccfg $ofs $ccfg
  
  echo "nohup workflows/workflow_main.py $ccfg $job >& out.$ofs &"
  nohup workflows/workflow_main.py $ccfg $job >& out.$ofs &

  echo "Sleeping for 10 seconds"
  sleep 10

done


