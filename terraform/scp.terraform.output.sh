#!/usr/bin/env bash
# set -x 

outputfile=deployment.info

echo "sleeping for 30 seconds to wait for output ..."
sleep 30
 
terraform output > $outputfile

key=`cat $outputfile | grep login_command | awk -F= '{print $2}' | awk '{print $3}'`
login=`cat $outputfile | grep login_command | awk -F= '{print $2}' | awk '{print $4}' | awk -F\" '{print $1}'`

remote_host=`cat $outputfile | grep login_command | awk -F@ '{print $2}' | awk -F\" '{print $1}'`
echo "remote_host: $remote_host"

ssh-keyscan -H $remote_host >> ~/.ssh/known_hosts

echo "Copying deployment.info to head node"
echo "++++++++++++++++++++++++++++++++++++"
echo "scp -i $key -p $outputfile ${login}:~/$outputfile"

scp -i $key -p $outputfile ${login}:~/$outputfile

