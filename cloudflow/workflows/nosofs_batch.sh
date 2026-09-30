#!/usr/bin/env bash

echo $PWD

cd ..

nosofs_roms=" cbofs ciofs  dbofs gomofs tbofs  wcofs"
nosofs_fvcom="leofs lmhofs loofs lsofs  ngofs2 sfbofs sscofs"

# loofs failed

small_models="cbofs dbofs gomofs leofs sfbofs tbofs wcofs"  # < 60 minutes
medium_models="lmhofs lsofs sscofs"          # about 60-75 minutes
large_models="ciofs ngofs2"          # over 100 miutes (ngofs2 180)


#ofslist="$nosofs_roms $nosofs_fvcom"
# ofslist="$large_models $medium_models"
#ofslist="ciofs"
#ofslist="cbofs"
ofslist="gomofs"

create_ccfg () {
  ofs=$1
  ccfg=$2

  cat <<-EOL > $ccfg
        {
        "platform"  : "AWS",
        "region"    : "us-east-2",
        "nodeType"  : "hpc8a.96xlarge",
        "nodeType8"  : "hpc8a.96xlarge",
        "nodeType7"  : "hpc7a.96xlarge",
        "nodeType6"  : "hpc6a.48xlarge",
        "nodeCount" : 1,
        "vm_retry_delay": 60,
        "vm_max_retries": 8,
        "tags"      : [
                { "Key": "Name", "Value": "$ofs-fcst" },
                { "Key": "Project", "Value": "IOOS-Cloud-Sandbox" }
              ],
        "key_name"  : "ioos-sandbox",
        "image_id"  : "ami-0016507bcc8757666",
        "sg_ids"    : [ "sg-05cc98305ade69e79",
                      "sg-0e61daf5532b0d2e7",
                      "sg-01c9c2d5f3b42619f" ],
        "subnet_id"       : "subnet-0be869ddbf3096968",
        "placement_group" : "rhel10-sandbox-us-east-2b_Terraform_Placement_Group",
        "table_name" : "IOOS-Sandbox-Compute-Nodes"
        }
EOL
}

for ofs in $ofslist
do

  echo "ofs: $ofs"

  # Old sandbox
  # job=job/jobs/OFS/$ofs.fcst
  # ccfg=./$ofs.cluster

  # New sandbox
  job=../job.configs/OFS/$ofs.fcst
  ccfg=../cluster.configs/IOOS/$ofs.cluster
  create_ccfg $ofs $ccfg

  echo "nohup workflows/workflow_main.py $ccfg $job >& out.$ofs &"
  nohup workflows/workflow_main.py $ccfg $job >& out.$ofs &

  stime=10
  echo "Sleeping for $stime seconds"
  sleep $stime

done


