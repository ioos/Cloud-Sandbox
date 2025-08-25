#!/usr/bin/env bash
# set -x 

outputfile=deployment.info

terraform output > $outputfile

key=`cat $outputfile | grep login_command | awk -F= '{print $2}' | awk '{print $3}'`
login=`cat $outputfile | grep login_command | awk -F= '{print $2}' | awk '{print $4}' | awk -F\" '{print $1}'`

remote_host=`cat deployment.info | grep login_command | awk -F@ '{print $2}' | awk -F\" '{print $1}'`
ssh-keyscan -H $remote_host >> ~/.ssh/known_hosts

echo "Copying deployment.info to head node"
echo "++++++++++++++++++++++++++++++++++++"
echo "scp -i $key -p $outputfile ${login}:~/$outputfile"

scp -i $key -p $outputfile ${login}:~/$outputfile
