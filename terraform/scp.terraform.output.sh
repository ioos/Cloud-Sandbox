#!/usr/bin/env bash
#set -x 

outputfile=deployment.info

wait_time=90
wait_time=0

echo "sleeping for $wait_time seconds to wait for output ..."
sleep $wait_time
 
terraform output > $outputfile
if grep -q "login_command" "$outputfile"; then
  echo "login_command found"

  key=`cat $outputfile | grep login_command | awk -F= '{print $2}' | awk '{print $3}'`
  login=`cat $outputfile | grep login_command | awk -F= '{print $2}' | awk '{print $4}' | awk -F\" '{print $1}'`
  remote_host=`cat $outputfile | grep login_command | awk -F@ '{print $2}' | awk -F\" '{print $1}'`
  echo "remote_host: $remote_host"

  ssh-keyscan -H $remote_host >> ~/.ssh/known_hosts

  echo "Copying deployment.info to head node"
  echo "++++++++++++++++++++++++++++++++++++"
  echo "scp -i $key -p $outputfile ${login}:~/$outputfile"

  scp -i $key -p $outputfile ${login}:~/$outputfile
else
  echo "WARNING: could not find login_command in output, might need longer wait_time"
fi

